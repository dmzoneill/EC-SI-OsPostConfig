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
# Detect fedora
#######################################################################################

FEDORAVERSION=`cat /etc/*-release | head -n 1 | tr -d '[A-Za-zi\(\)]' |sed 's/ //g'`

#######################################################################################
# Begin
#######################################################################################

hostname=`hostname`
dnsdomain=`grep domain /etc/resolv.conf | awk '{ print $2 }'`
nisdomain=`grep domain /etc/yp.conf | tail -n 1 | awk '{ print $2 }'`
if [[ "$FEDORAVERSION" == 16 ]]
then
ipaddr=`ifconfig | sed -rn 's/.*r:10([^ ]+) .*/10\1/p'`
else
ipaddr=`ifconfig | sed -rn 's/.*inet 10([^ ]+) .*/10\1/p'`
fi

echo "${sep}"
echo -e "${termblue}Fedora $FEDORAVERSION vanilla post configuration${termreset}"
echo "${sep}"

echo -n "Hostname [eg. wgcl023] :"
read newhostname
echo -e "${termgreen}${newhostname}${termreset}"
echo -n "Email Address : "
read email

ARCH=`uname -m | grep 64`
if [[ $? == 0 ]]
then
    ARCH="64"
else
    ARCH="32"
fi

#######################################################################################
# Setup properp hostname and ddns config 
#######################################################################################

rm -rvf /etc/dhcp/*.conf
echo "send host-name \"${newhostname}\";" > /etc/dhcp/dhclient.onf

echo "${newhostname}" > /etc/hostname
echo "${newhostname}" > /etc/HOSTNAME

echo "HOSTNAME=${newhostname}" > /etc/sysconfig/network
echo "NETWORKING=yes" > /etc/sysconfig/network
echo "NISDOMAIN=basiscomm.ie" > /etc/sysconfig/network
echo "NTPSERVERARGS=iburst" > /etc/sysconfig/network

#######################################################################################
# Proxies terminal, yum,  wget...
#######################################################################################

echo "${sep}"
echo -e "${termblue}Setting up yum, terminal etc${termreset}"
echo "${sep}"

export http_proxy=""
export no_proxy="localhost,ir.intel.com"

# yum.conf
sed -i 's/enabled=.*/enabled=0/g' /etc/yum.repos.d/*
wget "http://wgcrepos.ir.intel.com/f"$FEDORAVERSION"$ARCH.repo" -O "/etc/yum.repos.d/f"$FEDORAVERSION$ARCH".repo"

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

# yum up any previous yum usage
yum clean all

# setup yum proxy and update
yum -q -y update 

# install autofs, ypbind & sshd if not already
yum -q -y install autofs 
yum -q -y install ypbind 
yum -q -y install openssh-server 
yum -q -y install tcsh 
yum -q -y install tigervnc-server 

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Network 
#######################################################################################

echo "${sep}"
echo -e "${termblue}Adding systemd boot nis/automount workaround ${termreset}"
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
sed -ie 's/^+auto.master$/+auto.masterwgcpub/g' /etc/auto.master

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

# remove old kernels
numkernels=`rpm -q kernel | wc -l`
rerun=0

while [ $numkernels -gt 1 ]
do
	currentkernel=`uname -r`
	removekernel=`rpm -q kernel | head -n 1`

	if [[ "$removekernel" == *$currentkernel ]]
	then
		echo -e "${termred}A newer kernel exists, however it is not the running kernel${termreset}"
		echo -e "${termred}Reboot select the newer kernel in grub.  Then re-run this script${termreset}"
		numkernels=0
		rerun=1
	else
		yum -q -y remove `rpm -q kernel | head -n 1`
		numkernels=`rpm -q kernel | wc -l`
	fi
done

# set the default kernel as the selected kernel on grub selection
sed -rie 's/^GRUB_SAVEDEFAULT=(.*?)$/#GRUB_SAVEDEFAULT=\1/g' /etc/default/grub
echo "GRUB_SAVEDEFAULT=true" >> /etc/default/grub

# disable splash boot 
sed -ie 's/ rhgb / /g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

echo -e "${termgreen}done...${termreset}"

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

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Send complete email
#######################################################################################

echo "${sep}"
echo -e "${termblue}Sending email confirmation${termreset}"
echo "${sep}"

MSG="Hi, the configuration of "$hostname"."$dnsdomain" has been completed."

if [ $rerun -eq 1 ]
then
	MSG=$MSG"  You should rerun the script to complete new kernel/grub setup."
fi

echo "$MSG" | mailx -v -s "Configuration Complete" -S smtp=smtp://mailhost.ir.intel.com -S from="root@$hostname.$dnsdomain" $email 2>&1 >> /dev/null

echo -e "${termgreen}done...${termreset}"

#######################################################################################
# Rebooting
#######################################################################################

countdown=30

while [ $countdown -gt 0 ]
do
	echo "Rebooting in ${countdown} seconds!!!!!" | wall
	sleep 1
	let countdown=countdown-1
done

reboot

