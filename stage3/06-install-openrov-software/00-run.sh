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

# Clone repos and install node packages

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

# Install all dependencies

# Geomuxpp

# Clone Cockpit
git_repo="https://github.com/openrov/openrov-cockpit"
git_target_chroot_dir="/opt/openrov/cockpit"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_branch="feat_platform"
git_clone_branch

# Install Node modules, and set up services/sockets
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

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
EOF

# Clone Dashboard
git_repo="https://github.com/openrov/openrov-dashboard"
git_target_chroot_dir="/opt/openrov/dashboard"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_full

# Install Node/Bower modules, and set up services/sockets
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/

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
EOF

# Clone Proxy
git_repo="https://github.com/openrov/openrov-proxy"
git_target_chroot_dir="/opt/openrov/openrov-proxy"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_full

# Install Node modules, and run post install script
on_chroot sh -e - <<EOF
cd ${git_target_chroot_dir}/
TERM=dumb npm install --production
cd proxy-via-browser
TERM=dumb npm install --production
cd ${git_target_chroot_dir}/
ln -s /opt/openrov/openrov-proxy/proxy-via-browser/ /opt/openrov/proxy
bash install_lib/openrov-proxy-afterinstall.sh
EOF

# Clone MCU Firmware
git_repo="https://github.com/openrov/openrov-software-arduino"
git_branch="firmware-2.0"
git_target_chroot_dir="/opt/openrov/firmware"
git_target_dir="${ROOTFS_DIR}${git_target_chroot_dir}"
git_clone_branch

# Install the OpenROV Arduino Core and Arduino Builder tools
# TODO: Actually put these in the repo?
on_chroot sh -e - <<EOF

wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/openocd/openrov-openocd_1.0.0-1~3_armhf.deb
dpkg -i openrov-openocd_1.0.0-1~3_armhf.deb
rm openrov-openocd_1.0.0-1~3_armhf.deb

wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino/openrov-arduino_1.0.0-1~15_armhf.deb
dpkg -i openrov-arduino_1.0.0-1~15_armhf.deb
rm openrov-arduino_1.0.0-1~15_armhf.deb

wget http://openrov-software-nightlies.s3-us-west-2.amazonaws.com/jessie/arduino-builder/openrov-arduino-builder_1.0.0-1~4_armhf.deb
dpkg -i openrov-arduino-builder_1.0.0-1~4_armhf.deb
rm openrov-arduino-builder_1.0.0-1~4_armhf.deb
EOF

# TODO: Install wetty and cloud9

