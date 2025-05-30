# Cloud Project Terraform Configuration

Ta konfiguracja Terraform tworzy infrastrukturę AWS dla projektu Cloud Project, składającego się z mikrousług.

## Architektura

Infrastruktura obejmuje:

- VPC z publicznymi i prywatnymi podsieciami w wielu strefach dostępności
- Application Load Balancer dla każdej mikrousługi
- ECS Fargate do uruchamiania konteneryzowanych usług
- Repozytoria ECR dla obrazów Docker
- Logi CloudWatch do monitorowania

## Uwzględnione usługi

Infrastruktura jest skonfigurowana do wdrażania następujących mikrousług:

- authorities-service (Port 3000)
- cloud-project (Port 3001)
- road-event-service (Port 3002)
- satistics-service (Port 3003) - uwaga na literówkę w nazwie
- user-location-service (Port 3004)
- user-data-service (Port 3006)

## Wymagania wstępne

- AWS CLI skonfigurowane z odpowiednimi uprawnieniami
- Terraform >= 1.2.0
- Docker do budowania obrazów kontenerów

## Kroki wdrożenia

1. Zbuduj obrazy Docker:
   ```bash
   ./deploy.sh
   ```

2. Zainicjuj Terraform:
   ```bash
   cd terraform
   terraform init
   ```

3. Zaplanuj wdrożenie:
   ```bash
   terraform plan -var "rabbitmq_url=amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih"
   ```

4. Zastosuj konfigurację:
   ```bash
   terraform apply -var "rabbitmq_url=amqps://mlkhbtih:f1Mp-g3869SZYiRpiZuF0lecqwjcCJGj@seal.lmq.cloudamqp.com/mlkhbtih"
   ```

5. Po udanym wdrożeniu Terraform wyświetli adresy URL do dostępu do każdej usługi.

## Zmienne

Kluczowe zmienne, które można dostosować:

- `aws_region`: Region AWS do wdrażania zasobów (domyślnie: us-east-1)
- `project_name`: Prefiks nazwy dla zasobów (domyślnie: cloud-project)
- `rabbitmq_url`: Ciąg połączenia dla RabbitMQ
- `services`: Konfiguracja dla każdej mikrousługi (porty, CPU, pamięć itp.)

## Czyszczenie

Aby usunąć wszystkie utworzone zasoby:

```bash
terraform destroy
```
