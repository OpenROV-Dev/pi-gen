#!/bin/bash -x

# Clone the DietPi repo
git clone https://github.com/Fourdee/DietPi.git ./files/DietPi --depth 1

# Delete unnecessary files
rm ./files/DietPi/boot_c1.ini
rm ./files/DietPi/boot_c2.ini
rm ./files/DietPi/boot_xu4.ini
rm -r ./files/DietPi/.git
rm ./files/DietPi/.gitattributes
rm ./files/DietPi/.gitignore
rm ./files/DietPi/TESTING-BRANCH.md

# Change permissions on all of the files
# TODO: Sort out actual correct permissions, as opposed to a blind recursive 777
chmod -R 777 ./files/DietPi/*

# Copy the DietPi files to root
rsync -a files/DietPi/* ${ROOTFS_DIR}/boot/

# Install the debian keyrings
on_chroot sh -e - << OROV_EOF
	apt-get update
	
	apt-key update
	apt-get install debian-keyring -y --force-yes
	apt-get install debian-archive-keyring -y --force-yes
	apt-key update
OROV_EOF

# Add Non_RPI repos
cat << _EOF_ > ${ROOTFS_DIR}/etc/apt/sources.list
# ------- NOT RPI -------------------------
deb http://ftp.debian.org/debian jessie main contrib non-free
deb http://ftp.debian.org/debian jessie-updates main contrib non-free
deb http://security.debian.org jessie/updates main contrib non-free
deb http://ftp.debian.org/debian jessie-backports main contrib non-free
# ------- NOT RPI -------------------------
_EOF_

# Update and package list and remove unnecessary packages
on_chroot sh -e - << OROV_EOF
	# Remove following
	DEBIAN_FRONTEND=noninteractive apt-get purge dhcpcd5 libsqlite* libxapian22 lua5.1 luajit netcat-* make makedev ncdu plymouth openresolv \
	shared-mime-in* tcpd strace tasksel* wireless-* xdg-user-dirs triggerhappy python* v4l-utils traceroute xz-utils \
	ucf xauth zlib1g-dev xml-core aptitude* avahi-daemon rsyslog logrotate man-db manpages vim vim-common vim-runtime vim-tiny mc mc-data -y

	# Purge
	DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
OROV_EOF

# Install DietPi packages
on_chroot sh -e - << OROV_EOF

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	resolvconf bc dbus bzip2 psmisc bash-completion cron \
	whiptail sudo ntp ntfs-3g dosfstools parted hdparm \
	pciutils usbutils zip htop wput wget fake-hwclock \
	dphys-swapfile curl unzip ca-certificates console-setup \
	console-data console-common wireless-tools wireless-regdb crda

# Firmware installs
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	firmware-realtek firmware-ralink firmware-brcm80211 firmware-atheros
OROV_EOF

# Set swap size
echo -e "CONF_SWAPSIZE=0" > ${ROOTFS_DIR}/etc/dphys-swapfile

#FSTAB
cp ${ROOTFS_DIR}/boot/dietpi/conf/fstab ${ROOTFS_DIR}/etc/fstab

# Create various folders that will be needed
mkdir -p ${ROOTFS_DIR}/mnt/usb_1
mkdir -p ${ROOTFS_DIR}/mnt/samba
mkdir -p ${ROOTFS_DIR}/mnt/ftp_client
echo -e "Samba client can be installed and setup by DietPi-Config.\nSimply run: dietpi-config 8" > ${ROOTFS_DIR}/mnt/samba/readme.txt
echo -e "FTP client mount can be installed and setup by DietPi-Config.\nSimply run: dietpi-config 8" > ${ROOTFS_DIR}/mnt/ftp_client/readme.txt

on_chroot sh - << OROV_EOF
	/boot/dietpi/dietpi-logclear 2
OROV_EOF

# Copy fstab file
cp ${ROOTFS_DIR}/boot/dietpi/conf/fstab ${ROOTFS_DIR}/etc/fstab

# Update dietpi-service
on_chroot sh - << OROV_EOF
	echo 1 > /boot/dietpi/.install_stage
	cp /boot/dietpi/conf/dietpi-service /etc/init.d/dietpi-service
	chmod +x /etc/init.d/dietpi-service
	update-rc.d dietpi-service defaults 00 80
	service dietpi-service start
OROV_EOF

# Copy cron jobs to correct directory
cp ${ROOTFS_DIR}/boot/dietpi/conf/cron.daily_dietpi ${ROOTFS_DIR}/etc/cron.daily/dietpi
chmod +x ${ROOTFS_DIR}/etc/cron.daily/dietpi
cp ${ROOTFS_DIR}/boot/dietpi/conf/cron.hourly_dietpi ${ROOTFS_DIR}/etc/cron.hourly/dietpi
chmod +x ${ROOTFS_DIR}/etc/cron.hourly/dietpi

#Crontab
cat << _EOF_ > ${ROOTFS_DIR}/etc/crontab
#Please use dietpi-cron to change cron start times
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user  command
17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 1    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 1    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 1    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
_EOF_

# Remove ntp files
rm ${ROOTFS_DIR}/etc/cron.daily/ntp &> /dev/null
rm ${ROOTFS_DIR}/etc/init.d/ntp &> /dev/null

# Update swappiness
echo -e "vm.swappiness=1" >> ${ROOTFS_DIR}/etc/sysctl.conf

# Create rc.local
cat << _EOF_ > ${ROOTFS_DIR}/etc/rc.local
#!/bin/sh -e
/DietPi/dietpi/dietpi-services start
/DietPi/dietpi/dietpi-banner 0
echo " Default Login:\n Username = root\n Password = dietpi\n"
exit 0
_EOF_

# Append login script to root's bashrc
echo -e "\n/DietPi/dietpi/login" >> ${ROOTFS_DIR}/root/.bashrc

# Copy network configuration
cp ${ROOTFS_DIR}/boot/dietpi/conf/network_interfaces ${ROOTFS_DIR}/etc/network/interfaces

# Copy htop config
mkdir -p ${ROOTFS_DIR}/root/.config/htop/
cp ${ROOTFS_DIR}/boot/dietpi/conf/htoprc ${ROOTFS_DIR}/root/.config/htop/htoprc

# Set host and hostname info
cat << _EOF_ > ${ROOTFS_DIR}/etc/hosts
127.0.0.1 localhost
127.0.1.1 DietPi
_EOF_

cat << _EOF_ > ${ROOTFS_DIR}/etc/hostname
DietPi
_EOF_

#hdparm
cat << _EOF_ >> ${ROOTFS_DIR}/etc/hdparm.conf

#DietPi external USB drive. Power management settings.
/dev/sda {
        #10 mins
        spindown_time = 120

        #
        apm = 254
}
_EOF_

# Set bashrc settings
cat << _EOF_ > ${ROOTFS_DIR}/etc/bash.bashrc

        #MANUALLY ADD /etc/bash.bashrc -----------------------------------------
        export $(cat /etc/default/locale | grep LANG=)
        #DietPi Additions
        alias dietpi-process_tool='/DietPi/dietpi/dietpi-process_tool'
        alias dietpi-letsencrypt='/DietPi/dietpi/dietpi-letsencrypt'
        alias dietpi-autostart='/DietPi/dietpi/dietpi-autostart'
        alias dietpi-cron='/DietPi/dietpi/dietpi-cron'
        alias dietpi-launcher='/DietPi/dietpi/dietpi-launcher'
        alias dietpi-cleaner='/DietPi/dietpi/dietpi-cleaner'
        alias dietpi-morsecode='/DietPi/dietpi/dietpi-morsecode'
        alias dietpi-sync='/DietPi/dietpi/dietpi-sync'
        alias dietpi-backup='/DietPi/dietpi/dietpi-backup'
        alias dietpi-bugreport='/DietPi/dietpi/dietpi-bugreport'
        alias dietpi-uninstall='/DietPi/dietpi/dietpi-uninstall'
        alias dietpi-services='/DietPi/dietpi/dietpi-services'
        alias dietpi-config='/DietPi/dietpi/dietpi-config'
        alias dietpi-software='/DietPi/dietpi/dietpi-software'
        alias dietpi-update='/DietPi/dietpi/dietpi-update'
        alias emulationstation='/opt/retropie/supplementary/emulationstation/emulationstation'
        alias opentyrian='/usr/local/games/opentyrian/run'

        alias cpu='/DietPi/dietpi/dietpi-cpuinfo'
        alias dietpi-logclear='/DietPi/dietpi/dietpi-logclear'
        treesize()
        {
        du -k --max-depth=1 | sort -nr | awk '
        BEGIN {
                split("KB,MB,GB,TB", Units, ",");
        }
        {
                u = 1;
                while ($1 >= 1024)
                {
                $1 = $1 / 1024;
                u += 1;
                }
                $1 = sprintf("%.1f %s", $1, Units[u]);
                print $0;
        }
        '
        }
        #MANUAL ADD END---------------------------------------------------
_EOF_

# fakehwclock - allow times in the past
sed -i "/FORCE=/c\FORCE=force" ${ROOTFS_DIR}/etc/default/fake-hwclock

#wifi dongles
echo -e "options 8192cu rtw_power_mgnt=0" > ${ROOTFS_DIR}/etc/modprobe.d/8192cu.conf
echo -e "options 8188eu rtw_power_mgnt=0" > ${ROOTFS_DIR}/etc/modprobe.d/8188eu.conf

echo "Final step"

# Disable sysvinit services and enable systemd versions
on_chroot sh -x - << OROV_END

	# Disbale getty
	systemctl disable getty@tty[2-6].service

	#NTPd - remove systemd's version
	systemctl disable systemd-timesync

	#Remove rc.local from /etc/init.d
	update-rc.d -f rc.local remove
OROV_END


# Create rc-local service
cat << _EOF_ > ${ROOTFS_DIR}/etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local Compatibility
After=dietpi-service.service

[Service]
Type=idle
ExecStart=/etc/rc.local
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
_EOF_
	
# Disable sysvinit services and enable systemd versions
on_chroot sh -x - << OROV_END

	# Enable service
	systemctl enable rc-local.service
	systemctl daemon-reload
OROV_END

#Create service to shutdown SSH/Dropbear before reboot
cat << _EOF_ > /etc/systemd/system/kill-ssh-user-sessions-before-network.service
[Unit]
Description=Shutdown all ssh sessions before network
DefaultDependencies=no
Before=network.target shutdown.target

[Service]
Type=oneshot
ExecStart=/usr/bin/killall sshd && /usr/bin/killall dropbear

[Install]
WantedBy=poweroff.target halt.target reboot.target
_EOF_

on_chroot sh -x - << OROV_END	
	# Enable service
	systemctl enable kill-ssh-user-sessions-before-network
	systemctl daemon-reload

	#echo "dpkg reconfig" 
	#dpkg-reconfigure tzdata
	#dpkg-reconfigure locales
OROV_END	


echo Finished!