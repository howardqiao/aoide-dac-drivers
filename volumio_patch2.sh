#---Aoide Patch---#
[ -n "$ROOT" ] || ROOT="build/$BUILD/root"
echo "Patch Volumio For AOIDE Settings, using ROOT=$ROOT"
[ -d "$ROOT" ] || {
    echo "Error: ROOT=$ROOT is not a directory" >&2
    exit 1
}
linenum=$(grep -n 'allo-boss-dac' "$ROOT"/volumio/app/plugins/system_controller/i2s_dacs/dacs.json | awk -F ":" '{print $1}')
linenuma=$linenum"a"
dac1='    {"id":"aoide-dacii","name":"Aoide DAC II","overlay":"aoide-dacii","alsanum":"1","mixer":"Digital","modules":"","script":"","needsreboot":"yes"},'
dac2='    {"id":"aoide-digi-pro","name":"Aoide Digi Pro","overlay":"aoide-digipro","alsanum":"1","mixer":"Digital","modules":"","script":"","needsreboot":"yes"},'
dac3='    {"id":"aoide-zero-dacplus","name":"Aoide Zero DAC+","overlay":"aoide-zero-dacplus","alsanum":"1","mixer":"Digital","modules":"","script":"","needsreboot":"yes"},'
dac4='    {"id":"aoide-zero-digiplus","name":"Aoide Zero Digi+","overlay":"aoide-zero-digiplus","alsanum":"1","mixer":"","modules":"","script":"","needsreboot":"yes"},'
sed -i "$linenuma $dac4" "$ROOT"/volumio/app/plugins/system_controller/i2s_dacs/dacs.json
sed -i "$linenuma $dac3" "$ROOT"/volumio/app/plugins/system_controller/i2s_dacs/dacs.json
sed -i "$linenuma $dac2" "$ROOT"/volumio/app/plugins/system_controller/i2s_dacs/dacs.json
sed -i "$linenuma $dac1" "$ROOT"/volumio/app/plugins/system_controller/i2s_dacs/dacs.json

linenum=$(grep -n 'snd_rpi_hifiberry_dac' "$ROOT"/volumio/app/plugins/audio_interface/alsa_controller/cards.json | awk -F ":" '{print $1}')
linenuma=$linenum"a"
dac1='    {"name": "sndrpiaoidedigi", "multidevice": false, "prettyname": "Aoide Digi Pro", "type":"i2S"},'
dac2='    {"name": "II", "multidevice": false, "prettyname": "Aoide DAC II", "defaultmixer": "Digital", "type":"i2S"},'
dac3='    {"name": "sndrpiaoidezerodacplus", "multidevice": false, "prettyname": "Aoide Zero DAC Plus", "type":"i2S"},'
dac4='    {"name": "sndrpiaoidezerodigiplus", "multidevice": false, "prettyname": "Aoide Zero Digi Plus", "type":"i2S"},'
space4='    '
sed -i "$linenuma $dac4" "$ROOT"/volumio/app/plugins/audio_interface/alsa_controller/cards.json
sed -i "$linenuma $dac3" "$ROOT"/volumio/app/plugins/audio_interface/alsa_controller/cards.json
sed -i "$linenuma $dac2" "$ROOT"/volumio/app/plugins/audio_interface/alsa_controller/cards.json
sed -i "$linenuma $dac1" "$ROOT"/volumio/app/plugins/audio_interface/alsa_controller/cards.json
#---Aoide Patch---#
