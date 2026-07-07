#!/bin/bash
clear
echo -e "MASUKKAN DOMAIN BARU ATAU TEKAN CTL C UTK EXIT"
echo -e ""
read -rp "HOSTANME/DOMAIN: " -e host
rm -f /etc/xray/domain
mkdir /etc/xray
echo "$host" >> /etc/xray/domain
clear
#recert
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
sleep 1
echo -e "============================================="
echo -e " ${green} RECERT XRAY${NC}"
echo -e "============================================="
sleep 1
echo start
sleep 0.5
domain=$(cat /etc/xray/domain)
systemctl stop xray
systemctl stop xray@none
systemctl stop xray@xhttp

sudo kill -9 $(sudo lsof -t -i:80)
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256 --force --ecc
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
systemctl daemon-reload
systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp

echo Done
sleep 0.5
clear
echo -e "============================================="
echo -e " ${green} PERTUKARAN DOMAIN SELESAI${NC}"
echo -e "============================================="
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu