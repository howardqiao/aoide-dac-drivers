#!/bin/bash
VERSION="2.361"
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
function aoide_patch(){
sed -i -e '/BUILD="arm"/r volumio_aoide1.txt' build/build.sh
sed -i -e '/Cloning Volumio UI/r volumio_aoide2.txt' build/build.sh
}
function aoide_pitft_patch(){
sed -i -e '/BUILD="arm"/r volumio_aoide_pitft1.txt' build/build.sh
sed -i -e '/Cloning Volumio UI/r volumio_aoide_pitft2.txt' build/build.sh
}
function build(){
cd build
./build.sh -b arm -d pi -v $VERSION
echo "Build Complete!"
cd ..
}
for (( ; ; ))
do
OPTION=$(whiptail --title "Volumio Image Build Tools" --menu "Choose an option(Build Version:$VERSION)." \
--cancel-button "Exit" 16 60 8 \
"Tools" "Install tools needed by build script." \
"Download" "Download latest build script." \
"Original" "Build original image." \
"AOIDE" "Build with AOIDE DACs Drivers." \
"PITFT" "Build with AOIDE DACs Drivers and Screen." \
"Version" "Set image version." \
"Exit" "Exit" \
3>&1 1>&2 2>&3)
case $OPTION in
	"Tools")
	apt update
	apt install git squashfs-tools kpartx multistrap qemu-user-static samba debootstrap parted dosfstools qemu binfmt-support qemu-utils
	;;
	"Download")
	clear_all
	git clone https://github.com/volumio/build.git --depth 1
	;;
	"Original")
	clear_reset
	build
	;;
	"AOIDE")
	clear_reset
	aoide_patch
	build
	;;
	"PITFT")
	clear_reset
	aoide_pitft_patch
	build
	;;
	"Version")
	VERSION_CUSTOM=$(whiptail --inputbox "What is your image version?" 6 60 $VERSION --title "Volumio image version" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		VERSION=$VERSION_CUSTOM
	fi
	;;
	"Exit")
	exit
	;;
	"")
	exit
	;;
esac
done
