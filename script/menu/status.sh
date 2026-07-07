#!/bin/bash                                                                             
clear
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'  


echo -e  "  "
echo -e  " ═══════════════════════════════════════════════════ "
echo -e "\033[30;5;47m                 ⇱  SERVICE STATUS ⇲              \033[m"
echo -e  " ═══════════════════════════════════════════════════ "                            
echo -e  "  "                                                                            
                                                                            

status="$(systemctl show xray --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
echo -e " XRAY               : XRAY >> "$green"ON"$NC""              
else                                                                                       
echo -e " XRAY               : XRAY >> "$red"OFF"$NC""    
fi              

status="$(systemctl show xray@none --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
echo -e " XRAY NONE TLS      : XRAY NONE TLS >> "$green"ON"$NC""              
else                                                                                    
echo -e " XRAY NONE TLS      : XRAY NONE TLS >> "$red"OFF"$NC""    
fi 

status="$(systemctl show xray@xhttp --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
echo -e " XRAY XHTTP         : XRAY XHTTP >> "$green"ON"$NC""              
else                                                                                    
echo -e " XRAY XHTTP         : XRAY XHTTP >> "$red"OFF"$NC""    
fi 

status="$(systemctl show ws-http.service --no-page)"                                 
status_text=$(echo "${status}" | grep 'ActiveState=' | cut -f2 -d=)                     
if [ "${status_text}" == "active" ]                                                     
then                                                                                    
echo -e " SSH WS HTTP        : SSH WS HTTP  >> "$green"ON"$NC""              
else                                                                                    
echo -e " SSH WS HTTP        : SSH WS HTTP  >> "$red"OFF"$NC""    
fi 


echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu