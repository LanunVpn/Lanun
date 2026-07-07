#!/bin/bash
#
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
# ==================================================

# // initializing var
export DEBIAN_FRONTEND=noninteractive
MYIP=$(wget -qO- ipinfo.io/ip);
MYIP2="s/xxxxxxxxx/$MYIP/g";
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

# // Domain
domain=$(cat /root/domain)
websc=https://raw.githubusercontent.com/LanunVpn/Lanun/main

# // detail nama perusahaan
country=MY
state=Malaysia
locality=Malaysia
organization=lanun
organizationalunit=lanun
commonname=lanun.xyz
email=lanunvpn@gmail.com

# // simple password minimal
wget -O /etc/pam.d/common-password "${websc}/script/ssh/password"
chmod +x /etc/pam.d/common-password

# // go to root
cd

# // Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# // nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# // Ubah izin akses
chmod +x /etc/rc.local

# // enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# // disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# // update
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y

# // Install Requirements Tools
apt install ruby -y
apt install python -y
apt install make -y
apt install cmake -y
apt install coreutils -y
apt install rsyslog -y
apt install net-tools -y
apt install zip -y
apt install unzip -y
apt install nano -y
apt install sed -y
apt install gnupg -y
apt install gnupg1 -y
apt install bc -y
apt install jq -y
apt install apt-transport-https -y
apt install build-essential -y
apt install dirmngr -y
apt install libxml-parser-perl -y
apt install git -y
apt install lsof -y
apt install libsqlite3-dev -y
apt install libz-dev -y
apt install gcc -y
apt install g++ -y
apt install libreadline-dev -y
apt install zlib1g-dev -y
apt install libssl-dev -y
apt install libssl1.0-dev -y
apt install dos2unix -y
apt install pwgen openssl netcat cron -y
apt install socat -y
apt install htop -y
apt install iftop -y
echo "clear" >> .profile
echo "menu" >> .profile

# // set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime
date

ufw disable

# / / Make Main Directory
mkdir -p /usr/local/etc/xray/
touch /usr/local/etc/xray/vless.txt


# Generate certificates
mkdir /root/.acme.sh
curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /usr/local/etc/xray/xray.crt --keypath /usr/local/etc/xray/xray.key --ecc
cd
sleep 1
clear

# // install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "${websc}/script/sshovpn/badvpn-udpgw64"
chmod +x /usr/bin/badvpn-udpgw
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500' /etc/rc.local
sed -i '$ i\screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500' /etc/rc.local
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7100 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7200 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7400 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7500 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7600 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7700 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7800 --max-clients 500
screen -dmS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7900 --max-clients 500


# // setting port ssh
cat > /etc/ssh/sshd_config <<EOF
# =========================================
# Minimal & Safe SSHD Configuration
# =========================================

# Ports
Port 22
Port 2222

# Authentication
PermitRootLogin yes
PasswordAuthentication yes
PermitEmptyPasswords no
PubkeyAuthentication yes

# Connection Settings
AllowTcpForwarding yes
PermitTTY yes
X11Forwarding no
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10
MaxStartups 10:30:100
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Security & Performance
UsePAM yes
ChallengeResponseAuthentication no
UseDNS no
Compression delayed
GSSAPIAuthentication no

# Logging
SyslogFacility AUTH
LogLevel INFO
EOF

# // install dropbear
apt -y install dropbear
cat > /etc/default/dropbear <<EOF
# Dropbear configuration
NO_START=0
DROPBEAR_PORT=110
DROPBEAR_EXTRA_ARGS="-p 109"
EOF
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
/etc/init.d/dropbear restart

# // install squid
cd


# // Setting Vnstat
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6

# // install stunnel
apt install stunnel4 -y

cat > /etc/stunnel/stunnel.conf <<-END
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 444
connect = 127.0.0.1:110

[ssh-tls]
accept = 777
connect = 127.0.0.1:22


END

# // make a certificate
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1095 \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"
cat key.pem cert.pem >> /etc/stunnel/stunnel.pem

# // konfigurasi stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
/etc/init.d/stunnel4 restart

#sshws
apt -y install tmux
gem install lolcat
apt -y install figlet


# // install fail2ban
apt install -y dnsutils tcpdump dsniff grepcidr
apt -y install fail2ban



# banner /etc/issue.net
wget -O /etc/issue.net "${websc}/script/ssh/issue.net"
echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear


# // download script
cd /usr/local/bin

# // menu ssh-ovpn
wget -O mssh "${websc}/script/menu/mssh.sh"
wget -O delete "${websc}/script/menu/delete.sh" 
# // menu system
wget -O add-host "${websc}/script/menu/add-host.sh"
wget -O speedtest "${websc}/script/menu/speedtest_cli.py"
wget -O restart-service "${websc}/script/menu/restart-service.sh"
wget -O ram "${websc}/script/menu/ram.sh"
wget -O info "${websc}/script/menu/info.sh"
wget -O nf "${websc}/script/menu/nf.sh"
wget -O mdns "${websc}/script/menu/mdns.sh"
wget -O status "${websc}/script/menu/status.sh"
wget -O update "${websc}/script/menu/update.sh"


# menu
wget -O menu "${websc}/script/menu/menu.sh"
wget -O mwarp "${websc}/script/menu/mwarp.sh"


# // xpired
wget -O clear-log "${websc}/script/menu/clear-log.sh"
wget -O clearcache "${websc}/script/menu/clearcache.sh"

chmod +x mssh
chmod +x delete
chmod +x add-host
chmod +x speedtest
chmod +x restart-service
chmod +x ram
chmod +x info
chmod +x nf
chmod +x mdns
chmod +x status
chmod +x update
chmod +x menu
chmod +x mwarp

chmod +x clear-log
chmod +x clearcache


cd
rm -f /etc/crontab
touch /etc/crontab
echo "SHELL=/bin/sh" >> /etc/crontab
echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> /etc/crontab
echo "0 */08 * * * root /usr/local/bin/clear-log # clear log every 8 hours" >> /etc/crontab
echo "0 */08 * * * root /usr/local/bin/clearcache  # clear cache every 1hours daily" >> /etc/crontab
echo "0 8 * * * root /usr/local/bin/delete # delete expired user" >> /etc/crontab
echo "0 0 * * * root /usr/local/bin/delexp # delete expired user" >> /etc/crontab
echo "0 5 * * * root reboot" >> /etc/crontab


# // remove unnecessary files
cd
apt autoclean -y
apt -y remove --purge unscd
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove bind9*;
apt-get -y remove sendmail*
apt autoremove -y

history -c
cd
rm -f /root/key.pem
rm -f /root/cert.pem
rm -f /root/ssh-vpn.sh

# // finihsing
clear
echo -e "${RED}SSH-VPN INSTALL DONE${NC} "
sleep 2