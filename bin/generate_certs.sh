#!/usr/bin/env bash
echoerr() {
  printf "%s\n" "$*" >&2
}


if ! command -v openssl &> /dev/null; then
  echoerr "\`openssl\` is not installed on this machine. Install it with apt-get"
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=$(dirname "$SCRIPT_DIR")
CERTS_DIR_SUFFIX="etc-nginx-proxy/ssl/certs"
CA_CREATION_DIR="${PARENT_DIR}/ssl/ca"
CERT_CREATION_DIR="${PARENT_DIR}/ssl/certs"

if [ -d "$CA_CREATION_DIR"  ] && [ -f "$CA_CREATION_DIR/pihome-ca.pem" ]; then
  echoerr "it looks like we've already created the root certificate/ \`$CA_CREATION_DIR\` directory. If you need a new \
  root certificate, remove this directory."
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
fi

NGINX_CERT_CREATION_DIR="${CERT_CREATION_DIR}/nginx"

if [ -d "$NGINX_CERT_CREATION_DIR" ]; then
  echoerr "it looks like an nginx certificates directory already exists: \`$NGINX_CERT_CREATION_DIR\`. If you need new certificates \
  remove this directory."
else
  echoerr "creating an nginx certificate from our ca root certificate"
  mkdir -p "$NGINX_CERT_CREATION_DIR"

  echoerr "creating self signed x509 cert for pihome nginx-proxy to use"

  openssl genrsa -out "${NGINX_CERT_CREATION_DIR}/pihome.run.key" 4096
  openssl req -new -key "${NGINX_CERT_CREATION_DIR}/pihome.run.key" \
    -subj "/C=US/ST=MA/CN=pihome.run" \
    -out "${NGINX_CERT_CREATION_DIR}/pihome.run.csr"

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
    "DNS.3 = homebridge.pihome.run" \
  > "${NGINX_CERT_CREATION_DIR}/pihome.run.ext"

  openssl x509 -trustout -req -in "${NGINX_CERT_CREATION_DIR}/pihome.run.csr" -CA "${CA_CREATION_DIR}/pihome-ca.pem" -CAkey "${CA_CREATION_DIR}/pihome-ca.key" \
  -CAcreateserial -out "${NGINX_CERT_CREATION_DIR}/pihome.run.crt" -days 3650 -sha256 -extfile "${NGINX_CERT_CREATION_DIR}/pihome.run.ext"

  echoerr "done creating the self-signed x509 cert. make sure this cert is in the appropriate \
  place for nginx-proxy to find (probably $CERTS_DIR_SUFFIX within whatever dir you run \
  \`docker compose\` from). Also add the pihome-ca.pem to whichever computers you plan to access the \
  pihome UIs from."

  echoerr 'Copy the root certificate to your machine. From your machine, run:'
  echoerr "        scp $(whoami)@$(hostname).local:${CA_CREATION_DIR}/pihome-ca.pem ~/Downloads"
  echoerr 'then tell your OS to recognize this root certificate and trust it (e.g. with Keychain Access on MacOS).'
fi

MOSQUITTO_CERT_CREATION_DIR="${CERT_CREATION_DIR}/mosquitto"

if [ -d "$MOSQUITTO_CERT_CREATION_DIR" ]; then
  echoerr "it looks like a mosquitto certificates directory already exists: \`$MOSQUITTO_CERT_CREATION_DIR\`. If you need new certificates \
  remove this directory."
else
  echoerr "creating a mosquitto broker certificate from our ca root certificate"
  mkdir -p "$MOSQUITTO_CERT_CREATION_DIR"

  echoerr "creating self signed x509 cert for mosquitto to use"

  openssl genrsa -out "${MOSQUITTO_CERT_CREATION_DIR}/server.key" 4096
  openssl req -new -key "${MOSQUITTO_CERT_CREATION_DIR}/server.key" \
    -subj "/C=US/ST=MA/CN=pihome.run" \
    -out "${MOSQUITTO_CERT_CREATION_DIR}/server.csr"

  echoerr "creating the x509 cert extension config file to attach the SANs"
  printf '%s\n' \
    "authorityKeyIdentifier=keyid,issuer" \
    "basicConstraints=CA:FALSE" \
    "keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment" \
    "subjectAltName = @alt_names" \
    "" \
    "[alt_names]" \
    "DNS.1 = pihome.run" \
> "${MOSQUITTO_CERT_CREATION_DIR}/mosquitto.run.ext"

  openssl x509 -trustout -req -in "${MOSQUITTO_CERT_CREATION_DIR}/server.csr" -CA "${CA_CREATION_DIR}/pihome-ca.pem" -CAkey "${CA_CREATION_DIR}/pihome-ca.key" \
  -CAcreateserial -out "${MOSQUITTO_CERT_CREATION_DIR}/server.crt" -days 3650 -sha256 -extfile "${MOSQUITTO_CERT_CREATION_DIR}/mosquitto.run.ext"

fi
