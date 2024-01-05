#!/usr/bin/env bash

set -e

# make sure that globs that don't match anything return null 
shopt -s nullglob

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$script_dir/echoerr.sh"

function create_root_cert() {
  local root_cert_dirname=$1
  local root_cert_filename=$2
  local root_cert_key_filename=$3
  local root_cert_key_password=$4
  local cert_timestamp_version=$5

  root_cert_key_file="${root_cert_dirname}/${root_cert_key_filename}"
  root_cert_file="${root_cert_dirname}/${root_cert_filename}"
  echoerr "creating a local root certificate private key for LAN-hosted pages"
  openssl genrsa \
    -des3 \
    -out "$root_cert_key_file" \
    -passout "pass:${root_cert_key_password}" \
    4096

  echoerr "creating a local root certificate with that private key"
  openssl req \
    -x509 \
    -new \
    -nodes \
    -key "$root_cert_key_file" \
    -passin "pass:${root_cert_key_password}" \
    -sha256 \
    -days 3650 \
    -out "$root_cert_file" \
    -subj "/CN=pihome-ca.run"

  echoerr "copying the pihome-ca root certificate to the ca-certificates dir"
  sudo cp "$root_cert_file" "/usr/local/share/ca-certificates/pihome-ca-${cert_timestamp_version}.crt"

  echoerr "updating the certificates store"
  sudo update-ca-certificates

}

function build_certs() {
  local certs_dirname=$1
  local cert_prefix=$2
  local cert_subject=$3
  local domains_json_file=$4
  local ca_pemfile=$5
  local ca_key=$6
  local root_cert_key_password=$7

  if [ -d "$certs_dirname" ]; then
    echoerr "it looks like a \`$cert_prefix\` certificates directory already exists: \`$certs_dirname\`."\
    "If you need new certificates, remove this directory."
  else
    echoerr "creating a \`$cert_prefix\` certificate in \`$certs_dirname\` from our ca root certificate (\`$ca_pemfile\`)"
    mkdir -p "$certs_dirname"

    local cert_private_key_file="${certs_dirname}/${cert_prefix}.key"
    echoerr "creating a private key for \`$cert_prefix\`: \`$cert_private_key_file\`."

    openssl genrsa -out "$cert_private_key_file" 4096

    local csr_file="${certs_dirname}/${cert_prefix}.csr"
    echoerr "creating a CSR file: "
    openssl req -new -key "$cert_private_key_file" \
      -subj "/C=US/ST=MA/CN=${cert_subject}" \
      -out "$csr_file"

    echoerr "creating the x509 cert extension config file to attach the SANs"
    local extfile_name="${cert_prefix}.ext"

    printf '%s\n' \
      "authorityKeyIdentifier=keyid,issuer" \
      "basicConstraints=CA:FALSE" \
      "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" \
      "subjectAltName = @alt_names" \
      "" \
      "[alt_names]" \
      "$(build_dns_sans_block "$domains_json_file")" \
    > "${certs_dirname}/${extfile_name}"

    cert_file="${certs_dirname}/${cert_prefix}.crt"
    echoerr "creating a certificate: ${cert_file}"
    openssl x509 -req -in "$csr_file" -CA "${ca_pemfile}" -CAkey "${ca_key}" \
    -passin "pass:${root_cert_key_password}" \
    -CAcreateserial -out "$cert_file" -days 3650 -sha256 -extfile "${certs_dirname}/${extfile_name}"
  fi
}

function build_dns_sans_block() {
  local domain_json_file=$1
  jq --raw-output '. | to_entries | .[] | "DNS.\(.key + 1) = \(.value)"' "$domain_json_file"
}

if ! command -v openssl &> /dev/null; then
  echoerr "\`openssl\` is not installed on this machine. Install it with apt-get"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echoerr "\`jq\` is not installed on this machine. Install it with apt-get"
  exit 1
fi

cert_timestamp_version=$(date --utc +"%F-%H_%M_%S")

parent_dir=$(dirname "$script_dir")
ssl_dir="${parent_dir}/ssl"
pihome_sans_domains_file="${script_dir}/pihome_domains.json"
mosquitto_sans_domains_file="${script_dir}/mosquitto_domains.json"
mqtt_client_list_file="${script_dir}/mqtt_clients.json"

read -r -s -p "enter your desired ca private key password: " root_cert_key_password
printf '\n'
read -r -s -p "confirm your ca private key password: " confirm_password
printf '\n'

if [[ "$root_cert_key_password" != "$confirm_password" ]]; then
  echoerr "passwords do not match. exiting."
  exit 1
fi

root_cert_dirs=( "$ssl_dir"/root-cert-* )

most_recent_root_cert_dir=
root_cert_dir_prefix='root-cert'
pihome_ca_cert_filename='pihome-ca.pem'
pihome_ca_key_filename='pihome-ca.key'
root_cert_version=

if [ "${#root_cert_dirs[@]}" -eq 0 ]; then
  most_recent_root_cert_dir="${parent_dir}/ssl/${root_cert_dir_prefix}-${cert_timestamp_version}"
  echoerr "No root cert directory present. creating a root cert at ${most_recent_root_cert_dir}"
  mkdir -p "$most_recent_root_cert_dir"
  create_root_cert \
    "$most_recent_root_cert_dir" \
    "$pihome_ca_cert_filename" \
    "$pihome_ca_key_filename" \
    "$root_cert_key_password" \
    "$cert_timestamp_version"
    root_cert_version="$cert_timestamp_version"
elif [ ! -f  "${root_cert_dirs[-1]}/${pihome_ca_cert_filename}" ] \
      || [ ! -f  "${root_cert_dirs[-1]}/${pihome_ca_key_filename}" ] ; then
  recent_but_malformed_ca_dir=${root_cert_dirs[-1]}
  most_recent_root_cert_dir="${parent_dir}/ssl/${root_cert_dir_prefix}-${cert_timestamp_version}"
  echoerr "there's a root cert at ${recent_but_malformed_ca_dir}, but we're \
    missing either the cert or the key. creating a new root cert at ${most_recent_root_cert_dir}"
  mkdir -p "$most_recent_root_cert_dir"
  
  create_root_cert \
    "$most_recent_root_cert_dir" \
    "$pihome_ca_cert_filename" \
    "$pihome_ca_key_filename" \
    "$root_cert_key_password" \
    "$cert_timestamp_version"
    root_cert_version="$cert_timestamp_version"
else
  most_recent_root_cert_dir=${root_cert_dirs[-1]}
  
  read -r -n1 -p "a ca cert/key pair exists within ${most_recent_root_cert_dir}. Should we reuse it (Y/n)?" use_existing_ca
  printf '\n'

  if [ "$use_existing_ca" = 'Y' ] || [ "$use_existing_ca" = 'y' ]; then
    
    # check that the passwords match
    echoerr 'checking password against existing key'
    if ! openssl rsa -noout -in "${most_recent_root_cert_dir}/${pihome_ca_key_filename}" -passin "pass:$root_cert_key_password" 2>/dev/null; then
      echoerr "invalid password. exiting"
      exit 1
    fi

    echoerr "using most recent root cert inside ${most_recent_root_cert_dir}"
    root_cert_dir_basename=$(basename "$most_recent_root_cert_dir")
    root_cert_version="${root_cert_dir_basename#"$root_cert_dir_prefix-"}"

  else
    most_recent_root_cert_dir="${parent_dir}/ssl/${root_cert_dir_prefix}-${cert_timestamp_version}"
    echoerr "creating a root cert dir at ${most_recent_root_cert_dir}"
    mkdir -p "$most_recent_root_cert_dir"
    
    create_root_cert \
      "$most_recent_root_cert_dir" \
      "$pihome_ca_cert_filename" \
      "$pihome_ca_key_filename" \
      "$root_cert_key_password" \
      "$cert_timestamp_version"
  fi
fi

cert_dir_prefix="cert"
cert_creation_dir="$ssl_dir/${cert_dir_prefix}-${cert_timestamp_version}"
root_cert_pemfile="${most_recent_root_cert_dir}/${pihome_ca_cert_filename}"
root_cert_keyfile="${most_recent_root_cert_dir}/${pihome_ca_key_filename}"

traefik_cert_creation_dir="${cert_creation_dir}/traefik"
build_certs \
  "$traefik_cert_creation_dir" \
  'pihome.run' \
  'pihome.run' \
  "$pihome_sans_domains_file" \
  "$root_cert_pemfile" \
  "$root_cert_keyfile" \
  "$root_cert_key_password"

mosquitto_server_cert_creation_dir="${cert_creation_dir}/mosquitto-server"
build_certs \
  "$mosquitto_server_cert_creation_dir" \
  'server' \
  'pihome-mqtt-server.run' \
  "$mosquitto_sans_domains_file" \
  "$root_cert_pemfile" \
  "$root_cert_keyfile" \
  "$root_cert_key_password"

echoerr "creating the mqtt client certificates"

jq --raw-output '.[]' "$mqtt_client_list_file" | while read -r mqtt_client_name; do
  echoerr "creating the mqtt client certificate for $mqtt_client_name"
  certs_dirname="${cert_creation_dir}/$mqtt_client_name"
  build_certs \
    "$certs_dirname" \
    "$mqtt_client_name" \
    "$mqtt_client_name.pihome.run" \
    "$mosquitto_sans_domains_file" \
    "$root_cert_pemfile" \
    "$root_cert_keyfile" \
    "$root_cert_key_password"
done

extra_mqtt_clients_env_var="EXTRA_MQTT_CLIENTS"
if [[ -n "${!extra_mqtt_clients_env_var}" ]]; then
  echoerr "creating extra mqtt clients specified by ${extra_mqtt_clients_env_var}"
  # add an extra comment to end of the env var value to make sure we
  # capture the last value and nix the trailing newline
  readarray -t -d',' extra_mqtt_clients <<< "${!extra_mqtt_clients_env_var},";
  
  # nix the dummy element created by the trailing comma
  unset 'extra_mqtt_clients[-1]'

  for mqtt_client_name in "${extra_mqtt_clients[@]}"; do
    echoerr "creating the mqtt client certificate for $mqtt_client_name"
    certs_dirname="${cert_creation_dir}/$mqtt_client_name"
    build_certs \
      "$certs_dirname" \
      "$mqtt_client_name" \
      "$mqtt_client_name.pihome.run" \
      "$mosquitto_sans_domains_file" \
      "$root_cert_pemfile" \
      "$root_cert_keyfile" \
      "$root_cert_key_password"
  done
else
  echo "no extra mqtt clients configured via \$${extra_mqtt_clients_env_var}"
fi

echoerr 'done creating the mqtt client certificates'
echoerr "root cert version: ${root_cert_version}"
echoerr "cert version: ${cert_timestamp_version}"
