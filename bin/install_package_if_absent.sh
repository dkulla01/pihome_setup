#!/usr/bin/env bash
dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic,
# shellcheck disable=SC1091
source "$dir/echoerr.sh"

install_package_if_absent() {
  local dep_name=$1

  if dpkg-query -W -f='${Status}\n' "$dep_name" 2> /dev/null | grep -q 'ok installed'; then
    echoerr "$dep_name is already installed. nothing to do here."
  else
    echoerr "$dep_name is not yet installed. Installing it now."
    sudo apt-get install --assume-yes "$dep_name"
  fi
}
