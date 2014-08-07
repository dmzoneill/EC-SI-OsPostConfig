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
# Detect fedora
#######################################################################################

FEDORAVERSION=`cat /etc/*-release | sed -rn 's/VERSION_ID=(.*?)$/\1/p'`


#######################################################################################
# Proxies terminal, yum,  wget...
#######################################################################################

echo "${sep}"
echo -e "${termblue}Setting up yum, terminal proxies etc${termreset}"
echo "${sep}"

# bashrc
sed -rie 's/^export http(.*?)$/#export http\1/g' /root/.bashrc
sed -rie 's/^export no(.*?)$/#export no\1/g' /root/.bashrc
echo "export http_proxy=http://proxy.ir.intel.com:911" >> /root/.bashrc
echo "export no_proxy=localhost,127.0.0.1" >> /root/.bashrc

# yum.conf
sed -rie 's/^proxy(.*?)$/#proxy\1/g' /etc/yum.conf
echo "proxy=http://proxy.ir.intel.com:911" >> /etc/yum.conf
#sed -rie 's/^proxy(.*?)$/proxy=http:\/\/proxy.ir.intel.com:911/g' /etc/yum.conf

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Selinux
#######################################################################################

echo "${sep}"
echo -e "${termblue}Disabling Selinux${termreset}"
echo "${sep}"

# probably not needing for testing purposes
sed -rie 's/^SELINUX=.*?$/SELINUX=disabled/g' /etc/selinux/config

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Package update and installation
#######################################################################################

echo "${sep}"
echo -e "${termblue}Updating packages and installing autofs, ypbind etc ${termreset}"
echo -e "${termblue}This may take 15 minutes or more....${termreset}"
echo "${sep}"

# setup yum proxy and update
yum -q -y update 

# install autofs, ypbind & sshd if not already
yum -q -y install autofs 
yum -q -y install ypbind 
yum -q -y install openssh-server 
yum -q -y install tcsh 
yum -q -y install tigervnc-server 
yum -q -y remove gnome-initial-setup
yum -q -y install dialog

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Network 
#######################################################################################

echo "${sep}"
echo -e "${termblue}Adding systemd boot nis/autmount workaround ${termreset}"
echo "${sep}"

# Pause network allowing other process to come to depend on it
sed -rie 's/^NETWORKWAIT(.*?)$/#NETWORKWAIT\1/g' /etc/sysconfig/network
sed -rie 's/^NETWORKDELAY(.*?)$/#NETWORKDELAY\1/g' /etc/sysconfig/network
echo "NETWORKWAIT=yes" >> /etc/sysconfig/network
echo "NETWORKDELAY=15" >> /etc/sysconfig/network

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Run levels and gank
#######################################################################################

echo "${sep}"
echo -e "${termblue}Switching to sysv runlevel 3 like setup ${termreset}"
echo -e "${termblue}Disable bluetooth etc... ${termreset}"
echo "${sep}"

# set run level 3 default
rm -rf /etc/systemd/system/default.target
ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

# disable uneeded services
systemctl -q disable iptables.service
systemctl -q disable ip6tables.service
systemctl -q disable firewalld.service
systemctl -q disable abrt-ccpp.service
systemctl -q disable abrtd.service
systemctl -q disable abrt-oops.service
systemctl -q disable abrt-vmcore.service
systemctl -q disable avahi-daemon.service
systemctl -q disable gpm.service
systemctl -q disable mcelog.service
systemctl -q disable mdmonitor.service
systemctl -q disable mdmonitor-takeover.service
systemctl -q disable lvm2-monitor.service
systemctl -q disable bluetooth.service
systemctl -q disable systemd-readahead-collect.service
systemctl -q disable systemd-readahead-replay.service
systemctl -q disable abrt-xorg.service
systemctl -q disable sendmail.service
systemctl -q disable sm-client.service

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Nis / Automounter Configuration
#######################################################################################

echo "${sep}"
echo -e "${termblue}Adjusting system to nis logins ${termreset}"
echo "${sep}"

# correct the auto master map
sed -ie 's/^+auto.master$/+auto.masterpub/g' /etc/auto.master

# update nsswitch
authconfig --enablenis --updateall

# bug fix for fedora not inheriting user nis groups
sed -rie 's/^initgroups:(.*?)$/#initgroups:\1/g' /etc/nsswitch.conf
# host lookups should not be done against NIS, lets make sure of it
sed -rie 's/^hosts:(.*?)$/hosts: files dns/g' /etc/nsswitch.conf

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Boot gank
#######################################################################################

echo "${sep}"
echo -e "${termblue}Cleaning out useless kernels and updating grub${termreset}"
echo "${sep}"

# set the default kernel as the selected kernel on grub selection
sed -rie 's/^GRUB_SAVEDEFAULT=(.*?)$/#GRUB_SAVEDEFAULT=\1/g' /etc/default/grub
echo "GRUB_SAVEDEFAULT=true" >> /etc/default/grub

# disable splash boot 
sed -ie 's/ rhgb / /g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

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

# turn on sshd, ypbind and legacy autofs sysv script
systemctl -q enable sshd.service 

if [[ "$FEDORAVERSION" == 16 ]]
then
chkconfig autofs on
else
systemctl -q enable autofs.service
fi 

systemctl -q enable ypbind.service 
# restart ypbind after enabling or it wont come up on next boot ( fedora bug )
systemctl -q restart ypbind.service 

# clean up installation users
userdel -f tester
rm -rvf /home/*

# link tcsh for usr intel
mkdir -p /usr/intel/bin
ln -s /bin/tcsh /usr/intel/bin/tcsh

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Rebooting
#######################################################################################

# quick update of the locate db
updatedb

reboot

