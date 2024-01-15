#! /usr/bin/env bash

set -e

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
homeassistant_root_dir=$(dirname "$script_dir")
homeassistant_config_dir="${homeassistant_root_dir}/homeassistant-config"
docker_project_dir=$(dirname "$homeassistant_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

hass_node_red_git_uri='git@github.com:zachowj/hass-node-red.git'

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

tempdir=$(mktemp -d)

function cleanup() {
  rm -rf "$tempdir"
}

trap cleanup EXIT

echoerr "tempdir is ${tempdir}"
echoerr "cloning ${hass_node_red_git_uri} into ${tempdir}"
git clone "$hass_node_red_git_uri" "$tempdir"

hass_node_red_custom_component_dir="${homeassistant_config_dir}/custom_components/nodered"
echoerr "creating the nodered custom component directory \`${hass_node_red_custom_component_dir}\`"
mkdir -p "$hass_node_red_custom_component_dir"

echoerr "moving hass-node-red custom component files into the nodered custom component directory"
mv "${tempdir}/custom_components/nodered/*" "$hass_node_red_custom_component_dir"

echoerr "done installing hass-node-red custom component. Restart homeassistant and \
install the node-red integration from the UI"
