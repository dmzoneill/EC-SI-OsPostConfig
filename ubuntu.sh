#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

confirm_home_deletion

#######################################################################################
# Detect Ubuntu
#######################################################################################

UBUNTUVERSION=$(sed -rn 's/DISTRIB_RELEASE=(.*?)$/\1/p' /etc/lsb-release)
# The banner below keeps the historical misspelled, empty expansion.
UBUTNUVERSION=""
: "${UBUNTUVERSION}"

#######################################################################################
# Begin
#######################################################################################

echo "${sep}"
echo -e "${termblue}Ubuntu ${UBUTNUVERSION} vanilla post configuration${termreset}"
echo "${sep}"

#######################################################################################
# Enable root login
#######################################################################################

echo -n "Enabling root login, specify password : "
echo ""
passwd
usermod -U root
export DEBIAN_FRONTEND=noninteractive

#######################################################################################
# Proxies terminal, yum,  wget...
#######################################################################################

print_section_lines "Setting up apt, terminal proxies etc"
configure_bashrc_proxy
export http_proxy="http://proxy.ir.intel.com:911"
section_done

#######################################################################################
# Selinux Firewalls etc
#######################################################################################

print_section_lines "Disabling Firewall/Selinux"
apt-get -qq -y remove selinux
apt-get -qq -y remove ufw
apt-get -qq -y remove iptables
section_done

#######################################################################################
# Setup default domain for dpkg-confgiure nis
#######################################################################################

echo "basiscomm.ie" >/etc/defaultdomain

#######################################################################################
# Package update and installation
#######################################################################################

begin_package_update
# setup yum proxy and update
apt-get --force-yes -qq -y update && apt-get -qq -y upgrade
apt-get --force-yes -qq -y install portmap
apt-get --force-yes -qq -y install autofs
apt-get --force-yes -qq -y install openssh-server
apt-get --force-yes -qq -y install nis
apt-get --force-yes -qq -y install ypbind
apt-get --force-yes -qq -y install build-essential
apt-get --force-yes -qq -y install nfs-common
apt-get --force-yes -qq -y install tcsh
apt-get --force-yes -qq -y install vnc4server
apt-get --force-yes -qq -y install mailx
apt-get --force-yes -qq -y remove lightdm
section_done

#######################################################################################
# Nis / Automounter Configuration
#######################################################################################

print_section_lines "Adjusting system configuration for nis/nfs "

# autmounter
{
	echo "+auto.masterpub"
	echo ""
} >/etc/auto.master

# yp client
{
	echo "ypserver nis-host.ir.intel.com"
	echo "domain basiscomm.ie server nis-host.ir.intel.com"
	echo "domain basiscomm.ie server nis-host2.ir.intel.com"
} >/etc/yp.conf
echo "basiscomm.ie" >/etc/defaultdomain

# update nsswitch
{
	echo "passwd:       compat nis"
	echo "group:        compat nis"
	echo "shadow:       compat nis"
	echo "hosts:        files dns"
	echo "networks:     files"
	echo "protocols:    db files "
	echo "services:     db files"
	echo "ethers:       db files"
	echo "rpc:          db files"
	echo "netgroup:     nis"
	echo "automount:    files nis"
} >/etc/nsswitch.conf

section_done

#######################################################################################
# Boot Services
#######################################################################################

print_section_lines "Configuring boot up & services "

# disable unneeded services
update-rc.d -f bluetooth remove
update-rc.d -f ypxfrd remove
update-rc.d -f ypserv remove
update-rc.d -f rsync remove
update-rc.d -f cups remove
update-rc.d -f modemmanager remove
update-rc.d -f alsa-store remove
update-rc.d -f alsa-restore remove
update-rc.d -f avahi-daemon remove
update-rc.d -f gssd remove
update-rc.d -f bluetooth remove
update-rc.d -f yppasswdd remove
update-rc.d -f lightdm remove
update-rc.d -f gdm remove

# nis on boot
update-rc.d nis 60 3 5 . stop 30 3 5 .
update-rc.d ypbind 61 3 5 . stop 29 3 5 .
update-rc.d autofs 62 3 5 . stop 28 3 5 .
update-rc.d ssh defaults
update-rc.d rc.local defaults
update-rc.d network-manager defaults

# network on boot
{
	echo "auto lo"
	echo "iface lo inet loopback"
	echo "auto eth0"
	echo "iface eth0 inet dhcp"
} >/etc/network/interfaces

# just in case poxy upstart causing some race conditins and fails on boot
{
	echo "restart autofs"
	echo "restart ypbind"
	echo "restart autofs"
} >>/etc/init.d/rc.local

# boot text and console
sed -i 's/quiet splash/text/g' /etc/default/grub
update-grub

section_done

install_ec_support_key
finish_cleanup_and_tcsh /usr/bin/tcsh
updatedb_and_reboot
