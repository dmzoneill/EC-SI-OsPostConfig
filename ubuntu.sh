#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

termred='\e[0;31m'
termgreen='\e[0;32m'
termblue='\e[0;36m'
termreset='\e[0m' # No Color
sep="===================================================================="

#######################################################################################
# User email feedback / home warning
#######################################################################################

echo 'THIS SCRIPT DELETES /home'
echo 'Press enter to continue:'
read goahead


#######################################################################################
# Detect Ubuntu
#######################################################################################

UBUNTUVERSION=`cat /etc/lsb-release | sed -rn 's/DISTRIB_RELEASE=(.*?)$/\1/p'`

#######################################################################################
# Begin
#######################################################################################

echo "${sep}"
echo -e "${termblue}Ubuntu $UBUTNUVERSION vanilla post configuration${termreset}"
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

echo "${sep}"
echo -e "${termblue}Setting up apt, terminal proxies etc${termreset}"
echo "${sep}"

# bashrc
sed -rie 's/^export http(.*?)$/#export http\1/g' /root/.bashrc
sed -rie 's/^export no(.*?)$/#export no\1/g' /root/.bashrc
echo "export http_proxy=http://proxy.ir.intel.com:911" >> /root/.bashrc
echo "export no_proxy=localhost,127.0.0.1" >> /root/.bashrc

export http_proxy=http://proxy.ir.intel.com:911

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Selinux Firewalls etc
#######################################################################################

echo "${sep}"
echo -e "${termblue}Disabling Firewall/Selinux${termreset}"
echo "${sep}"

apt-get -qq -y remove selinux
apt-get -qq -y remove ufw
apt-get -qq -y remove iptables

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Setup default domain for dpkg-confgiure nis 
#######################################################################################

echo "basiscomm.ie" > /etc/defaultdomain

#######################################################################################
# Package update and installation
#######################################################################################

echo "${sep}"
echo -e "${termblue}Updating packages and installing autofs, ypbind etc ${termreset}"
echo -e "${termblue}This may take 15 minutes or more....${termreset}"
echo "${sep}"

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

echo -e "${termgreen}done...${termreset}"


#######################################################################################
# Nis / Automounter Configuration
#######################################################################################

echo "${sep}"
echo -e "${termblue}Adjusting system configuration for nis/nfs ${termreset}"
echo "${sep}"

# autmounter
echo "+auto.masterpub" > /etc/auto.master
echo "" >> /etc/auto.master

# yp client
echo "ypserver nis-host.ir.intel.com" > /etc/yp.conf
echo "domain basiscomm.ie server nis-host.ir.intel.com" >> /etc/yp.conf
echo "domain basiscomm.ie server nis-host2.ir.intel.com" >> /etc/yp.conf
echo "basiscomm.ie" > /etc/defaultdomain

# update nsswitch
echo "passwd:       compat nis" > /etc/nsswitch.conf
echo "group:        compat nis" >> /etc/nsswitch.conf
echo "shadow:       compat nis" >> /etc/nsswitch.conf
echo "hosts:        files dns" >> /etc/nsswitch.conf
echo "networks:     files" >> /etc/nsswitch.conf
echo "protocols:    db files " >> /etc/nsswitch.conf
echo "services:     db files" >> /etc/nsswitch.conf
echo "ethers:       db files" >> /etc/nsswitch.conf
echo "rpc:          db files" >> /etc/nsswitch.conf
echo "netgroup:     nis" >> /etc/nsswitch.conf
echo "automount:    files nis" >> /etc/nsswitch.conf

echo -e "${termgreen}done...${termreset}"


#######################################################################################
# Boot Services 
#######################################################################################

echo "${sep}"
echo -e "${termblue}Configuring bootup & services ${termreset}"
echo "${sep}"

# disable uneeded services
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
echo "auto lo" > /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet dhcp" >> /etc/network/interfaces

# just in case poxy upstart causing some race conditins and fails on boot
echo "restart autofs" >> /etc/init.d/rc.local
echo "restart ypbind" >> /etc/init.d/rc.local
echo "restart autofs" >> /etc/init.d/rc.local

# boot text and console
sed -i 's/quiet splash/text/g' /etc/default/grub
update-grub

echo -e "${termgreen}done...${termreset}"


#######################################################################################
# EC Support 
#######################################################################################

mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "ssh-dss AAAAB3NzaC1kc3MAAAEBANAAdxo/E2CTnqZbVTUhctX0QdSpMOOT5EznyX3qk4YBcBVpDIDsU8OOduSyokmQwtoinNb4SMxlcUzdcLWnQY6lVkOyl1lRZQaLccHat5BYx/eqUJNJs2LeImPWxbCiPu6jMSkxADLTjM0EkpMMDN5PCxPe8eaawOPk4sVJmG1m/r6KnUv4pKXY2nxx7lE/LMsllvMtiM8/XGc2l91Pgw7OW2aSNLVLC2u/H0Sr/FjV8FQhrd9LcnUwDdmEBi3SdjrMg/PQvmuPhzT3PchkEpgnM6K4bONDtG6jLripIyO+c/ET4xJzqH57KfFAMUPixs9g7yVx+rao2U6vX2C88YUAAAAVAJoIzsbLNMQTCmnj1oEbhd1SVQQjAAABAQCAzgLTdUBnZvYi27P+lIdaGFvu8fgtzUswWuHczTUJZDcPcLYfYU6EKBPrOOWPzTRkQDagzWPfR2scU1j2q0inhamTplLb9CG+UrADGPkfqTPRjHulySVkG9SyUpvNEZEi7ULjJv5CgvoVyqERtcbBD/iYEyF9/uWKn26u+hVUMwXEJNDuv7D4qh7VH4Y8ix2FK5lBfm/hYbwO0G8m4XygP0jkDCWADihxlYr8dhQyYkrGsIVRuMp5Sm213rx4lDaBZguSBkbcMzc25bxQr/orQxwRow+tiIlOnG83jTlZP344zXvBR9y/KBNZnCycbipQJGDPhSl2XNv9DDFAr3YMAAABAGXdPQ/AiuzZpa4WTQEvUUBfv4rQYNCodGpQWDIbaKxYAPzS8ef2QPM3ZAkAxfzvTjumTIcOX7eVtGlTIKkKpIZ9Czr2a00HRledxIRCdjjVziIC5Lb0+DJ2iMzMZGuEk+lw3b8FbGYfVShuhAA4zNPCgLeTLZ1kE3hmEYsIhfg30ui4LSdT/YKRHtzZmwNQmQPdgaZC3s4IwQqT72Yfb5ROt+p84+9laQmKynhIkbMF5scX2wrJnM0N5CEmDWOXyRn+dOmvELyKrJdemZIKXltpoHvNZgaZgFl8BJBgUWqEP3EJocFeelT81KEZ/JmFly1odxEt12ZXgG4q9p0mTbY= root@sisutil001" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys


#######################################################################################
# Finish up
#######################################################################################

echo "${sep}"
echo -e "${termblue}Finishing up${termreset}"
echo "${sep}"

# clean up installation users
userdel -f tester
rm -rvf /home/*

# link tcsh for usr intel
mkdir -p /usr/intel/bin
ln -s /usr/bin/tcsh /usr/intel/bin/tcsh

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Rebooting
#######################################################################################

# quick update of the locate db
updatedb

reboot

