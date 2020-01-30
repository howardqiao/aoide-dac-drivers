#!/bin/bash
VERSION="2.699"
KERNEL_VERSION="4.19.86"
DEFAULT_SS="archive.volumio.org/raspbian"
SS="archive.volumio.org\/raspbian"
REPONAME=""
IR_Support=true
PROXY=""
PROXY_Support=true

function download(){
	git clone https://github.com/volumio/build.git --depth 1
}
function clear_reset(){
	cd build
	git reset --hard
	rm *.img
	rm *.gz
	rm -rf ./build
	cd ..
}
function clear_all(){
	rm -rf ./build
}
function set_proxy(){
	sed -i -e "s/^proxy=\".*\"/proxy=\"$PROXY\"/" patches/volumio_aoide1.txt
	sed -i -e "s/^proxy=\".*\"/proxy=\"$PROXY\"/" patches/volumio_aoide_pitft1.txt
}
function set_kernel_version(){
	sed -i -e "s/^driver_version=\".*\"/driver_version=\"$KERNEL_VERSION\"/" patches/volumio_aoide1.txt
	sed -i -e "s/^driver_version=\".*\"/driver_version=\"$KERNEL_VERSION\"/" patches/volumio_aoide_pitft1.txt
}
function aoide_patch(){
	if [ "$PROXY_Support" = true ]; then
		set_proxy
	fi
	sed -i -e '/BUILD="arm"/r patches/volumio_aoide1.txt' build/build.sh
	sed -i -e '/Cloning Volumio UI/r patches/volumio_aoide2.txt' build/build.sh
	sed -i -e '/Writing cmdline.txt file/r patches/common.txt' build/scripts/raspberryconfig.sh
	
	cp build/scripts/initramfs/mkinitramfs-custom.sh build/scripts/initramfs/temp.sh
	linenum=$(grep -n 'DESTDIR=${DESTDIR_REAL}' build/scripts/initramfs/mkinitramfs-custom.sh | awk -F ":" '{print $1}' | tail -n1)
	{ head -n $(($linenum-1)) build/scripts/initramfs/mkinitramfs-custom.sh; cat patches/patch_mkinitramfs.txt; tail -n +$linenum build/scripts/initramfs/mkinitramfs-custom.sh; } > build/scripts/initramfs/temp.sh
	cp build/scripts/initramfs/temp.sh build/scripts/initramfs/mkinitramfs-custom.sh
	#rm cp build/scripts/initramfs/temp.sh
	
	if [ "$IR_Support" = true ]; then
		sed -i -e '/Writing cmdline.txt file/r patches/volumio_aoide_lirc_support.txt' build/scripts/raspberryconfig.sh
	fi
	
}
function aoide_pitft_patch(){
	if [ "$PROXY_Support" = true ]; then
		set_proxy
	fi
	sed -i -e '/BUILD="arm"/r patches/volumio_aoide_pitft1.txt' build/build.sh
	sed -i -e '/Cloning Volumio UI/r patches/volumio_aoide_pitft2.txt' build/build.sh
	sed -i -e '/Writing cmdline.txt file/r patches/common.txt' build/scripts/raspberryconfig.sh
	cp build/scripts/initramfs/mkinitramfs-custom.sh build/scripts/initramfs/temp.sh
	linenum=$(grep -n 'DESTDIR=${DESTDIR_REAL}' build/scripts/initramfs/mkinitramfs-custom.sh | awk -F ":" '{print $1}' | tail -n1)
	{ head -n $(($linenum-1)) build/scripts/initramfs/mkinitramfs-custom.sh; cat patches/patch_mkinitramfs.txt; tail -n +$linenum build/scripts/initramfs/mkinitramfs-custom.sh; } > build/scripts/initramfs/temp.sh
	cp build/scripts/initramfs/temp.sh build/scripts/initramfs/mkinitramfs-custom.sh
	#rm cp build/scripts/initramfs/temp.sh
	if [ "$IR_Support" = true ]; then
		sed -i -e '/Writing cmdline.txt file/r patches/volumio_aoide_lirc_support.txt' build/scripts/raspberryconfig.sh
	fi
}
function setsource(){
	sed -i 's/^source.*$/source=http:\/\/'"$SS"'/g' build/recipes/arm.conf
}
function build(){
	cd build
	sudo ./build.sh -b arm -d pi -v $VERSION -l $REPONAME
	echo "Build Complete!"
	cd ..
}
function gz(){
	gzip build/*.img
	sleep 3
	if [ ! -d "output" ]; then
	mkdir output
	fi
	mv build/*.img.gz output/
}
for (( ; ; ))
do
OPTION=$(whiptail --title "Volumio Image Build Tools(V$VERSION,$KERNEL_VERSION)" --menu "Choose an option($SS)." \
--cancel-button "Exit" 20 66 11 \
"Tools" "Install tools needed by build script." \
"Download" "Download latest build script." \
"Original" "Build original image." \
"AOIDE" "Build with AOIDE DACs Drivers." \
"AOIDE_PATCH" "Patch with AOIDE DACs Drivers." \
"AOIDE_BUILD" "build only" \
"PITFT" "Build with AOIDE DACs Drivers and Screen." \
"IRSupport" "Build with IR Support." \
"Version" "Set image version." \
"Kernel" "Set kernel version." \
"Source" "Set apt source of volumio." \
"Clear" "Clear build folder." \
"Exit" "Exit" \
3>&1 1>&2 2>&3)
case $OPTION in
	"Tools")
	apt update
	apt install git squashfs-tools kpartx multistrap qemu-user-static samba debootstrap parted dosfstools qemu binfmt-support qemu-utils docker.io
	;;
	"Download")
	clear_all
	git clone https://github.com/volumio/build.git --depth 1
	;;
	"Original")
	clear_reset
	setsource
	build
	gz
	;;
	"AOIDE")
	clear_reset
	setsource
	set_kernel_version
	aoide_patch
	REPONAME="aoide"
	build
	gz
	;;
	"AOIDE_PATCH")
	rm -rf build
	echo "Copy new build folder"
	cp -a build_new build
	echo "Set source"
	setsource
	echo "Set kernel version"
	set_kernel_version
	echo "Patch"
	#aoide_patch
	;;
	"AOIDE_BUILD")
	echo "Build aoide image"
	echo "Set repo name"
	REPONAME="aoide"
	echo "Build"
	build
	;;
	"PITFT")
	clear_reset
	setsource
	set_kernel_version
	aoide_pitft_patch
	REPONAME="aoide_pitft"
	build
	gz
	;;
	"IRSupport")
	OPTION_IR=$(whiptail --title "Build with IR Support?" --menu "Choose an option." \
		--cancel-button "exit" 20 66 11 \
		"EnableIR" "Enable IR Support" \
		"DisableIR" "Disable IR Support" \
		"Exit" "Exit" \
		3>&1 1>&2 2>&3)
	case $OPTION_IR in
		"EnableIR")
		IR_Support=true
		;;
		"DisableIR")
		IR_Support=false
		;;
		"Exit")
		;;
	esac
	;;
	"Version")
	VERSION_CUSTOM=$(whiptail --inputbox "What is your image version?" 6 60 $VERSION --title "Volumio image version" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		VERSION=$VERSION_CUSTOM
	fi
	;;
	"Kernel")
	KERNEL_VERSION_CUSTOM=$(whiptail --inputbox "What is your imkernelage version?" 6 60 $KERNEL_VERSION --title "Linux kernel version" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		KERNEL_VERSION=$KERNEL_VERSION_CUSTOM
	fi
	set_kernel_version
	;;
	"Source")
	OPTION_SOURCE=$(whiptail --title "Volumio Image Build Tools(V$VERSION)" --menu "Choose an option($SS)." \
		--cancel-button "Exit" 20 66 11 \
		"Official" "mirrordirector.raspbian.org/raspbian" \
		"Aliyun" "mirrors.aliyun.com/raspbian/raspbian" \
		"Sohu" "mirrors.sohu.com/raspbian/raspbian" \
		"Custom" "Custom settings." \
		"Exit" "Exit" \
		3>&1 1>&2 2>&3)
	case $OPTION_SOURCE in
		"Official")
		SS="mirrordirector.raspbian.org\/raspbian"
		;;
		"Aliyun")
		SS="mirrors.aliyun.com\/raspbian\/raspbian"
		;;
		"Sohu")
		SS="mirrors.sohu.com\/raspbian\/raspbian"
		;;
		"Custom")
		SS_CUSTOM=$(whiptail --inputbox "What is your apt source?" 6 60 $SS --title "Set apt source(Insert '\' before '/'" 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			SS=$SS_CUSTOM
		fi

		;;
		"Exit")
		;;
	esac
	setsource
	;;
	"Clear")
	clear_reset
	;;
	"Exit")
	exit
	;;
	"")
	exit
	;;
esac
done
