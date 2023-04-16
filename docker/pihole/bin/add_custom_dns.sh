#!/usr/bin/env bash
echoerr() {
  printf "%s\n" "$*" >&2
}

if ! command -v ip &> /dev/null; then
  echoerr "\`ip\` does not exist on this machine, so we cannot build the \`custom.list\` DNS file"
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=$(dirname "$SCRIPT_DIR")
ETC_PIHOLE_DIR="$PARENT_DIR/etc-pihole"
CUSTOM_PIHOLE_DNS_FILE="$ETC_PIHOLE_DIR/custom.list"

IP4=$(ip -o -4  addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echoerr "the LAN address of the eth0 interface is ${IP4}"

if [ ! -d "$ETC_PIHOLE_DIR" ]; then
  mkdir "$ETC_PIHOLE_DIR"
fi


cat <<EOF > "$CUSTOM_PIHOLE_DNS_FILE"
$IP4 pihome.run
$IP4 homebridge.pihome.run
$IP4 pihole.pihome.run
EOF

echoerr "added ip4: $IP4 entries to $CUSTOM_PIHOLE_DNS_FILE"
echoerr "confirm that the \`etc-pihole\` directory and docker-compose.yml file \
are in the same directory to ensure that docker compose mounts volumes properly"
