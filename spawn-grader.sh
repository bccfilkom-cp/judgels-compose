#!/bin/bash

NUM_OF_GRADERS=2
IMAGE_VERSION="${JUDGELS_VERSION:-2.22.0}"
COMPOSE_NETWORK=judgels-compose_judgels-net

for(( i=0; i<NUM_OF_GRADERS; i++ ))
do
    echo "Creating judgels-grader-$i container....";

    docker run -d \
        --name judgels-grader-$i \
        --privileged \
        --network $COMPOSE_NETWORK \
        -v ./judgels/grader-$i/var:/judgels/grader/var \
        -v ./conf/judgels-grader.yml:/judgels/grader/var/conf/judgels-grader.yml \
        -v ./judgels/server/var/data:/judgels/server/var/data:ro \
        --health-cmd="pgrep -f judgels || exit 1" \
        --restart on-failure:3 \
        --log-driver json-file \
        --log-opt max-size=256m \
        --log-opt max-file=2 \
        -e JUDGELS_GRADER_APP_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/judgels/grader/var/log" \
        "ghcr.io/ia-toki/judgels/grader:${IMAGE_VERSION}"

    echo "judgels-grader-$i container created....";
done 