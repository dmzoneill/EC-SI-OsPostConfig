#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

confirm_home_deletion

#######################################################################################
# Detect centos
#######################################################################################

if [ -f /etc/redhat-release ]; then
	CENTOSVERSION=$(awk '{print $4}' /etc/redhat-release | awk -F. '{print $1}')
else
	CENTOSVERSION=6
fi

prepare_standard_yum_host
yum -q -y install git
yum -q -y install subversion
yum -q -y install nfs-utils
yum -q -y remove gnome-initial-setup
yum -q -y install dialog

if [[ "${CENTOSVERSION}" == 6 || "${CENTOSVERSION}" == 7 ]]; then
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

section_done

#######################################################################################
# Run levels and gank
#######################################################################################

print_section_lines \
	"Switching to sysv runlevel 3 " \
	"Disable bluetooth etc... "

# set run level 3 default
sed -rie 's/^id:[0-9]:initdefault:/id:3:initdefault:/g' /etc/inittab

if [[ "${CENTOSVERSION}" == 5 || "${CENTOSVERSION}" == 6 ]]; then

	# disable unneeded services
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

	# disable unneeded services
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

section_done

#######################################################################################
# Nis / Automounter Configuration
#######################################################################################

print_section_lines "Adjusting system to nis logins "

# set nis domain
echo "NISDOMAIN=basiscomm.ie" >>/etc/sysconfig/network
set_auto_master_map "+auto.masterpub"
configure_nis_nsswitch

{
	echo "domain basiscomm.ie server nis-host1.ir.intel.com"
	echo "domain basiscomm.ie server nis-host2.ir.intel.com"
} >/etc/yp.conf

section_done

#######################################################################################
# Boot gank
#######################################################################################

print_section_lines "Enabling verbose boot"

# disable splash boot
sed -ie 's/ rhgb / /g' /boot/grub/menu.lst

section_done

install_ec_support_key
finish_cleanup_and_tcsh /bin/tcsh
updatedb_and_reboot
