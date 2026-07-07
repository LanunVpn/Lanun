#!/bin/bash
clear
red='\e[1;31m'
gr='\e[0;32m'
blue='\e[0;34m'
bb='\e[0;94m'
cy='\033[0;36m'
NC='\e[0m'



warp_list() {
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/usr/local/etc/xray/warp-domain.txt")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo ""
        echo "You have no existing domain!"
        sleep 3
        clear
        mwrap
    fi

    clear
    echo ""
    echo -e " ${cy}LIST DOMAIN BYPASS${NC}"
    echo " ==============================="
    echo -e "     ${bb}NO  DOMAIN${NC}   "
    grep -E "^### " "/usr/local/etc/xray/warp-domain.txt" | cut -d ' ' -f 2 | nl -s ') '
    read -n 1 -s -r -p " Press any key to back on menu warp"
    clear
    mwarp
}

domain_add() {
clear
    echo ""
    echo -e " ${cy}SILA MASUKKAN DOMAIN${NC}"
    echo ""
    read -rp "    Enter your Domain/Host: " -e new_dom
    sed -i '/#warp-domain$/a"'"$new_dom"'",' /usr/local/etc/xray/config.json
    sed -i '/#warp-domain$/a"'"$new_dom"'",' /usr/local/etc/xray/none.json
    sed -i '/#warp-domain$/a"'"$new_dom"'",' /usr/local/etc/xray/xhttp.json


    echo -e "### $new_dom" >> /usr/local/etc/xray/warp-domain.txt

    systemctl restart xray
      systemctl restart xray@none
            systemctl restart xray@xhttp
    clear
    warp_list
}

domain_del() {
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/usr/local/etc/xray/warp-domain.txt")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo ""
        echo "You have no existing domain!"
        sleep 3
        clear
        mwarp
    fi
    clear
    echo ""
    echo -e " ${cy}LIST DOMAIN TO DELETE${NC}"
    echo " ==============================="
    echo -e "     ${bb}NO  DOMAIN${NC}   "
    grep -E "^### " "/usr/local/etc/xray/warp-domain.txt" | cut -d ' ' -f 2 | nl -s ') '
    until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
        if [[ ${CLIENT_NUMBER} == '1' ]]; then
            read -rp "Select domain [1]: " CLIENT_NUMBER
        else
            read -rp "Select domain [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
        fi
    done
del_dom=$(grep -E "^### " "/usr/local/etc/xray/warp-domain.txt" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
sed -i "/\b$del_dom\b/d" /usr/local/etc/xray/warp-domain.txt
sed -i "/\b$del_dom\b/d" /usr/local/etc/xray/config.json
sed -i "/\b$del_dom\b/d" /usr/local/etc/xray/none.json
sed -i "/\b$del_dom\b/d" /usr/local/etc/xray/xhttp.json




systemctl restart xray
systemctl restart xray@none
      systemctl restart xray@xhttp
clear
warp_list
}


WARP_Proxy_Status=$(curl -sx "socks5h://127.0.0.1:40000" https://www.cloudflare.com/cdn-cgi/trace --connect-timeout 2 | grep warp | cut -d= -f2)                     
if [ "${WARP_Proxy_Status}" == "on" ]                                                     
then                                                                                    
warp_ok=""$gr"ON"$NC""             
else                                                                                    
warp_xok=""$red"OFF"$NC""    
fi 

echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  " \033[30;5;47m                      ⇱ SOCKS WRAP MENU ⇲                        \033[m"       
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} " 
echo -e  " "   "" ${cy}WRAP SOCKS STATUS ${NC}" $warp_ok $warp_xok"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} "       
echo -e  " ${bb}[ 01 ]${NC} INSTALL SOCKS WRAP "
echo -e  " ${bb}[ 02 ]${NC} LIST DOMAIN"
echo -e  " ${bb}[ 03 ]${NC} ADD DOMAIN"
echo -e  " ${bb}[ 04 ]${NC} DELETE DOMAIN"
echo -e  " ${bb}[ 05 ]${NC} UNINSTALL SOCKS WARP"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}" 
echo -e  " ${bb}[  0 ]${NC}" "${cy}EXIT TO MENU${NC}  "
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  "  "
echo -e "\e[1;31m"
read -p  "     Please select an option :  " warp
echo -e "\e[0m"
 case $warp in
  1)
	clear ; 
    bash <(curl -sSL https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh) ;
    clear 
    mwarp 
  ;;
  2)
    clear ; warp_list
  ;;
  3)
    clear ; domain_add
  ;;
  4)
    clear ; domain_del
  ;;
  5)
    clear ; 
    warp u
    clear 
    mwarp 
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
  mwarp
  ;;
  esac