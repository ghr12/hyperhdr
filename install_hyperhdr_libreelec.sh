#!/bin/bash

# Installing HyperHDR on LibreElec
# Example usage:
# Download and install latest HyperHDR release:		install_hyperhdr_libreelec.sh
# Download and install specific HyperHDR release:	install_hyperhdr_libreelec.sh 18.0.0.0
# Install a specific HyperHDR LOCAL tar.gz file:	install_hyperhdr_libreelec.sh HyperHDR-18.0.0.0-Linux-x86_64.tar.gz
#
# May need to pass video= option to grub as rulz ms2109 grabber sometimes is used for video, resulting on no picture or black screen
# head /sys/class/drm/*/status
# mount -o remount,rw /flash/
# vi /flash/syslinux.cfg # append video=<outputfrom  head /sys/class/drm/*/status , which is the primary display> e.g.:
# cat /proc/cmdline 
#root=/dev/ram0 rdinit=/init usbcore.autosuspend=-1 BOOT_IMAGE=/KERNEL boot=UUID=CD61-A0A7 disk=UUID=92f51f55-a797-4ae6-9041-5a022944aacd  quiet video=HDMI-A-1:d video=DP-3:1920x1080@60:D
# http://distro.ibiblio.org/fatdog/web/faqs/boot-options.html

INST_LOG=install_log-$(date +%F_%T)
OS_LIBREELEC=$( egrep -m1 -c LibreELEC /etc/issue )
CPU_RPI=$( egrep -m1 -c "BCM2708|BCM2709|BCM2710|BCM2835|BCM2836|BCM2837|BCM2711" /proc/cpuinfo )
CPU_x86_64=$( egrep -m1 -c "Intel|AMD" /proc/cpuinfo )
RPI_1_2=$( egrep -m1 -c "BCM2708|BCM2835" /proc/cpuinfo )
RPI_3_4=$( egrep -m1 -c "BCM2709|BCM2710|BCM2836|BCM2837|BCM2711" /proc/cpuinfo )
INTEL=$( egrep -m1 -c "Intel" /proc/cpuinfo )
AMD=$( egrep -m1 -c "AMD" /proc/cpuinfo )


pre_checks () {

	# Make sure script is run on LibreELEC
	if [ $OS_LIBREELEC -ne 1 ]; then
		echo "Error: We are not on LibreELEC... Exiting"
		exit 99
	fi
	
	# Make sure we are on an Raspberry Pi or x86_64
	if [ $CPU_RPI -ne 1 -a $CPU_x86_64 -ne 1 ]; then
		echo "Error: We are not on an Raspberry Pi or an x86_64 CPU... Exiting"
		echo $CPU_RPI
		echo $CPU_x86_64
		exit 99
	fi
	
	
	#Check, if dtparam=spi=on is in place (for RPi)
	if [ $CPU_RPI -eq 1 ]; then
		SPIOK=$( egrep "^dtparam=spi=on" /flash/config.txt | wc -l )
		if [ $SPIOK -ne 1 ]; then
			mount -o remount,rw /flash
			echo 'RPi with LibreELEC found, but SPI is not set, writing "dtparam=spi=on" to /flash/config.txt'
			sed -i '$a dtparam=spi=on' /flash/config.txt
			mount -o remount,ro /flash
			echo "Please reboot LibreELEC, inserted dtparam=spi=on to /flash/config.txt"
			exit 99
		fi
	fi

}

main () {

	# Check if the argument is not a local file
	if [ ! -f "$1" ]; then
		HYPERHDR_DOWNLOAD_URL="https://github.com/awawa-dev/HyperHDR/releases/download/"
		# Get the latest version or use the specified version
		if [ -z "$1" ]; then
			HYPERHDR_LATEST_VERSION=$( curl -sL https://github.com/awawa-dev/HyperHDR/releases/latest | egrep 'tag/v' -m1 | sed -e 's#.*tag/v##;s/".*//' )
		else
			HYPERHDR_LATEST_VERSION="$1"
		fi
	
		if [ $RPI_1_2 -eq 1 ]; then
			HYPERHDR_SUFFIX="armv6l"
		elif [ $RPI_3_4 -eq 1 ]; then
			HYPERHDR_SUFFIX="aarch64"
		elif [ $CPU_x86_64 -eq 1 ]; then
			HYPERHDR_SUFFIX="x86_64"
		else
			exit 99
		fi

		# Select the appropriate release
		if [ $RPI_1_2 -eq 1 ]; then
			HYPERHDR_RELEASE=$HYPERHDR_DOWNLOAD_URL/v$HYPERHDR_LATEST_VERSION/HyperHDR-$HYPERHDR_LATEST_VERSION-Linux-$HYPERHDR_SUFFIX.tar.gz
		elif [ $RPI_3_4 -eq 1 ]; then
			HYPERHDR_RELEASE=$HYPERHDR_DOWNLOAD_URL/v$HYPERHDR_LATEST_VERSION/HyperHDR-$HYPERHDR_LATEST_VERSION-Linux-$HYPERHDR_SUFFIX.tar.gz
		elif [ $INTEL -eq 1 ] || [ $AMD -eq 1 ]; then
			HYPERHDR_RELEASE=$HYPERHDR_DOWNLOAD_URL/v$HYPERHDR_LATEST_VERSION/HyperHDR-$HYPERHDR_LATEST_VERSION-Linux-$HYPERHDR_SUFFIX.tar.gz
		else
			exit 99
		fi
	
		# Get and extract HyperHDR
		echo "Downloading release: $HYPERHDR_RELEASE"
		curl -# -L --get $HYPERHDR_RELEASE | tar xz --strip-components=1 -C ~user/storage share/hyperhdr
	
	else
		echo "Extract local file: $1"
		tar -xzf "$1" --strip-components=1 -C /storage share/hyperhdr/
	fi
	
}

enable_systemd_service () {

	# Create the service control configuration
	echo "Installing systemd script"
	SERVICE_CONTENT="[Unit]
Description=HyperHDR ambient light systemd service
After=network.target

[Service]
Environment=DISPLAY=:0.0
ExecStart=/storage/hyperhdr/bin/hyperhdr --userdata /storage/hyperhdr/.hyperhdr
TimeoutStopSec=2
Restart=always
RestartSec=10

[Install]
WantedBy=default.target"
	
	# Enable systemd service and start
	echo "$SERVICE_CONTENT" > /storage/.config/system.d/hyperhdr.service
	systemctl -q enable --now hyperhdr.service

}

#Begin
echo "*******************************************************************************"
echo "This script will install HyperHDR on LibreELEC"
echo -e "Created by ghr12 2023-01-14\n"
echo "HyperHDR: https://github.com/awawa-dev/HyperHDR/"
echo "*******************************************************************************"
echo -e "$(date)\n" > $INST_LOG

pre_checks &>> $INST_LOG && main &>> $INST_LOG && enable_systemd_service &>> $INST_LOG && systemctl status hyperhdr

echo "*******************************************************************************"
echo -e "HyperHDR installation finished!\n\n"
echo "HyperHDR should be running. Check for errors and Reboot LibreELEC. Install logs available in $INST_LOG"
echo "*******************************************************************************"

#exit
