#!/bin/zsh

# Użycie: ./cleanup.sh [aws_region] [environment]
# UWAGA: Usuwa WSZYSTKIE zasoby AWS – uruchom gdy chcesz przestać płacić!

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

AWS_REGION=${1:-eu-north-1}
ENVIRONMENT=${2:-dev}

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
if [ -f ".terraform/terraform.tfstate" ] || [ -f "terraform.tfstate" ]; then
  terraform destroy \
    -var="aws_region=$AWS_REGION" \
    -var="environment=$ENVIRONMENT" \
    -auto-approve
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
