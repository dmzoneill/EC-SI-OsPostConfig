#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

#######################################################################################
# Detect fedora
#######################################################################################

FEDORAVERSION=$(cat /etc/*-release | head -n 1 | tr -d 'A-Za-z()[]' | sed 's/ //g')

#######################################################################################
# Begin
#######################################################################################

hostname=$(hostname)
dnsdomain=$(grep domain /etc/resolv.conf | awk '{ print $2 }')
nisdomain=$(grep domain /etc/yp.conf | tail -n 1 | awk '{ print $2 }')
if [[ "${FEDORAVERSION}" == 16 ]]; then
	ipaddr=$(ifconfig | sed -rn 's/.*r:10([^ ]+) .*/10\1/p')
else
	ipaddr=$(ifconfig | sed -rn 's/.*inet 10([^ ]+) .*/10\1/p')
fi
# nisdomain and ipaddr are collected by the original script and then left unused.
: "${nisdomain}" "${ipaddr}"

print_section_lines "Fedora ${FEDORAVERSION} vanilla post configuration"

echo -n "Hostname [eg. wgcl023] :"
read -r newhostname
echo -e "${termgreen}${newhostname}${termreset}"
echo -n "Email Address : "
read -r email

# The original captures grep's output and then replaces it, so the match is not printed.
if uname -m | grep -q 64; then
	ARCH="64"
else
	ARCH="32"
fi

#######################################################################################
# Setup properp hostname and ddns config
#######################################################################################

rm -rvf /etc/dhcp/*.conf
echo "send host-name \"${newhostname}\";" >/etc/dhcp/dhclient.onf

echo "${newhostname}" >/etc/hostname
echo "${newhostname}" >/etc/HOSTNAME

echo "HOSTNAME=${newhostname}" >/etc/sysconfig/network
echo "NETWORKING=yes" >/etc/sysconfig/network
echo "NISDOMAIN=basiscomm.ie" >/etc/sysconfig/network
echo "NTPSERVERARGS=iburst" >/etc/sysconfig/network

#######################################################################################
# Proxies terminal, yum,  wget...
#######################################################################################

print_section_lines "Setting up yum, terminal etc"

export http_proxy=""
export no_proxy="localhost,ir.intel.com"

# yum.conf
sed -i 's/enabled=.*/enabled=0/g' /etc/yum.repos.d/*
wget "http://wgcrepos.ir.intel.com/f${FEDORAVERSION}${ARCH}.repo" -O "/etc/yum.repos.d/f${FEDORAVERSION}${ARCH}.repo"

section_done

disable_selinux

#######################################################################################
# Package update and installation
#######################################################################################

begin_package_update

# yum up any previous yum usage
yum clean all

yum_update_quiet
yum_install_base_packages

section_done

configure_network_wait_section "Adding systemd boot nis/automount workaround "
configure_fedora_runlevel
configure_fedora_nis "+auto.masterwgcpub"

#######################################################################################
# Boot gank
#######################################################################################

print_section_lines "Cleaning out useless kernels and updating grub"

# remove old kernels
numkernels=$(rpm -q kernel | wc -l)
rerun=0

while [[ "${numkernels}" -gt 1 ]]; do
	currentkernel=$(uname -r)
	removekernel=$(rpm -q kernel | head -n 1)

	if [[ "${removekernel}" == *"${currentkernel}" ]]; then
		warn_newer_kernel
		numkernels=0
		rerun=1
	else
		yum -q -y remove "$(rpm -q kernel | head -n 1)"
		numkernels=$(rpm -q kernel | wc -l)
	fi
done

configure_grub_defaults
section_done

finish_fedora_host "${FEDORAVERSION}" no

#######################################################################################
# Send complete email
#######################################################################################

print_section_lines "Sending email confirmation"

MSG="Hi, the configuration of ${hostname}.${dnsdomain} has been completed."

if [[ "${rerun}" -eq 1 ]]; then
	MSG="${MSG}  You should rerun the script to complete new kernel/grub setup."
fi

# stdout is discarded and stderr stays on the original stdout, matching the
# historical `2>&1 >>/dev/null` order.
exec 3>&1
echo "${MSG}" | mailx -v -s "Configuration Complete" -S smtp=smtp://mailhost.ir.intel.com -S from="root@${hostname}.${dnsdomain}" "${email}" >>/dev/null 2>&3
exec 3>&-

section_done

#######################################################################################
# Rebooting
#######################################################################################

countdown=30

while [[ "${countdown}" -gt 0 ]]; do
	echo "Rebooting in ${countdown} seconds!!!!!" | wall
	sleep 1
	countdown=$((countdown - 1))
done

reboot
