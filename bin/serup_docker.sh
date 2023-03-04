#!/usr/bin/env bash

set +ex

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic, 
# shellcheck disable=SC1091
source "$DIR/echoerr.sh"

echoerr 'initializing docker swarm'
docker swarm init

echoerr 'adding this host as a node to the docker swarm'
docker swarm join
