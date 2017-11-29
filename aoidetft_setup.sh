#!/bin/bash

echo "Aoide PITFT Player setup."

echo "System & software update."
sudo apt update
sudo apt -y install git devscripts debhelper dh-autoreconf libasound2-dev libudev-dev libibus-1.0-dev libdbus-1-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev libxt-dev libxxf86vm-dev libgl1-mesa-dev fcitx-libs-dev mpd mpc alsa-tools samba samba-common-bin i2c-tools wiringpi usbmount libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libsdl2-gfx-1.0-0 dnsmasq hostapd bridge-utils

echo "Download drivers & player."
cd /home/pi
git clone https://github.com/adafruit/adafruit-retrogame.git --depth 1
git clone https://github.com/howardqiao/aoide-dac-drivers.git --depth 1
git clone https://github.com/howardqiao/zpod.git --depth 1

echo "Install drivers and player."
echo "Install SDL2."
cd /home/pi/zpod/zpod_res
sudo dpkg -i *.deb
cd /home/pi/zpod/
chmod +x ./play_pitft
sudo cp ~/adafruit-retrogame/retrogame /usr/bin/retrogame
sudo cp zpod_res/fbcp /usr/bin/fbcp
cd /home/pi/

echo "Update configs."
echo "1,config.txt"
echo "Enable I2C"
sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/dtparam=i2c_arm=off/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/#dtparam=i2c_arm=off/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/i2c-dev//g' /etc/modules
echo "i2c-dev" >> /etc/modules

echo "Enable screen"
sed -i '/^hdmi_force_hotplug/'d /boot/config.txt
sed -i '/^hdmi_group/'d /boot/config.txt
sed -i '/^hdmi_mode/'d /boot/config.txt
sed -i '/^hdmi_cvt/'d /boot/config.txt
sed -i '/^framebuffer_width/'d /boot/config.txt
sed -i '/^framebuffer_height/'d /boot/config.txt
sed -i '/^dtoverlay=pitft22/'d /boot/config.txt
echo "hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0
framebuffer_width=320
framebuffer_height=240
dtoverlay=pitft22,speed=64000000,fps=60,rotate=270
" >> /boot/config.txt

echo "2,rc.local"
sed -i '/iptables-restore/'d /etc/rc.local 
sed -i '/fbcp/'d /etc/rc.local
sed -i '/retrogame/'d /etc/rc.local
sed -i '/zpod/'d /etc/rc.local
sed -i '/play_pitft/'d /etc/rc.local
sed -i '/^exit 0/i\iptables-restore < /etc/iptables.ipv4.nat ' /etc/rc.local
sed -i '/^exit 0/i\/usr/bin/fbcp &' /etc/rc.local
sed -i '/^exit 0/i\/usr/bin/retrogame &' /etc/rc.local
sed -i '/^exit 0/i\cd /home/pi/zpod' /etc/rc.local
sed -i '/^exit 0/i\sudo ./play_pitft' /etc/rc.local

echo "3,config samba"
systemctl stop smbd
pass=raspberry
user=pi
smbpasswd -x pi
(echo $pass; echo $pass) | smbpasswd -s -a $user
mkdir /home/pi/music
chown pi:pi /home/pi/music
cp /home/pi/zpod/zpod_res/smb.conf /etc/samba/smb.conf
systemctl start smbd

echo "4,config AP mode"
systemctl stop dnsmasq
systemctl stop hostapd
echo "Config DHCPD."
sed -i 's/denyinterfaces wlan0//g' /etc/dhcpcd.conf
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

echo "Config /etc/network/interfaces."
sed -i 's/allow-hotplug wlan0//g' /etc/network/interfaces
sed -i 's/iface wlan0 inet static//g' /etc/network/interfaces
sed -i 's/address 192.168.0.1//g' /etc/network/interfaces
sed -i 's/netmask 255.255.255.0//g' /etc/network/interfaces
sed -i 's/network 192.168.0.0//g' /etc/network/interfaces
sed -i 's/auto eth0//g' /etc/network/interfaces
sed -i 's/iface eth0 inet dhcp//g' /etc/network/interfaces

echo "allow-hotplug wlan0" >> /etc/network/interfaces
echo "iface wlan0 inet static" >> /etc/network/interfaces
echo "    address 192.168.20.1" >> /etc/network/interfaces
echo "    netmask 255.255.255.0" >> /etc/network/interfaces
echo "    network 192.168.20.0" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet dhcp" >> /etc/network/interfaces

echo "Config DNSMASQ"
rm /etc/dnsmasq.conf
touch /etc/dnsmasq.conf
echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "  dhcp-range=192.168.20.2,192.168.20.20,255.255.255.0,24h" >> /etc/dnsmasq.conf

echo "Config hostapd"
rm /etc/hostapd/hostapd.conf
touch /etc/hostapd/hostapd.conf
echo "interface=wlan0
driver=nl80211
ssid=Aoide
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=raspberry
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf

sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd
echo "Config IP forward."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
cp /home/pi/zpod/zpod_res/iptables.ipv4.nat /etc/
echo "Install Complete,Please reboot!"
sudo reboot