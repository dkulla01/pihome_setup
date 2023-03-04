#!/usr/bin/env bash
set +ex

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic, 
# shellcheck disable=SC1091
source "$DIR/echoerr.sh"


echoerr "updating and upgrading apt..."


if ! sudo apt update; then
  echoerr "something went wrong updating apt"
  exit 1
fi

if ! sudo apt upgrade; then
  echoerr "something went wrong upgrading packages"
  exit 1
fi

echoerr "apt is up to date. moving on"

echoerr "checking git..."
if ! command -v git; then
  echoerr "git is not present, installing it now"
  if ! sudo apt install git; then
    echoerr "something went wrong installing git"
    exit 1
  else
    echoerr "installed git"
  fi
fi

if [ -f $HOME/.ssh/id_ed25519.pub ]; then
  echoerr "an ssh key already exists"
else
  echoerr "generating an ssh key"
  if ! ssh-keygen -t ed25519 -C "dan@dankulla.com" -q -P "" -f "$HOME/.ssh/id_ed25519.pub"; then
    echoerr "there was a problem generating the ssh key"
    exit 1
  fi

  # ssh -T returns 1 on success, other nonzero code on failure
  ssh -T git@github.com 1>/dev/null 2>&1 || EXIT_CODE=$?
  if [[ ${EXIT_CODE} != 1 ]]; then
    echoerr "failed to authenticate with github. you need to add your new ssh key to your github account"
    echoerr "> https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors#check-your-ssh-access"
    exit 1
  fi
fi

echoerr "installing pyenv"
