#pihome_setup

some scripts to get a raspberry pi set up for running some home automation stuff

## Getting started:
the first step is to add git to the raspberry pi and configure ssh keys. Get that done with:

```shell
curl https://raw.githubusercontent.com/dkulla01/pihome_setup/main/bin/install_and_configure_git.sh | sh
```

## Keeping it going:
Now that you have git installed and ssh keys linked with github, pull down this repo locally and install the secondary dependencies

```shell
git clone git@github.com:dkulla01/pihome_setup.git
cd pihome_setup
./bin/install_secondary_deps.sh
```

## Wrapping things up
Now you have git installed alongside some core dependencies like docker and pyenv. You're free to figure things out from here. Maybe you want nginx? or maybe this is destined to be a node in a kubernetes cluster? Who knows? Now it's all up to you!
