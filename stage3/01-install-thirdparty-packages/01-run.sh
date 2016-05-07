#!/bin/bash -e

# Run rpi-update to get latest kernel
on_chroot sh -e - <<EOF
SKIP_WARNING=1 rpi-update
EOF