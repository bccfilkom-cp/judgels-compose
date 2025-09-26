#!/bin/bash

# Source environment variables
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# Create directories for judgels client and server
mkdir -p ./judgels/client/var ./judgels/server/var ./logs
chmod -R 777 ./judgels

# Spin up the Judgels Containers
docker compose up -d

# Health check for containers
echo 'Waiting for Judgels services to start...'
for service in judgels-proxy judgels-client judgels-server judgels-db judgels-rabbitmq; do
  echo "Checking status of $service..."
  until [ "`docker inspect -f {{.State.Status}} $service`" == "running" ]; do
    echo "Waiting for $service to be in 'running' state..."
    sleep 3
  done;
  echo "$service is running."
done

echo 'All Judgels services are up and running!'

# Run the migration
COMPOSE_NETWORK=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Networks}}{{$p}}{{end}}' judgels-server)

echo "Running Judgels Server migration...";

docker run --rm \
    --name judgels-server-migrate \
    --network "$COMPOSE_NETWORK" \
    --env-file .env \
    -v "./conf/judgels-server.yml:/judgels/server/var/conf/judgels-server.yml" \
    -v "./logs/judgels-server.log:/judgels/server/var/log/judgels-server.log" \
    ghcr.io/ia-toki/judgels/server:${JUDGELS_VERSION} \
    db migrate