#!/bin/bash

echo "Aoide PITFT Player setup."
echo "----------------------------------------"
echo "STEP 1:System & software update."

if [ -f "/var/cache/apt/archives/lock" ]; then
  rm -rf /var/cache/apt/archives/lock
fi
apt update
if [ -f "/var/lib/dpkg/lock" ]; then
  rm /var/lib/dpkg/lock
fi
dpkg --configure -a

apt -y install git devscripts debhelper dh-autoreconf libasound2-dev libudev-dev libibus-1.0-dev libdbus-1-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev libxt-dev libxxf86vm-dev libgl1-mesa-dev fcitx-libs-dev mpd mpc alsa-tools samba samba-common-bin i2c-tools wiringpi usbmount libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libsdl2-gfx-1.0-0 dnsmasq hostapd bridge-utils evtest
echo "----------------------------------------"
echo "STEP 2:Download drivers & player."
cd /home/pi
git clone https://github.com/adafruit/adafruit-retrogame.git --depth 1
git clone https://github.com/howardqiao/aoide-dac-drivers.git --depth 1
git clone https://github.com/howardqiao/zpod.git --depth 1
echo "----------------------------------------"
echo "STEP 3:Install drivers and player."
echo "A:Install SDL2."
dpkg -i /home/pi/zpod/zpod_res/*.deb
chmod +x /home/pi/zpod/play_pitft
cp /home/pi/adafruit-retrogame/retrogame /usr/bin/retrogame
rm /boot/retrogame.cfg
touch /boot/retrogame.cfg
echo "RIGHTSHIFT 5 #23
LEFT 24 #22
RIGHT 22 #4
K 23 #5
" >> /boot/retrogame.cfg
cp /home/pi/zpod/zpod_res/fbcp /usr/bin/fbcp
echo ""
echo "B:Update configs."
echo "1.config.txt"
echo "1.1.Enable I2C"
sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/dtparam=i2c_arm=off/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/#dtparam=i2c_arm=off/dtparam=i2c_arm=on/g' /boot/config.txt
sed -i 's/i2c-dev//g' /etc/modules
echo "i2c-dev" >> /etc/modules
echo "1.2.Enable screen"
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
dtoverlay=pitft22,speed=64000000,fps=60,rotate=90
" >> /boot/config.txt
echo ""
echo "2.rc.local"
sed -i '/iptables-restore/'d /etc/rc.local
sed -i '/fbcp/'d /etc/rc.local
sed -i '/retrogame/'d /etc/rc.local
sed -i '/zpod/'d /etc/rc.local
sed -i '/play_pitft/'d /etc/rc.local
sed -i '/^exit 0/i\iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local
sed -i '/^exit 0/i\/usr/bin/fbcp &' /etc/rc.local
sed -i '/^exit 0/i\/usr/bin/retrogame &' /etc/rc.local
sed -i '/^exit 0/i\cd /home/pi/zpod' /etc/rc.local
sed -i '/^exit 0/i\sudo ./play_pitft' /etc/rc.local
echo ""
echo "3.mpd.conf"
sed -i 's/\/var\/lib\/mpd\/music/\/home\/pi\/music/' /etc/mpd.conf

echo "STEP 4:Config samba"
systemctl stop smbd
pass=raspberry
user=pi
smbpasswd -x pi
(echo $pass; echo $pass) | smbpasswd -s -a $user
if [ ! -d "/home/pi/music" ]; then
  mkdir /home/pi/music
fi
chown pi:pi /home/pi/music
cp /home/pi/zpod/zpod_res/smb.conf /etc/samba/smb.conf
systemctl start smbd

echo "STEP 5:Config AP mode"
systemctl stop dnsmasq
systemctl stop hostapd
echo "1.Config DHCPD."
sed -i 's/denyinterfaces wlan0//g' /etc/dhcpcd.conf
echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

echo "2.Config /etc/network/interfaces."
sed -i 's/allow-hotplug wlan0//g' /etc/network/interfaces
sed -i 's/iface wlan0 inet static//g' /etc/network/interfaces
sed -i 's/address 192.168.20.1//g' /etc/network/interfaces
sed -i 's/netmask 255.255.255.0//g' /etc/network/interfaces
sed -i 's/network 192.168.20.0//g' /etc/network/interfaces
sed -i 's/auto eth0//g' /etc/network/interfaces
sed -i 's/iface eth0 inet dhcp//g' /etc/network/interfaces

echo "allow-hotplug wlan0
iface wlan0 inet static
    address 192.168.20.1
    netmask 255.255.255.0
    network 192.168.20.0
auto eth0
iface eth0 inet dhcp" >> /etc/network/interfaces

echo "3.Config dnsmasq"
if [ -f "/etc/dnsmasq.conf" ]; then
  rm /etc/dnsmasq.conf
fi
touch /etc/dnsmasq.conf
echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "  dhcp-range=192.168.20.2,192.168.20.20,255.255.255.0,24h" >> /etc/dnsmasq.conf

echo "4.Config hostapd"
if [ -f "/etc/hostapd/hostapd.conf" ]; then
  rm /etc/hostapd/hostapd.conf
fi
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
echo "STEP 6:Install Complete!Please reboot!"
#reboot
