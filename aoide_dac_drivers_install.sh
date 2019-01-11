#!/bin/bash
newest_driver_version="4.14.92"
newest_firmware_hash="6aec73ed5547e09bea3e20aa2803343872c254b6"
current_kernel_version=$(uname -r)
proper_driver_version=${current_kernel_version:0:(${#current_kernel_version}-1)}
driver_test_path="/lib/modules/"$proper_driver_version+"/kernel/sound/soc/codecs/sabre9018k2m.ko"

function welcome(){
	echo ">AOIDE DAC Drivers Installer.<"
}

function check_current_kernel_driver(){
	echo ">Check the driver of current kernel."
	if [ -e "drivers/aoide_dac_$proper_driver_version.tar.gz" ]; then
		return 1
	else
		return 0
	fi
}

function kernel_install(){
	echo ">Install Raspberry PI Kernel "$newest_driver_version
	SOFT=$(dpkg -l $SOFTWARE_LIST | grep "<none>")
	if [ -n "$SOFT" ]; then
		apt update
		apt -y install $SOFTWARE_LIST
	fi
	if [ ! -f "/usr/bin/rpi-update" ]; then
		curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
	fi
	UPDATE_SELF=0 SKIP_BACKUP=1 rpi-update $newest_firmware_hash
	echo " Kernel install complete!"
}

function driver_install(){
	if [ -f "$driver_test_path" ]; then
		echo ">Drivers has been installed,exit."
		exit
	fi
	check_current_kernel_driver
	if [ $? -eq 1 ]; then
		echo " Driver exists,begin to install..."
		tar zxvf drivers/aoide_dac_$proper_driver_version.tar.gz -C /
		depmod -b / -a $proper_driver_version+
		depmod -b / -a $proper_driver_version-v7+
	else
		kernel_install
		tar zxvf drivers/aoide_dac_$newest_driver_version.tar.gz -C /
		depmod -b / -a $newest_driver_version+
		depmod -b / -a $newest_driver_version-v7+
	fi
	echo ">Drivers install complete!"
}

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi
welcome
driver_install
