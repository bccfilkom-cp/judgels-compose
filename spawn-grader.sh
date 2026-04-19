#!/bin/bash

NUM_OF_GRADERS=2
IMAGE_VERSION="${JUDGELS_VERSION:-2.22.0}"
COMPOSE_NETWORK=judgels-compose_judgels-net

if docker ps -a --format '{{.Names}}' | grep -q '^judgels-server$'; then
    SAME_HOST=true
    echo "Detected judgels-server on this host. Same-VM deployment."
    echo "Server data will be bind-mounted into graders (no SSH needed)."
    echo "Ensure conf/judgels-grader.yml has:"
    echo "    serverBaseDataDir: /judgels/server/var/data"
else
    SAME_HOST=false
    echo "No judgels-server container found. Assuming separate-VM deployment."
    echo "Graders will fetch problem data over SSH."
    echo "Ensure conf/judgels-grader.yml has:"
    echo "    serverBaseDataDir: <user>@<core-vm>:/path/to/server/var/data"
    echo "    rsyncIdentityFile: var/conf/judgels-grader"
    echo "And that the SSH private key is placed at ./judgels/grader-<N>/var/conf/judgels-grader."
fi

read -p "Continue spawning $NUM_OF_GRADERS grader(s)? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

for(( i=0; i<NUM_OF_GRADERS; i++ ))
do
    echo "Creating judgels-grader-$i container....";

    DATA_MOUNT=()
    if [[ "$SAME_HOST" == "true" ]]; then
        DATA_MOUNT=(-v ./judgels/server/var/data:/judgels/server/var/data:ro)
    fi

    docker run -d \
        --name judgels-grader-$i \
        --privileged \
        --network $COMPOSE_NETWORK \
        -v ./judgels/grader-$i/var:/judgels/grader/var \
        -v ./conf/judgels-grader.yml:/judgels/grader/var/conf/judgels-grader.yml \
        "${DATA_MOUNT[@]}" \
        --health-cmd="pgrep -f judgels || exit 1" \
        --restart on-failure:3 \
        --log-driver json-file \
        --log-opt max-size=256m \
        --log-opt max-file=2 \
        -e JUDGELS_GRADER_APP_OPTS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/judgels/grader/var/log" \
        "ghcr.io/ia-toki/judgels/grader:${IMAGE_VERSION}"

    echo "judgels-grader-$i container created....";
done
