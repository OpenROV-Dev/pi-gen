
# Install cloud9 using Robert Nelson's repos
# TODO: Build this ourselves?
on_chroot sh -e - <<EOF
	# Backup sources list
	cp /etc/apt/sources.list /etc/apt/sources.list.bk

	# Add RCN repos
	echo "deb http://repos.rcn-ee.com/debian/ jessie main" | tee --append /etc/apt/sources.list

	apt-get update

	# RCN Packages
	apt-get install c9-core-installer

	# Restore apt source list
	mv /etc/apt/sources.list.bk /etc/apt/source.list
EOF