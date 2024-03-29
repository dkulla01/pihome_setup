#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
zigbee2mqtt_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$zigbee2mqtt_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

if ! command -v yq; then
  echoerr "yq must be installed to create the mosquitto password files"
  exit 1
fi

mosquitto_username=
if [ -z "$1" ]; then
  echoerr "You did not pass in a mosquitto username. Using the default username \`pi\`"
  mosquitto_username='pi'
else
  mosquitto_username=$1
  echoerr "using mosquitto_username \`$mosquitto_username\`"
fi

read -r -s -p "enter your desired mqtt password: " mqtt_password
printf '\n'
read -r -s -p "confirm your mqtt password: " confirm_password
printf '\n'
if [[ "$mqtt_password" != "$confirm_password" ]]; then
  echoerr "passwords do not match. exiting."
  exit 1
fi

mosquitto_config_dirname='mosquitto-config'
mosquitto_config_dir="$zigbee2mqtt_root_dir/$mosquitto_config_dirname"
mosquitto_passwd_filename='passwordfile'
mosquitto_passwd_file="$mosquitto_config_dir/$mosquitto_passwd_filename"

echoerr "making sure the mosquitto-config dir \`$mosquitto_config_dir\` exists"
mkdir -p "$mosquitto_config_dir"

if [ -f "$mosquitto_passwd_file" ]; then
  echoerr "a mosquitto passwd file already exists: \`$mosquitto_passwd_file\`. if you need a new one, delete this file"
else
  echoerr "creating a mosquitto passwd file with user \`$mosquitto_username\`"
  touch "$mosquitto_config_dirname/$mosquitto_passwd_filename"
  docker run -v "$mosquitto_config_dir:/$mosquitto_config_dirname" \
    -w / \
    -it eclipse-mosquitto:2.0 mosquitto_passwd \
    -b \
    "/$mosquitto_config_dirname/$mosquitto_passwd_filename" \
    "$mosquitto_username" \
    "$mqtt_password"

fi

echoerr 'generating network key for zigbee network'
readarray -t network_key_hex < <(openssl rand -hex 16 | fold -w2)
delim=''
joined=''

for key_byte in "${network_key_hex[@]}"; do
    joined="${joined}${delim}0x${key_byte}"
    delim=', '
done
network_key_array_string="[${joined}]" 

zigbee2mqtt_config_dirname=zigbee2mqtt-data
zigbee2mqtt_mqtt_password_template_filename=secret.template.yaml
zigbee2mqtt_mqtt_password_filename=secret.yaml

zigbee2mqtt_mqtt_password_file="${zigbee2mqtt_root_dir}/${zigbee2mqtt_config_dirname}/${zigbee2mqtt_mqtt_password_filename}"
zigbee2mqtt_mqtt_password_template_file="${zigbee2mqtt_root_dir}/${zigbee2mqtt_config_dirname}/${zigbee2mqtt_mqtt_password_template_filename}"
yq_update_snippet=".user = \"${mosquitto_username}\" | .password = \"${mqtt_password}\" | .network_key = ${network_key_array_string}"
yq "$yq_update_snippet" "$zigbee2mqtt_mqtt_password_template_file" > "$zigbee2mqtt_mqtt_password_file"
