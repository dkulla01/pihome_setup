#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
project_dir=$(dirname "$script_dir")
ssl_certs_dir="${project_dir}/ssl"

source "$script_dir/echoerr.sh"

# 2023-12-25-01_53_17
date_version_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}_[0-9]{2}$'
if [[ ! -v $ROOT_CERT_VERSION ]] || [[ ! $ROOT_CERT_VERSION =~ $date_version_regex ]]; then
  echoerr "\$ROOT_CERT_VERSION envionment variable is unset or malformed. value: \"${ROOT_CERT_VERSION}\". Exiting now"
else
  echoerr "Using ROOT_CERT_VERSION=${ROOT_CERT_VERSION}"
fi;

versioned_root_cert_dir="${ssl_certs_dir}/root-cert-${ROOT_CERT_VERSION}"
root_cert_file="${versioned_root_cert_dir}/pihome-ca.pem"
root_cert_key_file="${versioned_root_cert_dir}/pihome-ca.key"

if [[ ! -d "$versioned_root_cert_dir" ]] \
  || [[ ! -f  $root_cert_file ]] \
  || [[ ! -f "$root_cert_key_file" ]]; then
  echoerr "the desired version of the root cert is missing a required component. Check ${versioned_root_cert_dir} for a pem and a key file"
  exit 1
fi


if [[ ! -v $CERT_VERSION ]] || [[ ! $CERT_VERSION =~ $date_version_regex ]]; then
  echoerr "\$CERT_VERSION envionment variable is unset or malformed. value: \"${CERT_VERSION}\". Exiting now"
  exit 1
else
  echoerr "using ROOT_CERT_VERSION=${ROOT_CERT_VERSION} and CERT_VERSION=${CERT_VERSION}"
fi

versioned_cert_dir="${ssl_certs_dir}/cert-${CERT_VERSION}"

# check that all of the non-root certs we're looking for exist
echoerr "checking for traefik reverse proxy certs"
traefik_cert_dir="${versioned_cert_dir}/traefik"
traefik_cert_file="${traefik_cert_dir}/pihome.run.crt"
traefik_cert_key_file="${traefik_cert_dir}/pihome.run.key"

if [[ ! -d "$traefik_cert_dir" ]] \
  || [[ ! -f "$traefik_cert_file" ]] \
  || [[ ! -f "$traefik_cert_key_file" ]]; then
  echoerr "the desired certificate version for traefik reverse proxy is missing a required component. Check ${traefik_cert_dir} for a certificate and key file"
  exit 1
fi

echoerr "checking for the mosquitto mqtt server certs"

mqtt_server_cert_dir="${versioned_cert_dir}/mosquitto-server"
mqtt_server_cert_file="$mqtt_server_cert_dir/server.crt"
mqtt_server_cert_key_file="$mqtt_server_cert_dir/server.key"

if [[ ! -d "$mqtt_server_cert_dir" ]] \
  || [[ ! -f "$mqtt_server_cert_file"  ]] \
  || [[ ! -f "$mqtt_server_cert_key_file" ]]; then
  echoerr "the desired certificate version for the mosquitto mqtt server is missing a required component. Check ${mqtt_server_cert_dir} for a certificate and key file."
  exit 1
fi

readarray -t all_mqtt_clients < <(jq --raw-output '.[]' "${script_dir}/mqtt_clients.json")

function check_mqtt_client_certs() {
  local client_name=$1
  local cert_dir="${versioned_cert_dir}/${client_name}"
  local cert_file="${cert_dir}/${client_name}.crt"
  local key_file="${cert_dir}/${client_name}.key"

  if [[ ! -d "$cert_dir" ]] || [[ ! -f "$cert_file" ]] || [[ ! -f "$key_file" ]]; then
    echoerr "the desired mqtt client certificate version for client \"${client_name}\" is missing a required component. Check ${cert_dir} for a certificate and key file."
    exit 1
  fi
}


echoerr "checking for the mqtt client certs"
for mqtt_client in "${all_mqtt_clients[@]}"; do
  check_mqtt_client_certs "$mqtt_client"
done


# at this point, all of the certs and keys we want exist and look good, so let's start copying them.
