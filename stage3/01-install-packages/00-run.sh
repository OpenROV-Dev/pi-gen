#!/bin/bash -e

# Add NodeSource to source list
on_chroot sh -e - <<EOF
	curl -sL https://deb.nodesource.com/setup_6.x | bash -
EOF