#!/bin/bash
#######################################################################################
# Shared post-install steps for the OS configuration scripts.
# Sourced by fedora.sh, wgc-fedora.sh, centos.sh, ubuntu.sh, freebsd.sh,
# and wgc-freebsd.sh.
#######################################################################################

termred='\e[0;31m'
termgreen='\e[0;32m'
termblue='\e[0;36m'
termreset='\e[0m' # No Color
sep="===================================================================="

ec_support_public_key='ssh-dss AAAAB3NzaC1kc3MAAAEBANAAdxo/E2CTnqZbVTUhctX0QdSpMOOT5EznyX3qk4YBcBVpDIDsU8OOduSyokmQwtoinNb4SMxlcUzdcLWnQY6lVkOyl1lRZQaLccHat5BYx/eqUJNJs2LeImPWxbCiPu6jMSkxADLTjM0EkpMMDN5PCxPe8eaawOPk4sVJmG1m/r6KnUv4pKXY2nxx7lE/LMsllvMtiM8/XGc2l91Pgw7OW2aSNLVLC2u/H0Sr/FjV8FQhrd9LcnUwDdmEBi3SdjrMg/PQvmuPhzT3PchkEpgnM6K4bONDtG6jLripIyO+c/ET4xJzqH57KfFAMUPixs9g7yVx+rao2U6vX2C88YUAAAAVAJoIzsbLNMQTCmnj1oEbhd1SVQQjAAABAQCAzgLTdUBnZvYi27P+lIdaGFvu8fgtzUswWuHczTUJZDcPcLYfYU6EKBPrOOWPzTRkQDagzWPfR2scU1j2q0inhamTplLb9CG+UrADGPkfqTPRjHulySVkG9SyUpvNEZEi7ULjJv5CgvoVyqERtcbBD/iYEyF9/uWKn26u+hVUMwXEJNDuv7D4qh7VH4Y8ix2FK5lBfm/hYbwO0G8m4XygP0jkDCWADihxlYr8dhQyYkrGsIVRuMp5Sm213rx4lDaBZguSBkbcMzc25bxQr/orQxwRow+tiIlOnG83jTlZP344zXvBR9y/KBNZnCycbipQJGDPhSl2XNv9DDFAr3YMAAABAGXdPQ/AiuzZpa4WTQEvUUBfv4rQYNCodGpQWDIbaKxYAPzS8ef2QPM3ZAkAxfzvTjumTIcOX7eVtGlTIKkKpIZ9Czr2a00HRledxIRCdjjVziIC5Lb0+DJ2iMzMZGuEk+lw3b8FbGYfVShuhAA4zNPCgLeTLZ1kE3hmEYsIhfg30ui4LSdT/YKRHtzZmwNQmQPdgaZC3s4IwQqT72Yfb5ROt+p84+9laQmKynhIkbMF5scX2wrJnM0N5CEmDWOXyRn+dOmvELyKrJdemZIKXltpoHvNZgaZgFl8BJBgUWqEP3EJocFeelT81KEZ/JmFly1odxEt12ZXgG4q9p0mTbY= root@sisutil001'

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "common.sh is a function library and must be sourced." >&2
	exit 1
fi

print_section_lines() {
	echo "${sep}"
	local line
	for line in "$@"; do
		echo -e "${termblue}${line}${termreset}"
	done
	echo "${sep}"
}

section_done() {
	echo -e "${termgreen}done...${termreset}"
}

confirm_home_deletion() {
	echo 'THIS SCRIPT DELETES /home'
	echo 'Press enter to continue:'
	read -r _
}

configure_bashrc_proxy() {
	# bashrc
	sed -rie 's/^export http(.*?)$/#export http\1/g' /root/.bashrc
	sed -rie 's/^export no(.*?)$/#export no\1/g' /root/.bashrc
	echo "export http_proxy=http://proxy.ir.intel.com:911" >>/root/.bashrc
	echo "export no_proxy=localhost,127.0.0.1" >>/root/.bashrc
}

setup_yum_terminal_proxies() {
	print_section_lines "Setting up yum, terminal proxies etc"

	configure_bashrc_proxy

	# yum.conf
	sed -rie 's/^proxy(.*?)$/#proxy\1/g' /etc/yum.conf
	echo "proxy=http://proxy.ir.intel.com:911" >>/etc/yum.conf
	#sed -rie 's/^proxy(.*?)$/proxy=http:\/\/proxy.ir.intel.com:911/g' /etc/yum.conf

	section_done
}

disable_selinux() {
	print_section_lines "Disabling Selinux"

	# probably not needing for testing purposes
	sed -rie 's/^SELINUX=.*?$/SELINUX=disabled/g' /etc/selinux/config

	section_done
}

begin_package_update() {
	echo "${sep}"
	echo -e "${termblue}Updating packages and installing autofs, ypbind etc ${termreset}"
	echo -e "${termblue}This may take 15 minutes or more....${termreset}"
	echo "${sep}"
}

yum_update_quiet() {
	# setup yum proxy and update
	yum -q -y update
}

yum_install_base_packages() {
	# install autofs, ypbind & sshd if not already
	yum -q -y install autofs
	yum -q -y install ypbind
	yum -q -y install openssh-server
	yum -q -y install tcsh
	yum -q -y install tigervnc-server
}

prepare_standard_yum_host() {
	setup_yum_terminal_proxies
	disable_selinux
	begin_package_update
	yum_update_quiet
	yum_install_base_packages
}

configure_network_wait_section() {
	local message="$1"

	print_section_lines "${message}"

	# Pause network allowing other process to come to depend on it
	sed -rie 's/^NETWORKWAIT(.*?)$/#NETWORKWAIT\1/g' /etc/sysconfig/network
	sed -rie 's/^NETWORKDELAY(.*?)$/#NETWORKDELAY\1/g' /etc/sysconfig/network
	echo "NETWORKWAIT=yes" >>/etc/sysconfig/network
	echo "NETWORKDELAY=15" >>/etc/sysconfig/network

	section_done
}

configure_fedora_runlevel() {
	print_section_lines \
		"Switching to sysv runlevel 3 like setup " \
		"Disable bluetooth etc... "

	# set run level 3 default
	rm -rf /etc/systemd/system/default.target
	ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

	# disable unneeded services
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

	section_done
}

set_auto_master_map() {
	local master_map="$1"

	# correct the auto master map
	sed -ie "s/^+auto.master\$/${master_map}/g" /etc/auto.master
}

configure_nis_nsswitch() {
	# update nsswitch
	authconfig --enablenis --updateall

	# bug fix for fedora not inheriting user nis groups
	sed -rie 's/^initgroups:(.*?)$/#initgroups:\1/g' /etc/nsswitch.conf
	# host lookups should not be done against NIS, lets make sure of it
	sed -rie 's/^hosts:(.*?)$/hosts: files dns/g' /etc/nsswitch.conf
}

configure_fedora_nis() {
	local master_map="$1"

	print_section_lines "Adjusting system to nis logins "
	set_auto_master_map "${master_map}"
	configure_nis_nsswitch
	section_done
}

configure_grub_defaults() {
	# set the default kernel as the selected kernel on grub selection
	sed -rie 's/^GRUB_SAVEDEFAULT=(.*?)$/#GRUB_SAVEDEFAULT=\1/g' /etc/default/grub
	echo "GRUB_SAVEDEFAULT=true" >>/etc/default/grub

	# disable splash boot
	sed -ie 's/ rhgb / /g' /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
}

configure_fedora_boot_gank() {
	print_section_lines "Cleaning out useless kernels and updating grub"
	configure_grub_defaults
	section_done
}

warn_newer_kernel() {
	echo -e "${termred}A newer kernel exists, however it is not the running kernel${termreset}"
	echo -e "${termred}Reboot select the newer kernel in grub.  Then re-run this script${termreset}"
}

install_ec_support_key() {
	#######################################################################################
	# EC Support
	#######################################################################################

	mkdir -p /root/.ssh
	chmod 700 /root/.ssh
	echo "${ec_support_public_key}" >/root/.ssh/authorized_keys
	chmod 600 /root/.ssh/authorized_keys
}

remove_tester_home() {
	# clean up installation users
	userdel -f tester
	local home_dir=/home
	rm -rvf "${home_dir:?}/"*
}

link_intel_tcsh() {
	local tcsh_path="$1"

	# link tcsh for usr intel
	mkdir -p /usr/intel/bin
	ln -s "${tcsh_path}" /usr/intel/bin/tcsh
}

finish_banner() {
	print_section_lines "Finishing up"
}

enable_fedora_login_services() {
	local fedora_version="$1"

	# turn on sshd, ypbind and legacy autofs sysv script
	systemctl -q enable sshd.service

	if [[ "${fedora_version}" == 16 ]]; then
		chkconfig autofs on
	else
		systemctl -q enable autofs.service
	fi

	systemctl -q enable ypbind.service
	# restart ypbind after enabling or it won't come up on next boot ( fedora bug )
	systemctl -q restart ypbind.service
}

finish_fedora_host() {
	local fedora_version="$1"
	local cleanup_home="$2"

	finish_banner
	enable_fedora_login_services "${fedora_version}"
	if [[ "${cleanup_home}" == yes ]]; then
		remove_tester_home
		link_intel_tcsh /bin/tcsh
	fi
	section_done
}

finish_cleanup_and_tcsh() {
	local tcsh_path="$1"

	finish_banner
	remove_tester_home
	link_intel_tcsh "${tcsh_path}"
	section_done
}

updatedb_and_reboot() {
	# quick update of the locate db
	updatedb
	reboot
}

run_freebsd_post_config() {
	local home_map="$1"
	local nfs_map="$2"
	local dns_domain="$3"
	local nis_domain="$4"
	local nis_host1="$5"
	local nis_host2="$6"
	local ntp_host1="ntp-host1"
	local ntp_host2="ntp-host2"
	local ntp_host3="ntp-host3"
	local mail_host="mailhost"
	local proxy_host="proxy.${dns_domain}"
	local proxy_port=911
	local host_name
	local bsd_arch
	local bsd_release
	local bsd_version

	confirm_home_deletion

	echo 'Please enter an unqualified hostname, [eg. mybox]:'
	IFS= read -r host_name

	#######################################################################################
	# Detect Freebsd
	#######################################################################################

	bsd_version=$(uname -r)
	bsd_arch=$(uname -m)
	bsd_release=$(uname -r | tr '[:upper:]' '[:lower:]')
	bsd_version=$(uname -r | tr '[:upper:]' '[:lower:]' | awk -F'-' '{print $1}')
	# BSDVERSION is detected by the original scripts and then left unused.
	: "${bsd_version}"

	#######################################################################################
	# Proxies terminal, pkg_add,  wget...
	#######################################################################################

	{
		echo 'setenv PACKAGEROOT http://ftp3.ie.freebsd.org'
		echo "setenv PACKAGESITE http://ftp.freebsd.org/pub/FreeBSD/ports/${bsd_arch}/packages-${bsd_release}/Latest/"
		echo "setenv HTTP_PROXY http://${proxy_host}:${proxy_port}"
		echo "setenv HTTPS_PROXY http://${proxy_host}:${proxy_port}"
		echo "setenv FTP_PROXY http://${proxy_host}:${proxy_port}"
		echo "setenv RSYNC_PROXY http://${proxy_host}:${proxy_port}"
		echo "setenv NO_PROXY 127.0.0.1,localhost,.intel.com,.${dns_domain}"
		echo "setenv http_proxy \$HTTP_PROXY"
		echo "setenv https_proxy \$HTTPS_PROXY"
		echo "setenv ftp_proxy \$FTP_PROXY"
		echo "setenv rsync_proxy \$RSYNC_PROXY"
		echo "setenv no_proxy \$NO_PROXY"
	} >>/root/.cshrc || exit

	#######################################################################################
	# Package update and installation
	#######################################################################################

	# temporary proxies
	export HTTP_PROXY="http://${proxy_host}:${proxy_port}"
	export http_proxy="${HTTP_PROXY}"
	export HTTPS_PROXY="${HTTP_PROXY}"
	export https_proxy="${HTTP_PROXY}"
	export PACKAGEROOT="http://ftp3.ie.freebsd.org"
	export PACKAGESITE="http://ftp.freebsd.org/pub/FreeBSD/ports/${bsd_arch}/packages-${bsd_release}/Latest/"
	export BATCH="yes"

	# csh exits the script when cd or a redirection fails. External command
	# failures, such as make, do not.
	cd /usr/ports/net/isc-dhcp41-client || exit
	make rmconfig
	make install clean
	mv /sbin/dhclient /sbin/dhclient.bak
	ln -s /usr/local/sbin/dhclient /sbin/dhclient

	cd /usr/ports/shells/bash || exit
	make install clean
	cd /usr/ports/devel/git || exit
	make install clean
	cd /usr/ports/devel/subversion || exit
	make install clean
	cd /usr/ports/security/xinetd || exit
	make install clean
	cd /usr/ports/dns/bind-tools || exit
	make install clean

	# future DDNS support
	echo "send host-name \"${host_name}\";" >/etc/dhclient.conf || exit

	#######################################################################################
	# Rc config
	#######################################################################################

	{
		echo "hostname=\"${host_name}\""
		echo 'ifconfig_em0="DHCP"'
		echo 'sshd_enable="YES"'
		echo 'dumpdev="AUTO"'
		echo 'saver="blank"'
		echo 'keymap="uk.iso"'
		echo 'hald_enable="YES"'
		echo 'dbus_enable="YES"'
		echo 'nis_client_enable="YES"'
		echo 'rpcbind_enable="YES"'
		echo 'rpc_statd_enable="YES"'
		echo 'rpc_lockd_enable="YES"'
		echo 'nfs_client_enable="YES"'
		echo "nisdomainname=\"${nis_domain}\""
		echo 'nis_client_enable="YES"'
		echo "nis_client_flags=\"-ypset -s -m -S ${nis_domain},${nis_host1},${nis_host2}\""
		echo 'portmap_enable="YES"'
		echo 'xinetd_enable="YES"'
		echo 'ifconfig_vxn0="dhcp"'
		echo 'dhclient_program="/sbin/dhclient"'
		echo 'dhclient_flags="-v -cf /etc/dhclient.conf"'
		echo 'ipv6_network_interfaces="none"'
		echo 'ipv6addrctl_enable="NO"'
		echo 'ipv6addrctl_policy="ipv4_prefer"'
		echo 'ipv6_activate_all_interfaces="NO"'
		echo 'firewall_enable="NO"'
		echo 'amd_enable="YES"'
		echo 'amd_program="/usr/sbin/amd"'
		echo 'amd_flags="-F /etc/amd.conf"'
		echo 'ntpdate_enable="YES"'
		echo "ntpdate_hosts=\"${ntp_host1}.${dns_domain} ${ntp_host2}.${dns_domain} ${ntp_host3}.${dns_domain}\""
	} >/etc/rc.conf || exit

	#######################################################################################
	# Name Server Switch
	#######################################################################################

	{
		echo 'group: compat'
		echo 'group_compat: nis'
		echo 'hosts: files dns'
		echo 'networks: files'
		echo 'passwd: compat'
		echo 'passwd_compat: nis'
		echo 'shells: files'
		echo 'services: compat'
		echo 'services_compat: nis'
		echo 'protocols: files'
		echo 'rpc: files'
	} >/etc/nsswitch.conf || exit

	#######################################################################################
	# NIS / YP / Root logins
	#######################################################################################

	echo '+:::::::::' >>/etc/master.passwd || exit
	echo '+:*::' >>/etc/group || exit
	pwd_mkdb -p /etc/master.passwd

	# enable ssh root login
	sed -rie 's/^\#PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config

	# enable intel default shell
	link_intel_tcsh /bin/tcsh

	#######################################################################################
	# AMD
	#######################################################################################

	# get home ready for automounting
	local home_mount=/home
	rm -rvf "${home_mount}"
	mkdir /home
	chown root:wheel /home
	chmod 755 /home

	# get nfs ready for automounting
	mkdir /nfs
	chown root:wheel /nfs
	chmod 755 /nfs

	{
		echo '[ global ]'
		echo 'normalize_hostnames =           no'
		echo 'print_pid =                     no'
		echo 'pid_file =                      /var/run/amd.pid'
		echo 'restart_mounts =                yes'
		echo 'unmount_on_exit =               no'
		echo 'forced_unmounts =               yes'
		echo 'auto_dir =                      /a'
		echo "local_domain =                  ${dns_domain}"
		echo 'print_version =                 no'
		echo 'log_file =                      /var/log/amd'
		echo 'log_options =                   all'
		echo 'truncate_log =                  no'
		echo "nis_domain =                    ${nis_domain}"
		echo 'fully_qualified_hosts =         yes'
		echo 'normalize_slashes =             yes'
		echo 'browsable_dirs =                yes'
		echo 'map_options =                   cache:=all'
		echo 'map_type =                      nis'
		echo '[ /home ]'
		echo "map_name =                      ${home_map}"
		echo 'map_options =                   cache:=all'
		echo 'map_type =                      nis'
		echo 'browsable_dirs =                yes'
		echo '[ /nfs ]'
		echo "map_name =                      ${nfs_map}"
		echo 'map_options =                   cache:=all'
		echo 'map_type =                      nis'
		echo 'browsable_dirs =                yes'
	} >/etc/amd.conf || exit

	#######################################################################################
	# Sendmail
	#######################################################################################

	# SMART configuration of sendmail
	sed -rie "s/^DS/DS${mail_host}.${dns_domain}/g" /etc/mail/sendmail.cf

	install_ec_support_key

	#######################################################################################
	# Rebooting
	#######################################################################################

	# quick update of the locate db
	/usr/libexec/locate.updatedb

	reboot
}
