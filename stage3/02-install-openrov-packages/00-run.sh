#!/bin/bash -e

# Add openrov repos
#on_chroot sh -e - <<EOF
#	echo "deb http://deb-repo.openrov.com jessie unstable" | tee --append /etc/apt/sources.list
#	wget -O - -q http://deb-repo.openrov.com/build.openrov.com.gpg.key | apt-key add -
	
#	apt-get update
#EOF