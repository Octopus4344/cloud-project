#!/bin/zsh

# Script do wdrażania mikrousług do AWS
# Użycie: ./deploy.sh [aws_region] [environment] [supabase_db_url] [rabbitmq_url]

# Kolory do wyświetlania
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Podstawowe zmienne
AWS_REGION=${1:-us-east-1}
ENVIRONMENT=${2:-dev}
# Użycie opcjonalnych argumentów 3 i 4 dla stałych URL-i
SUPABASE_DB_URL=${3:-"postgresql://postgres.sfbspjuexczprymnpoer:postgres@aws-0-eu-central-2.pooler.supabase.com:5432/postgres"}
RABBITMQ_URL=${4:-"amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "${BLUE}=== Deployment Mikrousług do AWS ===${NC}"
echo "${YELLOW}Region AWS:${NC} $AWS_REGION"
echo "${YELLOW}Środowisko:${NC} $ENVIRONMENT"
echo "${YELLOW}ID konta AWS:${NC} $ACCOUNT_ID"

# Sprawdzanie, czy narzędzia są zainstalowane
if ! command -v aws &> /dev/null; then
    echo "${RED}AWS CLI nie jest zainstalowane. Proszę najpierw zainstalować AWS CLI.${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "${RED}Terraform nie jest zainstalowany. Proszę najpierw zainstalować Terraform.${NC}"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "${RED}Docker nie jest zainstalowany. Proszę najpierw zainstalować Docker.${NC}"
    exit 1
fi

# Funkcja do potwierdzenia
confirm() {
    read -p "$1 (t/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Tt]$ ]]; then
        echo "${RED}Deployment przerwany.${NC}"
        exit 1
    fi
}

confirm "Czy chcesz kontynuować wdrażanie mikrousług do AWS?"

# Pytanie o tryb wdrożenia
echo "${YELLOW}Wybierz tryb wdrożenia:${NC}"
echo "1) Normalne wdrożenie (może zawieść, jeśli zasoby już istnieją)"
echo "2) Najpierw usuń istniejące zasoby (zalecane, jeśli występują błędy z istniejącymi zasobami)"
read -p "Twój wybór (1/2): " DEPLOYMENT_MODE
echo

echo "${GREEN}Wdrażanie mikrousług...${NC}"
# Przechodzimy do katalogu głównego projektu
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

cd terraform/stage2

# Inicjalizacja Terraform
echo "${YELLOW}Inicjalizacja Terraform...${NC}"
terraform init

# Jeśli wybrano usuwanie istniejących zasobów
if [ "$DEPLOYMENT_MODE" = "2" ]; then
    echo "${YELLOW}Usuwanie istniejących zasobów w AWS...${NC}"
    
    # Uruchom skrypt czyszczący z odpowiednimi parametrami
    cd ../../
    ./cleanup.sh $AWS_REGION
    cd terraform/stage2
    
    # Ponowna inicjalizacja Terraform po czyszczeniu
    echo "${YELLOW}Inicjalizacja Terraform po czyszczeniu...${NC}"
    terraform init
fi

# Apply konfiguracji
echo "${YELLOW}Aplikowanie konfiguracji Terraform...${NC}"
terraform apply \
  -var="aws_region=$AWS_REGION" \
  -var="environment=$ENVIRONMENT" \
  -var="supabase_db_url=$SUPABASE_DB_URL" \
  -var="rabbitmq_url=$RABBITMQ_URL" \
  -auto-approve

if [ $? -ne 0 ]; then
    echo "${RED}Deployment etapu 2 nie powiódł się. Sprawdź logi powyżej.${NC}"
    exit 1
fi

# Pobieranie URL z repozytoriów ECR
AUTHORITIES_SERVICE_REPO=$(terraform output -raw ecr_authorities_service_repository_url)
ROAD_EVENT_SERVICE_REPO=$(terraform output -raw ecr_road_event_service_repository_url)
STATISTICS_SERVICE_REPO=$(terraform output -raw ecr_statistics_service_repository_url)
USER_DATA_SERVICE_REPO=$(terraform output -raw ecr_user_data_service_repository_url)
USER_LOCATION_SERVICE_REPO=$(terraform output -raw ecr_user_location_service_repository_url)

# Logowanie do ECR
echo "${YELLOW}Logowanie do Amazon ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Budowanie i wypychanie obrazów Docker
echo "${GREEN}Budowanie i wypychanie obrazów Docker do ECR...${NC}"

# Funckja do budowania i wypychania każdego serwisu
build_and_push() {
  local SERVICE=$1
  local REPO_URL=$2
  echo "${YELLOW}Budowanie i wypychanie $SERVICE...${NC}"
  docker build -t $REPO_URL:latest -f $ROOT_DIR/apps/$SERVICE/Dockerfile $ROOT_DIR
  docker push $REPO_URL:latest
}

build_and_push authorities-service $AUTHORITIES_SERVICE_REPO
build_and_push road-event-service $ROAD_EVENT_SERVICE_REPO
build_and_push satistics-service $STATISTICS_SERVICE_REPO
build_and_push user-data-service $USER_DATA_SERVICE_REPO
build_and_push user-location-service $USER_LOCATION_SERVICE_REPO

# Aktualizacja ECS usług, aby użyć nowych obrazów
echo "${GREEN}Aktualizacja usług ECS...${NC}"
cd ../../terraform/stage2
terraform apply \
  -var="aws_region=$AWS_REGION" \
  -var="environment=$ENVIRONMENT" \
  -var="supabase_db_url=$SUPABASE_DB_URL" \
  -var="rabbitmq_url=$RABBITMQ_URL" \
  -auto-approve

# Pobranie adresu URL load balancera
ALB_DNS=$(terraform output -raw alb_dns_name)

echo "${GREEN}Deployment zakończony pomyślnie!${NC}"
echo "${YELLOW}Twoje mikrousługi są dostępne pod adresem:${NC} http://$ALB_DNS"
echo "Endpointy:"
echo "- Authorities Service: http://$ALB_DNS/authorities"
echo "- Road Event Service: http://$ALB_DNS/road-events"
echo "- Statistics Service: http://$ALB_DNS/statistics"
echo "- User Data Service: http://$ALB_DNS/user-data"
echo "- User Location Service: http://$ALB_DNS/user-location"