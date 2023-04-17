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

if [ ! -d "$CERTS_DIR" ]; then
  echoerr "creating $CERTS_DIR"
  mkdir -p "$CERTS_DIR"
fi

echoerr "creating self signed x509 cert for pihome nginx-proxy to use"

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout "$CERTS_DIR/pihome.run.key" -out "$CERTS_DIR/pihome.run.crt" -subj "/CN=pihome.run"

echoerr "done creating the self-signed x509 cert. make sure this cert is in the appropriate \
place for nginx-proxy to find (probably $CERTS_DIR_SUFFIX within whatever dir you run \
\`docker compose\` from)"
