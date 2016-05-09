#!/bin/bash -e

# Run rpi-update to get 4.4.9-v7+ at a specific commit that matches the uvcvideo module we built
on_chroot sh -e - <<EOF
SKIP_WARNING=1 rpi-update 15ffab5493d74b12194e6bfc5bbb1c0f71140155
EOF