#!/usr/bin/env bash
DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# shellcheck source=./echoerr.sh
source "$DIR/echoerr.sh"

# shellcheck source=./install_package_if_absent.sh
source "$DIR/install_package_if_absent.sh"

echoerr 'making sure dnsmasq and iptables-persistent are installed'
install_package_if_absent 'dnsmasq'
install_package_if_absent 'iptables-persistent'


printf 'interface eth0\
static ip_address=10.0.0.1/24\
static domain_name_servers=1.1.1.1,8.8.8.8' | sudo tee -a /etc/dhcpcd.conf > /dev/null


echoerr 'enabling ipv4 forwarding in /etc/sysctl.conf'
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

echoerr 'configuring dnsmasq'
echoerr 'moving aside the old dnsmasq.conf'
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.backup


