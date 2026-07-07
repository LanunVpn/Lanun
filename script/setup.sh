#!/bin/bash
if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi

red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'

apt -y update 
apt install -y bzip2 gzip coreutils screen curl
sleep 2
clear

# Script Access
echo -e "${gr}CHECKING SCRIPT ACCESS${NC}"
sleep 2
mkdir /etc/pass
clear
read -rp "    MASUKKAN PASSWORD ANDA: " -e pass
IZIN=$(curl https://raw.githubusercontent.com/LanunVpn/Lanun/main/IP/accsess | grep $pass | awk '{print $2}')
if [ $pass = $IZIN ]; then
    echo -e ""
    echo -e "${gr}ACCESS GRANTED...${NC}"
    echo "$pass" >> /etc/pass/accsess
    sleep 2
else
	echo -e ""
    echo -e "${red}ACCESS DENIED...PM TELEGRAM OWNER${NC}"
    sleep 2
    rm -f setup.sh
    rm -rf /etc/pass
    exit 1
fi
clear
clear

MYIP=$(wget -qO- icanhazip.com);
echo "Checking Vps"
sleep 2
clear

#Welcome Note
echo -e "============================================="
echo -e " ${green} WELCOME TO LANUN SCRIPT${NC}"
echo -e "============================================="
echo -e ""

#Install Update
echo -e "============================================="
echo -e " ${green} UPDATE && UPGRADE PROCESS${NC}"
echo -e "============================================="
apt -y update 
apt install -y bzip2 gzip coreutils screen curl
sleep 2
clear

# Disable IPv6
echo -e "============================================="
echo -e " ${green} DISABLE IPV6${NC}"
echo -e "============================================="
sleep 2
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo -e "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sleep 2
clear

# Subdomain Settings
echo -e "============================================="
echo -e "${green} DOMAIN INPUT${NC} "
echo -e "============================================="
sleep 2
mkdir /etc/xray
clear
echo -e ""
echo -e "${green}MASUKKAN DOMAIN ANDA YANG TELAH DI POINT KE IP ANDA${NC}"
read -rp "    Enter your Domain/Host: " -e host
ip=$(wget -qO- ipv4.icanhazip.com)
host_ip=$(ping "${host}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
if [[ ${host_ip} == "${ip}" ]]; then
	echo -e ""
	echo -e "${green}HOST/DOMAIN MATCHED..INSTALLATION WILL CONTINUE${NC}"
    echo "$host" >> /etc/xray/domain
    echo "$host" > /root/domain
	sleep 2
	clear
else
	echo -e "${green}HOST/DOMAIN NOT MATCHED..INSTALLATION WILL TERMINATED${NC}"
	echo -e ""
    rm -f setup.sh
    rm -rf /etc/pass
    exit 1
fi

# Install BBR+FQ
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
clear

websc=https://raw.githubusercontent.com/LanunVpn/Lanun/main
#install ssh 
echo -e "============================================="
echo -e " ${green} INSTALLING SSH ${NC}"
echo -e "============================================="
sleep 2
wget ${websc}/script/ssh/ssh-vpn.sh && chmod +x ssh-vpn.sh && ./ssh-vpn.sh
sleep 2
clear

#install ssh ws
echo -e "============================================="
echo -e " ${green} INSTALLING SSH WS  ${NC}"
echo -e "============================================="
sleep 2
wget ${websc}/script/sshws/install_ws_http.sh && chmod +x install_ws_http.sh  
sleep 2
clear


#install Xray
echo -e "============================================="
echo -e " ${green} INSTALLING XRAY${NC} "
echo -e "============================================="
sleep 2
wget ${websc}/script/xray/install-xray.sh && chmod +x install-xray.sh && ./install-xray.sh
sleep 2
clear

#install resolv
echo -e "============================================="
echo -e " ${green} INSTALLING RESOLVCONF${NC} "
echo -e "============================================="
sleep 2
apt install resolvconf -y
systemctl start resolvconf.service
systemctl enable resolvconf.service
echo 'nameserver 8.8.8.8' > /etc/resolvconf/resolv.conf.d/head
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
systemctl restart resolvconf.service
clear
echo -e " ${red}RESOLVE INSTALL DONE ${NC}"
sleep 2
clear

rm -f /root/ssh-vpn.sh
rm -f /root/install-xray.sh
rm -f /root/websocket.sh



clear
echo " "
echo "INSTALLATION COMPLETE!!"
echo " "
echo "====================== LANUNVPN AUTOSCRIPT =======================" | tee -a log-install.txt
echo "" | tee -a log-install.txt
echo "   >>> Service & Port"  | tee -a log-install.txt
echo "   - XRAY VLESS WS TLS            : 443"  | tee -a log-install.txt
echo "   - XRAY VLESS XTLS              : 443"  | tee -a log-install.txt
echo "   - XRAY VLESS GRPC              : 443"  | tee -a log-install.txt
echo "   - XRAY VLESS WS NON TLS        : 80"  | tee -a log-install.txt
echo "   - XRAY VLESS HTTPUPG NON TLS   : 80"  | tee -a log-install.txt
echo "   - XRAY VLESS XHTTP NON TLS     : 8080"  | tee -a log-install.txt
echo "   - SSH WEBSOCKET HTTP           : 8880"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "===================================================================="
echo ""  | tee -a log-install.txt
echo "   - Telegram                : t.me/Lanunvpn"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "========================== SCRIPT BY Lanunvpn =====================" | tee -a log-install.txt
echo ""
sleep 1
rm -f setup.sh
read -n 1 -r -s -p $'Press any key to reboot...\n';reboot
