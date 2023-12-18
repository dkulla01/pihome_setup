#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic, 
# shellcheck source=./echoerr.sh
source "$DIR/echoerr.sh"

# todo: if we point to cloudflare, then to pihole (on localhost),
# rerunning this script will overwrite our config to use local DNS
echoerr 'pointing nameserver to a public nameserver'
if grep -q 'name_servers' /etc/resolvconf.conf; then
  sudo sed -i -E 's/^.*name_servers=.*$/name_servers=1.1.1.1/ # point to cloudflare DNS' /etc/resolvconf.conf
else
  echo 'name_servers=127.0.0.1 # point to localhost (pihole)' | sudo tee -a /etc/resolvconf.conf > /dev/null
fi

sudo resolvconf -u

echoerr 'adding pihole docker compose manifest'
PIHOLE_DOCKER_DIR="/$HOME/docker_manifests/pihole"
if [ ! -d "$PIHOLE_DOCKER_DIR" ]; then
  mkdir -p "/$PIHOLE_DOCKER_DIR"
fi

if [ ! -d "$PIHOLE_DOCKER_DIR/etc-pihole" ]; then
  mkdir "$PIHOLE_DOCKER_DIR/etc-pihole"
fi

cat << EOF > "$PIHOLE_DOCKER_DIR/etc-pihole/custom.list"
  # dns a records to be served by the pihole
  # <ip-address> <domain>
  # you should probably update this script
EOF

echoerr 'starting up pihole'
cp "$DIR/../docker/pihole/docker-compose.yml" "$PIHOLE_DOCKER_DIR"
( cd "$PIHOLE_DOCKER_DIR" && docker compose up -d )

#shellcheck disable=2016
echoerr 'pihole has started up. exec into the container and change the password with `pihole -a -p`'
