#!/bin/bash -e

# Set up samba configuration
mkdir -p ${ROOTFS_DIR}/var/run/samba

cat <<__EOF__ >> ${ROOTFS_DIR}/etc/samba/smb.conf
[OpenROV]
comment = OpenROV Cockpit
path = /
force user = rov
force group = admin
read only = No
guest ok = Yes
__EOF__

sed -i 's|log/samba|log|g' ${ROOTFS_DIR}/etc/samba/smb.conf


