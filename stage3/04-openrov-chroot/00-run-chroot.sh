#!/bin/bash -e

echo "env: [`env`]"

git_clone () {
	mkdir -p ${git_target_dir} || true
	git clone ${git_repo} ${git_target_dir} --depth 1 || true
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_branch () {
	mkdir -p ${git_target_dir} || true
	git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

git_clone_full () {
	mkdir -p ${git_target_dir} || true
	git clone ${git_repo} ${git_target_dir} || true
	echo "${git_target_dir} : ${git_repo}" >> /opt/source/list.txt
}

install_node_pkgs () 
{
	if [ -f /usr/bin/npm ] ; then
		cd /
		echo "Installing npm packages"
		echo "debug: node: [`nodejs --version`]"

		npm_bin="/usr/bin/npm"

		git_repo="https://github.com/openrov/openrov-cockpit"
		git_target_dir="/opt/openrov/cockpit"
		git_branch="exp-raspi-cockpit"
		git_clone_branch
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			
			TERM=dumb npm install --production --unsafe-perm

			wfile="/lib/systemd/system/orov-cockpit.socket"
			echo "[Socket]" > ${wfile}
			echo "ListenStream=8080" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=sockets.target" >> ${wfile}

			wfile="/lib/systemd/system/orov-cockpit.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Cockpit server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/cockpit/src" >> ${wfile}
			echo "ExecStart=/usr/bin/node cockpit.js" >> ${wfile}
			echo "SyslogIdentifier=orov-cockpit" >> ${wfile}

			systemctl enable orov-cockpit.socket || true

			bash install_lib/openrov-cockpit-afterinstall.sh
		fi

		git_repo="https://github.com/openrov/openrov-dashboard"
		git_target_dir="/opt/openrov/dashboard"
		git_clone_full
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production --unsafe-perm
			TERM=dumb npm run-script bower
			wfile="/lib/systemd/system/orov-dashboard.socket"
			echo "[Socket]" > ${wfile}
			echo "ListenStream=3080" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Install]" >> ${wfile}
			echo "WantedBy=sockets.target" >> ${wfile}

			wfile="/lib/systemd/system/orov-dashboard.service"
			echo "[Unit]" > ${wfile}
			echo "Description=Cockpit server" >> ${wfile}
			echo "" >> ${wfile}
			echo "[Service]" >> ${wfile}
			#http://stackoverflow.com/questions/22498753/no-data-from-socket-activation-with-systemd
			echo "NonBlocking=True" >> ${wfile}
			echo "WorkingDirectory=/opt/openrov/dashboard/src" >> ${wfile}
			echo "ExecStart=/usr/bin/node dashboard.js" >> ${wfile}
			echo "SyslogIdentifier=orov-dashboard" >> ${wfile}

			systemctl enable orov-dashboard.socket || true

		fi

		git_repo="https://github.com/openrov/openrov-proxy"
		git_target_dir="/opt/openrov/openrov-proxy"
		git_clone_full
		if [ -f ${git_target_dir}/.git/config ] ; then
			cd ${git_target_dir}/
			TERM=dumb npm install --production
			cd proxy-via-browser
			TERM=dumb npm install --production
			cd ${git_target_dir}/
			ln -s /opt/openrov/openrov-proxy/proxy-via-browser/ /opt/openrov/proxy
			bash install_lib/openrov-proxy-afterinstall.sh
		fi
		
		wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino/openrov-arduino_1.0.0-1~13_armhf.deb
		dpkg -i openrov-arduino_1.0.0-1~13_armhf.deb
		
		wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino-builder/openrov-arduino-builder_1.0.0-1~3_armhf.deb
		dpkg -i openrov-arduino-builder_1.0.0-1~3_armhf.deb

		echo "Installing wetty"
		TERM=dumb npm install -g wetty

		echo "Installing ungit"
		TERM=dumb npm install -g ungit
		#cloud9 installed by cloud9-installer
		# removed for now
    cd /
	fi
}

install_git_repos () 
{
	# MCU Firmware
	git_repo="https://github.com/openrov/openrov-software-arduino"
	git_branch="firmware-2.0"
	git_target_dir="/opt/openrov/firmware"
	git_clone_branch

	# Perform Image Customization
	git_repo="https://github.com/openrov/openrov-image-customization"
	git_target_dir="/opt/openrov/image-customization"
	git_branch="exp-raspi-image"
	git_clone_branch
	if [ -f ${git_target_dir}/.git/config ] ; then
		cd ${git_target_dir}/
		./afterinstall.sh || true
	fi

}

# Install Node Packages
install_node_pkgs

# Install git repos
if [ -f /usr/bin/git ] ; then
	git config --global user.email "openrovuser@example.com"
	git config --global user.name "OpenROV User"

	install_git_repos

	git config --global --unset-all user.email
	git config --global --unset-all user.name
fi