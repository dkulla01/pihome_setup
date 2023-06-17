#!/usr/bin/env bash
echoerr() {
  printf "%s\n" "$*" >&2
}

if ! command -v ip &> /dev/null; then
  echoerr "\`ip\` does not exist on this machine, so we cannot build the \`custom.list\` DNS file"
  exit 1
fi

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
parent_dir=$(dirname "$script_dir")
etc_pihole_dir="$parent_dir/etc-pihole"

ip4=$(ip -o -4  addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echoerr "the LAN address of the eth0 interface is ${ip4}"

if [ ! -d "$etc_pihole_dir" ]; then
  mkdir "$etc_pihole_dir"
fi

dnsmasq_conf_dir="${etc_pihole_dir}/dnsmasq.d"
dnsmasq_wildcard_dns_conf_filename="wildcard-pihome-dot-run-dns.conf"
dnsmasq_wildcard_dns_conf_file="${dnsmasq_conf_dir}/${dnsmasq_wildcard_dns_conf_filename}"

if [ ! -d "$dnsmasq_conf_dir" ]; then
  mkdir "$dnsmasq_conf_dir"
fi

echoerr "creating a dnsmasq wildcard DNS entry in \`${dnsmasq_wildcard_dns_conf_file}\` \
to point *.pihome.run to ${ip4}"
cat <<EOF > "$dnsmasq_wildcard_dns_conf_file"
address=/pihome.run/$ip4
EOF

echoerr "confirm that the \`etc-pihole\` directory and docker-compose.yml file \
are in the same directory to ensure that docker compose mounts volumes properly"
