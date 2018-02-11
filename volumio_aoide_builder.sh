#!/bin/bash
VERSION="2.361"
DEFAULT_SS="mirrordirector.raspbian.org/raspbian"
SS="mirrordirector.raspbian.org/raspbian"
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
function setsource(){
sed -i 's/^source.*$/source=http:\/\/'"$SS"'/g' build/recipes/arm.conf
}
function build(){
cd build
./build.sh -b arm -d pi -v $VERSION
echo "Build Complete!"
cd ..
}
for (( ; ; ))
do
OPTION=$(whiptail --title "Volumio Image Build Tools(V$VERSION)" --menu "Choose an option($SS)." \
--cancel-button "Exit" 20 66 11 \
"Tools" "Install tools needed by build script." \
"Download" "Download latest build script." \
"Original" "Build original image." \
"AOIDE" "Build with AOIDE DACs Drivers." \
"PITFT" "Build with AOIDE DACs Drivers and Screen." \
"Version" "Set image version." \
"Source" "Set apt source of volumio." \
"Clear" "Clear build folder." \
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
	setsource
	build
	;;
	"AOIDE")
	clear_reset
	setsource
	aoide_patch
	build
	;;
	"PITFT")
	clear_reset
	setsource
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
	"Source")
	SS_CUSTOM=$(whiptail --inputbox "What is your apt source?" 6 60 $SS --title "Set apt source(Insert '\' before '/'" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		SS=$SS_CUSTOM
	fi
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
