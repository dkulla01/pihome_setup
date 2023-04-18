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
CERTS_DIR="$PARENT_DIR/$CERTS_DIR_SUFFIX"

if [ -d "$CERTS_DIR" ]; then
  echoerr "it looks like a certificates directory already exists: \`$CERTS_DIR\`. If you need new certificates \
  remove this directory."
else
  echoerr "creating $CERTS_DIR"
  mkdir -p "$CERTS_DIR"
  echoerr "creating a local root CA private key for LAN-hosted pages"
  openssl genrsa -des3 -out "${CERTS_DIR}/pihome-ca.key" 4096

  echoerr "creating a local certificate with that root CA private key"
  openssl req -x509 -new -nodes -key "${CERTS_DIR}/pihome-ca.key" -sha256 -days 3650 -out "${CERTS_DIR}/pihome-ca.pem" -subj "/CN=pihome-ca.run"

  echoerr "copying the pihome-ca cert to the ca-certificates dir"
  sudo cp "${CERTS_DIR}/pihome-ca.pem" /usr/local/share/ca-certificates/pihome-ca.crt

  echoerr "updating the certificates store"
  sudo update-ca-certificates

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
  > "${CERTS_DIR}/pihome.run.ext"

  openssl x509 -req -in "${CERTS_DIR}/pihome.run.csr" -CA "${CERTS_DIR}/pihome-ca.pem" -CAkey "${CERTS_DIR}/pihome-ca.key"\
  -CAcreateserial -out "${CERTS_DIR}pihome.run.crt" -days 3650 -sha256 -extfile "${CERTS_DIR}/pihome.run.ext"
fi

echoerr "creating self signed x509 cert for pihome nginx-proxy to use"

openssl genrsa -out "${CERTS_DIR}/pihome.run.key" 4096
openssl req -new -key "${CERTS_DIR}/pihome.run.key" -out "${CERTS_DIR}/pihome.run.csr"



#can't do the oneliner below because `openssl req` doesn't support -trustout
# openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout "home.run.key" -out "home.run.crt" -subj "/CN=pihome.run" -addext "subjectAltName=DNS:pihome.run,DNS:www.pihome.run,DNS:homebridge.pihome.run,DNS:pihole.pihome.run"

echoerr "done creating the self-signed x509 cert. make sure this cert is in the appropriate \
place for nginx-proxy to find (probably $CERTS_DIR_SUFFIX within whatever dir you run \
\`docker compose\` from)"
