#!/bin/bash

NUM_OF_GRADERS=2
IMAGE_VERSION="${JUDGELS_VERSION:-2.22.0}"

for(( i=0; i<NUM_OF_GRADERS; i++ ))
do
    echo "Creating judgels-grader-$i container....";

    docker run \ 
        --name judgels-grader-$i \
        --network judgels-compose_judgels-net \
        --privileged \
        -v ./judgels/grader/var:/judgels/grader/var \
        -v ./conf/judgels-grader.yml:/judgels/grader/var/conf/judgels-grader.yml \
        --log-driver json-file \
        --log-opt max-size=256m \
        --log-opt max-file=2 \
        -e JUDGELS_GRADER_APP_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/judgels/grader/var/log" \
        "ghcr.io/ia-toki/judgels/grader:${IMAGE_VERSION}"

    echo "Judgels-grader-$i container created....";
done 