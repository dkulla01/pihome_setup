#!/usr/bin/env bash
echoerr() {
  printf "%s\n" "$*" >&2
}


if ! command -v openssl &> /dev/null; then
  echoerr "\`openssl\` is not installed on this machine. install it with apt-get"
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=$(dirname "$SCRIPT_DIR")
CERTS_DIR_SUFFIX="etc-nginx-proxy/ssl/certs"
CA_CREATION_DIR="${PARENT_DIR}/ssl/ca"
CERT_CREATION_DIR="${PARENT_DIR}/ssl/certs"

if [ -d "$CA_CREATION_DIR" ]; then
  echoerr "it looks like a certificates directory already exists: \`$CA_CREATION_DIR\`. If you need new certificates \
  remove this directory."
else
  echoerr "creating $CA_CREATION_DIR"
  mkdir -p "$CA_CREATION_DIR"

  echoerr "creating a local root CA private key for LAN-hosted pages"
  openssl genrsa -des3 -out "${CA_CREATION_DIR}/pihome-ca.key" 4096

  echoerr "creating a local certificate with that root CA private key"
  openssl req -x509 -new -nodes -key "${CA_CREATION_DIR}/pihome-ca.key" -sha256 -days 3650 -out "${CA_CREATION_DIR}/pihome-ca.pem" -subj "/CN=pihome-ca.run"

  echoerr "copying the pihome-ca cert to the ca-certificates dir"
  sudo cp "${CA_CREATION_DIR}/pihome-ca.pem" /usr/local/share/ca-certificates/pihome-ca.crt

  echoerr "updating the certificates store"
  sudo update-ca-certificates

  echoerr "creating a certificate from our ca certificate"
  mkdir -p "$CERT_CREATION_DIR"

  echoerr "creating self signed x509 cert for pihome nginx-proxy to use"

  openssl genrsa -out "${CERT_CREATION_DIR}/pihome.run.key" 4096
  openssl req -new -key "${CERT_CREATION_DIR}/pihome.run.key" -out "${CERT_CREATION_DIR}/pihome.run.csr"

  echoerr "creating the x509 cert extension config file to attach the SANs"
  printf '%s\n' \
    "authorityKeyIdentifier=keyid,issuer" \
    "basicConstraints=CA:FALSE" \
    "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" \
    "subjectAltName = @alt_names" \
    "" \
    "[alt_names]" \
    "DNS.1 = pihome.run" \
    "DNS.2 = pihole.pihome.run" \
    "DNS.1 = homebridge.pihome" \
  > "${CERT_CREATION_DIR}/pihome.run.ext"

  openssl x509 -req -in "${CERT_CREATION_DIR}/pihome.run.csr" -CA "${CA_CREATION_DIR}/pihome-ca.pem" -CAkey "${CA_CREATION_DIR}/pihome-ca.key"\
  -CAcreateserial -out "${CERT_CREATION_DIR}pihome.run.crt" -days 3650 -sha256 -extfile "${CERT_CREATION_DIR}/pihome.run.ext"
fi

#can't do the oneliner below because `openssl req` doesn't support -trustout
# openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout "home.run.key" -out "home.run.crt" -subj "/CN=pihome.run" -addext "subjectAltName=DNS:pihome.run,DNS:www.pihome.run,DNS:homebridge.pihome.run,DNS:pihole.pihome.run"

echoerr "done creating the self-signed x509 cert. make sure this cert is in the appropriate \
place for nginx-proxy to find (probably $CERTS_DIR_SUFFIX within whatever dir you run \
\`docker compose\` from)"
