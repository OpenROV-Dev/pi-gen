#!/bin/bash -e

cat <<__EOF__ > ${ROOTFS_DIR}/etc/issue
  ____                ___  ____ _   __
 / __ \___  ___ ___  / _ \/ __ \ | / /
/ /_/ / _ \/ -_) _ \/ , _/ /_/ / |/ /
\____/ .__/\__/_//_/_/|_|\____/|___/
    /_/

Software Version 30.1.0 [master]

Support/FAQ: http://openrov.com

default username:password is [rov:openrov]
__EOF__

cp -a ${ROOTFS_DIR}/etc/issue ${ROOTFS_DIR}/etc/issue.net


# Create directory
mkdir -p ${ROOTFS_DIR}/etc/update-motd.d/

# Create dynamic files
install -m 755 files/* ${ROOTFS_DIR}/etc/update-motd.d/

# Remove MOTD file
rm ${ROOTFS_DIR}/etc/motd

# symlink dynamic MOTD file
ln -s ${ROOTFS_DIR}/var/run/motd ${ROOTFS_DIR}/etc/motd

