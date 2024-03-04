#!/usr/bin/env bash

set -euo pipefail

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck source=./echoerr.sh
source "$DIR/echoerr.sh"

# shellcheck source=./install_package_if_absent.sh
source "$DIR/install_package_if_absent.sh"

echoerr 'installing some utility packages I like to keep around'
install_package_if_absent 'netcat-openbsd'
install_package_if_absent 'vim'
install_package_if_absent 'fd-find'

echoerr 'installing packages required for pyenv to build pythons'

install_package_if_absent 'libssl-dev'
install_package_if_absent 'build-essential'
install_package_if_absent 'zlib1g-dev'
install_package_if_absent 'libffi-dev'
install_package_if_absent 'libssl-dev'
install_package_if_absent 'libbz2-dev'
install_package_if_absent 'libreadline-dev'
install_package_if_absent 'libsqlite3-dev'
install_package_if_absent 'liblzma-dev'
install_package_if_absent 'apache2-utils' # needed for htpasswd
install_package_if_absent 'pipx'

install_package_if_absent 'jq'
if ! command -v yq ; then
  echoerr 'installing yq'
  sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm -O /usr/bin/yq &&\
    sudo chmod +x /usr/bin/yq
fi

echoerr 'done installing packages required for pyenv to build pythons.'

if ! command -v pyenv; then
  echoerr 'installing pyenv'
  curl https://pyenv.run | bash
  echoerr "done installing pyenv"
fi

# $HOME/.profile adds $HOME/.local/bin to the path if the directory exists.
echoerr "Making sure that a ${HOME}/.local/bin directory exists"
mkdir -p "${HOME}/.local/bin"

echoerr "linking ${HOME}/.local/bin/fd to fdfind"
command -v fd || ln -s "$(which fdfind)" ~/.local/bin/fd

# we want to put these literal strings (with their variables) into .bashrc
# without interpolating/evaluating the variables
# shellcheck disable=SC2016
pyenv_shell_config_snippet='export PYENV_ROOT="$HOME/.pyenv"'

if ! grep "$pyenv_shell_config_snippet" ~/.bashrc; then 
  echoerr 'adding pyenv environment variables to .bashrc'
  # we want to put these literal strings (with their variables) into .bashrc
  # without interpolating/evaluating the variables
  # shellcheck disable=SC2016
  {
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  } >> ~/.bashrc
fi

if ! grep "$pyenv_shell_config_snippet" ~/.profile; then 
  echoerr "adding pyenv environment variables to .profile"
  # we want to put these literal strings (with their variables) into .profile
  # without interpolating/evaluating the variables
  # shellcheck disable=SC2016
  {
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  } >> ~/.profile
fi

# we want to put these literal strings (with their variables) into .profile
# without interpolating/evaluating the variables
# shellcheck disable=SC2016
direnv_bashrc_snippet='eval "$(direnv hook bash)"'

install_package_if_absent 'direnv'
if ! grep "$direnv_bashrc_snippet" ~/.bashrc; then
  echo "$direnv_bashrc_snippet" >> ~/.bashrc
fi
echoerr 'done installing and loading direnv'

# shellcheck disable=SC2016
echoerr 'restarting the shell to pick up the changes to $PATH'
# the aim is for this to be run on a host that already has a bashrc
# shellcheck disable=1091
source "$HOME/.bashrc"


# hack to get systemd to create the symlinks in /dev/serial/by-id
# we need this for zigbee adapters, and rasperrypi os/debian bullseye has an
# outdated version of systemd that has a bug
# see https://www.reddit.com/r/debian/comments/1331wlr/devserialbyid_suddenly_missing/

systemd_version=$(dpkg-query -W -f='${Version}\n' systemd)
if dpkg --compare-versions "$systemd_version" "<=" "252"; then
 echoerr "systemd version ${systemd_version} is less than 252, so we're replacing 60-serial.rules with a more recent version"
 curl https://raw.githubusercontent.com/systemd/systemd/main/rules.d/60-serial.rules | sudo tee -a /usr/lib/udev/rules.d/60-serial.rules > /dev/null
 sudo udevadm control --reload-rules
 sudo udevadm trigger

 echoerr "done updating 60-serial.rules and reloading udevadm"
fi


python_minor_version='3.12'
if ! pyenv versions --bare | grep "$python_minor_version"; then
  echoerr "installing the latest python ${python_minor_version} version"
  pyenv install "$python_minor_version"

  echoerr "making python ${python_minor_version} the global python"
  pyenv global "$python_minor_version"

  echoerr 'restarting the shell to pick up the pyenv changes'

  # the aim is for this to be run on a host that already has a bashrc
  # shellcheck disable=1091
  source "$HOME/.bashrc"
fi

if ! command -v docker; then
  echoerr "installing docker"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh

  echoerr "done installing docker. adding user \"${USER}\" to the docker group"
  if [ "$(getent group docker)" ]; then
    echoerr 'docker group already exists'
  else
    echoerr 'docker group does not exist. adding it now'
    sudo groupadd docker
  fi
  sudo usermod -aG docker "$USER"
  newgrp docker

  echoerr "done setting up docker. reboot now"
fi
