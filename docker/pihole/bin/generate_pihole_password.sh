#! /usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pihole_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$pihole_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

container_id="$(docker ps --filter "status=running" --filter "name=pihole" -q)"

if [[ -z "$container_id" ]]; then
  echoerr 'ERROR: pihole must be running in order to set a password. Ensure that pihole is running before trying to set a new pihole password'
  exit 1
else
  docker exec -it "$container_id" 'pihole -a -p'
fi
