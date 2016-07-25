#!/bin/bash

# Helper functions
git_clone () {
	mkdir -p ${git_target_dir} || true
	git clone ${git_repo} ${git_target_dir} --depth 1 || true
	echo "${git_target_dir} : ${git_repo}" >> ${ROOTFS_DIR}/opt/source/list.txt
}

git_clone_branch () {
	mkdir -p ${git_target_dir} || true
	git clone -b ${git_branch} ${git_repo} ${git_target_dir} --depth 1 || true
	echo "${git_target_dir} : ${git_repo}" >> ${ROOTFS_DIR}/opt/source/list.txt
}

git_clone_full () {
	mkdir -p ${git_target_dir} || true
	git clone ${git_repo} ${git_target_dir} || true
	echo "${git_target_dir} : ${git_repo}" >> ${ROOTFS_DIR}/opt/source/list.txt
}

cleanup_npm_cache () {
on_chroot sh -e - <<EOF
	if [ -d /root/tmp/ ] ; then
		rm -rf /root/tmp/ || true
	fi

	if [ -d /root/.npm ] ; then
		rm -rf /root/.npm || true
	fi

	if [ -f /home/${USER_NAME}/.npmrc ] ; then
		rm -f /home/${USER_NAME}/.npmrc || true
	fi
EOF
}

#TODO: These packages need to be deployed to the deb repo for production image
install_custom_pkgs () {
on_chroot sh -e - <<EOF
	# Nginx-common
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/nginx/nginx-common_1.9.10-1~bpo8%202_all.deb
	dpkg -i nginx-common_1.9.10-1~bpo8\ 2_all.deb
	rm nginx-common_1.9.10-1~bpo8\ 2_all.deb

	# Nginx-light
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/nginx/nginx-light_1.9.10-1~bpo8%202_armhf.deb
	dpkg -i nginx-light_1.9.10-1~bpo8\ 2_armhf.deb
	rm nginx-light_1.9.10-1~bpo8\ 2_armhf.deb
	
	# ZeroMQ
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/zmq/openrov-zmq_1.0.0-1~2_armhf.deb
	dpkg -i openrov-zmq_1.0.0-1~2_armhf.deb
	rm openrov-zmq_1.0.0-1~2_armhf.deb
	
	# UVC Driver
	wget https://s3-us-west-1.amazonaws.com/openrov-rpi-kernel-modules/4.4.9-v7%2B/uvcvideo.ko
	mv uvcvideo.ko /lib/modules/4.4.9-v7+/kernel/drivers/media/usb/uvc/

	# GC6500 Apps
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/geocamera-libs/openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	dpkg -i openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	rm openrov-geocamera-utils_1.0.0-1~35.16a26aa_armhf.deb
	
	# Geomuxpp App
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/geomuxpp/openrov-geomuxpp_1.0.0-1~13_armhf.deb
	dpkg -i openrov-geomuxpp_1.0.0-1~14_armhf.deb
	rm openrov-geomuxpp_1.0.0-1~14_armhf.deb
	
	# OpenOCD
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/openocd/openrov-openocd_1.0.0-1~3_armhf.deb
	dpkg -i openrov-openocd_1.0.0-1~3_armhf.deb
	rm openrov-openocd_1.0.0-1~3_armhf.deb
	
	# OpenROV Arduino Core
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino/openrov-arduino_1.0.0-1~16_armhf.deb
	dpkg -i openrov-arduino_1.0.0-1~18_armhf.deb
	rm openrov-arduino_1.0.0-1~18_armhf.deb
	
	# Arduino Builder
	wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino-builder/openrov-arduino-builder_1.0.0-1~6_armhf.deb
	dpkg -i openrov-arduino-builder_1.0.0-1~6_armhf.deb
	rm openrov-arduino-builder_1.0.0-1~6_armhf.deb
EOF
}


install_node_pkgs () {

mkdir -p ${ROOTFS_DIR}/opt/source

# Fix npm in chroot
on_chroot sh -e - <<EOF
if [ ! -d /root/.npm ] ; then
	mkdir -p /root/.npm
fi

npm config set cache /root/.npm
npm config set group 0
npm config set init-module /root/.npm-init.js

if [ ! -d /root/tmp ] ; then
	mkdir -p /root/tmp
fi

npm config set tmp /root/tmp
npm config set user 0
npm config set userconfig /root/.npmrc
EOF

##############################################################
# Sysdetect
##############################################################
git_repo="https://github.com/openrov-dev/orov-sysdetect.git"
git_branch="master"
git_target_chroot_dir="/opt/openrov/system"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_branch

# Install sysdetect node modules
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

TERM=dumb npm install --unsafe-perm
EOF
	
wfile=${ROOTFS_DIR}/lib/systemd/system/orov-sysdetect.service
echo "[Unit]" > ${wfile}
echo "Description=OpenROV System Detection Process" >> ${wfile}
echo "Before=orov-cockpit.service" >> ${wfile}
echo "" >> ${wfile}
echo "[Service]" >> ${wfile}
echo "Type=oneshot" >> ${wfile}
echo "NonBlocking=True" >> ${wfile}
echo "WorkingDirectory=/opt/openrov/system" >> ${wfile}
echo "ExecStart=/usr/bin/node src/index.js" >> ${wfile}
echo "SyslogIdentifier=orov-sysdetect" >> ${wfile}
echo "" >> ${wfile}
echo "[Install]" >> ${wfile}
echo "WantedBy=orov-cockpit.service" >> ${wfile}

on_chroot sh -e - <<EOF
systemctl enable orov-sysdetect.service || true
EOF

##############################################################
# Cockpit
##############################################################
git_repo="https://github.com/openrov/openrov-cockpit"
git_target_chroot_dir="/opt/openrov/cockpit"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_branch="master"
git_clone_branch

# Install cockpit node modules
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

TERM=dumb npm install --production --unsafe-perm
EOF

# Create cockpit service
wfile=${ROOTFS_DIR}/lib/systemd/system/orov-cockpit.service
echo "[Unit]" > ${wfile}
echo "Description=Cockpit server" >> ${wfile}
echo "" >> ${wfile}
echo "[Service]" >> ${wfile}
echo "NonBlocking=True" >> ${wfile}
echo "WorkingDirectory=/opt/openrov/cockpit/src" >> ${wfile}
echo "ExecStart=/usr/bin/node cockpit.js" >> ${wfile}
echo "SyslogIdentifier=orov-cockpit" >> ${wfile}
echo "" >> ${wfile}
echo "[Install]" >> ${wfile}
echo "WantedBy=multi-user.target" >> ${wfile}

# Enable the cockpit socket and run the after install script
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

systemctl enable orov-cockpit.service|| true
bash install_lib/openrov-cockpit-afterinstall.sh
EOF

##############################################################
# Dashboard
##############################################################
git_repo="https://github.com/openrov/openrov-dashboard"
git_target_chroot_dir="/opt/openrov/dashboard"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_full

# Install Dashboard Node/Bower modules
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

TERM=dumb npm install --production --unsafe-perm
TERM=dumb npm run-script bower
EOF

# Create dashboard socket
wfile=${ROOTFS_DIR}/lib/systemd/system/orov-dashboard.socket
echo "[Socket]" > ${wfile}
echo "ListenStream=3080" >> ${wfile}
echo "" >> ${wfile}
echo "[Install]" >> ${wfile}
echo "WantedBy=sockets.target" >> ${wfile}

# Create dashboard service
wfile=${ROOTFS_DIR}/lib/systemd/system/orov-dashboard.service
echo "[Unit]" > ${wfile}
echo "Description=Cockpit server" >> ${wfile}
echo "" >> ${wfile}
echo "[Service]" >> ${wfile}
echo "NonBlocking=True" >> ${wfile}
echo "WorkingDirectory=/opt/openrov/dashboard/src" >> ${wfile}
echo "ExecStart=/usr/bin/node dashboard.js" >> ${wfile}
echo "SyslogIdentifier=orov-dashboard" >> ${wfile}

# Enable dashboard socket
on_chroot sh -e - <<EOF
systemctl enable orov-dashboard.socket || true
EOF

##############################################################
# Proxy
##############################################################
git_repo="https://github.com/openrov/openrov-proxy"
git_target_chroot_dir="/opt/openrov/openrov-proxy"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_full

# Install proxy node modules, and run post install script
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/
TERM=dumb npm install --production
cd proxy-via-browser
TERM=dumb npm install --production
cd ${git_target_chroot_dir}/
ln -s /opt/openrov/openrov-proxy/proxy-via-browser/ /opt/openrov/proxy
bash install_lib/openrov-proxy-afterinstall.sh
EOF

cleanup_npm_cache

}

install_git_repos ()
{
on_chroot sh -e - <<EOF
git config --global user.email "${USER_NAME}@example.com"
git config --global user.name "${USER_NAME}"
EOF

# MCU Firmware
git_repo="https://github.com/openrov/openrov-software-arduino"
git_branch="firmware-2.0"
git_target_chroot_dir="/opt/openrov/firmware"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_branch

# Image customizations
git_repo="https://github.com/openrov/openrov-image-customization"
git_branch="rpi"
git_target_chroot_dir="/opt/openrov/image-customization"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_branch

on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/
./beforeinstall.sh || true
./afterinstall.sh || true
EOF

on_chroot sh -e - <<EOF
git config --global --unset-all user.email
git config --global --unset-all user.name
EOF
}


install_custom_pkgs
install_node_pkgs
install_git_repos
