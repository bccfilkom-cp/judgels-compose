#!/bin/bash

# Source environment variables
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

NUM_OF_GRADERS=${NUM_OF_GRADERS:-2}
COMPOSE_NETWORK=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Networks}}{{$p}}{{end}}' judgels-server)

if [ -z "$COMPOSE_NETWORK" ]; then
    echo "Could not find the judgels-server container. Is it running?"
    exit 1
fi

for(( i=0; i<NUM_OF_GRADERS; i++ ))
do
    echo "Creating judgels-grader-$i container....";

    docker run -d --rm \
        --name judgels-grader-$i \
        --network "$COMPOSE_NETWORK" \
        --privileged \
        --env-file .env \
        -v ./judgels/grader/var:/judgels/grader/var \
        -v ./conf/judgels-grader.yml:/judgels/grader/var/conf/judgels-grader.yml \
        --log-driver json-file \
        --log-opt max-size=256m \
        --log-opt max-file=2 \
        -e JUDGELS_GRADER_APP_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/judgels/grader/var/log" \
        ghcr.io/ia-toki/judgels/grader:${JUDGELS_VERSION}

    echo "Judgels-grader-$i container created....";
done