#!/bin/bash -e

# Update and package list and remove unnecessary packages

on_chroot sh -e - <<EOF
apt-get purge \
ed \
lua5.1 \
luajit \
man-db \
manpages \
manpages-dev -y

apt-get autoremove --purge -y
EOF