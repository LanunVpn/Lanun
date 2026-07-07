#!/bin/bash
clear
red='\e[1;31m'
gr='\e[0;32m'
blue='\e[0;34m'
bb='\e[0;94m'
cy='\033[0;36m'
NC='\e[0m'
clear
MYIP=$(wget -qO- icanhazip.com);
domain=$(cat /etc/xray/domain)
clear

usernew() {
clear
read -p "Username : " Login
read -p "Password : " Pass
read -p "Expired (hari): " masaaktif

IP=$(wget -qO- icanhazip.com);
sleep 1
echo Ping Host
echo Cek Hak Akses...
sleep 0.5
echo Permission Accepted
clear
sleep 0.5
echo Membuat Akun: $Login
sleep 0.5
echo Setting Password: $Pass
sleep 0.5
clear
useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
exp="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
echo -e ""
echo -e "Thank You For Using Our Services"
echo -e "SSH & OpenVPN Account Info"
echo -e "==============================="
echo -e "Username            : $Login "
echo -e "Password            : $Pass"
echo -e "Expired On          : $exp"
echo -e "==============================="
echo -e "Domain              : ${domain}"
echo -e "IP/Host             : $MYIP"
echo -e "OpenSSH             : 22"
echo -e "Dropbear            : 109, 143"
echo -e "SSL/TLS             : 444, 777"
echo -e "Port SSH WS HTTP    : 8880"
echo -e "badvpn              : 7100-7300"
echo -e "==============================="
echo -e "PAYLOAD SSH WS HTTP : GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "==============================="
echo -e "Script Mod By LanunVpn"
read -n 1 -s -r -p "Press any key to back on menu"
menu  
}

trial() {
clear
Login=trial`</dev/urandom tr -dc X-Z0-9 | head -c4`
hari="1"
Pass=1
echo Ping Host
echo Cek Hak Akses...
sleep 0.5
echo Permission Accepted
clear
sleep 0.5
echo Membuat Akun: $Login
sleep 0.5
echo Setting Password: $Pass
sleep 0.5
clear
useradd -e `date -d "$hari days" +"%Y-%m-%d"` -s /bin/false -M $Login
exp="$(chage -l $Login | grep "Account expires" | awk -F": " '{print $2}')"
echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null
echo -e ""
echo -e "Thank You For Using Our Services"
echo -e "SSH & OpenVPN Account Info"
echo -e "==============================="
echo -e "Username            : $Login "
echo -e "Password            : $Pass"
echo -e "Expired On          : $exp"
echo -e "==============================="
echo -e "Domain              : ${domain}"
echo -e "IP/Host             : $MYIP"
echo -e "OpenSSH             : 22"
echo -e "Dropbear            : 109, 143"
echo -e "SSL/TLS             : 444, 777"
echo -e "Port SSH WS HTTP    : 8880"
echo -e "badvpn              : 7100-7300"
echo -e "==============================="
echo -e "PAYLOAD SSH WS HTTP : GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]"
echo -e "==============================="
echo -e "Script Mod By LanunVpn"
read -n 1 -s -r -p "Press any key to back on menu"
menu  
}

renew() {
clear
read -p "         Username       :  " User
egrep "^$User" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
read -p "         Day Extend     :  " Days
Today=`date +%s`
Days_Detailed=$(( $Days * 86400 ))
Expire_On=$(($Today + $Days_Detailed))
Expiration=$(date -u --date="1970-01-01 $Expire_On sec GMT" +%Y/%m/%d)
Expiration_Display=$(date -u --date="1970-01-01 $Expire_On sec GMT" '+%d %b %Y')
passwd -u $User
usermod -e  $Expiration $User
egrep "^$User" /etc/passwd >/dev/null
echo -e "$Pass\n$Pass\n"|passwd $User &> /dev/null
clear
echo -e ""
echo -e "========================================"
echo -e ""
echo -e "    Username        :  $User"
echo -e "    Expires on      :  $Expiration_Display"
echo -e "    Days Added      :  $Days Days"
echo -e ""
echo -e "========================================"
else
clear
echo -e ""
echo -e "======================================"
echo -e ""
echo -e "        Username Doesnt Exist        "
echo -e ""
echo -e "======================================"
fi
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

hapus() {
clear
read -p "Username SSH to Delete : " Pengguna

if getent passwd $Pengguna > /dev/null 2>&1; then
        userdel $Pengguna
        echo -e "User $Pengguna was removed."
else
        echo -e "Failure: User $Pengguna Not Exist."
fi
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

cek() {
clear
echo " "
echo " "

if [ -e "/var/log/auth.log" ]; then
        LOG="/var/log/auth.log";
fi
if [ -e "/var/log/secure" ]; then
        LOG="/var/log/secure";
fi
                
data=( `ps aux | grep -i dropbear | awk '{print $2}'`);
echo "-----=[ Dropbear User Login ]=-----";
echo "ID  |  Username  |  IP Address";
echo "-------------------------------------";
cat $LOG | grep -i dropbear | grep -i "Password auth succeeded" > /tmp/login-db.txt;
for PID in "${data[@]}"
do
        cat /tmp/login-db.txt | grep "dropbear\[$PID\]" > /tmp/login-db-pid.txt;
        NUM=`cat /tmp/login-db-pid.txt | wc -l`;
        USER=`cat /tmp/login-db-pid.txt | awk '{print $10}'`;
        IP=`cat /tmp/login-db-pid.txt | awk '{print $12}'`;
        if [ $NUM -eq 1 ]; then
                echo "$PID - $USER - $IP";
                fi
done
echo " "
echo "-----=[ OpenSSH User Login ]=-----";
echo "ID  |  Username  |  IP Address";
echo "-------------------------------------";
cat $LOG | grep -i sshd | grep -i "Accepted password for" > /tmp/login-db.txt
data=( `ps aux | grep "\[priv\]" | sort -k 72 | awk '{print $2}'`);

for PID in "${data[@]}"
do
        cat /tmp/login-db.txt | grep "sshd\[$PID\]" > /tmp/login-db-pid.txt;
        NUM=`cat /tmp/login-db-pid.txt | wc -l`;
        USER=`cat /tmp/login-db-pid.txt | awk '{print $9}'`;
        IP=`cat /tmp/login-db-pid.txt | awk '{print $11}'`;
        if [ $NUM -eq 1 ]; then
                echo "$PID - $USER - $IP";
        fi
done
if [ -f "/etc/openvpn/server/openvpn-tcp.log" ]; then
        echo " "
        echo "-----=[ OpenVPN TCP User Login ]=-----";
        echo "Username  |  IP Address  |  Connected Since";
        echo "-------------------------------------";
        cat /etc/openvpn/server/openvpn-tcp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-tcp.txt
        cat /tmp/vpn-login-tcp.txt
fi
echo "-------------------------------------"

if [ -f "/etc/openvpn/server/openvpn-udp.log" ]; then
        echo " "
        echo "-----=[ OpenVPN UDP User Login ]=-----";
        echo "Username  |  IP Address  |  Connected Since";
        echo "-------------------------------------";
        cat /etc/openvpn/server/openvpn-udp.log | grep -w "^CLIENT_LIST" | cut -d ',' -f 2,3,8 | sed -e 's/,/      /g' > /tmp/vpn-login-udp.txt
        cat /tmp/vpn-login-udp.txt
fi
echo "-------------------------------------"
echo "";
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

member() {
clear
echo "---------------------------------------------------"
echo "USERNAME          EXP DATE          STATUS"
echo "---------------------------------------------------"
while read expired
do
AKUN="$(echo $expired | cut -d: -f1)"
ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
status="$(passwd -S $AKUN | awk '{print $2}' )"
if [[ $ID -ge 1000 ]]; then
if [[ "$status" = "L" ]]; then
printf "%-17s %2s %-17s %2s \n" "$AKUN" "$exp     " "${RED}LOCKED${NORMAL}"
else
printf "%-17s %2s %-17s %2s \n" "$AKUN" "$exp     " "${GREEN}UNLOCKED${NORMAL}"
fi
fi
done < /etc/passwd
JUMLAH="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
echo "---------------------------------------------------"
echo "Account number: $JUMLAH user"
echo "---------------------------------------------------"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

autokill() {
clear
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[ON]${Font_color_suffix}"
Error="${Red_font_prefix}[OFF]${Font_color_suffix}"
cek=$(grep -c -E "^# Autokill" /etc/cron.d/tendang)
if [[ "$cek" = "1" ]]; then
sts="${Info}"
else
sts="${Error}"
fi
clear
echo -e ""
echo -e "======================================"
echo -e ""
echo -e "     Status Autokill $sts        "
echo -e ""
echo -e "     [1]  AutoKill After 5 Minutes"
echo -e "     [2]  AutoKill After 10 Minutes"
echo -e "     [3]  AutoKill After 15 Minutes"
echo -e "     [4]  Turn Off AutoKill/MultiLogin"
echo -e "     [0]  Exit To Menu"
echo -e "======================================"                                                                                                          
echo -e ""
read -p "     Select From Options [1-4 or x] :  " AutoKill
read -p "     Multilogin Maximum Number Of Allowed: " max
echo -e ""
case $AutoKill in
                1)
                echo -e ""
                sleep 1
                clear
                echo > /etc/cron.d/tendang
                echo "# Autokill" >>/etc/cron.d/tendang
                echo "*/5 * * * *  root /usr/bin/tendang $max" >>/etc/cron.d/tendang
                echo -e ""
                echo -e "======================================"
                echo -e ""
                echo -e "      Allowed MultiLogin : $max"
                echo -e "      AutoKill Every     : 5 Minutes"      
                echo -e ""
                echo -e "======================================"                                                                                           
                ;;
                2)
                echo -e ""
                sleep 1
                clear
                echo > /etc/cron.d/tendang
                echo "# Autokill" >>/etc/cron.d/tendang
                echo "*/10 * * * *  root /usr/bin/tendang $max" >>/etc/cron.d/tendang
                echo -e ""
                echo -e "======================================"
                echo -e ""
                echo -e "      Allowed MultiLogin : $max"
                echo -e "      AutoKill Every     : 10 Minutes"
                echo -e ""
                echo -e "======================================"
                ;;
                3)
                echo -e ""
                sleep 1
                clear
                echo > /etc/cron.d/tendang
                echo "# Autokill" >>/etc/cron.d/tendang
                echo "*/15 * * * *  root /usr/bin/tendang $max" >>/etc/cron.d/tendang
                echo -e ""
                echo -e "======================================"
                echo -e ""
                echo -e "      Allowed MultiLogin : $max"
                echo -e "      AutoKill Every     : 15 Minutes"
                echo -e ""
                echo -e "======================================"
                ;;
                4)
                clear
                echo > /etc/cron.d/tendang
                echo -e ""
                echo -e "======================================"
                echo -e ""
                echo -e "      AutoKill MultiLogin Turned Off  "
                echo -e ""
                echo -e "======================================"
                ;;
                0)
                menu
                clear
                ;;
        esac
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

ceklim() {
clear
echo " "
echo "===========================================";
echo " ";
if [ -e "/root/log-limit.txt" ]; then
echo "User Who Violate The Maximum Limit";
echo "Time - Username - Number of Multilogin"
echo "-------------------------------------";
cat /root/log-limit.txt
else
echo " No user has committed a violation"
echo " "
echo " or"
echo " "
echo " The user-limit script not been executed."
fi
echo " ";
echo "===========================================";
echo " ";
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

status="$(systemctl show ssh --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
ssh_ok=""$gr"ON"$NC""             
else                                                                                    
ssh_xok=""$red"OFF"$NC""    
fi 

status="$(systemctl show ws-http.service --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
sshws_ok=""$gr"ON"$NC""             
else                                                                                    
sshws_xok=""$red"OFF"$NC""    
fi 


usrovpn="$gr$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)$NC"

clear
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  " \033[30;5;47m                         ⇱ MENU SSH ⇲                         \033[m"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC} "
echo -e  " "   "" ${cy}SSH : ${NC}" $ssh_ok $ssh_xok" ${cy}SSHWS : ${NC}" $sshws_ok $sshws_xok" ${cy}TOTAL USER : ${NC}" $usrovpn"
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  " ${bb}[ 01 ]${NC} CREATE NEW USER            ${bb}[ 06 ]${NC} LIST USER INFORMATION"
echo -e  " ${bb}[ 02 ]${NC} CREATE TRIAL USER          ${bb}[ 07 ]${NC} SET AUTO KILL LOGIN"
echo -e  " ${bb}[ 03 ]${NC} EXTEND ACCOUNT ACTIVE      ${bb}[ 08 ]${NC} DISPLAY USER MULTILOGIN"
echo -e  " ${bb}[ 04 ]${NC} DELETE ACTIVE USER         ${bb}[ 09 ]${NC} INSTALL SSHWS"
echo -e  " ${bb}[ 05 ]${NC} CHECK USER LOGIN"         
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}" 
echo -e  " ${bb}[  0 ]${NC}" "${cy}EXIT TO MENU${NC}  "
echo -e  " ${bb}═════════════════════════════════════════════════════════════════${NC}"
echo -e  "  "
echo -e "\e[1;31m"
read -p  "     Please select an option :  " mss
echo -e "\e[0m"
 case $mss in
  1)
  clear ; usernew
  ;;
  2)
  clear ; trial 
  ;;
  3)
  clear ; renew
  ;;
  4)
  clear ; hapus
  ;;
  5)
  clear ; cek
  ;;
  6)
  clear ; member
  ;;
  7)
  clear ; autokill
  ;;
  8)
  clear ; ceklim
  ;;
  9)
  clear ; ./install_ws_http.sh install
  ;;
  0)
  sleep 0.5
  clear
  menu
  exit
  ;;
  *)
  echo -e "ERROR!! Please Enter an Correct Number"
  sleep 1
  clear
  mssh
  ;;
  esac
