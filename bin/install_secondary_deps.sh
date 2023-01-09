#!/usr/bin/env bash

set +ex

source echoerr

echoerr 'installing pyenv'
curl https://pyenv.run | bash
echoerr "done installing pyenv"

echoerr 'adding pyenv environment variables to .bashrc'
# we want to put these literal strings (with their variables) into .bashrc
# without interpolating/evaluating the variables
# shellcheck disable=SC2016
{
  echo 'export PYENV_ROOT="$HOME/.pyenv"'
  echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
  echo 'eval "$(pyenv init -)"'
} >> ~/.bashrc

echoerr "adding pyenv environment variables to .profile"
# we want to put these literal strings (with their variables) into .profile
# without interpolating/evaluating the variables
# shellcheck disable=SC2016
{
  echo 'export PYENV_ROOT="$HOME/.pyenv"'
  echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
  echo 'eval "$(pyenv init -)"'
} >> ~/.profile

# shellcheck disable=SC2016
echoerr 'restarting the shell to pick up the changes to $PATH'
source "$HOME/.bashrc"

echoerr "installing the latest python 3.11 version"
pyenv install 3.11

echoerr 'making python 3.11 the global python'
pyenv global 3.11

echoerr 'restarting the shell to pick up the pyenv changes'
source "$HOME/.bashrc"

echoerr "installing docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

echoerr "done installing docker. adding user \"${USER}\" to the docker group"
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker

echoerr "done setting up docker. reboot now"