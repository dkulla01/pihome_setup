#pihome_setup

some scripts to get a raspberry pi set up for running some home automation stuff

## getting started:
the first step is to add git to the raspberry pi and configure ssh keys. Do this
by scp-ing [`bin/install_and_configure_git`](bin/install_and_configure_git.sh) to
pi and running it:

```shell
# on your dev machine:
git pull # pull down the most recent version of this repo
scp bin/install_and_configure_git pi@some_raspi_host:~

#on the remote pi:
cat ~/install_and_configure_git | bash
```

