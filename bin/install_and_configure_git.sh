#!/usr/bin/env bash
set +ex

# a copy of echoerr so we can curl/download the script from raw.githubusercontent.com/...
#!/usr/bin/env bash
echoerr() {
  printf "%s\n" "$*" >&2
}

# a copy of install_package_if_absent so we can curl/download the script from raw.githubusercontent.com/...
install_package_if_absent() {
  local dep_name=$1

  if dpkg-query -W -f='${Status}\n' "$dep_name" 2> /dev/null | grep -q 'ok installed'; then
    echoerr "$dep_name is already installed. nothing to do here."
  else
    echoerr "$dep_name is not yet installed. Installing it now."
    sudo apt-get install --assume-yes "$dep_name"
  fi
}

echoerr "updating and upgrading apt-get..."


if ! sudo apt-get update --assume-yes; then
  echoerr "something went wrong updating apt"
  exit 1
fi

if ! sudo apt-get upgrade --assume-yes; then
  echoerr "something went wrong upgrading packages"
  exit 1
fi

echoerr "apt-get is up to date. moving on"

echoerr "checking git..."
install_package_if_absent 'git'
git config --global pull.rebase false

global_git_excludes_file="$HOME/.gitignore_global"
echoerr "configuring a global excludes file at $global_git_excludes_file"
touch "$global_git_excludes_file"
cat << 'EOF' > "$global_git_excludes_file"
.envrc
etc-*/
.gitignored_junk/
EOF

git config --global core.excludesFile "$global_git_excludes_file"

if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
  echoerr "an ssh key already exists"
else
  echoerr "generating an ssh key"
  
  read -r -p "Enter the email address to assign to this ssh key: " ssh_key_email_address
  printf '\n'
  echoerr "creating ssh keys for email address \"${ssh_key_email_address}\""
  read -r -p "Using email address \`${ssh_key_email_address}\`. Is this correct? (Y/n)? " email_address_confirmation
  if [ "$email_address_confirmation" != "Y" ]; then
    echoerr "SSH key generation cancelled. Exiting now."
    exit 1
  fi

  if ! ssh-keygen -t ed25519 -C "$ssh_key_email_address" -q -P "" -f "$HOME/.ssh/id_ed25519"; then
    echoerr "there was a problem generating the ssh key"
    exit 1
  fi
  echoerr 'done creating ssh keys'
fi

# ssh -T returns 1 on success, other nonzero code on failure
ssh -o StrictHostKeyChecking=no -T git@github.com 1>/dev/null 2>&1 || EXIT_CODE=$?
if [ "$EXIT_CODE" -ne 1 ]; then
  echoerr "failed to authenticate with github. you need to add your new ssh key to your github account"
  echoerr "> https://docs.github.com/en/repositories/creating-and-managing-repositories/troubleshooting-cloning-errors#check-your-ssh-access"
  exit 1
else
  echoerr "It looks like your ssh key has been added to github. You're all set now!"
fi
