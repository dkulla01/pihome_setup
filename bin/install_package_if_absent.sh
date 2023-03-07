DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# since the path building here is dynamic,
# shellcheck disable=SC1091
source "$DIR/echoerr.sh"

install_package_if_absent() {
  DEP_NAME=$1

  if dpkg-query -W -f='${Status}\n' "$DEP_NAME" 2> /dev/null | grep -q 'ok installed'; then
    echoerr "$DEP_NAME is already installed. nothing to do here."
  else
    echoerr "$DEP_NAME is not yet installed. Installing it now."
    sudo apt-get install --assume-yes "$DEP_NAME"
  fi
}