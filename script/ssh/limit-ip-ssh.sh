#!/usr/bin/env bash
# ========================================================
# Project: Lanun-script
# File: limit-ip-ssh.sh – SSH IP-limit enforcement
# Description: One-shot script run by timer (every 2 min)
#   Counts only CURRENTLY LIVE sessions (ss + logs)
#   Kills sessions when distinct live IPs > limit
# Adapted from risqinf/autoscript (flat-file version)
# ========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "/usr/local/etc/xray/lanun-lib.sh" ]]; then
  . "/usr/local/etc/xray/lanun-lib.sh"
elif [[ -f "${SCRIPT_DIR}/../xray/lanun-lib.sh" ]]; then
  . "${SCRIPT_DIR}/../xray/lanun-lib.sh"
elif [[ -f "/usr/local/bin/lanun-lib.sh" ]]; then
  . "/usr/local/bin/lanun-lib.sh"
else
  # Fallback minimal paths
  LANUN_LIMIT_IP_DIR="/usr/local/etc/xray/limit/ip"
  LANUN_SUSP_DIR="/usr/local/etc/xray/suspended"
  LANUN_LIMIT_LOG="/var/log/xray/limit.log"
  lanun_get_limit_ip(){ local f="/usr/local/etc/xray/limit/ip/$1/$2"; [[ -f "$f" ]] && cat "$f" | tr -d ' \n\r' || echo 0; }
fi

# Ensure dirs
mkdir -p "${LANUN_LIMIT_IP_DIR}/ssh" "${LANUN_SUSP_DIR}/ssh" 2>/dev/null
touch "${LANUN_LIMIT_LOG}" 2>/dev/null || true

WSLOG="/var/log/ssh-ws.log"
SECLOG=""
if   [[ -e /var/log/secure ]]; then SECLOG=/var/log/secure
elif [[ -e /var/log/auth.log ]]; then SECLOG=/var/log/auth.log
else
  # No auth log, cannot enforce
  exit 0
fi

# proxy-port -> username
declare -A PORT2USER
while read -r port user; do
  [[ -n "$port" && -n "$user" ]] && PORT2USER[$port]="$user"
done < <(
  awk '
    /dropbear\[/ && /Password auth succeeded/ {
      f=$NF; n=split(f,a,":"); port=a[n]; u="";
      for(i=1;i<=NF;i++){ if($i ~ /^\047.*\047$/){ u=$i; gsub(/\047/,"",u) } }
      if(port ~ /^[0-9]+$/ && u!="") print port, u
    }
    /sshd\[/ && /Accepted / {
      u=""; port="";
      for(i=1;i<=NF;i++){ if($i=="for") u=$(i+1); if($i=="port") port=$(i+1) }
      if(port ~ /^[0-9]+$/ && u!="") print port, u
    }
  ' "$SECLOG" 2>/dev/null
)

# proxy-port -> real client IP (from ssh-ws CONNECT lines)
# Format expected: ... [CONNECT] ... proxy-port:XXXX ... IP:port or similar
declare -A PORT2CIP
if [[ -f "$WSLOG" ]]; then
  while IFS='|' read -r pport cip; do
    [[ -z "$pport" ]] && continue
    cip="${cip%%:*}"
    [[ -n "$cip" ]] && PORT2CIP[$pport]="$cip"
  done < <(
    awk '$3=="[CONNECT]"{ pp=$0; sub(/.*proxy-port:/,"",pp); gsub(/[^0-9]/,"",pp); print pp"|"$5 }' "$WSLOG" 2>/dev/null
  )
fi

# Build per-user set of distinct live client IPs from current TCP connections
declare -A USER_IPS
while read -r pport; do
  [[ -z "$pport" ]] && continue
  u="${PORT2USER[$pport]}"; [[ -z "$u" ]] && continue
  cip="${PORT2CIP[$pport]}"; [[ -z "$cip" ]] && cip="port:$pport"
  case " ${USER_IPS[$u]} " in
    *" $cip "*) ;;
    *) USER_IPS[$u]="${USER_IPS[$u]} $cip" ;;
  esac
done < <(ss -tnH 2>/dev/null | grep '127.0.0.1:109' \
          | grep -oE '127\.0\.0\.1:[0-9]+' | grep -v ':109$' | cut -d: -f2 | sort -u)

# Alternative: if no ssh-ws, also check direct dropbear port 109 connections via ss -tnp?
# Keep simple: also count IPs from SECLOG mapping if ss method not enough – use fallback live PID based
if [[ ${#USER_IPS[@]} -eq 0 ]]; then
  # Fallback: use live PID based auth (similar to old mssh cek)
  # This at least gives username, even if IP not precise
  :
fi

# Enforce
for user in "${!USER_IPS[@]}"; do
  [[ -z "$user" ]] && continue
  limit=$(lanun_get_limit_ip "ssh" "$user")
  limit=$(echo "$limit" | tr -dc '0-9')
  [[ -z "$limit" ]] && limit=0
  (( limit <= 0 )) && continue

  ips="${USER_IPS[$user]}"
  cnt=$(echo "$ips" | tr ' ' '\n' | grep -c '[^[:space:]]')
  (( cnt == 0 )) && continue

  if (( cnt > limit )); then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SSH IP LIMIT] $user IPs $cnt/$limit -> KILL" | tee -a "${LANUN_LIMIT_LOG}"
    pkill -KILL -u "$user" 2>/dev/null
    # Also kill by username for dropbear
    pkill -KILL -f "dropbear.*$user" 2>/dev/null || true
    # Mark suspended? For SSH we just kill; but we can mark for audit
    mkdir -p "${LANUN_SUSP_DIR}/ssh"
    echo "iplimit|$(date +%s)|$cnt/$limit" > "${LANUN_SUSP_DIR}/ssh/$user" 2>/dev/null || true
  fi
done

exit 0
