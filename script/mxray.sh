#!/bin/bash
clear
red='\e[1;31m'
gr='\e[0;32m'
blue='\e[0;34m'
bb='\e[0;94m'
cy='\033[0;36m'
NC='\e[0m'
clear

MYIP=$(wget -qO- ipv4.icanhazip.com); 
clear

domain=$(cat /etc/xray/domain)
tls="$(cat ~/log-install.txt | grep -w "XRAY VLESS WS TLS" | cut -d: -f2|sed 's/ //g')"
none="$(cat ~/log-install.txt | grep -w "XRAY VLESS WS NON TLS" | cut -d: -f2|sed 's/ //g')"
xhttp="$(cat ~/log-install.txt | grep -w "XRAY VLESS XHTTP NON TLS" | cut -d: -f2|sed 's/ //g')"
hup="$(cat ~/log-install.txt | grep -w "XRAY VLESS HTTPUPG NON TLS" | cut -d: -f2|sed 's/ //g')"

add_user() {
	clear
	until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		read -rp "User: " -e user
		CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo "A client with the specified name was already created, please choose another name."
			sleep 1
            add_user
		fi
	done
uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Expired (days): " masaaktif
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
read -p "SNI (bug) : " sni
read -p "PATH (EXP : wss://bug.com /Press Enter If Only Use Default) : " wss
path=$wss
read -p "Subdomain (EXP : m.google.com. / Press Enter If Only Using Hosts) : " sub
dom=$sub$domain
sed -i '/#xray-vless-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-grpc$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-xtls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","flow": "xtls-rprx-vision","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-hup$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#vless-xhttp-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/xhttp.json
sed -i '/#vless-xhttp-ntls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/xhttp.json

echo -e "### $user $exp" $uuid >> /usr/local/etc/xray/vless.txt

vlesslink1="vless://${uuid}@${dom}:$tls?path=$path/xvless&security=tls&encryption=none&type=ws&sni=$sni#${user}"
vlesslink2="vless://${uuid}@${dom}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=$sni#${user}"
vlesslink3="vless://${uuid}@${dom}:$none?path=$path/xvless-hup&encryption=none&type=httpupgrade&host=$sni#${user}"
vlesslink4="vless://${uuid}@$dom:$xhttp?mode=auto&path=$path/xvless-xhttp-ntls&encryption=none&type=xhttp&host=$dom#${user}"
vless_vision="vless://${uuid}@${dom}:$tls?security=tls&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision&sni=$sni#$user"
vlessgrpc="vless://${uuid}@${dom}:$tls?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vlgrpc&sni=$sni#$user"


digiboost="vless://${uuid}@162.159.133.61:$none?path=/xvlessntls&encryption=none&type=ws&host=cdn.opensignal.com.$dom#${user}-digi-boost-3mbps"
digiboost2="vless://${uuid}@opensignal.com.$dom:$none?path=/xvlessntls&encryption=none&type=ws#${user}-digi-boost-6/12mbps"
diginew="vless://${uuid}@172.66.169.187:$none?path=/xvlessntls&encryption=none&type=ws&host=speedtest.net.$dom#${user}-digi-new"

maxisviu="vless://${uuid}@help.viu.com.$dom:$none?path=/xvlessntls&encryption=none&type=ws&host=help.viu.com#${user}-maxis-viu"
maxisfrez="vless://${uuid}@auth.opensignal.com:$xhttp?mode=auto&path=$path/xvless-xhttp-ntls&encryption=none&type=xhttp&host=cdn.opensignal.$dom#${user}-max-frez"

umobile3="vless://${uuid}@172.66.40.170:$none?path=/xvlessntls&encryption=none&type=ws&host=$dom#${user}-umobile-ws"

yes="vless://${uuid}@104.17.147.22:$none?path=/vlessntls&encryption=none&type=ws&host=$dom#${user}-yes-router"
#yes1="vless://${uuid}@eurohealthobservatory.who.int:$none?path=/vlessntlst&encryption=none&type=ws&host=$dom#${user}-yes-hp"

yoodopubg1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=m.pubgmobile.com#${user}-yodoopubg1"
yoodopokemon1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=community.pokemon.com#${user}-yodoopokemon1"

yoodoml1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=m.mobilelegends.com#${user}-yodooml1"

unifi1="vless://${uuid}@auth.opensignal.com:$none?path=/xvlessntls&encryption=none&type=ws&host=$domain#${user}-unifi-wow"
unifi2="vless://${uuid}@104.17.10.12:$none?path=/xvlessntls&encryption=none&type=ws&host=$domain#${user}-unifi-bebas"

systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp

clear
echo -e ""
echo -e "================================="
echo -e "   XRAY VLESS WS & XTLS       " 
echo -e "================================="
echo -e "Remarks             : ${user}"
echo -e "Expired On          : $exp"
echo -e "IP/Host             : ${MYIP}"
echo -e "Domain              : ${domain}"
echo -e "port TLS            : $tls"
echo -e "port none TLS       : $none"
echo -e "port xhttp none TLS : $xhttp"
echo -e "id                  : ${uuid}"
echo -e "Encryption          : none"
echo -e "network             : ws/httpupgrade/xhttp"
echo -e "path ws             : multipath"
echo -e "path httpupgrade    : /xvless-hup"
echo -e "path xhttp          : /xvless-xhttp-ntls"
echo -e "================================="
echo -e ""
echo -e ""
echo -e " ${bb}═══════════════════════${NC} "
echo -e " \033[30;5;47m ⇱ CONFIG BY LANUN ⇲  \033[m"
echo -e " ${bb}═══════════════════════${NC} "
echo -e ""
echo -e ""
echo -e "${cy}🟡VLESS DIGI BOOSTER 3🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${digiboost}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟡VLESS DIGI BOOSTER 6/12🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${digiboost2}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟡VLESS DIGI TANPA LANGGAN🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${diginew}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🔴VLESS MAXIS-TV🔴 :${NC} "
#echo -e ""
echo -e "\`\`\`"
echo -e "${maxisviu}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🔴VLESS MAXIS-FREZ-XHTTP🔴 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${maxisfrez}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟠VLESS UMOBILE EXP🟠:${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${umobile3}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟣VLESS YES🟣 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${yes}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}⚪VLESS UNIFI BEBAS⚪:${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${unifi2}"
echo -e "\`\`\`"
echo -e ""
echo -e "================================="
echo -e ""
echo -e "Remarks             : ${user}"
echo -e "Expired On          : $exp"
echo -e ""
echo -e "================================="
echo -e "ScriptMod By LanunVPN"
read -n 1 -s -r -p "Press any key to back on menu"
clear
menu
}

trial_user() {

uuid=$(cat /proc/sys/kernel/random/uuid)
user=TRIALvless-`</dev/urandom tr -dc X-Z0-9 | head -c4`
duration=1
exp=`date -d "$duration days" +"%Y-%m-%d"`
read -p "SNI (bug) : " sni
read -p "PATH (EXP : wss://bug.com /Press Enter If Only Use Default) : " wss
path=$wss
read -p "Subdomain (EXP : m.google.com. / Press Enter If Only Using Hosts) : " sub
dom=$sub$domain
sed -i '/#xray-vless-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-grpc$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-vless-xtls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","flow": "xtls-rprx-vision","email": "'""$user""'"' /usr/local/etc/xray/config.json
sed -i '/#xray-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#xray-vless-hup$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/none.json
sed -i '/#vless-xhttp-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/xhttp.json
sed -i '/#vless-xhttp-ntls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /usr/local/etc/xray/xhttp.json

echo -e "### $user $exp" $uuid >> /usr/local/etc/xray/vless.txt

vlesslink1="vless://${uuid}@${dom}:$tls?path=$path/xvless&security=tls&encryption=none&type=ws&sni=$sni#${user}"
vlesslink2="vless://${uuid}@${dom}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=$sni#${user}"
vlesslink3="vless://${uuid}@${dom}:$none?path=$path/xvless-hup&encryption=none&type=httpupgrade&host=$sni#${user}"
vlesslink4="vless://${uuid}@$dom:$xhttp?mode=auto&path=$path/xvless-xhttp-ntls&encryption=none&type=xhttp&host=$dom#${user}"
vless_vision="vless://${uuid}@${dom}:$tls?security=tls&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision&sni=$sni#$user"
vlessgrpc="vless://${uuid}@${dom}:$tls?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vlgrpc&sni=$sni#$user"


digiboost="vless://${uuid}@162.159.133.61:$none?path=/xvlessntls&encryption=none&type=ws&host=cdn.opensignal.com.$dom#${user}-digi-boost-3mbps"
digiboost2="vless://${uuid}@opensignal.com.$dom:$none?path=/xvlessntls&encryption=none&type=ws#${user}-digi-boost-6/12mbps"
diginew="vless://${uuid}@172.66.169.187:$none?path=/xvlessntls&encryption=none&type=ws&host=speedtest.net.$dom#${user}-digi-new"

maxisviu="vless://${uuid}@help.viu.com.$dom:$none?path=/xvlessntls&encryption=none&type=ws&host=help.viu.com#${user}-maxis-viu"
maxisfrez="vless://${uuid}@auth.opensignal.com:$xhttp?mode=auto&path=$path/xvless-xhttp-ntls&encryption=none&type=xhttp&host=cdn.opensignal.$dom#${user}-max-frez"

umobile3="vless://${uuid}@172.66.40.170:$none?path=/xvlessntls&encryption=none&type=ws&host=$dom#${user}-umobile-ws"

yes="vless://${uuid}@104.17.147.22:$none?path=/vlessntls&encryption=none&type=ws&host=$dom#${user}-yes-router"
#yes1="vless://${uuid}@eurohealthobservatory.who.int:$none?path=/vlessntlst&encryption=none&type=ws&host=$dom#${user}-yes-hp"

yoodopubg1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=m.pubgmobile.com#${user}-yodoopubg1"
yoodopokemon1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=community.pokemon.com#${user}-yodoopokemon1"

yoodoml1="vless://${uuid}@${MYIP}:$none?path=$path/xvlessntls&encryption=none&type=ws&host=m.mobilelegends.com#${user}-yodooml1"

unifi1="vless://${uuid}@auth.opensignal.com:$none?path=/xvlessntls&encryption=none&type=ws&host=$domain#${user}-unifi-wow"
unifi2="vless://${uuid}@104.17.10.12:$none?path=/xvlessntls&encryption=none&type=ws&host=$domain#${user}-unifi-bebas"

systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp

clear
echo -e ""
echo -e "================================="
echo -e "   XRAY VLESS WS & XTLS       " 
echo -e "================================="
echo -e "Remarks             : ${user}"
echo -e "Expired On          : $exp"
echo -e "IP/Host             : ${MYIP}"
echo -e "Domain              : ${domain}"
echo -e "port TLS            : $tls"
echo -e "port none TLS       : $none"
echo -e "port xhttp none TLS : $xhttp"
echo -e "id                  : ${uuid}"
echo -e "Encryption          : none"
echo -e "network             : ws/httpupgrade/xhttp"
echo -e "path ws             : multipath"
echo -e "path httpupgrade    : /xvless-hup"
echo -e "path xhttp          : /xvless-xhttp-ntls"
echo -e "================================="
echo -e ""
echo -e ""
echo -e " ${bb}═══════════════════════${NC} "
echo -e " \033[30;5;47m ⇱ CONFIG BY LANUN ⇲  \033[m"
echo -e " ${bb}═══════════════════════${NC} "
echo -e ""
echo -e ""
echo -e "${cy}🟡VLESS DIGI BOOSTER 3🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${digiboost}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟡VLESS DIGI BOOSTER 6/12🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${digiboost2}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟡VLESS DIGI TANPA LANGGAN🟡 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${diginew}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🔴VLESS MAXIS-TV🔴 :${NC} "
#echo -e ""
echo -e "\`\`\`"
echo -e "${maxisviu}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🔴VLESS MAXIS-FREZ-XHTTP🔴 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${maxisfrez}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy}🟠VLESS UMOBILE EXP🟠 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${umobile3}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e "================================="
echo -e "${cy} 🟣VLESS YES🟣 :${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${yes}"
echo -e "\`\`\`"
echo -e ""
echo -e ""
echo -e  "================================="
echo -e "${cy} ⚪VLESS UNIFI BEBAS⚪:${NC} "
echo -e ""
echo -e ""
echo -e "\`\`\`"
echo -e "${unifi2}"
echo -e "\`\`\`"
echo -e ""
echo -e "================================="
echo -e ""
echo -e "Remarks             : ${user}"
echo -e "Expired On          : $exp"
echo -e ""
echo -e "================================="
echo -e "ScriptMod By LanunVPN"
read -n 1 -s -r -p "Press any key to back on menu"
clear
menu
}

renew_user() {
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/usr/local/etc/xray/vless.txt")
	if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
		clear
		echo ""
		echo "You have no existing clients!"
		sleep 1
		mxray
	fi

	clear
	echo ""
	echo " Client Vless renew"
	echo " Press CTRL+C to return"
	echo -e "==============================="
	grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 2-3 | nl -s ') '
	until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
		if [[ ${CLIENT_NUMBER} == '1' ]]; then
			read -rp "Select one client [1]: " CLIENT_NUMBER
		else
			read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
		fi
	done
read -p "Expired (Days): " masaaktif

user=$(grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$(($exp2 + $masaaktif))
exp4=`date -d "$exp3 days" +"%Y-%m-%d"`
sed -i "s/### $user $exp/### $user $exp4/g" /usr/local/etc/xray/config.json
sed -i "s/### $user $exp/### $user $exp4/g" /usr/local/etc/xray/none.json
sed -i "s/### $user $exp/### $user $exp4/g" /usr/local/etc/xray/xhttp.json
sed -i "s/### $user $exp/### $user $exp4/g" /usr/local/etc/xray/vless.txt


systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp

clear
echo ""
echo "==============================="
echo "    Vless Account Renewed  "
echo "==============================="
echo " Username  : $user"
echo " Expired   : $exp4"
echo "==============================="
echo -e "ScriptMod By LanunVpn"
read -n 1 -s -r -p "Press any key to back on menu"
 menu
}

del_user() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/usr/local/etc/xray/vless.txt")
	if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
		echo ""
		echo "You have no existing clients!"
		sleep 1
		mxray
	fi

	clear
	echo ""
	echo " Select the existing client you want to remove"
	echo " Press CTRL+C to return"
	echo " ==============================="
	echo "     No  Expired   User"
	grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 2-3 | nl -s ') '
	until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
		if [[ ${CLIENT_NUMBER} == '1' ]]; then
			read -rp "Select one client [1]: " CLIENT_NUMBER
		else
			read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
		fi
	done
user=$(grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
sed -i "/\b$user\b/d" /usr/local/etc/xray/vless.txt
sed -i "/^### $user $exp/,/^},{/d" /usr/local/etc/xray/config.json
sed -i "/^### $user $exp/,/^},{/d" /usr/local/etc/xray/none.json
sed -i "/^### $user $exp/,/^},{/d" /usr/local/etc/xray/xhttp.json
sed -i "/^### $user $exp/,/^},{/d" /usr/local/etc/xray/vless.txt

systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp


clear
echo " Vless Account Deleted Successfully"
echo " =========================="
echo " Client Name : $user"
echo " Expired On  : $exp"
echo " =========================="
echo -e "ScriptMod By LanunVpn"
read -n 1 -s -r -p "Press any key to back on menu"
 menu
}

check_user() {
echo -n > /tmp/other.txt
data=( `cat /usr/local/etc/xray/vless.txt | cut -d ' ' -f 2`);
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \E[0;47;30m     XRAY VLESS USER LOGIN      \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
for akun in "${data[@]}"
do
if [[ -z "$akun" ]]; then
akun="tidakada"
fi
echo -n > /tmp/ipvless.txt
data2=( `cat /var/log/xray/access.log | tail -n 500 | cut -d " " -f 4 | sed 's/tcp://g' | cut -d ":" -f 1 | sort | uniq`);
for ip in "${data2[@]}"
do
jum=$(cat /var/log/xray/access.log | grep -w "$akun" | tail -n 500 | cut -d " " -f 4 | sed 's/tcp://g' | cut -d ":" -f 1 | grep -w "$ip" | sort | uniq)
if [[ "$jum" = "$ip" ]]; then
echo "$jum" >> /tmp/ipvless.txt
else
echo "$ip" >> /tmp/other.txt
fi
jum2=$(cat /tmp/ipvless.txt)
sed -i "/$jum2/d" /tmp/other.txt > /dev/null 2>&1
done
jum=$(cat /tmp/ipvless.txt)
if [[ -z "$jum" ]]; then
echo > /dev/null
else
jum2=$(cat /tmp/ipvless.txt | nl)
echo "User : $akun";
echo "$jum2";
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi
rm -rf /tmp/ipvless.txt
rm -rf /tmp/other.txt
done
echo ""
echo ""
echo -e "ScriptMod By LanunVpn"
read -n 1 -s -r -p "Press any key to back on menu"
 menu
}

recert_xray() {
echo -e "============================================="
echo -e " ${gr} RECERT XRAY${NC}"
echo -e "============================================="
sleep 1
echo start
sleep 0.5
domain=$(cat /etc/xray/domain)
systemctl stop xray
systemctl stop xray@none
systemctl stop xray@xhttp

sudo kill -9 $(sudo lsof -t -i:80)
~/.acme.sh/acme.sh --renew -d $domain --standalone -k ec-256 --force --ecc
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
systemctl daemon-reload
systemctl restart xray
systemctl restart xray@none
systemctl restart xray@xhttp

echo Done
sleep 0.5
clear
echo -e "============================================="
echo -e " ${gr} RECERT DOMAIN SELESAI${NC}"
echo -e "============================================="
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
 menu
}

user_list() {
	NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/usr/local/etc/xray/vless.txt")
        if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
                clear
                echo ""
                echo "You have no existing clients!"
                sleep 1
        fi

        clear
        echo -e "==============================="
        echo " VLESS USER LIST"
        echo -e "==============================="
        echo ""
        grep -E "^### " "/usr/local/etc/xray/vless.txt" | cut -d ' ' -f 2-4 | nl -s ') '
        echo " "
read -n 1 -s -r -p "Press any key to back on menu"
clear
menu
}

status="$(systemctl show xray --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
xray_ok=""$gr"ON"$NC""             
else                                                                                    
xray_xok=""$red"OFF"$NC""    
fi 

status="$(systemctl show xray@none --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
none_ok=""$gr"ON"$NC""             
else                                                                                    
none_xok=""$red"OFF"$NC""    
fi 

status="$(systemctl show xray@xhttp --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
xhttp_ok=""$gr"ON"$NC""             
else                                                                                    
xhttp_xok=""$red"OFF"$NC""    
fi 

usrvl="$gr$(grep -o -i "###" /usr/local/etc/xray/vless.txt | wc -l)$NC"


echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  " \033[30;5;47m                      ⇱ MENU XRAY VLESS ⇲                        \033[m"       
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} " 
echo -e  " "   "" ${cy}XRAY : ${NC}" $xray_ok $xray_xok" ${cy}XRAY NONE : ${NC}" $none_ok $none_xok" ${cy}XRAY XHTTP : ${NC}" $xhttp_ok $xhttp_xok" ${cy}TOTAL USER : ${NC}" $usrvl"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} "       
echo -e  " ${bb}[ 01 ]${NC} CREATE NEW USER            ${bb}[ 05 ]${NC}"" CHECK USER LOGIN"
echo -e  " ${bb}[ 02 ]${NC} CREATE TRIAL USER          ${bb}[ 06 ]${NC}"" LIST USER"
echo -e  " ${bb}[ 03 ]${NC} EXTEND ACCOUNT ACTIVE      ${bb}[ 07 ]${NC}"" RENEW XRAY CERTIFICATION"
echo -e  " ${bb}[ 04 ]${NC} DELETE ACTIVE USER         ${bb}[ 08 ]${NC}"" CHANGE PORT XRAY"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}" 
echo -e  " ${bb}[  0 ]${NC}" "${cy}EXIT TO MENU${NC}  "
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  "  "
echo -e "\e[1;31m"
read -p  "     Please select an option :  " mx
echo -e "\e[0m"
 case $mx in
  1)
	clear ; add_user
  ;;
  2)
    clear ; trial_user
  ;;
  3)
    clear ; renew_user
  ;;
  4)
    clear ; del_user
  ;;
  5)
    clear ; check_user
  ;;
  6)
    clear ; user_list
  ;;  
  7)
    clear ; recert_xray
  ;;
  8)
   clear ; mport-xray
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
  mxray
  ;;
  esac
