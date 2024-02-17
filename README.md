#pihome_setup

some scripts to get a raspberry pi set up for running some home automation stuff

## Getting started:
the first step is to add git to the raspberry pi and configure ssh keys. Get that done with:

```shell
bash -c "$(curl https://raw.githubusercontent.com/dkulla01/pihome_setup/main/bin/install_and_configure_git.sh)"
```

This script will try to authenticate with github with those ssh keys, and it will direct you to the instructions for linking an ssh key on github.

## Keeping it going:
Now that you have git installed and ssh keys linked with github, pull down this repo locally and install the secondary dependencies

```shell
git clone git@github.com:dkulla01/pihome_setup.git
cd pihome_setup
./bin/install_secondary_deps.sh
```

Next, you'll need to generate the SSL certificates that all of the projects will use. Do that by running

```shell
./bin/generate_certs.sh
```

and following the prompts.

That script generates a root CA cert and uses it to create and sign certs for traefik, mosquitto mqtt server, and various mqtt clients. This script writes the root cert and the certs generated with it into different directories with version timestamp suffixes. To get the rest of the project to use these certs, you must set the following environment variables:

```shell
# the timestamps get generated with:
# date --utc +"%F-%H_%M_%S"
# for example: 2023-12-25-01_23_45
export ROOT_CERT_VERSION=...
export CERT_VERSION=...
```

Adding those `export` statements to an `.envrc` file will make sure those environment variables are set.

## Wrapping things up
Now you have git installed alongside some core dependencies like docker and pyenv. Take a look at the different directories within the `docker` directory. Some of those will have setup scripts within their `bin` directory, so run those before using `docker compose` to start up the various pihome components.
