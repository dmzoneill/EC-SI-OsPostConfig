#!/bin/csh 

#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

set HOMEMAP="amd.public_home"
set NFSMAP="amd.nfs"
set DNSDOMAIN="ir.intel.com"
set NISDOMAIN="basiscomm.ie"
set NISHOST1="nis-host1"
set NISHOST2="nis-host2"
set NTPHOST1="ntp-host1"
set NTPHOST2="ntp-host2"
set NTPHOST3="ntp-host3"
set MAILHOST="mailhost"
set PROXYHOST="proxy.$DNSDOMAIN"
set PROXYPORT=911

echo 'THIS SCRIPT DELETES /home'
echo 'Press enter to continue:'
set X=$< 

echo 'Please enter an unqualified hostname, [eg. mybox]:'
set HOSTNAME=$< 

#######################################################################################
# Detect Freebsd
#######################################################################################

set BSDVERSION=`uname -r`
set BSDARCH=`uname -m`
set BSDRELEASE=`uname -r | tr '[A-Z]' '[a-z]'` 
set BSDVERSION=`uname -r | tr '[A-Z]' '[a-z]' | awk -F'-' '{print $1}' `

#######################################################################################
# Proxies terminal, pkg_add,  wget...
#######################################################################################

echo 'setenv PACKAGEROOT http://ftp3.ie.freebsd.org' >> /root/.cshrc
echo 'setenv PACKAGESITE http://ftp.freebsd.org/pub/FreeBSD/ports/'${BSDARCH}'/packages-'${BSDRELEASE}'/Latest/' >> /root/.cshrc
echo 'setenv HTTP_PROXY http://'${PROXYHOST}':'${PROXYPORT}'' >> /root/.cshrc
echo 'setenv HTTPS_PROXY http://'${PROXYHOST}':'${PROXYPORT}'' >> /root/.cshrc
echo 'setenv FTP_PROXY http://'${PROXYHOST}':'${PROXYPORT}'' >> /root/.cshrc
echo 'setenv RSYNC_PROXY http://'${PROXYHOST}':'${PROXYPORT}'' >> /root/.cshrc
echo 'setenv NO_PROXY 127.0.0.1,localhost,.intel.com,.'${DNSDOMAIN}'' >> /root/.cshrc
echo 'setenv http_proxy $HTTP_PROXY' >> /root/.cshrc
echo 'setenv https_proxy $HTTPS_PROXY' >> /root/.cshrc
echo 'setenv ftp_proxy $FTP_PROXY' >> /root/.cshrc
echo 'setenv rsync_proxy $RSYNC_PROXY' >> /root/.cshrc
echo 'setenv no_proxy $NO_PROXY' >> /root/.cshrc

#######################################################################################
# Package update and installation
#######################################################################################

# temporary proxies
setenv HTTP_PROXY http://${PROXYHOST}:${PROXYPORT}
setenv http_proxy ${HTTP_PROXY}
setenv HTTPS_PROXY ${HTTP_PROXY}
setenv https_proxy ${HTTP_PROXY}
setenv PACKAGEROOT http://ftp3.ie.freebsd.org
setenv PACKAGESITE http://ftp.freebsd.org/pub/FreeBSD/ports/${BSDARCH}/packages-${BSDRELEASE}/Latest/

setenv BATCH yes

cd /usr/ports/net/isc-dhcp41-client
make rmconfig
make install clean 
mv /sbin/dhclient /sbin/dhclient.bak
ln -s /usr/local/sbin/dhclient /sbin/dhclient

cd /usr/ports/shells/bash
make install clean
cd /usr/ports/devel/git
make install clean
cd /usr/ports/devel/subversion
make install clean
cd /usr/ports/security/xinetd
make install clean
cd /usr/ports/dns/bind-tools
make install clean

# future DDNS support
echo 'send host-name "'$HOSTNAME'";' > /etc/dhclient.conf

#######################################################################################
# Rc config
#######################################################################################

echo 'hostname="'$HOSTNAME'"' > /etc/rc.conf
echo 'ifconfig_em0="DHCP"' >> /etc/rc.conf
echo 'sshd_enable="YES"' >> /etc/rc.conf
echo 'dumpdev="AUTO"' >> /etc/rc.conf
echo 'saver="blank"' >> /etc/rc.conf
echo 'keymap="uk.iso"' >> /etc/rc.conf
echo 'hald_enable="YES"' >> /etc/rc.conf
echo 'dbus_enable="YES"' >> /etc/rc.conf
echo 'nis_client_enable="YES"' >> /etc/rc.conf
echo 'rpcbind_enable="YES"' >> /etc/rc.conf
echo 'rpc_statd_enable="YES"' >> /etc/rc.conf
echo 'rpc_lockd_enable="YES"' >> /etc/rc.conf
echo 'nfs_client_enable="YES"' >> /etc/rc.conf
echo 'nisdomainname="'$NISDOMAIN'"' >> /etc/rc.conf
echo 'nis_client_enable="YES"' >> /etc/rc.conf
echo 'nis_client_flags="-ypset -s -m -S '$NISDOMAIN','$NISHOST1','$NISHOST2'"' >> /etc/rc.conf
echo 'portmap_enable="YES"' >> /etc/rc.conf
echo 'xinetd_enable="YES"' >> /etc/rc.conf
echo 'ifconfig_vxn0="dhcp"' >> /etc/rc.conf
echo 'dhclient_program="/sbin/dhclient"' >> /etc/rc.conf
echo 'dhclient_flags="-v -cf /etc/dhclient.conf"' >> /etc/rc.conf
echo 'ipv6_network_interfaces="none"' >> /etc/rc.conf
echo 'ipv6addrctl_enable="NO"' >> /etc/rc.conf
echo 'ipv6addrctl_policy="ipv4_prefer"' >> /etc/rc.conf
echo 'ipv6_activate_all_interfaces="NO"' >> /etc/rc.conf
echo 'firewall_enable="NO"' >> /etc/rc.conf
echo 'amd_enable="YES"' >> /etc/rc.conf
echo 'amd_program="/usr/sbin/amd"' >> /etc/rc.conf
echo 'amd_flags="-F /etc/amd.conf"' >> /etc/rc.conf
echo 'ntpdate_enable="YES"' >> /etc/rc.conf
echo 'ntpdate_hosts="'$NTPHOST1'.'$DNSDOMAIN' '$NTPHOST2'.'$DNSDOMAIN' '$NTPHOST3'.'$DNSDOMAIN'"' >> /etc/rc.conf

#######################################################################################
# Name Server Switch
#######################################################################################

echo 'group: compat' > /etc/nsswitch.conf
echo 'group_compat: nis' >> /etc/nsswitch.conf
echo 'hosts: files dns' >> /etc/nsswitch.conf
echo 'networks: files' >> /etc/nsswitch.conf
echo 'passwd: compat' >> /etc/nsswitch.conf
echo 'passwd_compat: nis' >> /etc/nsswitch.conf
echo 'shells: files' >> /etc/nsswitch.conf
echo 'services: compat' >> /etc/nsswitch.conf
echo 'services_compat: nis' >> /etc/nsswitch.conf
echo 'protocols: files' >> /etc/nsswitch.conf
echo 'rpc: files' >> /etc/nsswitch.conf

#######################################################################################
# NIS / YP / Root logins
#######################################################################################

echo '+:::::::::' >> /etc/master.passwd
echo '+:*::' >> /etc/group
pwd_mkdb  -p /etc/master.passwd

# enable ssh root login
sed -rie 's/^\#PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config

# enable intel default shell
mkdir -p /usr/intel/bin
ln -s /bin/tcsh /usr/intel/bin/tcsh

#######################################################################################
# AMD
#######################################################################################

# get home ready for automounting
rm -rvf /home
mkdir /home
chown root:wheel /home
chmod 755 /home

# get nfs ready for automounting
mkdir /nfs
chown root:wheel /nfs
chmod 755 /nfs

echo '[ global ]' > /etc/amd.conf
echo 'normalize_hostnames =           no' >> /etc/amd.conf
echo 'print_pid =                     no' >> /etc/amd.conf
echo 'pid_file =                      /var/run/amd.pid' >> /etc/amd.conf
echo 'restart_mounts =                yes' >> /etc/amd.conf
echo 'unmount_on_exit =               no' >> /etc/amd.conf
echo 'forced_unmounts =               yes' >> /etc/amd.conf
echo 'auto_dir =                      /a' >> /etc/amd.conf
echo 'local_domain =                  '${DNSDOMAIN}'' >> /etc/amd.conf
echo 'print_version =                 no' >> /etc/amd.conf
echo 'log_file =                      /var/log/amd' >> /etc/amd.conf
echo 'log_options =                   all' >> /etc/amd.conf
echo 'truncate_log =                  no' >> /etc/amd.conf
echo 'nis_domain =                    '${NISDOMAIN}'' >> /etc/amd.conf
echo 'fully_qualified_hosts =         yes' >> /etc/amd.conf
echo 'normalize_slashes =             yes' >> /etc/amd.conf
echo 'browsable_dirs =                yes' >> /etc/amd.conf
echo 'map_options =                   cache:=all' >> /etc/amd.conf
echo 'map_type =                      nis' >> /etc/amd.conf

echo '[ /home ]' >> /etc/amd.conf
echo 'map_name =                      '$HOMEMAP'' >> /etc/amd.conf
echo 'map_options =                   cache:=all' >> /etc/amd.conf
echo 'map_type =                      nis' >> /etc/amd.conf
echo 'browsable_dirs =                yes' >> /etc/amd.conf

echo '[ /nfs ]' >> /etc/amd.conf
echo 'map_name =                      '$NFSMAP'' >> /etc/amd.conf
echo 'map_options =                   cache:=all' >> /etc/amd.conf
echo 'map_type =                      nis' >> /etc/amd.conf
echo 'browsable_dirs =                yes' >> /etc/amd.conf

#######################################################################################
# Sendmail
#######################################################################################

# SMART congfiguration of sendmail
sed -rie "s/^DS/DS$MAILHOST.$DNSDOMAIN/g" /etc/mail/sendmail.cf

#######################################################################################
# EC Support 
#######################################################################################

mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "ssh-dss AAAAB3NzaC1kc3MAAAEBANAAdxo/E2CTnqZbVTUhctX0QdSpMOOT5EznyX3qk4YBcBVpDIDsU8OOduSyokmQwtoinNb4SMxlcUzdcLWnQY6lVkOyl1lRZQaLccHat5BYx/eqUJNJs2LeImPWxbCiPu6jMSkxADLTjM0EkpMMDN5PCxPe8eaawOPk4sVJmG1m/r6KnUv4pKXY2nxx7lE/LMsllvMtiM8/XGc2l91Pgw7OW2aSNLVLC2u/H0Sr/FjV8FQhrd9LcnUwDdmEBi3SdjrMg/PQvmuPhzT3PchkEpgnM6K4bONDtG6jLripIyO+c/ET4xJzqH57KfFAMUPixs9g7yVx+rao2U6vX2C88YUAAAAVAJoIzsbLNMQTCmnj1oEbhd1SVQQjAAABAQCAzgLTdUBnZvYi27P+lIdaGFvu8fgtzUswWuHczTUJZDcPcLYfYU6EKBPrOOWPzTRkQDagzWPfR2scU1j2q0inhamTplLb9CG+UrADGPkfqTPRjHulySVkG9SyUpvNEZEi7ULjJv5CgvoVyqERtcbBD/iYEyF9/uWKn26u+hVUMwXEJNDuv7D4qh7VH4Y8ix2FK5lBfm/hYbwO0G8m4XygP0jkDCWADihxlYr8dhQyYkrGsIVRuMp5Sm213rx4lDaBZguSBkbcMzc25bxQr/orQxwRow+tiIlOnG83jTlZP344zXvBR9y/KBNZnCycbipQJGDPhSl2XNv9DDFAr3YMAAABAGXdPQ/AiuzZpa4WTQEvUUBfv4rQYNCodGpQWDIbaKxYAPzS8ef2QPM3ZAkAxfzvTjumTIcOX7eVtGlTIKkKpIZ9Czr2a00HRledxIRCdjjVziIC5Lb0+DJ2iMzMZGuEk+lw3b8FbGYfVShuhAA4zNPCgLeTLZ1kE3hmEYsIhfg30ui4LSdT/YKRHtzZmwNQmQPdgaZC3s4IwQqT72Yfb5ROt+p84+9laQmKynhIkbMF5scX2wrJnM0N5CEmDWOXyRn+dOmvELyKrJdemZIKXltpoHvNZgaZgFl8BJBgUWqEP3EJocFeelT81KEZ/JmFly1odxEt12ZXgG4q9p0mTbY= root@sisutil001" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

#######################################################################################
# Rebooting
#######################################################################################

# quick update of the locate db
/usr/libexec/locate.updatedb

reboot
