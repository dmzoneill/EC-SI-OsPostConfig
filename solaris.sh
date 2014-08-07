#!/usr/bin/bash

#######################################################################################
# Constants
#######################################################################################

export LANG=en_US.UTF-8

DOMAIN="ir.intel.com"
NISDOMAIN="basiscomm.ie"
PROXY_HOST="proxy.$DOMAIN"
PROXY_PORT="911"
NTP1="ntp-host1.$DOMAIN"
NTP2="ntp-host2.$DOMAIN"
NTP3="ntp-host3.$DOMAIN"
NIS1="nis-host1.$DOMAIN"
NIS2="nis-host2.$DOMAIN"
MAILHOST="mailhost.$DOMAIN"
AUTOMAP="+auto.masterpub"
LOCALE="Europe/Dublin"
KEYMAP="UK-English"
LANG="en_UK.UTF-8"

#######################################################################################
# User input
#######################################################################################

echo "Please enter hostname:"
read HOSTNAME

echo "Please enter email address:"
read EMAIL

#######################################################################################
# Root password and complexity
#######################################################################################

perl -pi -e 's/\#MINNONALPHA.*$/MINNONALPHA=0/g' /etc/default/passwd
perl -pi -e 's/\PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
passwd

#######################################################################################
# Proxy configuration
#######################################################################################

export http_proxy=http://$PROXY_HOST:$PROXY_PORT

svccfg -s system-repository:default setprop config/http_proxy = "http://$PROXY_HOST:$PROXY_PORT"
svccfg -s system-repository:default setprop config/https_proxy = "http://$PROXY_HOST:$PROXY_PORT"
svcadm refresh system-repository:default

#######################################################################################
# Pkg update and install
#######################################################################################

pkg update
pkg install slim_install
pkg install solaris-desktop
pkg install git
pkg install developer/versioning/subversion
pkg install dialog
pkg install tcsh
pkg install SUNWgcc

#######################################################################################
# Hostname, Time, Keyboard
#######################################################################################

svccfg -s identity:node setprop config/nodename = "$HOSTNAME"
svcadm refresh identity:node
echo "127.0.0.1 $HOSTNAME.$DOMAIN localhost loghost" > /etc/hosts

svccfg -s timezone:default setprop timezone/localtime = astring: "$LOCALE"
svccfg refresh timezone:default

svccfg -s keymap:default setprop keymap/layout = "$KEYMAP"
svcadm refresh keymap:default

svccfg -s environment:init setprop environment/LANG = astring: "$LANG" 
svcadm refresh environment:init

#######################################################################################
# Time
#######################################################################################

cp /etc/inet/ntp.client /etc/inet/ntp.conf
perl -pi -e "s/\# server server_name1.*$/server $NTP1 iburst/g" /etc/inet/ntp.conf
perl -pi -e "s/\# server server_name2.*$/server $NTP2 iburst/g" /etc/inet/ntp.conf
perl -pi -e "s/\# server server_name3.*$/server $NTP3 iburst/g" /etc/inet/ntp.conf
svcadm refresh network/ntp:default
svcadm enable ntp

#######################################################################################
# Notifications
#######################################################################################

svcfg setnotify -g from-online,to-maintenance mailto:$EMAIL

#######################################################################################
# Services
#######################################################################################

svcadm enable network/dns/client
svcadm enable network/ssh
svcadm disable network/ipfilter:default
svcadm disable application/graphical-login/gdm:default

#######################################################################################
# sendmail
#######################################################################################

perl -pi -e "s/^DS.*$/DS$MAILHOST/g" /etc/mail/sendmail.cf
svccfg -s smtp:sendmail setprop config/local_only=false
svcadm refresh network/smtp:sendmail
svcadm enable network/smtp:sendmail

#######################################################################################
# NSI, autofs, nsswitch
#######################################################################################

svccfg -s name-service/switch setprop config/default = astring: \"files nis\"
svccfg -s name-service/switch setprop config/password = astring: \"files nis\"
svccfg -s name-service/switch setprop config/group = astring: \"files nis\"
svccfg -s name-service/switch setprop config/host = astring: \"files dns\"
svccfg -s name-service/switch setprop config/netgroup = astring: \"nis\"
svccfg -s name-service/switch setprop config/automount = astring: \"files nis\"
svccfg -s name-service/switch:default refresh

svcadm disable nis/domain
svccfg -s network/nis/domain setprop config/domainname = $NISDOMAIN
svccfg -s network/nis/domain:default refresh
svcadm enable nis/domain

mkdir -p /var/yp/binding/$NISDOMAIN/
echo "$NIS1" > /var/yp/binding/$NISDOMAIN/ypservers
echo "$NIS1" >> /var/yp/binding/$NISDOMAIN/ypservers
svcadm enable -r network/nis/domain:default
svcadm enable -r network/nis/client:default

svcadm refresh network/nis/domain
svcadm restart network/nis/domain

svcadm refresh network/nis/client
svcadm restart network/nis/client

mkdir /nfs

echo "$AUTOMAP" > /etc/auto_master
svcadm enable system/filesystem/autofs

#######################################################################################
# Rebooting
#######################################################################################

# quick update of the locate db
updatedb

reboot
