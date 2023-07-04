#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
traefik_root_dir=$(dirname "$script_dir")
docker_project_dir=$(dirname "$traefik_root_dir")
project_root_dir=$(dirname "$docker_project_dir")
main_scripts_dir="$project_root_dir/bin"

# since the path building here is dynamic, 
# shellcheck source=../../../bin/echoerr.sh
source "$main_scripts_dir/echoerr.sh"

traefik_auth_username=
if [ -z "$1" ]; then
  echoerr "You did not pass in a username. Using the default username \`pi\`"
  traefik_auth_username='pi'
else
  traefik_auth_username=$1
  echoerr "using traefik_auth_username \`$traefik_auth_username\`"
fi

traefik_passwd_dirname='auth'
traefik_passwd_filename='users'
etc_traefik_dirname='etc-traefik'
traefik_passwd_dir="${traefik_root_dir}/${etc_traefik_dirname}/${traefik_passwd_dirname}"
traefik_passwd_file="${traefik_passwd_dir}/${traefik_passwd_filename}"

echoerr "making sure the traefic password dir \`${traefik_passwd_dir}\` exists"
mkdir -p "$traefik_passwd_dir"

if [ -f "$traefik_passwd_file" ]; then
  echoerr "a traefik password file already exists: \`${traefik_passwd_file}\`. If you need a new one, delete this file"
else
  echoerr "creating a trafik password file with user \`${traefik_auth_username}\`"
  htpasswd -B -c "$traefik_passwd_file" "$traefik_auth_username"
fi
