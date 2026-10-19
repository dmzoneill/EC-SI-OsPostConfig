#!/bin/bash
#######################################################################################
# david.m.oneill@intel.com
#######################################################################################

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

run_freebsd_post_config \
	"amd.public_home" \
	"amd.nfs" \
	"ir.intel.com" \
	"basiscomm.ie" \
	"nis-host1" \
	"nis-host2"
