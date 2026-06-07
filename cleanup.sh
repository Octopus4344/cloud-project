#!/bin/zsh

# Użycie: ./cleanup.sh [aws_region] [environment]
# UWAGA: Usuwa WSZYSTKIE zasoby AWS – uruchom gdy chcesz przestać płacić!

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

AWS_REGION=${1:-eu-north-1}
ENVIRONMENT=${2:-dev}
CLUSTER_NAME=${3:-microservices-cluster}

force_delete_ecs_services() {
  echo "${YELLOW}Wymuszam usunięcie serwisów ECS (obsługa DRAINING)...${NC}"

  local SERVICE_ARNS
  SERVICE_ARNS=$(aws ecs list-services \
    --cluster "$CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query 'serviceArns' \
    --output text 2>/dev/null || true)

  if [[ -z "$SERVICE_ARNS" || "$SERVICE_ARNS" == "None" ]]; then
    echo "  Brak aktywnych serwisów ECS do usunięcia."
    return 0
  fi

  for SERVICE_ARN in $SERVICE_ARNS; do
    local SERVICE_NAME=${SERVICE_ARN##*/}
    echo "  Force delete: $SERVICE_NAME"
    aws ecs update-service \
      --cluster "$CLUSTER_NAME" \
      --service "$SERVICE_NAME" \
      --desired-count 0 \
      --region "$AWS_REGION" >/dev/null 2>&1 || true

    aws ecs delete-service \
      --cluster "$CLUSTER_NAME" \
      --service "$SERVICE_NAME" \
      --force \
      --region "$AWS_REGION" >/dev/null 2>&1 || true
  done

  local MAX_WAIT=1800
  local SLEEP_SECONDS=20
  local ELAPSED=0

  while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    SERVICE_ARNS=$(aws ecs list-services \
      --cluster "$CLUSTER_NAME" \
      --region "$AWS_REGION" \
      --query 'serviceArns' \
      --output text 2>/dev/null || true)

    if [[ -z "$SERVICE_ARNS" || "$SERVICE_ARNS" == "None" ]]; then
      echo "  Wszystkie serwisy ECS usunięte."
      return 0
    fi

    for SERVICE_ARN in $SERVICE_ARNS; do
      local SERVICE_NAME=${SERVICE_ARN##*/}
      aws ecs delete-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE_NAME" \
        --force \
        --region "$AWS_REGION" >/dev/null 2>&1 || true
    done

    sleep $SLEEP_SECONDS
    ELAPSED=$((ELAPSED + SLEEP_SECONDS))
    echo "  Oczekiwanie na usunięcie ECS... ${ELAPSED}s"
  done

  echo "${YELLOW}  Uwaga: timeout czekania na usunięcie ECS; kontynuuję cleanup.${NC}"
}

delete_alb_if_exists() {
  echo "${YELLOW}Sprawdzam i usuwam ALB blokujący publiczne ENI...${NC}"

  local LB_ARNS
  LB_ARNS=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "LoadBalancers[?contains(LoadBalancerName, 'microservices') || contains(LoadBalancerName, '${ENVIRONMENT}')].LoadBalancerArn" \
    --output text 2>/dev/null || true)

  if [[ -z "$LB_ARNS" || "$LB_ARNS" == "None" ]]; then
    echo "  Brak ALB do usunięcia."
    return 0
  fi

  for LB_ARN in $LB_ARNS; do
    echo "  Usuwam ALB: $LB_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$AWS_REGION" >/dev/null 2>&1 || true
    aws elbv2 wait load-balancers-deleted --load-balancer-arns "$LB_ARN" --region "$AWS_REGION" >/dev/null 2>&1 || true
  done
}

terraform_destroy_with_retries() {
  local ATTEMPT=1
  local MAX_ATTEMPTS=3

  while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    echo "${YELLOW}Terraform destroy (próba $ATTEMPT/$MAX_ATTEMPTS)...${NC}"
    if terraform destroy \
      -var="aws_region=$AWS_REGION" \
      -var="environment=$ENVIRONMENT" \
      -auto-approve; then
      echo "${GREEN}Terraform destroy zakończony sukcesem.${NC}"
      return 0
    fi

    echo "${YELLOW}Destroy nieudany – próba odblokowania zależności (ECS/ALB) i retry...${NC}"
    force_delete_ecs_services
    delete_alb_if_exists
    sleep 20
    ATTEMPT=$((ATTEMPT + 1))
  done

  echo "${RED}Terraform destroy nie powiódł się po $MAX_ATTEMPTS próbach.${NC}"
  return 1
}

echo "${RED}=== USUWANIE WSZYSTKICH ZASOBÓW AWS ===${NC}"
echo "${YELLOW}Region:${NC} $AWS_REGION | ${YELLOW}Środowisko:${NC} $ENVIRONMENT"
echo "${RED}To usunie: ECS, ECR, SQS, SNS, DynamoDB, S3, Cognito, Lambda, VPC, ALB, NAT Gateway, IAM roles!${NC}"
print -n "Czy na pewno chcesz usunąć WSZYSTKO? (wpisz 'TAK' żeby potwierdzić): "
read -r CONFIRM
if [[ "$CONFIRM" != "TAK" ]]; then
  echo "${GREEN}Anulowano.${NC}"
  exit 0
fi

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

# ----------------------------------------------------------------
# 1. Terraform destroy (usuwa wszystko zdefiniowane w Terraform)
# ----------------------------------------------------------------
echo "${YELLOW}[1/4] Terraform destroy...${NC}"
cd "$ROOT_DIR/terraform/stage2"

# Najpierw spróbuj usunąć serwisy ECS, które często blokują destroy (DRAINING)
force_delete_ecs_services

if [ -f ".terraform/terraform.tfstate" ] || [ -f "terraform.tfstate" ]; then
  terraform_destroy_with_retries || true
else
  echo "${YELLOW}Brak stanu Terraform – próba ręcznego czyszczenia...${NC}"
fi

# ----------------------------------------------------------------
# 2. Opróżnienie i usunięcie S3 (Terraform nie usuwa niepustych bucketów)
# ----------------------------------------------------------------
echo "${YELLOW}[2/4] Czyszczenie S3...${NC}"
for BUCKET in $(aws s3api list-buckets --query "Buckets[?contains(Name,'${ENVIRONMENT}')].Name" --output text --region $AWS_REGION 2>/dev/null); do
  echo "  Opróżniam bucket: $BUCKET"
  aws s3 rm "s3://$BUCKET" --recursive --region $AWS_REGION 2>/dev/null || true
  aws s3 rb "s3://$BUCKET" --force --region $AWS_REGION 2>/dev/null || true
done

# ----------------------------------------------------------------
# 3. Opróżnienie repozytoriów ECR (Terraform nie usuwa niepustych)
# ----------------------------------------------------------------
echo "${YELLOW}[3/4] Czyszczenie ECR...${NC}"
for REPO in $(aws ecr describe-repositories --query "repositories[?contains(repositoryName,'${ENVIRONMENT}') || contains(repositoryName,'service')].repositoryName" --output text --region $AWS_REGION 2>/dev/null); do
  echo "  Usuwam obrazy z ECR: $REPO"
  IMAGE_IDS=$(aws ecr list-images --repository-name "$REPO" --query 'imageIds[*]' --output json --region $AWS_REGION 2>/dev/null)
  if [[ "$IMAGE_IDS" != "[]" && -n "$IMAGE_IDS" ]]; then
    aws ecr batch-delete-image --repository-name "$REPO" --image-ids "$IMAGE_IDS" --region $AWS_REGION 2>/dev/null || true
  fi
  aws ecr delete-repository --repository-name "$REPO" --force --region $AWS_REGION 2>/dev/null || true
done

# ----------------------------------------------------------------
# 4. Usunięcie NAT Gateway i Elastic IP (kosztują nawet jak ECS nie działa!)
# ----------------------------------------------------------------
echo "${YELLOW}[4/4] Czyszczenie NAT Gateway i Elastic IP...${NC}"
for NAT_ID in $(aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query "NatGateways[].NatGatewayId" --output text --region $AWS_REGION 2>/dev/null); do
  echo "  Usuwam NAT Gateway: $NAT_ID"
  aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" --region $AWS_REGION 2>/dev/null || true
done

# Poczekaj na usunięcie NAT Gateway przed zwolnieniem EIP
echo "  Czekam 30s na usunięcie NAT Gateway..."
sleep 30

for ALLOC_ID in $(aws ec2 describe-addresses --query "Addresses[?Domain=='vpc' && AssociationId==null].AllocationId" --output text --region $AWS_REGION 2>/dev/null); do
  echo "  Zwalninam Elastic IP: $ALLOC_ID"
  aws ec2 release-address --allocation-id "$ALLOC_ID" --region $AWS_REGION 2>/dev/null || true
done

echo ""
echo "${GREEN}=== Czyszczenie zakończone! ===${NC}"
echo "${YELLOW}Sprawdź w AWS Console czy nie zostały żadne zasoby:${NC}"
echo "  - EC2 > Instances (powinno być puste)"
echo "  - EC2 > Load Balancers (powinno być puste)"
echo "  - EC2 > NAT Gateways (powinno być 'deleted')"
echo "  - EC2 > Elastic IPs (powinno być puste)"
echo "  - DynamoDB > Tables (powinno być puste)"
echo "  - SQS > Queues (powinno być puste)"
echo "  - ECR > Repositories (powinno być puste)"
echo "  - Lambda > Functions (powinno być puste)"
