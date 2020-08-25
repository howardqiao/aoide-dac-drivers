#!/bin/bash

# AOIDE DAC Drivers Installer

# Newest driver version and firmware git hash
TITLE="AOIDE DAC Drivers Installer"
BACKTITLE="UGEEK WORKSHOP [ ugeek.aliexpress.com | ukonline2000.taobao.com ]"
driver_version="5.4.51"
firmware_hash="390477bf6dc80dddfafcd3682b4e026e96cfc4d7"

driver_path="/lib/modules/"$driver_version+"/kernel/sound/soc/bcm/aoide-dacii.ko"
driver_url="https://github.com/howardqiao/aoide-dac-drivers/raw/master/drivers/aoide_dac_"$driver_version".tar.gz"
driver_filename="aoide_dac_"$driver_version".tar.gz"
dtoverlay=""
file_config="/boot/config.txt"
file_config_dietpi="/DietPi/config.txt"

# Get kernel version
function get_kernel_version(){
	kernel_version=$(uname -r)
	IFS='-' read -ra kernel_version <<< "$kernel_version"
}

# Install newest kernel
function kernel_install(){
	echo "Install Raspberry PI Kernel "$driver_version
	if [ ! -f /usr/bin/rpi-update ]; then
		apt update
		apt install binutils curl
		curl -L --output /usr/bin/rpi-update https://raw.githubusercontent.com/Hexxeh/rpi-update/master/rpi-update && sudo chmod +x /usr/bin/rpi-update
	fi
	UPDATE_SELF=0 SKIP_BACKUP=1 rpi-update $firmware_hash
}

# Test function
# function driver_install(){
	# echo "Install Aoide DACs driver V"$driver_version
	# cd /
	# if [ -f "$driver_filename" ]; then
		# rm $driver_filename
	# fi
	# #wget https://github.com/howardqiao/aoide-dac-drivers/raw/master/drivers/aoide_dac_$driver_version.tar.gz
	# echo "Download driver($driver_version) now..."
	# echo "URL:"$driver_url
	# echo "FILENAME:"$driver_filename
	# curl -L $driver_url -o $driver_filename --progress --retry 10 --retry-delay 10  --retry-max-time 100
	# #wget $driver_url 
	# if [ -f "$driver_filename" ]; then
		# tar zxvf $driver_filename
		# rm $driver_filename
		# depmod -b / -a $driver_version+
		# depmod -b / -a $driver_version-v7+
		# depmod -b / -a $driver_version-v7l+
		# depmod -b / -a $driver_version-v8+
		# sync
	# else
		# echo "Download driver failed"
	# fi
# }

# Disable DAC in config.txt
function disable_dac(){
	sed -i "s/audio=on/audio=off/" $file_config
	sed -i '/dtoverlay=aoide-dacii/d' $file_config
	sed -i '/dtoverlay=aoide-dacpro/d' $file_config
	sed -i '/dtoverlay=aoide-digipro/d' $file_config
	sed -i '/dtoverlay=aoide-zero-dacplus/d' $file_config
	sed -i '/dtoverlay=aoide-zero-digiplus/d' $file_config
	sed -i '/dtoverlay=aoide-zpod-dac/d' $file_config
	sed -i '/dtoverlay=raspivoicehat/d' $file_config
	
	if [ -f "$file_config_dietpi" ]; then
		sed -i "s/audio=on/audio=off/" $file_config_dietpi
		sed -i '/dtoverlay=aoide-dacii/d' $file_config_dietpi
		sed -i '/dtoverlay=aoide-dacpro/d' $file_config_dietpi
		sed -i '/dtoverlay=aoide-digipro/d' $file_config_dietpi
		sed -i '/dtoverlay=aoide-zero-dacplus/d' $file_config_dietpi
		sed -i '/dtoverlay=aoide-zero-digiplus/d' $file_config_dietpi
		sed -i '/dtoverlay=aoide-zpod-dac/d' $file_config_dietpi
		sed -i '/dtoverlay=raspivoicehat/d' $file_config_dietpi
	fi
}

# Install newest kernel and driver
function install_newest_kernel_driver(){
	kernel_install
	if [ -f "drivers/aoide_volumio_$driver_version.tar.gz" ]; then
		cp drivers/aoide_volumio_$driver_version.tar.gz /
		cd /
		tar zxvf drivers/aoide_volumio_$driver_version.tar.gz
		rm drivers/aoide_volumio_$driver_version.tar.gz
	fi
	if [ -f "drivers/aoide_dac_$driver_version.tar.gz" ]; then
		cp drivers/aoide_dac_$driver_version.tar.gz /
		cd /
		tar zxvf drivers/aoide_dac_$driver_version.tar.gz
		rm drivers/aoide_dac_$driver_version.tar.gz
	fi
	cd ~
}

# Deploy driver
function deploy_driver(){
	depmod -b / -a $driver_version+
	depmod -b / -a $driver_version-v7+
	depmod -b / -a $driver_version-v7l+
	depmod -b / -a $driver_version-v8+
}

# Enable dac in config.txt
function enable_dac_in_config(){
	# Disable all DAC first
	disable_dac
	
	# Enable dac in config.txt
	echo "dtoverlay="$dtoverlay >> /boot/config.txt
	if [ -f "$file_config_dietpi" ]; then
		echo "dtoverlay="$dtoverlay >> $file_config_dietpi
	fi
}

# Reboot prompt
function reboot_prompt(){
	if [ -z "$1" ]; then
		return
	fi
	if (whiptail --title "$TITLE" \
	--backtitle "$BACKTITLE" \
	--yes-button "Reboot" --no-button "NO" \
	--yesno "Reboot system to enable driver" 10 60) then
		sync
		reboot
	else
		return
	fi
}

# Enable DAC
function enable_dac(){
	# If there's driver pair current version of kernel
	if [ -f "/boot/overlays/$dtoverlay.dtbo" ]; then
		enable_dac_in_config
		reboot_prompt
		return
	fi
	if [ -f "drivers/aoide_dac_$kernel_version.tar.gz" ]; then
		cp drivers/aoide_dac_$kernel_version.tar.gz /
		cd /
		tar zxvf aoide_dac_$kernel_version.tar.gz
		rm aoide_dac_$kernel_version.tar.gz
	fi
	if [ -f "drivers/aoide_volumio_$kernel_version.tar.gz" ]; then
		cp drivers/aoide_volumio_$kernel_version.tar.gz /
		cd /
		tar zxvf aoide_volumio_$kernel_version.tar.gz
		rm aoide_volumio_$kernel_version.tar.gz
	fi
	
	# If there's no specfied dtbo file , Install newest kernel and driver
	if [ ! -f "/boot/overlays/$dtoverlay.dtbo" ]; then
		install_newest_kernel_driver
	fi
	
	# Deploy driver
	deploy_driver
	
	# Enable dac in config.txt
	enable_dac_in_config
	
	# reboot_prompt
	if [ -z "$1" ]; then
		reboot_prompt
	fi
}

# Check privileges
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

# Get kernel version
get_kernel_version

# Check para
if [ ! -z "$1" ]; then
	echo "Install driver of $1"
	dtoverlay=$1
	enable_dac
	exit 1
fi

# Main loop
while true
do
	OPTION=$(whiptail --title "$TITLE(V$driver_version)" \
	--menu "Select your DAC(Sound Card)." \
	--backtitle "$BACKTITLE" \
	--cancel-button "Exit" 18 60 10 \
	"1" "AOIDE DAC Pro" \
	"2" "AOIDE DAC II" \
	"3" "AOIDE Digi Pro" \
	"4" "AOIDE Zero DAC+" \
	"5" "AOIDE Zero Digi+" \
	"6" "AOIDE ZPOD DAC" \
	"7" "Raspi Voice HAT" \
	"8" "Install RPi Kernel V$driver_version" \
	"D" "Disable DAC" \
	"E" "Exit" \
	3>&1 1>&2 2>&3)
	case $OPTION in
		1)
		dtoverlay="aoide-dacpro"
		enable_dac
		;;
		2)
		dtoverlay="aoide-dacii"
		enable_dac
		;;
		3)
		dtoverlay="aoide-digipro"
		enable_dac
		;;
		4)
		dtoverlay="aoide-zero-dacplus"
		enable_dac
		;;
		5)
		dtoverlay="aoide-zero-digiplus"
		enable_dac
		;;
		6)
		dtoverlay="aoide-zpod-dac"
		enable_dac
		;;
		7)
		dtoverlay="raspivoicehat"
		enable_dac
		;;
		8)
		kernel_install
		;;
		"D")
		disable_dac
		;;
		"E")
		exit 1
		;;
	esac
done

