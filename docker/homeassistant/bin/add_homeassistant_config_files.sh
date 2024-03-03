#!/usr/bin/env bash

set -euxo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
homeassistant_root_dir=$(dirname "$script_dir")
homeassistant_config_dir="${homeassistant_root_dir}/homeassistant-config"
docker_project_dir=$(dirname "$homeassistant_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

mkdir -p "$homeassistant_config_dir"
echoerr "creating a homeassistant scenes file"
touch "${homeassistant_config_dir}/scenes.yaml"

echoerr "creating a homeassistant automations file"
touch "${homeassistant_config_dir}/automations.yaml"
