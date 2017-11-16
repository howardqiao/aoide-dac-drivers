#---Aoide Patch---#
echo "Patch arm.conf"
cp recipes/arm.conf.bak recipes/arm.conf
cp scripts/raspberryconfig.sh.bak scripts/raspberryconfig.sh
sed -i '/busybox/ s/$/ binutils lirc/' recipes/arm.conf
linenum=$(grep -n 'On The Fly Patch' scripts/raspberryconfig.sh | awk -F ":" '{print $1}')
linenumfinal=$[$linenum+1]
linenumfinala=$linenumfinal"a"
sed -i "$linenumfinala rm aoide_dac_4.9.51.tar.gz" scripts/raspberryconfig.sh
sed -i "$linenumfinala tar xf aoide_dac_4.9.51.tar.gz" scripts/raspberryconfig.sh
sed -i "$linenumfinala echo 'Extracting Aoide-DACs Modules'" scripts/raspberryconfig.sh
sed -i "$linenumfinala wget https://github.com/howardqiao/volumio2-aoide-drivers/raw/master/aoide_dac_4.9.51.tar.gz" scripts/raspberryconfig.sh
sed -i "$linenumfinala cd /" scripts/raspberryconfig.sh
sed -i "$linenumfinala touch /boot/ssh" scripts/raspberryconfig.sh
sed -i "$linenumfinala echo 'Adding Aoide-DACs Kernel Module and dtbo'" scripts/raspberryconfig.sh
#---Aoide Patch---#
