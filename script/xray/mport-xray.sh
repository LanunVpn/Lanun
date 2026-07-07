#!/bin/bash
clear
red='\e[1;31m'
gr='\e[0;32m'
blue='\e[0;34m'
bb='\e[0;94m'
cy='\033[0;36m'
NC='\e[0m'
clear

tls="$(cat ~/log-install.txt | grep -w "XRAY VLESS WS TLS" | cut -d: -f2|sed 's/ //g')"
none="$(cat ~/log-install.txt | grep -w "XRAY VLESS WS NON TLS" | cut -d: -f2|sed 's/ //g')"
xhttp="$(cat ~/log-install.txt | grep -w "XRAY VLESS XHTTP NON TLS" | cut -d: -f2|sed 's/ //g')"
hup="$(cat ~/log-install.txt | grep -w "XRAY VLESS HTTPUPG NON TLS" | cut -d: -f2|sed 's/ //g')"
CONFIG1="/usr/local/etc/xray/config.json"
CONFIG2="/usr/local/etc/xray/none.json"
CONFIG3="/usr/local/etc/xray/xhttp.json"



port_tls() {
	clear
	echo -e "PORT VLESS TLS KINI= $tls"
	echo -e ""
	echo -e "${gr}MASUKKAN PORT BARU TLS ATAU TEKAN CTL C UTK EXIT${NC}"
	echo -e ""
	read -p "NEW PORT TLS: " tls2
	# Check kalau port baru dah guna
	if netstat -tulnp | grep -q ":$tls2 "; then
  	echo "[ERROR] Port $tls2 already in use!"
  	sleep 2
  	clear
  	mport-xray
	fi
	# Replace port
	sed -i "s/\"port\": $tls/\"port\": $tls2/g" $CONFIG1
	sed -i "s/   - XRAY VLESS WS TLS            : $tls/   - XRAY VLESS WS TLS            : $tls2/g" /root/log-install.txt
	sed -i "s/   - XRAY VLESS XTLS              : $tls/   - XRAY VLESS XTLS              : $tls2/g" /root/log-install.txt
	sed -i "s/   - XRAY VLESS GRPC              : $tls/   - XRAY VLESS GRPC              : $tls2/g" /root/log-install.txt
	clear
	# Restart Xray
	systemctl restart xray
	systemctl restart xray@none
	systemctl restart xray@xhttp
	clear
	echo "[INFO] PERTUKARAN PORT VLESS TLS SELESAI"
	sleep 2
	clear
    menu
}
port_ntls() {
	clear
	echo -e "PORT VLESS NON TLS KINI= $none"
	echo -e ""
	echo -e "${gr}MASUKKAN PORT BARU NON TLS ATAU TEKAN CTL C UTK EXIT${NC}"
	echo -e ""
	read -p "NEW PORT NONE TLS: " none2
	# Check kalau port baru dah guna
	if netstat -tulnp | grep -q ":$none2 "; then
  	echo "[ERROR] Port $none2 already in use!"
  	sleep 2
  	clear
  	mport-xray
	fi
	# Replace port
	sed -i "s/\"port\": $none/\"port\": $none2/g" $CONFIG2
	sed -i "s/   - XRAY VLESS WS NON TLS        : $none/   - XRAY VLESS WS NON TLS        : $none2/g" /root/log-install.txt
	sed -i "s/   - XRAY VLESS HTTPUPG NON TLS   : $none/   - XRAY VLESS HTTPUPG NON TLS   : $none2/g" /root/log-install.txt
	clear
	# Restart Xray
	systemctl restart xray
	systemctl restart xray@none
	systemctl restart xray@xhttp
	clear
	echo "[INFO] PERTUKARAN PORT VLESS NON TLS SELESAI"
	sleep 2
	clear
    menu
}
port_xhttp() {
	clear
	echo -e "PORT VLESS XHTTP NON TLS KINI= $xhttp"
	echo -e ""
	echo -e "${gr}MASUKKAN PORT BARU XHTTP NON TLS ATAU TEKAN CTL C UTK EXIT${NC}"
	echo -e ""
	read -p "NEW PORT XHTTP NONE TLS: " xhttp2
	# Check kalau port baru dah guna
	if netstat -tulnp | grep -q ":$xhttp2 "; then
  	echo "[ERROR] Port $xhttp2 already in use!"
  	sleep 2
  	clear
  	mport-xray
	fi
	# Replace port
	sed -i "s/\"port\": $xhttp/\"port\": $xhttp2/g" $CONFIG3
	sed -i "s/   - XRAY VLESS XHTTP NON TLS     : $xhttp/   - XRAY VLESS XHTTP NON TLS     : $xhttp2/g" /root/log-install.txt
	clear
	# Restart Xray
	systemctl restart xray
	systemctl restart xray@none
	systemctl restart xray@xhttp
	clear
	echo "[INFO] PERTUKARAN PORT VLESS XHTTP NON TLS SELESAI"
	sleep 2
	clear
    menu
}

echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  " \033[30;5;47m                      ⇱ MENU CHANGE PORT XRAY ⇲                        \033[m"       
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} "   
echo -e  " ${bb}[ 01 ]${NC} PORT VLESS TLS "
echo -e  " ${bb}[ 02 ]${NC} PORT VLESS NON TLS/HTTPUPG"
echo -e  " ${bb}[ 03 ]${NC} PORT VLESS XHTTP NON TLS"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}" 
echo -e  " ${bb}[  0 ]${NC}" "${cy}EXIT TO MENU${NC}  "
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  "  "
echo -e "\e[1;31m"
read -p  "     Please select an option :  " mp
echo -e "\e[0m"
 case $mp in
  1)
	clear ; port_tls
  ;;
  2)
    clear ; port_ntls
  ;;
  3)
    clear ; port_xhttp
  ;;
  0)
  sleep 0.5
  clear
  menu
  ;;
  *)
  echo -e "ERROR!! Please Enter an Correct Number"
  sleep 1
  clear
  mport-xray
  ;;
  esac