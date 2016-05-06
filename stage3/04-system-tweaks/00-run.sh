#!/bin/bash -e

# Filesystem optimization
echo "vm.dirty_background_ratio = 5" >> ${ROOTFS_DIR}/etc/sysctl.conf
echo "vm.dirty_ratio = 10" >> ${ROOTFS_DIR}/etc/sysctl.conf

# NOTE: May not be necessary because of 'fsck.repair=yes' in boot cmdline.txt
sed -i 's/FSCKFIX=no/FSCKFIX=yes/g' ${ROOTFS_DIR}/lib/init/vars.sh

# Disable hciuart service, since we disabled bluetooth
on_chroot sh -e - <<EOF
systemctl disable hciuart
EOF

# Add admin group and put the admin user in it
on_chroot sh -e - <<EOF
groupadd -f -r admin
adduser ${USER_NAME} admin
EOF


