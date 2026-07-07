#!/bin/bash
clear

websc=https://raw.githubusercontent.com/LanunVpn/Lanun/main

#delete file
rm -f /usr/local/bin/mxray

# download script
cd /usr/local/bin

wget -O mxray "${websc}/script/mxray.sh" && chmod +x mxray
cd
clear

