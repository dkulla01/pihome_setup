#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# since the path building here is dynamic, 
# shellcheck disable=SC1091
source "$DIR/echoerr.sh"

# since the path building here is dynamic, 
# shellcheck disable=SC1091
source "$DIR/install_package_if_absent.sh"

install_package_if_absent 'netcat'
install_package_if_absent 'vim'
