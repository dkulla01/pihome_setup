#!/usr/bin/env bash
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pihole_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$pihole_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

if ! command -v ip &> /dev/null; then
  echoerr "\`ip\` does not exist on this machine, so we cannot build the \`custom.list\` DNS file"
  exit 1
fi

dnsmasq_conf_dir="${pihole_root_dir}/etc-dnsmasq.d"

ip4=$(ip -o -4  addr list eth0 | awk '{print $4}' | cut -d/ -f1)

echoerr "the LAN address of the eth0 interface is ${ip4}"

mkdir -p "$dnsmasq_conf_dir"

dnsmasq_wildcard_dns_conf_filename="wildcard-${PIHOME_HOSTNAME:?err}-dot-${PIHOME_TPD:?err}-dns.conf"
dnsmasq_wildcard_dns_conf_file="${dnsmasq_conf_dir}/${dnsmasq_wildcard_dns_conf_filename}"

echoerr "creating a dnsmasq wildcard DNS entry in \`${dnsmasq_wildcard_dns_conf_file}\` \
to point \`*.${PIHOME_HOSTNAME:?err}.${PIHOME_TPD:?err}\` to \`${ip4}\`"
cat <<EOF > "$dnsmasq_wildcard_dns_conf_file"
address=/${PIHOME_HOSTNAME:?err}.${PIHOME_TPD:?err}/$ip4
EOF

echoerr "confirm that the \`etc-pihole\` directory and docker-compose.yml file \
are in the same directory to ensure that docker compose mounts volumes properly"
