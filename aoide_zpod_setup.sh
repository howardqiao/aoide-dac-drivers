#!/bin/bash
FONT_URL="https://github.com/adobe-fonts/source-han-sans/raw/release/OTC/SourceHanSans-Bold.ttc"
FONT_FILE="/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc"
FONT_SIZE="0.055"
FILE_CONFIG="/boot/config.txt"
FILE_RCLOCAL="/etc/rc.local"
FILE_MODULES="/etc/modules"
FILE_RETROARCH="/opt/retropie/configs/all/retroarch.cfg"
FILE_ESINPUT="/opt/retropie/configs/all/emulationstation/es_input.cfg"
FILE_AUTOSTART="/opt/retropie/configs/all/autostart.sh"
SOFTWARE_LIST="ffmpeg libconfig9 binutils curl dnsmasq hostapd bridge-utils hostapd python-dev python-pip python-smbus libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libsdl2-gfx-1.0-0 wiringpi mpd mpc libmpdclient2 libasound2 libasound2-dev libasound2-data"
UPMPD_URL="http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian/pool/main/u/upmpdcli/upmpdcli_1.2.16-1~ppa1~stretch_armhf.deb"
UPMPD_FILENAME="upmpdcli_1.2.16-1~ppa1~stretch_armhf.deb"
LIBUPNP6_URL="http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian/pool/main/libu/libupnp/libupnp6_1.6.20.jfd5-1~ppa1~stretch_armhf.deb"
LIBUPNP6_FILENAME="libupnp6_1.6.20.jfd5-1~ppa1~stretch_armhf.deb"
LIBUPNPP4_URL="http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian/pool/main/libu/libupnpp4/libupnpp4_0.16.1-1~ppa1~stretch_armhf.deb"
LIBUPNPP4_FILENAME="libupnpp4_0.16.1-1~ppa1~stretch_armhf.deb"
SHAIRPORTSYNCMR_URL="http://repo.volumio.org/Volumio2/Binaries/shairport-sync-metadata-reader-arm.tar.gz"
SHAIRPORTSYNCMR_FILENAME="shairport-sync-metadata-reader-arm.tar.gz"
#SHAIRPORTSYNC_URL="http://repo.volumio.org/Volumio2/Binaries/shairport-sync-3.0.2-arm.tar.gz"
#SHAIRPORTSYNC_FILENAME="shairport-sync-3.0.2-arm.tar.gz"

function software_install(){
	echo "]Update system and install software.["
	
	SOFT=$(dpkg -l $SOFTWARE_LIST | grep "<none>")
	if [ -n "$SOFT" ]; then
		apt update
		apt -y install $SOFTWARE_LIST
	fi
	
	echo "Install upnp and airplay support."

	SOFT=$(dpkg -l libupnpp4 | grep "<none>")
	if [ -n "$SOFT" ]; then
		echo "Install libupnpp4."
		curl -LJ0 -o $LIBUPNPP4_FILENAME $LIBUPNPP4_URL
	else
		echo "Libupnpp4 install complete."
	fi

	SOFT=$(dpkg -l libupnp6 | grep "<none>")
	if [ -n "$SOFT" ]; then
		echo "Install libupnp6."
		curl -LJ0 -o $LIBUPNP6_FILENAME $LIBUPNP6_URL
	else
		echo "Libupnp6 install complete."
	fi

	SOFT=$(dpkg -l upmpdcli | grep "<none>")
	if [ -n "$SOFT" ]; then
		echo "Install upmpdcli."
		curl -LJ0 -o $UPMPD_FILENAME $UPMPD_URL
	else
		echo "Upmpdcli install complete."
	fi

	if [ ! -f "/usr/local/bin/shairport-sync-metadata-reader" ]; then
		echo "Install shairpot-sync metadata reader."
		cd /
		curl -LJ0 -o $SHAIRPORTSYNCMR_FILENAME  $SHAIRPORTSYNCMR_URL
		tar xf $SHAIRPORTSYNCMR_FILENAME
		if [ -f "$SHAIRPORTSYNCMR_FILENAME" ]; then
			rm $SHAIRPORTSYNCMR_FILENAME
		fi
	fi

#	if [ ! -f "/usr/local/bin/shairport-sync" ]; then
#		echo "Install shairpot-sync."
#		cd /
#		curl -LJ0 -o $SHAIRPORTSYNC_FILENAME  $SHAIRPORTSYNC_URL
#		tar xf $SHAIRPORTSYNC_FILENAME
#		if [ -f "$SHAIRPORTSYNC_FILENAME" ]; then
#			rm $SHAIRPORTSYNC_FILENAME
#		fi
#	fi

	if [ ! -f "/usr/sbin/hostapd-ori" ]; then
		cp /usr/sbin/hostapd /usr/sbin/hostapd-ori
	fi
	
	if [ ! -f "/usr/sbin/hostapd-edimax" ]; then
		echo "Install special version of hostapd for edimax dongle."
		curl -LJ0 -o /usr/sbin/hostapd-edimax http://repo.volumio.org/Volumio2/Binaries/arm/hostapd-edimax
		chmod a+x /usr/sbin/hostapd-edimax
	fi
	
}

function driver_install(){
	echo "Install zpod driver."
	cd /home/pi
	if [ ! -f "/home/pi/aoide-dac-drivers" ]; then
		sudo -u pi git clone https://github.com/howardqiao/aoide-dac-drivers.git --depth 1
	else
		cd /home/pi/aoide-dac-drivers/
		./dac_install.sh
		sudo -u pi git reset --hard
		sudo -u pi git pull
	fi

}

function zpod_player_install(){
	echo "Download ZPOD player!"
	cd /home/pi
	if [ ! -f "/home/pi/zpod/" ]; then
		sudo -u pi git clone https://github.com/howardqiao/zpod.git --depth 1
	else
		cd /home/pi/zpod/
		sudo -u pi git reset --hard
		sudo -u pi git pull
	fi
}

function shairport_install(){
	if [ ! -f "/usr/local/bin/shairport-sync" ]; then
		if [ ! -f "/home/pi/zpod/zpod_res/shairport-sync" ]; then
			echo "Shairport-sync doesn't exist."
		else
			cp /home/pi/zpod/zpod_res/shairport-sync /usr/local/bin/
		fi
	else
		echo "shairport-sync exist."
	fi
	
	if [ -f "/lib/systemd/system/airplay.service" ]; then
		rm /lib/systemd/system/airplay.service
	fi

	touch /lib/systemd/system/airplay.service
	cat << EOF >> /lib/systemd/system/airplay.service
[Unit]
Description=ShairportSync AirTunes receiver
After=sound.target
Requires=avahi-daemon.service
After=avahi-daemon.service

[Service]
ExecStart=/usr/local/bin/shairport-sync
User=pi
Group=pi

[Install]
WantedBy=multi-user.target
EOF

	if [ -f "/etc/shairport-sync.conf" ]; then
		rm /etc/shairport-sync.conf
	fi
	
	touch /etc/shairport-sync.conf
	cat << EOF >> /etc/shairport-sync.conf
general =
{
    name = "ZPOD";
};

alsa =
{
  output_device = "hw:0,0";
};
EOF
}

function disable_input(){
	sed -i '/^dtparam=i2c_arm/d' $FILE_CONFIG
	sed -i '/^uinput/d' $FILE_MODULES
	sed -i '/^i2c-dev/d' $FILE_MODULES
	# sed -i '/joyBonnet.py/d' $FILE_RCLOCAL
	# if [ -e "/boot/joyBonnet.py" ]; then
		# rm /boot/joyBonnet.py
	# fi
	if [ -e "/etc/udev/rules.d/10-retrogame.rules" ]; then
		rm /etc/udev/rules.d/10-retrogame.rules
	fi
	sed -i '/^\/home\/pi\/zpod\/volcontrol &/d' $FILE_RCLOCAL
	sed -i '/^\/usr\/local\/bin\/retrogame &/d' $FILE_RCLOCAL
	if [ -f "/boot/retrogame.cfg" ]; then
		rm /boot/retrogame.cfg
	fi
}

function enable_input(){
	echo "dtparam=i2c_arm=on" >> $FILE_CONFIG
	# sed -i '/^exit 0/icd \/boot;python joyBonnet.py &' $FILE_RCLOCAL
	# if [ -e "/boot/joyBonnet.py" ]; then
		# rm /boot/joyBonnet.py
	# fi
	# cp resources/joyBonnet.py /boot/
	echo "uinput" >> $FILE_MODULES
	echo "i2c-dev" >> $FILE_MODULES
	touch /etc/udev/rules.d/10-retrogame.rules
	echo "SUBSYSTEM==\"input\", ATTRS{name}==\"retrogame\", ENV{ID_INPUT_KEYBOARD}=\"1\"" > /etc/udev/rules.d/10-retrogame.rules
	if [ ! -f "/usr/local/bin/retrogame" ]; then
		if [ ! -f "/home/pi/zpod/zpod_res/retrogame" ]; then
			zpod_player_install
		fi
		cp /home/pi/zpod/zpod_res/retrogame /usr/local/bin/retrogame
	fi
	sed -i '/^exit 0/i\/home\/pi\/zpod\/volcontrol &' $FILE_RCLOCAL
	sed -i '/^exit 0/i\/usr\/local\/bin\/retrogame &' $FILE_RCLOCAL
	if [ -f "/boot/retrogame.cfg" ]; then
		rm /boot/retrogame.cfg
	fi
	touch /boot/retrogame.cfg
	cat << EOF >> /boot/retrogame.cfg
LEFT      17
RIGHT     23
UP         4
DOWN      22
U         12
I         13
J         16
K         26
EQUAL     5
MINUS     20
RIGHTSHIFT      24
ENTER     6
EOF
}

function config_input(){
	echo ">Config input"
	disable_input
	enable_input
}

function disable_sound(){
	sed -i '/^dtparam=audio/d' $FILE_CONFIG
	echo "dtparam=audio=on" >> $FILE_CONFIG
	sed -i '/^dtoverlay=aoide-zpod-dac/d' $FILE_CONFIG
}

function enable_sound(){
	sed -i '/^dtparam=audio/d' $FILE_CONFIG
	echo "dtoverlay=aoide-zpod-dac" >> $FILE_CONFIG
}

function config_sound(){
	echo ">Config Sound"
	disable_sound
	enable_sound
}

function disable_screen(){
	sed -i '/^dtparam=spi/d' $FILE_CONFIG
	sed -i '/^dtoverlay=pitft22/d' $FILE_CONFIG
	sed -i '/^hdmi_group=/d' $FILE_CONFIG
	sed -i '/^hdmi_mode=/d' $FILE_CONFIG
	sed -i '/^hdmi_cvt=/d' $FILE_CONFIG
	sed -i '/^hdmi_force_hotplug=/d' $FILE_CONFIG
	sed -i '/^sh -c "TERM=linux/d' $FILE_RCLOCAL
}

function enable_screen(){
	sed -i '/^exit 0/ish -c "TERM=linux setterm -blank 0 >/dev/tty0"' $FILE_RCLOCAL
	cat << EOF >> $FILE_CONFIG
dtparam=spi=on
dtoverlay=pitft22,speed=80000000,rotate=90,fps=60
hdmi_group=2
hdmi_mode=87
hdmi_cvt=320 240 60 1 0 0 0
hdmi_force_hotplug=1
EOF
}

function config_screen(){
	echo ">Config Screen"
	disable_screen
	enable_screen
}

function disable_raspi2fb(){
	systemctl stop raspi2fb@1.service
	systemctl disable raspi2fb@1
	if [ -e "/etc/systemd/system/raspi2fb@.service" ]; then
		rm /etc/systemd/system/raspi2fb@.service
	fi
	systemctl daemon-reload
	if [ -e "/usr/local/bin/raspi2fb" ]; then
		rm /usr/local/bin/raspi2fb
	fi
}

function enable_raspi2fb(){
	cp /home/pi/zpod/zpod_res/raspi2fb /usr/local/bin/
	cp /home/pi/zpod/zpod_res/raspi2fb@.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable raspi2fb@1.service
	systemctl start raspi2fb@1
}

function config_raspi2fb(){
	echo ">Config Raspi2fb"
	if [ ! -f "/home/pi/zpod/zpod_res/raspi2fb" ]; then
		zpod_player_install
	fi
	disable_raspi2fb
	enable_raspi2fb
}

function config_emulationstation(){
	echo "]Config EmulationStation["
	echo ">Download Font"
	if [ ! -e "/etc/emulationstation/themes/carbon/art/SourceHanSans-Bold.ttc" ]; then
		#curl -LJ0 -o $FONT_FILE $FONT_URL
		cp /home/pi/zpod/resources/SourceHanSans-Regular.ttc $FONT_FILE
	fi
	
	echo ">Change font of emulationstatoin"
	sed -i -e 's/Cabin-Bold.ttf/SourceHanSans-Bold.ttc/g' /etc/emulationstation/themes/carbon/carbon.xml
	echo ">Change font size of EmulationStation"
	sed -i -e "s/<fontSize>.*<\/fontSize>/<fontSize>$FONT_SIZE<\/fontSize>/g" /etc/emulationstation/themes/carbon/carbon.xml
	echo ">Add ZPOD Theme in EmulationStation"
	if [ -d "/etc/emulationstation/themes/carbon/zpod" ]; then
		echo "remove old folder"
		rm -rf /etc/emulationstation/themes/carbon/zpod
	fi
	cp -a /home/pi/zpod/zpod_res/zpod /etc/emulationstation/themes/carbon/
	echo ">Add ZPOD System in EmulationStation"
	# if [ -d "/home/pi/RetroPie/zpod" ]; then
		# echo "remove old folder"
		# rm -rf /home/pi/RetroPie/zpod
	# fi
	# cp -a resources/ugeek /home/pi/RetroPie
	# chown -R pi:pi /home/pi/RetroPie
	IN_SYSTEM=$(cat /etc/emulationstation/es_systems.cfg | grep zpod)
	if [ -z "$IN_SYSTEM" ]; then
		sed -i -e '/<systemList>/r /home/pi/zpod/zpod_res/es_system_zpod.cfg' /etc/emulationstation/es_systems.cfg
	fi
	#cp /opt/retropie/configs/all/emulationstation/es_input.cfg.bak /opt/retropie/configs/all/emulationstation/es_input.cfg
	#sed -i -e '/inputAction>/r patches/es_input.cfg' /opt/retropie/configs/all/emulationstation/es_input.cfg
	if [ -e "$FILE_ESINPUT" ]; then
		rm $FILE_ESINPUT
	fi
	touch $FILE_ESINPUT
	cat << EOF >> $FILE_ESINPUT
<?xml version="1.0"?>
<inputList>
  <inputAction type="onfinish">
    <command>/opt/retropie/supplementary/emulationstation/scripts/inputconfiguration.sh</command>
  </inputAction>
  <inputConfig type="keyboard" deviceName="Keyboard" deviceGUID="-1">
    <input name="start" type="key" id="13" value="1"/>
    <input name="down" type="key" id="1073741905" value="1"/>
    <input name="right" type="key" id="1073741903" value="1"/>
    <input name="select" type="key" id="1073742053" value="1"/>
    <input name="left" type="key" id="1073741904" value="1"/>
    <input name="up" type="key" id="1073741906" value="1"/>
    <input name="a" type="key" id="107" value="1"/>
    <input name="b" type="key" id="106" value="1"/>
    <input name="x" type="key" id="105" value="1"/>
    <input name="y" type="key" id="117" value="1"/>
  </inputConfig>
</inputList>
EOF
	echo "Start player first."
	IN_SYSTEM=$(cat /opt/retropie/configs/all/autostart.sh | grep zpod)
	if [ -z "$IN_SYSTEM" ]; then
		sed -i '/^emulationstation/icd \/home\/pi\/zpod' $FILE_AUTOSTART
		sed -i '/^emulationstation/isudo .\/play' $FILE_AUTOSTART
	fk
	if [ -f "/home/pi/zpod/images/splash.png" ]; then
		if [ -f "/etc/splashscreen.list" ]; then
			rm /etc/splashscreen.list
			touch /etc/splashscreen.list
			echo "/home/pi/zpod/images/splash.png" > /etc/splashscreen.list
		fi
	fi
}

function config_retroarch(){
	echo ">Config Retroarch"
	
	sed -i 's/^#[ \t]*audio_out_rate.*/audio_out_rate = 44100/' $FILE_RETROARCH
	sed -i 's/[ \t]*input_player1_a[ \t]*=[ \t]*\".*\"/input_player1_a = \"k\"/' $FILE_RETROARCH
	sed -i 's/[ \t]*input_player1_b[ \t]*=[ \t]*\".*\"/input_player1_b = \"j\"/' $FILE_RETROARCH
	sed -i 's/[ \t]*input_player1_y[ \t]*=[ \t]*\".*\"/input_player1_y = \"u\"/' $FILE_RETROARCH
	sed -i 's/[ \t]*input_player1_x[ \t]*=[ \t]*\".*\"/input_player1_x = \"i\"/' $FILE_RETROARCH
	sed -i 's/^#[ \t]*input_state_slot_increase/input_state_slot_increase/' $FILE_RETROARCH
	sed -i 's/^#[ \t]*input_state_slot_decrease/input_state_slot_decrease/' $FILE_RETROARCH
	sed -i 's/^input_state_slot_increase[ \t]*=.*/input_state_slot_increase = \"right\"/' $FILE_RETROARCH
	sed -i 's/^input_state_slot_decrease[ \t]*=.*/input_state_slot_decrease = \"left\"/' $FILE_RETROARCH
	sed -i 's/[ \t].*input_exit_emulator[ \t].*=[ \t].*\".*\"/input_exit_emulator = \"enter\"/' $FILE_RETROARCH
	sed -i 's/^#[ \t]*input_reset.*/input_reset = \"j\"/' $FILE_RETROARCH
	sed -i 's/^#[ \t]*input_menu_toggle[ \t]*=.*/input_menu_toggle = \"i\"/' $FILE_RETROARCH
	sed -i 's/^input_enable_hotkey[ \t]*=[ \t]\".*\"/input_enable_hotkey = \"rshift\"/' $FILE_RETROARCH
}

function config_mpd(){
	echo ">Config Music Player Daemon"
	if [ ! -d "/home/pi/music" ]; then
		sudo -u pi mkdir /home/pi/music
	fi
#	sed -i -e 's/\/var\/lib\/mpd\/music/\/home\/pi\/music/g' /etc/mpd.conf
	sed -i -e 's/^music_directory.*".*"/music_directory "\/home\/pi\/music"/' /etc/mpd.conf
	sed -i 's/#[ \t]*mixer_device[ \t]*\".*\".*/\tmixer_device\t\"hw:0\"/' /etc/mpd.conf
        sed -i 's/#[ \t]*mixer_control[ \t]*\".*\".*/\tmixer_control\t\"Digital\"/' /etc/mpd.conf

}

function config_ap(){
	echo ">Config Wireless."
echo "] Enable DHCPCD ["
if [ -f "/etc/dhcpcd.conf" ]; then
	IN_DHCPCD=$(cat /etc/dhcpcd.conf | grep wlan0)
        if [ -z "$IN_DHCPCD" ]; then
                cat << EOF >> /etc/dhcpcd.conf
interface wlan0
    static ip_address=192.168.20.1/24
EOF
	fi
fi
sudo systemctl enable dhcpcd
sudo systemctl start dhcpcd

echo "] Enable DNSMASQ ["
sudo sed -i 's/^[ \t]*interface.*//g' /etc/dnsmasq.conf
sudo sed -i 's/^[ \t]*dhcp-range.*//g' /etc/dnsmasq.conf

sudo cat << EOF >> /etc/dnsmasq.conf
interface=wlan0
  dhcp-range=192.168.20.2,192.168.20.20,255.255.255.0,24h
EOF

echo "] Enable HOSTAPD ["
if [ -f "/etc/hostapd/hostapd.conf" ]; then
	sudo rm /etc/hostapd/hostapd.conf
fi
sudo touch /etc/hostapd/hostapd.conf
sudo cat << EOF >> /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=ZPOD
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
rsn_pairwise=CCMP
EOF

sed -i 's/#DAEMON_CONF/DAEMON_CONF/g' /etc/default/hostapd
sed -i 's/^DAEMON_CONF=\".*\"/DAEMON_CONF=\"\/etc\/hostapd\/hostapd.conf\"/g' /etc/default/hostapd

cp /usr/sbin/hostapd-ori /usr/sbin/hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

if [ ! -f "/etc/sysctl.conf" ]; then
	touch /etc/sysctl.conf
fi
sed -i 's/#net.ipv4.ip_forward=1//g' /etc/default/hostapd
echo "net.ipv4.ip_forward=1" >>  /etc/sysctl.conf

sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE

if [ ! -f "/etc/iptables.ipv4.nat" ]; then
	sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
fi

sed -i 's/iptables-restore.*//g' /etc/rc.local
sed -i '/^exit 0/iiptables-restore < \/etc\/iptables.ipv4.nat' /etc/rc.local


}

function config_samba(){
	echo ">Config Samba."
	IN_SMB=$(cat /etc/samba/smb.conf | grep music)
	if [ -z "$IN_SMB" ]; then
		systemctl stop smbd
		cat << EOF >> /etc/samba/smb.conf
[music]
comment = music
path = "/home/pi/music"
writeable = yes
guest ok = yes
create mask = 0644
directory mask = 0755
force user = pi
EOF
		systemctl start smbd
	fi
}

function driver_install(){
	./aoide_dac_drivers_install.sh
}

function config_wifi(){
	echo "Config wifi"	
}

function main(){
	driver_install
	software_install
	zpod_player_install
	shairport_install
	config_input
	config_screen
	config_raspi2fb
	config_sound
	config_emulationstation
	config_retroarch
	config_mpd
	config_samba
	config_ap
	echo ">Complete!<"
}
main
#reboot
