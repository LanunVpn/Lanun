#!/bin/bash
clear

websc=https://raw.githubusercontent.com/LanunVpn/Lanun/main/script

#delete file
rm -f /usr/local/bin/mxray

# download script
cd /usr/local/bin

wget -O mxray "${websc}/script/lifetime/upgrade/mxray.sh" && chmod +x mxray
cd
clear

