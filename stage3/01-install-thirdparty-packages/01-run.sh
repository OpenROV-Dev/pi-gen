#!/bin/bash -e

# Run rpi-update to get 4.4.9-v7+ at a specific commit that matches the uvcvideo module we built
on_chroot sh -e - <<EOF
SKIP_WARNING=1 rpi-update 15ffab5493d74b12194e6bfc5bbb1c0f71140155
EOF

# TODO: Figure out how to build a deb package for this generically
# Install cloud9 using RCN's Beaglebone package
# on_chroot sh -e - <<EOF
#     cp /etc/apt/sources.list /etc/apt/sources.list.backup
# 	echo "deb http://repos.rcn-ee.com/debian jessie main" | tee --append /etc/apt/sources.list
	
# 	apt-get update
#     apt-get --yes --force-yes install c9-core-installer

#     mv /etc/apt/sources.list.backup /etc/apt/sources.list
#     apt-get update
# EOF