#!/bin/bash -e

# Enable dhcpd on eth0
cat <<__EOF__ > ${ROOTFS_DIR}/etc/dnsmasq.d/eth0_0-dhcp 
interface=eth0:0

#one address range
dhcp-range=192.168.254.10,192.168.254.20

dhcp-option=3
except-interface=lo
listen-address=192.168.254.1
bind-interfaces
__EOF__


