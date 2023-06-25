#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
zigbee2mqtt_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$zigbee2mqtt_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"


function ensure_file_exists() {
  local file_path=$1
  if [ ! -f "$file_path" ]; then
    echoerr "unable to find required file ${file_path}. Ensure this file exists before proceeding"
    exit 1
  fi
}

#ensure that the ca cert has been created
pihome_ca_cert=${project_root_dir}/ssl/ca/pihome-ca.pem
ensure_file_exists "$pihome_ca_cert"

# ensure that all of the certs have been created
certs_root_dir="${project_root_dir}/ssl/certs"
mosquitto_server_certs_dir="$certs_root_dir/mosquitto-server"
mosquitto_server_key="$mosquitto_server_certs_dir/server.key"
mosquitto_server_cert="$mosquitto_server_certs_dir/server.crt"

mosquitto_client_certs_dir="$certs_root_dir/mosquitto-client"
mosquitto_client_key="$mosquitto_client_certs_dir/client.key"
mosquitto_client_cert="$mosquitto_client_certs_dir/client.crt"

ensure_file_exists "$mosquitto_server_key"
ensure_file_exists "$mosquitto_server_cert"
ensure_file_exists "$mosquitto_client_key"
ensure_file_exists "$mosquitto_client_cert"

mosquitto_server_cert_destination_dir="$zigbee2mqtt_root_dir/mosquitto-ssl"
mkdir -p "$mosquitto_server_cert_destination_dir"
cp "$mosquitto_server_key" "$mosquitto_server_cert_destination_dir"
cp "$mosquitto_server_cert" "$mosquitto_server_cert_destination_dir"
cp "$pihome_ca_cert" "$mosquitto_server_cert_destination_dir"

mosquitto_client_cert_destination_dir="$zigbee2mqtt_root_dir/zigbee2mqtt-ssl"
mkdir -p "$mosquitto_client_cert_destination_dir"
cp "$mosquitto_client_key" "$mosquitto_client_cert_destination_dir"
cp "$mosquitto_client_cert" "$mosquitto_client_cert_destination_dir"
cp "$pihome_ca_cert" "$mosquitto_client_cert_destination_dir"

echoerr "done copying mosquitto server and client certificates"
