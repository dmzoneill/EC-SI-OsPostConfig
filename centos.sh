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
# Detect centos
#######################################################################################

if [ -f /etc/redhat-release ]; then
CENTOSVERSION=$(cat /etc/redhat-release | awk '{print $4}' | awk -F. '{print $1} )
else
CENTOSVERSION=6
fi


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
yum -q -y install git 
yum -q -y install subversion 
yum -q -y install nfs-utils
yum -q -y remove gnome-initial-setup
yum -q -y install dialog

if [[ "$CENTOSVERSION" == 6 || "$CENTOSVERSION" == 7 ]]; then
yum -q -y groupinstall "Debugging Tools"
yum -q -y groupinstall "Development tools"
yum -q -y groupinstall "Compatibility libraries"
yum -q -y groupinstall "System Management"
yum -q -y groupinstall "System administration tools"
yum -q -y groupinstall "Console internet tools"
else
yum -q -y groupinstall "Development Libraries" 
yum -q -y groupinstall "Development Tools"
fi

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Run levels and gank
#######################################################################################

echo "${sep}"
echo -e "${termblue}Switching to sysv runlevel 3 ${termreset}"
echo -e "${termblue}Disable bluetooth etc... ${termreset}"
echo "${sep}"

# set run level 3 default
sed -rie 's/^id:[0-9]:initdefault:/id:3:initdefault:/g' /etc/inittab

if [[ "$CENTOSVERSION" == 5 || "$CENTOSVERSION" == 6 ]]; then

  # disable uneeded services
  chkconfig iptables off >/dev/null 2>&1 
  chkconfig ip6tables off >/dev/null 2>&1 
  chkconfig firewalld off >/dev/null 2>&1 
  chkconfig abrt-ccpp off >/dev/null 2>&1 
  chkconfig abrtd off >/dev/null 2>&1 
  chkconfig abrt-oops off >/dev/null 2>&1 
  chkconfig abrt-vmcore off >/dev/null 2>&1 
  chkconfig avahi-daemon off >/dev/null 2>&1 
  chkconfig gpm off >/dev/null 2>&1 
  chkconfig mcelog off >/dev/null 2>&1 
  chkconfig mdmonitor off >/dev/null 2>&1 
  chkconfig mdmonitor-takeover off >/dev/null 2>&1 
  chkconfig lvm2-monitor off >/dev/null 2>&1 
  chkconfig bluetooth off >/dev/null 2>&1 
  chkconfig abrt-xorg off >/dev/null 2>&1 
  chkconfig sendmail off >/dev/null 2>&1 
  chkconfig postfix off >/dev/null 2>&1  
  chkconfig sm-client off >/dev/null 2>&1 
  chkconfig yum-updatesd off >/dev/null 2>&1 
  chkconfig smartd off >/dev/null 2>&1 
  chkconfig readahead_early off >/dev/null 2>&1 
  chkconfig readahead_later off >/dev/null 2>&1 
  chkconfig nscd off >/dev/null 2>&1 
  chkconfif cups off >/dev/null 2>&1  
  chkconfig isdn off >/dev/null 2>&1 
  chkconfig kudzu off >/dev/null 2>&1 
  chkconifg NetworkManager off >/dev/null 2>&1 
  
  # make sure these are on
  chkconfig sshd on >/dev/null 2>&1 
  chkconfig network on >/dev/null 2>&1 
  chkconfig rpcbind on >/dev/null 2>&1 
  chkconfig portmap on >/dev/null 2>&1 
  chkconfig ypbind on >/dev/null 2>&1 
  chkconfig autofs on >/dev/null 2>&1 

else

  # disable uneeded services
  systemctl disable iptables.service >/dev/null 2>&1 
  systemctl disable ip6tables.service >/dev/null 2>&1 
  systemctl disable firewalld.service >/dev/null 2>&1 
  systemctl disable abrt-ccpp.service >/dev/null 2>&1 
  systemctl disable abrtd.service >/dev/null 2>&1 
  systemctl disable abrt-oops.service >/dev/null 2>&1 
  systemctl disable abrt-vmcore.service >/dev/null 2>&1 
  systemctl disable avahi-daemon.service >/dev/null 2>&1 
  systemctl disable gpm.service >/dev/null 2>&1 
  systemctl disable mcelog.service >/dev/null 2>&1 
  systemctl disable mdmonitor.service >/dev/null 2>&1 
  systemctl disable mdmonitor-takeover.service >/dev/null 2>&1 
  systemctl disable lvm2-monitor.service >/dev/null 2>&1 
  systemctl disable bluetooth.service >/dev/null 2>&1 
  systemctl disable abrt-xorg.service >/dev/null 2>&1 
  systemctl disable sendmail.service >/dev/null 2>&1 
  systemctl disable postfix.service >/dev/null 2>&1  
  systemctl disable sm-client.service >/dev/null 2>&1 
  systemctl disable yum-updatesd.service >/dev/null 2>&1 
  systemctl disable smartd.service >/dev/null 2>&1 
  systemctl disable readahead_early.service >/dev/null 2>&1 
  systemctl disable readahead_later.service >/dev/null 2>&1 
  systemctl disable nscd.service >/dev/null 2>&1 
  systemctl disable cups.service >/dev/null 2>&1  
  systemctl disable isdn.service >/dev/null 2>&1 
  systemctl disable kudzu .service >/dev/null 2>&1 
  systemctl disable NetworkManager.service >/dev/null 2>&1 
  
  # make sure these are on
  systemctl enable sshd.service >/dev/null 2>&1 
  systemctl enable network.service >/dev/null 2>&1 
  systemctl enable rpcbind.service >/dev/null 2>&1 
  systemctl enable portmap.service >/dev/null 2>&1 
  systemctl enable ypbind.service >/dev/null 2>&1 
  systemctl enable autofs.service >/dev/null 2>&1 
  
fi

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Nis / Automounter Configuration
#######################################################################################

echo "${sep}"
echo -e "${termblue}Adjusting system to nis logins ${termreset}"
echo "${sep}"

# set nis domain
echo "NISDOMAIN=basiscomm.ie" >> /etc/sysconfig/network
# correct the auto master map
sed -ie 's/^+auto.master$/+auto.masterpub/g' /etc/auto.master

# update nsswitch
authconfig --enablenis --updateall

# bug fix for fedora not inheriting user nis groups
sed -rie 's/^initgroups:(.*?)$/#initgroups:\1/g' /etc/nsswitch.conf
# host lookups should not be done against NIS, lets make sure of it
sed -rie 's/^hosts:(.*?)$/hosts: files dns/g' /etc/nsswitch.conf

echo "domain basiscomm.ie server nis-host1.ir.intel.com" > /etc/yp.conf
echo "domain basiscomm.ie server nis-host2.ir.intel.com" >> /etc/yp.conf

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Boot gank
#######################################################################################

echo "${sep}"
echo -e "${termblue}Enabling verbose boot${termreset}"
echo "${sep}"

# disable splash boot 
sed -ie 's/ rhgb / /g' /boot/grub/menu.lst

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
ln -s /bin/tcsh /usr/intel/bin/tcsh

echo -e "${termgreen}done...${termreset}"


#######################################################################################
# Rebooting
#######################################################################################

# quick update of the locate db
updatedb

reboot

