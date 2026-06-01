```bash
docker compose up -d
docker compose down

docker compose build
docker stack deploy -c docker-compose.yml traffic-stack
docker service ls
docker service scale traffic-stack_road-event-service=5
docker stack rm traffic-stack
```