#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$script_dir/echoerr.sh"

if ! command -v openssl &> /dev/null; then
  echoerr "\`openssl\` is not installed on this machine. Install it with apt-get"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echoerr "\`jq\` is not installed on this machine. Install it with apt-get"
  exit 1
fi

parent_dir=$(dirname "$script_dir")
ca_creation_dir="${parent_dir}/ssl/ca"
cert_creation_dir="${parent_dir}/ssl/certs"
pihome_ca_key="${ca_creation_dir}/pihome-ca.key"
pihome_ca_pemfile="${ca_creation_dir}/pihome-ca.pem"
pihome_sans_domains_file="${script_dir})/pihome_domains.json"
mosquitto_sans_domains_file="${script_dir}/mosquitto_domains.json"


if [ -d "$ca_creation_dir"  ] && [ -f "$ca_creation_dir/pihome-ca.pem" ]; then
  echoerr "it looks like we've already created the root certificate: \`$ca_creation_dir\` directory." \
  "If you need a new root certificate, remove this directory."
else
  echoerr "creating $ca_creation_dir"
  mkdir -p "$ca_creation_dir"

  echoerr "creating a local root CA private key for LAN-hosted pages"
  openssl genrsa -des3 -out "${pihome_ca_key}" 4096

  echoerr "creating a local certificate with that root CA private key"
  openssl req -x509 -new -nodes -key "${pihome_ca_key}" -sha256 -days 3650 -out "${pihome_ca_pemfile}" -subj "/CN=pihome-ca.run"

  echoerr "copying the pihome-ca cert to the ca-certificates dir"
  sudo cp "${pihome_ca_pemfile}" /usr/local/share/ca-certificates/pihome-ca.crt

  echoerr "updating the certificates store"
  sudo update-ca-certificates
fi

function build_certs() {
  local certs_dirname=$1
  local cert_prefix=$2
  local cert_subject=$3
  local domains_json_file=$4
  local ca_pemfile=$5
  local ca_key=$6

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
    -CAcreateserial -out "$cert_file" -days 3650 -sha256 -extfile "${certs_dirname}/${extfile_name}"
  fi
}

function build_dns_sans_block() {
  local domain_json_file=$1
  jq '. | to_entries | .[] | "DNS.\(.key + 1) = \(.value)"' "$domain_json_file"
}

traefik_cert_creation_dir="${cert_creation_dir}/traefik"
build_certs "$traefik_cert_creation_dir" 'pihome.run' 'pihome.run' "$pihome_sans_domains_file" "${pihome_ca_pemfile}" "${pihome_ca_key}"

mosquitto_server_cert_creation_dir="${cert_creation_dir}/mosquitto-server"
build_certs "$mosquitto_server_cert_creation_dir" 'server' 'pihome-mqtt-server.run' "$mosquitto_sans_domains_file" "${pihome_ca_pemfile}" "${pihome_ca_key}"

mosquitto_client_cert_creation_dir="${cert_creation_dir}/mosquitto-client"
build_certs "$mosquitto_client_cert_creation_dir" 'client' 'pihome-mqtt-client.run' "$mosquitto_sans_domains_file" "${pihome_ca_pemfile}" "${pihome_ca_key}"
