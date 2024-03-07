#!/usr/bin/env bash

set -euo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
zigbee2mqtt_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$zigbee2mqtt_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

zigbee2mqtt_config_dirname=zigbee2mqtt-data
zigbee2mqtt_configuration_template_filename=configuration.template.yaml
zigbee2mqtt_configuration_filename=configuration.yaml

zigbee2mqtt_configuration_file="${zigbee2mqtt_root_dir}/${zigbee2mqtt_config_dirname}/${zigbee2mqtt_configuration_filename}"
zigbee2mqtt_configuration_template_file="${zigbee2mqtt_root_dir}/${zigbee2mqtt_config_dirname}/${zigbee2mqtt_configuration_template_filename}"
mqtt_fqdn="mqtts://mqtt.${PIHOME_HOSTNAME:?err}.${PIHOME_TLD:?err}"
yq_server_update_snippet=".mqtt.server = \"${mqtt_fqdn}\""
# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

if ! command -v yq > /dev/null; then
  echoerr "yq must be installed to create the zigbee2mqtt configuration files"
  exit 1
fi

echoerr \
"We neeed to know what kind of zigbee adapter you're using in order to create \
the appropriate zigbee2mqt configuration. Read more at https://www.zigbee2mqtt.io/guide/adapters/"

read -r -n1 -p "Are you using a zigbee adapter based on a TI CC2652/CC1352 (Y/n)? " using_ti_zigbee
printf '\n'

if [ "$using_ti_zigbee" = 'Y' ] || [ "$using_ti_zigbee" = 'y' ]; then
  echoerr "Formatting configuration to use default zigbee adapter"
  yq \
    "$yq_server_update_snippet" \
    "$zigbee2mqtt_configuration_template_file" > "$zigbee2mqtt_configuration_file"
  exit 0
fi

read -r -n1 -p "Are you using a zigbee adapter based on a Silicon Labs EFR32MG2x/MGM21x or EFR32MG1x/MGM1x series (Y/n)? " using_si_labs_zigbee
printf '\n'

if [ "$using_si_labs_zigbee" = 'Y' ] || [ "$using_si_labs_zigbee" = 'y' ]; then
  echoerr "Formatting configuration to use \`ezsp\` zigbee adapter"
  # do formatting and exit
  yq_serial_adapter_update_snippet=".serial.adapter = \"ezsp\""
  yq \
    "${yq_server_update_snippet}, ${yq_serial_adapter_update_snippet}" \
    "$zigbee2mqtt_configuration_template_file" > "$zigbee2mqtt_configuration_file"
  exit 0
fi


echoerr "Error: you must select either a Texas Instruments or a Silicon labs based zigbee adapter"
exit 1
