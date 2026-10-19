#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

confirm_home_deletion

#######################################################################################
# Detect fedora
#######################################################################################

FEDORAVERSION=$(cat /etc/*-release | sed -rn 's/VERSION_ID=(.*?)$/\1/p')

prepare_standard_yum_host
yum -q -y remove gnome-initial-setup
yum -q -y install dialog
section_done

configure_network_wait_section "Adding systemd boot nis/autmount workaround "
configure_fedora_runlevel
configure_fedora_nis "+auto.masterpub"
configure_fedora_boot_gank
install_ec_support_key
finish_fedora_host "${FEDORAVERSION}" yes
updatedb_and_reboot
