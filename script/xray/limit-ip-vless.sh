#!/usr/bin/env bash
# ========================================================
# Project: Lanun-script – limit-ip-vless.sh
# With Telegram, archive, rollback safety
# ========================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "/usr/local/etc/xray/lanun-lib.sh" ]]; then
  . "/usr/local/etc/xray/lanun-lib.sh"
elif [[ -f "${SCRIPT_DIR}/lanun-lib.sh" ]]; then
  . "${SCRIPT_DIR}/lanun-lib.sh"
elif [[ -f "/usr/local/bin/lanun-lib.sh" ]]; then
  . "/usr/local/bin/lanun-lib.sh"
else
  echo "[ERROR] lanun-lib.sh not found" >&2; exit 1
fi

lanun_init_dirs
LOG_FILE="${LANUN_XRAY_ACC_LOG}"
VIOLATION_THRESHOLD=3
declare -A strikes

[[ -f "$LOG_FILE" ]] || touch "$LOG_FILE"
touch "${LANUN_LIMIT_LOG}" 2>/dev/null || true

while true; do
  for user in $(lanun_list_vless_users 2>/dev/null); do
    [[ -z "$user" ]] && continue
    lanun_is_suspended "vless" "$user" && continue

    limit=$(lanun_get_limit_ip "vless" "$user")
    limit=$(echo "$limit" | tr -dc '0-9'); [[ -z "$limit" ]] && limit=0
    (( limit <= 0 )) && continue

    nets=$(grep -w "email: $user" "$LOG_FILE" 2>/dev/null | grep "accepted" | tail -n 100 \
      | awk '{
          ip="";
          for(i=1;i<=NF;i++) if($i=="from"){ ip=$(i+1); break }
          if(ip=="") next;
          sub(/:[0-9]+$/, "", ip);
          gsub(/^\[|\]$/, "", ip);
          if(ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/){
            split(ip, o, ".");
            if(length(o)>=3) print o[1]"."o[2]"."o[3]
          }
        }' | sort -u | wc -l)

    nets=$(echo "$nets" | tr -d ' '); [[ "$nets" =~ ^[0-9]+$ ]] || nets=0

    if (( nets > limit )); then
      strikes[$user]=$(( ${strikes[$user]:-0} + 1 ))
      echo "$(date '+%Y-%m-%d %H:%M:%S') [CHECK] $user nets=$nets limit=$limit strike=${strikes[$user]}/${VIOLATION_THRESHOLD}" >> "${LANUN_LIMIT_LOG}"
      if (( ${strikes[$user]} >= VIOLATION_THRESHOLD )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [VLESS IP LIMIT] $user IPs $nets/$limit -> SUSPEND" | tee -a "${LANUN_LIMIT_LOG}"
        # detail arg for telegram
        lanun_suspend_vless "$user" "iplimit" "$nets/$limit"
        unset 'strikes[$user]'
      fi
    else
      unset 'strikes[$user]'
    fi
  done
  sleep 30
done
