#!/usr/bin/env bash
set +ex

echoerr() {
  printf "%s\n" "$*" >&2
}

echoerr "installing pyenv"
curl https://pyenv.run | bash
echoerr "done installing pyenv"

echoerr "installing docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

echoerr "done installing docker. adding user \"${USER}\" to the docker group"
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker

echoerr "done setting up docker. reboot now"