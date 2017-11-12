#!/bin/bash
line1=$(grep -n "BUILD=\"arm\"" build/build.sh | awk -F ":" '{print $1}')
line2=$(grep -n "Cloning Volumio UI" build/build.sh | awk -F ":" '{print $1}')
line2b=$[$line2 - 1]
echo $line1
echo $line2b
line1a=$line1"a"
line2ba=$line2b"a"
sed -i '$line1a r volumio_patch1.sh' build/build.sh
sed -i '$line2ba r volumio_patch2.sh' build/build.sh

