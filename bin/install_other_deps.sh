#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic, 
# shellcheck disable=SC1091
source "$DIR/echoerr.sh"

if ! command -v nc; then
  echoerr 'netcat is not installed. installing it now'
  sudo apt install netcat
else
  echoerr 'netcat is already installed'
fi


if ! command -v vim; then
  echoerr 'vim is not installed. installing it now'
  sudo apt install vim
else
  echoerr 'vim is already installed'
fi
