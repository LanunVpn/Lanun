#!/usr/bin/env bash
# ========================================================
# Project: Lanun-script
# File: quota-vless.sh – Quota enforcement daemon
# Description: Every 30s accumulates xray stats uplink+downlink
#   via xray api stats, stores in /etc/xray/usage/quota/vless/<user>
#   suspends when quota exceeded
# Adapted from risqinf/autoscript (flat-file)
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
touch "${LANUN_LIMIT_LOG}" 2>/dev/null || true

while true; do
  sleep 30
  for user in $(lanun_list_vless_users 2>/dev/null); do
    [[ -z "$user" ]] && continue
    lanun_is_suspended "vless" "$user" && continue

    quota=$(lanun_get_quota "vless" "$user")
    [[ "$quota" =~ ^[0-9]+$ ]] || quota=0
    # Unlimited users still accounted
    delta=$(lanun_xray_user_bytes "$user" reset)
    [[ "$delta" =~ ^[0-9]+$ ]] || delta=0

    if (( delta > 0 )); then
      lanun_add_usage "vless" "$user" "$delta"
    fi

    used=$(lanun_get_usage "vless" "$user")
    [[ "$used" =~ ^[0-9]+$ ]] || used=0

    # Enforce only when finite quota
    if (( quota > 0 )) && (( used >= quota )); then
      echo "$(date '+%Y-%m-%d %H:%M:%S') [VLESS QUOTA] $user $(lanun_human_bytes $used)/$(lanun_human_bytes $quota) -> SUSPEND" | tee -a "${LANUN_LIMIT_LOG}"
      lanun_suspend_vless "$user" "quota"
    fi
  done
done
