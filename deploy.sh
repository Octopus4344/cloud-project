#!/bin/zsh

# Script do wdrażania mikrousług do AWS
# Użycie: ./deploy.sh [aws_region] [environment]

# Kolory do wyświetlania
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Podstawowe zmienne
AWS_REGION=${1:-us-east-1}
ENVIRONMENT=${2:-dev}
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

# Pobieranie danych połączeniowych
echo "${YELLOW}Proszę podać następujące dane połączeniowe:${NC}"
read -s -p "URL bazy danych Supabase: " SUPABASE_DB_URL
echo
read -s -p "URL RabbitMQ (np. amqp://user:pass@host:port): " RABBITMQ_URL
echo

# Deployment etapu 2 (mikrousługi)
echo "${GREEN}Wdrażanie mikrousług...${NC}"
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

echo "${YELLOW}Budowanie i wypychanie authorities-service...${NC}"
cd ../../apps/authorities-service
docker build -t $AUTHORITIES_SERVICE_REPO:latest .
docker push $AUTHORITIES_SERVICE_REPO:latest

echo "${YELLOW}Budowanie i wypychanie road-event-service...${NC}"
cd ../road-event-service
docker build -t $ROAD_EVENT_SERVICE_REPO:latest .
docker push $ROAD_EVENT_SERVICE_REPO:latest

echo "${YELLOW}Budowanie i wypychanie statistics-service...${NC}"
cd ../satistics-service
docker build -t $STATISTICS_SERVICE_REPO:latest .
docker push $STATISTICS_SERVICE_REPO:latest

echo "${YELLOW}Budowanie i wypychanie user-data-service...${NC}"
cd ../user-data-service
docker build -t $USER_DATA_SERVICE_REPO:latest .
docker push $USER_DATA_SERVICE_REPO:latest

echo "${YELLOW}Budowanie i wypychanie user-location-service...${NC}"
cd ../user-location-service
docker build -t $USER_LOCATION_SERVICE_REPO:latest .
docker push $USER_LOCATION_SERVICE_REPO:latest

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