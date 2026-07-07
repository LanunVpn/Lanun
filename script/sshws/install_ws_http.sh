#!/bin/bash
# Installer for Python Proxy Mod by JinGGO – Debian 13

SCRIPT_PATH="/usr/local/bin/ws-http"
SERVICE_PATH="/etc/systemd/system/ws-http.service"

# --- Uninstall Mode ---
if [[ "$1" == "uninstall" ]]; then
    echo "[+] Stopping service..."
    systemctl stop ws-http.service 2>/dev/null

    echo "[+] Disabling service..."
    systemctl disable ws-http.service 2>/dev/null

    echo "[+] Removing service file..."
    rm -f "$SERVICE_PATH"

    echo "[+] Removing program..."
    rm -f "$SCRIPT_PATH"

    systemctl daemon-reload
    echo "[+] Uninstallation completed!"
    exit 0
fi

# --- Install Mode ---
clear
echo "=============================================="
echo "   Python WS-HTTP Proxy Installer (Debian 13) "
echo "             Script By JinGGO                "
echo "=============================================="
echo ""

read -p "Enter listening port (default: 8880): " PORT
PORT=${PORT:-8880}

echo "[+] Updating system..."
apt update -y

echo "[+] Installing Python3..."
apt install -y python3 python3-pip

echo "[+] Installing required Python modules..."
pip3 install --upgrade pip >/dev/null 2>&1

echo "[+] Cleaning old installation..."
systemctl stop ws-http.service 2>/dev/null
systemctl disable ws-http.service 2>/dev/null
rm -f "$SERVICE_PATH"
rm -f "$SCRIPT_PATH"

echo "[+] Creating program file..."
cat > $SCRIPT_PATH << 'EOF'
#!/usr/bin/env python3
import socket, threading, select, sys, time

LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80

PASS = ''
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:109'
RESPONSE = (
    'HTTP/1.1 101 <b><u><font color="purple">(HTTP) Script By JinGGO</font></b>\r\n'
    'Content-Length: 104857600000\r\n\r\n'
)

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.lock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, int(self.port)))
        self.soc.listen(100)
        self.running = True

        while self.running:
            try:
                client, addr = self.soc.accept()
                client.setblocking(1)
                conn = ConnectionHandler(client, self, addr)
                conn.start()
                with self.lock:
                    self.threads.append(conn)
            except socket.timeout:
                continue

        self.soc.close()

    def close(self):
        self.running = False
        with self.lock:
            for c in self.threads:
                c.close()

class ConnectionHandler(threading.Thread):
    def __init__(self, client, server, addr):
        threading.Thread.__init__(self)
        self.client = client
        self.server = server
        self.addr = addr
        self.log = f"Connection: {addr}"
        self.client_buffer = b''
        self.target = None

    def close(self):
        try: self.client.close()
        except: pass
        if self.target:
            try: self.target.close()
            except: pass

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)

            hostPort = self.find_header(self.client_buffer, b'X-Real-Host')
            if not hostPort:
                hostPort = DEFAULT_HOST

            self.method_CONNECT(hostPort)

        except Exception as e:
            print(self.log, "- error:", e)
        finally:
            self.close()

    def find_header(self, data, header):
        try:
            start = data.find(header + b': ')
            if start == -1:
                return ''
            start = data.find(b':', start) + 2
            end = data.find(b'\r\n', start)
            return data[start:end].decode()
        except:
            return ''

    def connect_target(self, host):
        if ':' in host:
            h, p = host.split(':', 1)
            port = int(p)
        else:
            h = host
            port = LISTENING_PORT

        self.target = socket.create_connection((h, port))

    def method_CONNECT(self, path):
        print(self.log, "- CONNECT", path)
        self.connect_target(path)
        self.client.sendall(RESPONSE.encode())
        self.forward()

    def forward(self):
        sockets = [self.client, self.target]
        count = 0

        while True:
            count += 1
            try:
                r, _, err = select.select(sockets, [], sockets, 3)
                if err:
                    break
                if r:
                    for s in r:
                        data = s.recv(BUFLEN)
                        if data:
                            (self.target if s is self.client else self.client).sendall(data)
                            count = 0
                        else:
                            return
            except:
                break
            if count >= TIMEOUT:
                break

def main():
    print(f"Listening on {LISTENING_ADDR}:{LISTENING_PORT}")
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    try:
        while True:
            time.sleep(2)
    except KeyboardInterrupt:
        server.close()

if __name__ == "__main__":
    main()
EOF

chmod +x $SCRIPT_PATH

echo "[+] Creating systemd service..."

cat > $SERVICE_PATH << EOF
[Unit]
Description=Python Proxy Mod By JinGGO
After=network.target

[Service]
ExecStart=/usr/bin/python3 $SCRIPT_PATH $PORT
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Reloading systemd..."
systemctl daemon-reload

echo "[+] Enabling service..."
systemctl enable ws-http.service

echo "[+] Starting service..."
systemctl restart ws-http.service

echo ""
echo "=============================================="
echo " Installation Completed!"
echo " Listening Port  : $PORT"
echo " Service Name    : ws-http"
echo " Start Service   : systemctl start ws-http"
echo " Stop Service    : systemctl stop ws-http"
echo " Status Check    : systemctl status ws-http"
echo "=============================================="
echo ""
echo "To uninstall: bash install_ws_http.sh uninstall"
