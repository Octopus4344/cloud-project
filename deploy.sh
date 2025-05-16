#!/bin/zsh

# Script do wdrażania mikrousług do AWS
# Użycie: ./deploy.sh [aws_region] [environment] [rabbitmq_url]
# Parametry:
#   aws_region    - Region AWS (domyślnie: us-east-1)
#   environment   - Środowisko (domyślnie: dev)
#   rabbitmq_url  - URL RabbitMQ (opcjonalny)

# Kolory do wyświetlania
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Podstawowe zmienne
AWS_REGION=${1:-us-east-1}
ENVIRONMENT=${2:-dev}
# Użycie opcjonalnego argumentu dla RabbitMQ URL
RABBITMQ_URL=${3:-"amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih"}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# Flaga usunięta, będziemy zawsze budować bez cache

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

# Funkcja do czyszczenia Docker
docker_cleanup() {
  local SILENT=${1:-false}
  
  if [ "$SILENT" != "true" ]; then
    echo "${YELLOW}Rozpoczynam czyszczenie Docker...${NC}"
  fi
  
  # Zatrzymaj wszystkie kontenery
  if [ "$SILENT" = "true" ]; then
    docker stop $(docker ps -aq 2>/dev/null) 2>/dev/null || true
  else
    echo "${YELLOW}Zatrzymuję wszystkie kontenery...${NC}"
    docker stop $(docker ps -aq 2>/dev/null) 2>/dev/null || true
  fi
  
  # Usuń wszystkie kontenery
  if [ "$SILENT" = "true" ]; then
    docker rm $(docker ps -aq 2>/dev/null) 2>/dev/null || true
  else
    echo "${YELLOW}Usuwam wszystkie kontenery...${NC}"
    docker rm $(docker ps -aq 2>/dev/null) 2>/dev/null || true
  fi
  
  # Usuń wszystkie nieużywane obrazy
  if [ "$SILENT" = "true" ]; then
    docker image prune -af > /dev/null 2>&1 || true
  else
    echo "${YELLOW}Usuwam wszystkie nieużywane obrazy...${NC}"
    docker image prune -af || true
  fi
  
  if [ "$SILENT" != "true" ]; then
    echo "${GREEN}Czyszczenie Docker zakończone!${NC}"
    echo "${YELLOW}Obecnie zajęte miejsce przez Docker:${NC}"
    docker system df
  fi
}

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

# Najpierw uruchom czyszczenie, aby mieć pewność, że mamy wolne miejsce
echo "${YELLOW}Uruchamiam czyszczenie przed rozpoczęciem wdrażania...${NC}"
docker_cleanup

cd terraform

# Inicjalizacja Terraform
echo "${YELLOW}Inicjalizacja Terraform...${NC}"
terraform init

# Jeśli wybrano usuwanie istniejących zasobów
if [ "$DEPLOYMENT_MODE" = "2" ]; then
    echo "${YELLOW}Usuwanie istniejących zasobów w AWS...${NC}"
    
    # Uruchom skrypt czyszczący z odpowiednimi parametrami
    cd ../
    ./cleanup.sh $AWS_REGION
    cd terraform
    
    # Ponowna inicjalizacja Terraform po czyszczeniu
    echo "${YELLOW}Inicjalizacja Terraform po czyszczeniu...${NC}"
    terraform init
fi

# Apply konfiguracji
echo "${YELLOW}Aplikowanie konfiguracji Terraform...${NC}"
terraform apply \
  -var="aws_region=$AWS_REGION" \
  -var="rabbitmq_url=$RABBITMQ_URL" \
  -auto-approve

if [ $? -ne 0 ]; then
    echo "${RED}Deployment nie powiódł się. Sprawdź logi powyżej.${NC}"
    exit 1
fi

# Pobieranie URL z repozytoriów ECR
echo "${YELLOW}Pobieranie adresów repozytoriów ECR...${NC}"
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

# Funkcja do budowania i wypychania każdego serwisu
build_and_push() {
  local SERVICE=$1
  local REPO_URL=$2
  echo "${YELLOW}Budowanie i wypychanie $SERVICE...${NC}"
  
  # Sprawdź czy Dockerfile istnieje
  if [ ! -f "$ROOT_DIR/apps/$SERVICE/Dockerfile" ]; then
    echo "${RED}Błąd: Dockerfile dla $SERVICE nie istnieje w $ROOT_DIR/apps/$SERVICE/Dockerfile${NC}"
    return 1
  fi
  
  echo "${YELLOW}Budowanie $SERVICE z $ROOT_DIR/apps/$SERVICE/Dockerfile...${NC}"
  
  # Budowanie obrazu Docker
  docker build \
    -t $REPO_URL:latest \
    -f $ROOT_DIR/apps/$SERVICE/Dockerfile \
    $ROOT_DIR
  
  if [ $? -ne 0 ]; then
    echo "${RED}Budowanie obrazu dla $SERVICE nie powiodło się${NC}"
    return 1
  fi
    
  # Wypchnij obraz do ECR
  echo "${YELLOW}Wypychanie $SERVICE do ECR...${NC}"
  docker push $REPO_URL:latest
  
  if [ $? -ne 0 ]; then
    echo "${RED}Wypychanie obrazu dla $SERVICE nie powiodło się${NC}"
    return 1
  fi
  
  # Usuń lokalny obraz
  docker rmi $REPO_URL:latest
  
  echo "${GREEN}$SERVICE pomyślnie zbudowany i wypchnięty do ECR${NC}"
  return 0
}

# Zbuduj i wypchnij wszystkie serwisy
echo "${YELLOW}Budowanie i wypychanie wszystkich serwisów...${NC}"

build_and_push "authorities-service" "$AUTHORITIES_SERVICE_REPO"
build_and_push "road-event-service" "$ROAD_EVENT_SERVICE_REPO"
build_and_push "satistics-service" "$STATISTICS_SERVICE_REPO"
build_and_push "user-data-service" "$USER_DATA_SERVICE_REPO"
build_and_push "user-location-service" "$USER_LOCATION_SERVICE_REPO"

# Aktualizacja ECS usług, aby użyć nowych obrazów
echo "${GREEN}Aktualizacja usług ECS...${NC}"
cd ../terraform
terraform apply \
  -var="aws_region=$AWS_REGION" \
  -var="rabbitmq_url=$RABBITMQ_URL" \
  -auto-approve

# Pobranie adresu URL load balancera
ALB_DNS=$(terraform output -raw alb_dns_name)

# Finalne czyszczenie po deploymencie
echo "${YELLOW}Finalne czyszczenie po deploymencie...${NC}"
docker_cleanup

echo "${GREEN}Deployment zakończony pomyślnie!${NC}"
echo "${YELLOW}Twoje mikrousługi są dostępne pod adresem:${NC} http://$ALB_DNS"
echo "Endpointy:"
echo "- Authorities Service: http://$ALB_DNS/authorities"
echo "- Road Event Service: http://$ALB_DNS/road-events"
echo "- Statistics Service: http://$ALB_DNS/statistics"
echo "- User Data Service: http://$ALB_DNS/user-data"
echo "- User Location Service: http://$ALB_DNS/user-location"