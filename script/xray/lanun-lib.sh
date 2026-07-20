#!/usr/bin/env bash
# ============================================================
# File: lanun-lib.sh
# Project: Lanun-script
# Purpose: Shared library for limit-ip and limit-quota feature
#
# This library follows flat-file pattern used in Lanun-script
# (compatible with sed marker based config manipulation),
# but adds safety features adapted from autoscript:
#   - telegram notification (optional, silent if not configured)
#   - archive before delete/expire (so limits can be recovered)
#   - config backup and rollback (xray -test validation)
#   - recovery for expired/suspended accounts
#
# Storage layout:
#   /usr/local/etc/xray/limit/ip/<proto>/<user>      -> max ip (number)
#   /usr/local/etc/xray/limit/quota/<proto>/<user>   -> max quota bytes
#   /usr/local/etc/xray/usage/quota/<proto>/<user>   -> used bytes
#   /usr/local/etc/xray/suspended/<proto>/<user>     -> reason|timestamp
#   /usr/local/etc/xray/suspended/<proto>/<user>.rec  -> recovery record
#   /usr/local/etc/xray/archive/<proto>/...          -> archived history
#   /usr/local/etc/xray/expired/...                  -> expired accounts
#   /usr/local/etc/xray/deleted/...                  -> deleted accounts
#   /usr/local/etc/xray/recovery/<proto>/<user>.rec  -> for recovery menu
#   /usr/local/etc/xray/backup/*.bak                 -> config backups
#
# Usage: source this file from other scripts
#   if [[ -f "/usr/local/etc/xray/lanun-lib.sh" ]]; then
#     . "/usr/local/etc/xray/lanun-lib.sh"
#   fi
#   lanun_init_dirs
# ============================================================

# Prevent double sourcing
[[ -n "${__LANUN_LIB_LOADED:-}" ]] && return 0
__LANUN_LIB_LOADED=1

# ---------- Paths ----------
export LANUN_ETC="/usr/local/etc/xray"
export LANUN_LIMIT_IP_DIR="${LANUN_ETC}/limit/ip"
export LANUN_LIMIT_QT_DIR="${LANUN_ETC}/limit/quota"
export LANUN_USAGE_QT_DIR="${LANUN_ETC}/usage/quota"
export LANUN_SUSP_DIR="${LANUN_ETC}/suspended"
export LANUN_ARCHIVE_DIR="${LANUN_ETC}/archive"
export LANUN_EXPIRED_DIR="${LANUN_ETC}/expired"
export LANUN_DELETED_DIR="${LANUN_ETC}/deleted"
export LANUN_RECOVERY_DIR="${LANUN_ETC}/recovery"
export LANUN_BACKUP_DIR="${LANUN_ETC}/backup"
export LANUN_LOG_DIR="/var/log/xray"
export LANUN_XRAY_ACC_LOG="${LANUN_LOG_DIR}/access.log"
export LANUN_VLESS_TXT="${LANUN_ETC}/vless.txt"
export LANUN_LIMIT_LOG="${LANUN_LOG_DIR}/limit.log"
export LANUN_BOTKEY="${LANUN_ETC}/bot.key"
export LANUN_CHATID="${LANUN_ETC}/client.id"

export LANUN_XRAY_BIN="${LANUN_XRAY_BIN:-/usr/local/bin/xray}"
export LANUN_XRAY_API="${LANUN_XRAY_API:-127.0.0.1:10085}"
export LANUN_XRAY_CONFIG="${LANUN_ETC}/config.json"
export LANUN_XRAY_NONE="${LANUN_ETC}/none.json"
export LANUN_XRAY_XHTTP="${LANUN_ETC}/xhttp.json"

# Constants
export LANUN_GB_BYTES=1073741824
export LANUN_STRIKE_THRESHOLD=3

# Colors (reuse so other scripts don't redefine)
export LN_NC='\e[0m'
export LN_RED='\e[0;31m'
export LN_GREEN='\e[0;32m'
export LN_YELLOW='\e[1;33m'
export LN_CYAN='\033[0;36m'

# ---------- Simple log helpers ----------
lanun_err()  { echo -e "${LN_RED}[ERROR]${LN_NC} $1" >&2; }
lanun_ok()   { echo -e "${LN_GREEN}[OK]${LN_NC} $1"; }
lanun_info() { echo -e "${LN_CYAN}[INFO]${LN_NC} $1"; }

# ---------- Init directories ----------
# Creates all required directories, safe to run multiple times
lanun_init_dirs() {
  mkdir -p "${LANUN_LIMIT_IP_DIR}/vless" "${LANUN_LIMIT_IP_DIR}/ssh"
  mkdir -p "${LANUN_LIMIT_QT_DIR}/vless"
  mkdir -p "${LANUN_USAGE_QT_DIR}/vless"
  mkdir -p "${LANUN_SUSP_DIR}/vless" "${LANUN_SUSP_DIR}/ssh"
  mkdir -p "${LANUN_ARCHIVE_DIR}/vless" "${LANUN_ARCHIVE_DIR}/ssh"
  mkdir -p "${LANUN_EXPIRED_DIR}/vless" "${LANUN_EXPIRED_DIR}/ssh"
  mkdir -p "${LANUN_DELETED_DIR}/vless" "${LANUN_DELETED_DIR}/ssh"
  mkdir -p "${LANUN_RECOVERY_DIR}/vless" "${LANUN_RECOVERY_DIR}/ssh"
  mkdir -p "${LANUN_BACKUP_DIR}"
  mkdir -p "${LANUN_LOG_DIR}"
  chmod 700 "${LANUN_ETC}" 2>/dev/null || true
  touch "${LANUN_XRAY_ACC_LOG}" "${LANUN_LIMIT_LOG}" 2>/dev/null || true
  chmod 600 "${LANUN_LIMIT_LOG}" 2>/dev/null || true
}

# ---------- Validation ----------
lanun_valid_username() { [[ "$1" =~ ^[a-zA-Z0-9_]{3,32}$ ]]; }
lanun_valid_number()   { [[ "$1" =~ ^[0-9]+$ ]]; }

# ---------- Telegram ----------
# Check if telegram is configured (both files exist and not empty)
# Returns 0 if configured
lanun_tg_configured() {
  [[ -s "${LANUN_BOTKEY}" && -s "${LANUN_CHATID}" ]]
}

# Send telegram message
# Arguments: $1 = message text (HTML allowed, %0A will be converted to newline)
# Returns 0 on success, 1 if not configured or failed
# Logic: try HTML, handle 429 retry, fallback plain text
lanun_tg_send() {
  local text="$1"
  lanun_tg_configured || return 1

  # Convert %0A to real newline (compatibility with autoscript style)
  text=${text//%0A/$'\n'}

  local token chat resp
  token=$(cat "${LANUN_BOTKEY}" 2>/dev/null)
  chat=$(cat "${LANUN_CHATID}" 2>/dev/null)
  [[ -z "$token" || -z "$chat" ]] && return 1

  # Try HTML parse_mode
  resp=$(curl -s --max-time 20 -X POST "https://api.telegram.org/bot${token}/sendMessage" \
    -d chat_id="${chat}" -d parse_mode="HTML" -d disable_web_page_preview="true" \
    --data-urlencode "text=${text}" 2>/dev/null)

  if [[ "$resp" == *'"ok":true'* ]]; then return 0; fi

  # Handle rate limit
  if [[ "$resp" == *'"error_code":429'* ]]; then
    local wait_sec
    wait_sec=$(echo "$resp" | grep -o '"retry_after":[0-9]\+' | grep -o '[0-9]\+')
    [[ -z "$wait_sec" ]] && wait_sec=2
    sleep "$wait_sec"
    resp=$(curl -s --max-time 20 -X POST "https://api.telegram.org/bot${token}/sendMessage" \
      -d chat_id="${chat}" -d parse_mode="HTML" -d disable_web_page_preview="true" \
      --data-urlencode "text=${text}" 2>/dev/null)
    [[ "$resp" == *'"ok":true'* ]] && return 0
  fi

  # Fallback to plain text (strip HTML tags)
  local plain
  plain=$(echo "$text" | sed -e 's/<[^>]*>//g')
  resp=$(curl -s --max-time 20 -X POST "https://api.telegram.org/bot${token}/sendMessage" \
    -d chat_id="${chat}" -d disable_web_page_preview="true" \
    --data-urlencode "text=${plain}" 2>/dev/null)
  [[ "$resp" == *'"ok":true'* ]]
}

# ---------- Limit-IP helpers ----------
# File format: /etc/xray/limit/ip/<proto>/<user> contains a single number

# Get limit ip for a user
# Args: proto, username
# Returns: number (0 = unlimited)
lanun_get_limit_ip() {
  local proto="$1" user="$2"
  local file="${LANUN_LIMIT_IP_DIR}/${proto}/${user}"
  if [[ -f "$file" ]]; then
    cat "$file" 2>/dev/null | tr -d ' \n\r'
  else
    echo 0
  fi
}

# Set limit ip for a user
lanun_set_limit_ip() {
  local proto="$1" user="$2" limit="$3"
  mkdir -p "${LANUN_LIMIT_IP_DIR}/${proto}"
  echo "$limit" > "${LANUN_LIMIT_IP_DIR}/${proto}/${user}"
  chmod 600 "${LANUN_LIMIT_IP_DIR}/${proto}/${user}" 2>/dev/null || true
}

lanun_del_limit_ip() {
  rm -f "${LANUN_LIMIT_IP_DIR}/$1/$2"
}

# Archive limit-ip file before deleting (keeps history)
lanun_archive_limit_ip() {
  local proto="$1" user="$2" dest="${3:-deleted}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local src="${LANUN_LIMIT_IP_DIR}/${proto}/${user}"
  if [[ -f "$src" ]]; then
    mkdir -p "${LANUN_ETC}/${dest}/ip/${proto}" "${LANUN_ARCHIVE_DIR}/${proto}"
    cp -f "$src" "${LANUN_ETC}/${dest}/ip/${proto}/${user}.${ts}" 2>/dev/null || true
    cp -f "$src" "${LANUN_ARCHIVE_DIR}/${proto}/${user}.ip.${ts}" 2>/dev/null || true
  fi
}

# ---------- Quota helpers ----------
# Quota file contains bytes (not GB)

lanun_get_quota() {
  local proto="$1" user="$2"
  local file="${LANUN_LIMIT_QT_DIR}/${proto}/${user}"
  if [[ -f "$file" ]]; then
    cat "$file" 2>/dev/null | tr -d ' \n\r'
  else
    echo 0
  fi
}

lanun_set_quota_bytes() {
  local proto="$1" user="$2" bytes="$3"
  mkdir -p "${LANUN_LIMIT_QT_DIR}/${proto}"
  echo "$bytes" > "${LANUN_LIMIT_QT_DIR}/${proto}/${user}"
  chmod 600 "${LANUN_LIMIT_QT_DIR}/${proto}/${user}" 2>/dev/null || true
}

# Alias for compatibility
lanun_set_quota() { lanun_set_quota_bytes "$@"; }

lanun_del_quota() {
  rm -f "${LANUN_LIMIT_QT_DIR}/$1/$2"
}

lanun_archive_quota() {
  local proto="$1" user="$2" dest="${3:-deleted}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local src="${LANUN_LIMIT_QT_DIR}/${proto}/${user}"
  if [[ -f "$src" ]]; then
    mkdir -p "${LANUN_ETC}/${dest}/quota/${proto}" "${LANUN_ARCHIVE_DIR}/${proto}"
    cp -f "$src" "${LANUN_ETC}/${dest}/quota/${proto}/${user}.${ts}" 2>/dev/null || true
    cp -f "$src" "${LANUN_ARCHIVE_DIR}/${proto}/${user}.quota.${ts}" 2>/dev/null || true
  fi
}

# ---------- Usage helpers ----------
lanun_get_usage() {
  local proto="$1" user="$2"
  local file="${LANUN_USAGE_QT_DIR}/${proto}/${user}"
  if [[ -f "$file" ]]; then
    cat "$file" 2>/dev/null | tr -d ' \n\r'
  else
    echo 0
  fi
}

lanun_set_usage() {
  mkdir -p "${LANUN_USAGE_QT_DIR}/$1"
  echo "$3" > "${LANUN_USAGE_QT_DIR}/$1/$2"
}

lanun_add_usage() {
  local proto="$1" user="$2" delta="$3"
  local cur
  cur=$(lanun_get_usage "$proto" "$user")
  [[ "$cur" =~ ^[0-9]+$ ]] || cur=0
  [[ "$delta" =~ ^[0-9]+$ ]] || delta=0
  if (( delta > 0 )); then
    lanun_set_usage "$proto" "$user" $(( cur + delta ))
  fi
}

lanun_del_usage() {
  rm -f "${LANUN_USAGE_QT_DIR}/$1/$2"
}

lanun_archive_usage() {
  local proto="$1" user="$2" dest="${3:-deleted}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local src="${LANUN_USAGE_QT_DIR}/${proto}/${user}"
  if [[ -f "$src" ]]; then
    mkdir -p "${LANUN_ETC}/${dest}/usage/${proto}" "${LANUN_ARCHIVE_DIR}/${proto}"
    cp -f "$src" "${LANUN_ETC}/${dest}/usage/${proto}/${user}.${ts}" 2>/dev/null || true
    cp -f "$src" "${LANUN_ARCHIVE_DIR}/${proto}/${user}.usage.${ts}" 2>/dev/null || true
  fi
}

# ---------- Archive full user ----------
# Saves meta file with username, exp, uuid, limit_ip, quota, usage, action, timestamp
# Called before delete/expire/suspend so data can be recovered
lanun_archive_user() {
  local proto="$1" user="$2" action="${3:-deleted}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local arch_base="${LANUN_ARCHIVE_DIR}/${proto}"
  local dest_base="${LANUN_ETC}/${action}"

  mkdir -p "$arch_base" "${dest_base}/ip/${proto}" "${dest_base}/quota/${proto}" \
    "${dest_base}/usage/${proto}" "${dest_base}/meta/${proto}" 2>/dev/null

  local exp uuid lip quota usage
  exp=$(lanun_get_vless_exp "$user" 2>/dev/null || echo "")
  uuid=$(lanun_get_vless_uuid "$user" 2>/dev/null || echo "")
  lip=$(lanun_get_limit_ip "$proto" "$user")
  quota=$(lanun_get_quota "$proto" "$user")
  usage=$(lanun_get_usage "$proto" "$user")

  local meta="username=${user}
proto=${proto}
exp=${exp}
uuid=${uuid}
limit_ip=${lip}
quota_bytes=${quota}
usage_bytes=${usage}
action=${action}
timestamp=${ts}"

  echo "$meta" > "${dest_base}/meta/${proto}/${user}.${ts}"
  echo "$meta" > "${arch_base}/${user}.${action}.${ts}.meta"

  lanun_archive_limit_ip "$proto" "$user" "$action"
  lanun_archive_quota "$proto" "$user" "$action"
  lanun_archive_usage "$proto" "$user" "$action"

  echo "$(date '+%Y-%m-%d %H:%M:%S') ARCHIVE ${proto} ${user} action=${action} ts=${ts}" >> "${LANUN_LIMIT_LOG}" 2>/dev/null || true
}

# ---------- Suspend tracking ----------
lanun_suspend_file() { echo "${LANUN_SUSP_DIR}/$1/$2"; }

lanun_is_suspended() {
  [[ -f "$(lanun_suspend_file "$1" "$2")" ]]
}

lanun_mark_suspended() {
  mkdir -p "${LANUN_SUSP_DIR}/$1"
  echo "$3|$(date +%s)" > "$(lanun_suspend_file "$1" "$2")"
}

lanun_clear_suspended() {
  rm -f "$(lanun_suspend_file "$1" "$2")"
}

lanun_get_suspend_reason() {
  local file
  file="$(lanun_suspend_file "$1" "$2")"
  if [[ -f "$file" ]]; then
    cut -d'|' -f1 "$file"
  else
    echo ""
  fi
}

# ---------- Human readable bytes ----------
lanun_human_bytes() {
  local b="${1:-0}"
  [[ "$b" =~ ^[0-9]+$ ]] || b=0
  if   (( b >= 1099511627776 )); then awk -v x="$b" 'BEGIN{printf "%.2f TB", x/1099511627776}'
  elif (( b >= 1073741824 ));    then awk -v x="$b" 'BEGIN{printf "%.2f GB", x/1073741824}'
  elif (( b >= 1048576 ));       then awk -v x="$b" 'BEGIN{printf "%.2f MB", x/1048576}'
  elif (( b >= 1024 ));          then awk -v x="$b" 'BEGIN{printf "%.2f KB", x/1024}'
  else echo "${b} B"; fi
}

lanun_gb_to_bytes() {
  local gb="$1"
  [[ "$gb" =~ ^[0-9]+$ ]] || gb=0
  echo $(( gb * LANUN_GB_BYTES ))
}

lanun_bytes_to_gb() {
  local bytes="$1"
  [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
  echo $(( bytes / LANUN_GB_BYTES ))
}

# ---------- Xray stats API (for quota) ----------
# Reads traffic counter for a user via xray api stats
# Args: username, [reset] -> if second arg is "reset" counters will be zeroed after read
# Returns: total bytes (uplink+downlink)
lanun_xray_user_bytes() {
  local user="$1" reset="${2:-}"
  local total=0 dir val
  local bin="${LANUN_XRAY_BIN}"
  [[ -x "$bin" ]] || bin="xray"
  local -a rflag=()
  [[ "$reset" == "reset" ]] && rflag=(-reset)

  for dir in uplink downlink; do
    val=$("$bin" api stats --server="${LANUN_XRAY_API}" \
          -name "user>>>${user}>>>traffic>>>${dir}" "${rflag[@]}" 2>/dev/null \
        | grep -w value | awk '{print $2}' | tr -d '", ')
    [[ "$val" =~ ^[0-9]+$ ]] && total=$(( total + val ))
  done
  echo "$total"
}

# ---------- Config backup and validation ----------
# Backs up all 3 xray configs, keeps last 20, returns path to main backup
lanun_config_backup() {
  local ts
  ts=$(date +%s)
  mkdir -p "${LANUN_BACKUP_DIR}"
  cp -f "${LANUN_XRAY_CONFIG}" "${LANUN_BACKUP_DIR}/config.json.${ts}.bak" 2>/dev/null
  cp -f "${LANUN_XRAY_NONE}" "${LANUN_BACKUP_DIR}/none.json.${ts}.bak" 2>/dev/null
  cp -f "${LANUN_XRAY_XHTTP}" "${LANUN_BACKUP_DIR}/xhttp.json.${ts}.bak" 2>/dev/null
  # Prune old backups (keep 20)
  ls -t "${LANUN_BACKUP_DIR}/config.json."*.bak 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
  echo "${LANUN_BACKUP_DIR}/config.json.${ts}.bak"
}

# Test if config is valid
# If config has # markers, skip jq check and rely on xray -test
lanun_xray_test() {
  local cfg="${1:-${LANUN_XRAY_CONFIG}}"
  local bin="${LANUN_XRAY_BIN}"
  [[ -x "$bin" ]] || bin=$(which xray 2>/dev/null || echo "xray")

  if command -v jq >/dev/null 2>&1; then
    if ! grep -qE '^[[:space:]]*#|^###' "$cfg" 2>/dev/null; then
      jq -e . "$cfg" >/dev/null 2>&1 || return 1
    fi
  fi

  if [[ -x "$bin" ]]; then
    "$bin" -test -config "$cfg" >/dev/null 2>&1
  elif command -v xray >/dev/null 2>&1; then
    xray -test -config "$cfg" >/dev/null 2>&1
  else
    return 0
  fi
}

# Rollback config from backup file
lanun_xray_rollback() {
  local bak="$1"
  if [[ -f "$bak" ]]; then
    cp -f "$bak" "${LANUN_XRAY_CONFIG}" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') ROLLBACK config from $bak" >> "${LANUN_LIMIT_LOG}" 2>/dev/null || true
  fi
}

# ---------- Xray config: remove user (with backup + test + rollback) ----------
lanun_xray_remove_user() {
  local user="$1"
  local exp
  exp=$(grep -E "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null | head -1 | awk '{print $3}')
  local bak
  bak=$(lanun_config_backup)

  if [[ -n "$exp" ]]; then
    sed -i "/^### $user $exp/,/^},{/d" "${LANUN_XRAY_CONFIG}" 2>/dev/null || true
    sed -i "/^### $user $exp/,/^},{/d" "${LANUN_XRAY_NONE}" 2>/dev/null || true
    sed -i "/^### $user $exp/,/^},{/d" "${LANUN_XRAY_XHTTP}" 2>/dev/null || true
  fi

  if ! lanun_xray_test "${LANUN_XRAY_CONFIG}"; then
    lanun_err "config invalid after removing $user, rolling back"
    lanun_xray_rollback "$bak"
    return 1
  fi
  return 0
}

# ---------- Internal inject helper ----------
# Inserts user into all 3 xray configs (same markers as mxray.sh)
# Args: user, exp, uuid
_lanun_inject_user() {
  local user="$1" exp="$2" uuid="$3"
  sed -i '/#xray-vless-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_CONFIG}"
  sed -i '/#xray-vless-grpc$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_CONFIG}"
  sed -i '/#xray-vless-xtls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","flow": "xtls-rprx-vision","email": "'""$user""'"' "${LANUN_XRAY_CONFIG}"
  sed -i '/#xray-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_NONE}"
  sed -i '/#xray-vless-nontls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_NONE}"
  sed -i '/#xray-vless-hup$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_NONE}"
  sed -i '/#vless-xhttp-tls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_XHTTP}"
  sed -i '/#vless-xhttp-ntls$/a\### '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' "${LANUN_XRAY_XHTTP}"
}

# ---------- Suspend VLESS ----------
# Archive, remove from config, mark suspended, save recovery record, restart, telegram
lanun_suspend_vless() {
  local user="$1" reason="${2:-limit}" detail="${3:-}"
  local lip quota usage
  lip=$(lanun_get_limit_ip vless "$user")
  quota=$(lanun_get_quota vless "$user")
  usage=$(lanun_get_usage vless "$user")

  lanun_archive_user vless "$user" "suspended"

  if ! lanun_xray_remove_user "$user"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') FAIL SUSPEND vless $user rollback" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
    return 1
  fi

  lanun_mark_suspended vless "$user" "$reason"

  # Save recovery record (so unlock/recover can work)
  local rec
  rec=$(grep -E "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null | head -1)
  if [[ -n "$rec" ]]; then
    mkdir -p "${LANUN_SUSP_DIR}/vless" "${LANUN_RECOVERY_DIR}/vless"
    echo "$rec" > "${LANUN_SUSP_DIR}/vless/${user}.rec"
    {
      echo "$rec"
      echo "limit_ip=${lip}"
      echo "quota=${quota}"
      echo "usage=${usage}"
      echo "reason=${reason}"
      echo "ts=$(date +%s)"
    } > "${LANUN_RECOVERY_DIR}/vless/${user}.rec"
  fi

  systemctl restart xray 2>/dev/null
  systemctl restart xray@none 2>/dev/null
  systemctl restart xray@xhttp 2>/dev/null

  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")

  local msg=""
  case "$reason" in
    iplimit)
      msg="<b>[VLESS IP LIMIT]</b>%0AUsername: <code>${user}</code>%0AIPs: ${detail}%0AQuota: $(lanun_human_bytes ${quota:-0})%0AUsage: $(lanun_human_bytes ${usage:-0})%0ADomain: ${domain}%0AStatus: suspended"
      ;;
    quota)
      msg="<b>[VLESS QUOTA EXCEEDED]</b>%0AUsername: <code>${user}</code>%0AUsage: $(lanun_human_bytes ${usage:-0}) / $(lanun_human_bytes ${quota:-0})%0ADomain: ${domain}%0AStatus: suspended"
      ;;
    *)
      msg="<b>[VLESS SUSPENDED]</b>%0AUsername: <code>${user}</code>%0AReason: ${reason}%0ADomain: ${domain}"
      ;;
  esac

  echo "$(date '+%Y-%m-%d %H:%M:%S') SUSPEND vless $user reason=$reason $detail" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
  lanun_tg_send "$msg" 2>/dev/null || true
}

# ---------- Recover suspended ----------
lanun_recover_vless() {
  local user="$1" exp="$2" uuid="$3"

  if [[ -z "$exp" || -z "$uuid" ]]; then
    local recf="${LANUN_SUSP_DIR}/vless/${user}.rec"
    local recf2="${LANUN_RECOVERY_DIR}/vless/${user}.rec"
    local rec=""
    [[ -f "$recf" ]] && rec=$(grep "^###" "$recf" | head -1)
    [[ -z "$rec" && -f "$recf2" ]] && rec=$(grep "^###" "$recf2" | head -1)
    [[ -z "$rec" ]] && rec=$(grep -E "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null | head -1)
    exp=$(echo "$rec" | awk '{print $3}')
    uuid=$(echo "$rec" | awk '{print $4}')
  fi

  if [[ -z "$user" || -z "$exp" || -z "$uuid" ]]; then
    lanun_err "recover requires user exp uuid"
    return 1
  fi

  if grep -q "\"email\": *\"$user\"" "${LANUN_XRAY_CONFIG}" 2>/dev/null; then
    lanun_err "user $user already in config"
    return 1
  fi

  local bak
  bak=$(lanun_config_backup)

  _lanun_inject_user "$user" "$exp" "$uuid"

  if ! lanun_xray_test "${LANUN_XRAY_CONFIG}"; then
    lanun_err "xray test failed after recover $user, rollback"
    lanun_xray_rollback "$bak"
    return 1
  fi

  if ! grep -q "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null; then
    echo "### $user $exp $uuid" >> "${LANUN_VLESS_TXT}"
  fi

  lanun_clear_suspended vless "$user"
  rm -f "${LANUN_SUSP_DIR}/vless/${user}.rec"

  systemctl restart xray 2>/dev/null
  systemctl restart xray@none 2>/dev/null
  systemctl restart xray@xhttp 2>/dev/null

  echo "$(date '+%Y-%m-%d %H:%M:%S') RECOVER vless $user" >> "${LANUN_LIMIT_LOG}" 2>/dev/null

  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[VLESS RECOVERED]</b>%0AUsername: <code>${user}</code>%0AExpired: ${exp}%0ADomain: ${domain}%0AStatus: active" 2>/dev/null || true
}

# ---------- Delete with archive and telegram ----------
lanun_delete_vless() {
  local user="$1"
  lanun_archive_user vless "$user" "deleted"
  lanun_xray_remove_user "$user" || true

  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  for f in "${LANUN_LIMIT_IP_DIR}/vless/${user}" "${LANUN_LIMIT_QT_DIR}/vless/${user}" "${LANUN_USAGE_QT_DIR}/vless/${user}"; do
    if [[ -f "$f" ]]; then
      cp -f "$f" "${LANUN_ARCHIVE_DIR}/vless/${user}.$(basename "$(dirname "$f")").${ts}" 2>/dev/null || true
    fi
  done

  rm -f "${LANUN_LIMIT_IP_DIR}/vless/${user}" "${LANUN_LIMIT_QT_DIR}/vless/${user}" "${LANUN_USAGE_QT_DIR}/vless/${user}"
  rm -f "${LANUN_SUSP_DIR}/vless/${user}" "${LANUN_SUSP_DIR}/vless/${user}.rec"

  systemctl restart xray 2>/dev/null
  systemctl restart xray@none 2>/dev/null
  systemctl restart xray@xhttp 2>/dev/null

  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[VLESS DELETED]</b>%0AUsername: <code>${user}</code>%0ADomain: ${domain}" 2>/dev/null || true
  echo "$(date '+%Y-%m-%d %H:%M:%S') DELETE vless $user" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
}

# ---------- Expire handling ----------
lanun_expire_vless() {
  local user="$1" exp="$2"
  lanun_archive_user vless "$user" "expired"
  lanun_xray_remove_user "$user" || true

  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  mkdir -p "${LANUN_EXPIRED_DIR}/vless"

  for f in "${LANUN_LIMIT_IP_DIR}/vless/${user}" "${LANUN_LIMIT_QT_DIR}/vless/${user}" "${LANUN_USAGE_QT_DIR}/vless/${user}"; do
    if [[ -f "$f" ]]; then
      cp -f "$f" "${LANUN_EXPIRED_DIR}/vless/${user}.$(basename "$f").${ts}" 2>/dev/null || true
    fi
  done

  grep -E "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null | head -1 >> "${LANUN_EXPIRED_DIR}/vless/expired.list" 2>/dev/null || true

  mkdir -p "${LANUN_RECOVERY_DIR}/vless"
  grep -E "^### $user " "${LANUN_VLESS_TXT}" 2>/dev/null | head -1 > "${LANUN_RECOVERY_DIR}/vless/${user}.rec" 2>/dev/null || true
  {
    echo "limit_ip=$(cat ${LANUN_LIMIT_IP_DIR}/vless/${user} 2>/dev/null || echo 0)"
    echo "quota=$(cat ${LANUN_LIMIT_QT_DIR}/vless/${user} 2>/dev/null || echo 0)"
    echo "usage=$(cat ${LANUN_USAGE_QT_DIR}/vless/${user} 2>/dev/null || echo 0)"
  } >> "${LANUN_RECOVERY_DIR}/vless/${user}.rec" 2>/dev/null

  rm -f "${LANUN_LIMIT_IP_DIR}/vless/${user}" "${LANUN_LIMIT_QT_DIR}/vless/${user}" "${LANUN_USAGE_QT_DIR}/vless/${user}"
  rm -f "${LANUN_SUSP_DIR}/vless/${user}" "${LANUN_SUSP_DIR}/vless/${user}.rec"

  systemctl restart xray 2>/dev/null
  systemctl restart xray@none 2>/dev/null
  systemctl restart xray@xhttp 2>/dev/null

  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[VLESS EXPIRED]</b>%0AUsername: <code>${user}</code>%0AExpired: ${exp}%0ADomain: ${domain}%0AArchived for recovery" 2>/dev/null || true
  echo "$(date '+%Y-%m-%d %H:%M:%S') EXPIRE vless $user exp=$exp" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
}

# ---------- Recover expired ----------
lanun_recover_expired_vless() {
  local user="$1" new_days="$2"
  local recf="${LANUN_RECOVERY_DIR}/vless/${user}.rec"
  local recf2="${LANUN_EXPIRED_DIR}/vless/expired.list"

  if [[ ! -f "$recf" ]]; then
    local line
    line=$(grep "^### $user " "$recf2" 2>/dev/null | tail -1)
    if [[ -n "$line" ]]; then
      mkdir -p "${LANUN_RECOVERY_DIR}/vless"
      echo "$line" > "$recf"
    else
      lanun_err "No recovery data for expired $user"
      return 1
    fi
  fi

  local line
  line=$(grep "^###" "$recf" | head -1)
  local exp uuid
  exp=$(echo "$line" | awk '{print $3}')
  uuid=$(echo "$line" | awk '{print $4}')

  if [[ -n "$new_days" && "$new_days" =~ ^[0-9]+$ ]]; then
    exp=$(date -d "$new_days days" +"%Y-%m-%d")
  fi

  if [[ -z "$uuid" ]]; then
    lanun_err "No uuid in recovery for $user"
    return 1
  fi

  # Restore limit-ip
  local lip
  lip=$(grep "^limit_ip=" "$recf" 2>/dev/null | cut -d= -f2)
  if [[ -n "$lip" && "$lip" =~ ^[0-9]+$ && "$lip" != "0" ]]; then
    lanun_set_limit_ip vless "$user" "$lip"
  fi

  # Restore quota
  local quota
  quota=$(grep "^quota=" "$recf" 2>/dev/null | cut -d= -f2)
  if [[ -n "$quota" && "$quota" =~ ^[0-9]+$ && "$quota" != "0" ]]; then
    lanun_set_quota_bytes vless "$user" "$quota"
  fi

  # Reset usage on recovery
  mkdir -p "${LANUN_USAGE_QT_DIR}/vless"
  echo 0 > "${LANUN_USAGE_QT_DIR}/vless/${user}" 2>/dev/null

  lanun_recover_vless "$user" "$exp" "$uuid"
}

# ---------- List helpers ----------
lanun_list_vless_users() {
  grep -E "^### " "${LANUN_VLESS_TXT}" 2>/dev/null | awk '{print $2}'
}

lanun_get_vless_uuid() {
  local u="$1"
  grep -E "^### $u " "${LANUN_VLESS_TXT}" 2>/dev/null | awk '{print $4}' | head -1
}

lanun_get_vless_exp() {
  local u="$1"
  grep -E "^### $u " "${LANUN_VLESS_TXT}" 2>/dev/null | awk '{print $3}' | head -1
}

lanun_list_suspended_vless() {
  ls "${LANUN_SUSP_DIR}/vless" 2>/dev/null | grep -v '\.rec$' || true
}

lanun_list_expired_vless() {
  ls "${LANUN_RECOVERY_DIR}/vless" 2>/dev/null | grep '\.rec$' | sed 's/\.rec$//' || true
}

# ---------- SSH archive ----------
lanun_archive_ssh() {
  local user="$1" action="${2:-deleted}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local src="${LANUN_LIMIT_IP_DIR}/ssh/${user}"
  if [[ -f "$src" ]]; then
    mkdir -p "${LANUN_ETC}/${action}/ip/ssh" "${LANUN_ARCHIVE_DIR}/ssh"
    cp -f "$src" "${LANUN_ETC}/${action}/ip/ssh/${user}.${ts}" 2>/dev/null || true
    cp -f "$src" "${LANUN_ARCHIVE_DIR}/ssh/${user}.ip.${ts}" 2>/dev/null || true
  fi
  echo "$(date '+%Y-%m-%d %H:%M:%S') ARCHIVE ssh $user action=$action ts=$ts" >> "${LANUN_LIMIT_LOG}" 2>/dev/null || true
}

# Delete SSH with archive and telegram
lanun_delete_ssh() {
  local user="$1"
  lanun_archive_ssh "$user" "deleted"
  rm -f "${LANUN_LIMIT_IP_DIR}/ssh/${user}" "${LANUN_SUSP_DIR}/ssh/${user}"
  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[SSH DELETED]</b>%0AUsername: <code>${user}</code>%0ADomain: ${domain}" 2>/dev/null || true
  echo "$(date '+%Y-%m-%d %H:%M:%S') DELETE ssh $user" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
}

# Expire SSH with archive
lanun_expire_ssh() {
  local user="$1"
  lanun_archive_ssh "$user" "expired"
  mkdir -p "${LANUN_EXPIRED_DIR}/ssh"
  cat "${LANUN_LIMIT_IP_DIR}/ssh/${user}" 2>/dev/null > "${LANUN_EXPIRED_DIR}/ssh/${user}.ip" 2>/dev/null || true
  echo "$user $(date '+%Y-%m-%d')" >> "${LANUN_EXPIRED_DIR}/ssh/expired.list" 2>/dev/null || true
  rm -f "${LANUN_LIMIT_IP_DIR}/ssh/${user}" "${LANUN_SUSP_DIR}/ssh/${user}"
  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[SSH EXPIRED]</b>%0AUsername: <code>${user}</code>%0ADomain: ${domain}%0AArchived for recovery" 2>/dev/null || true
  echo "$(date '+%Y-%m-%d %H:%M:%S') EXPIRE ssh $user" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
}

# Recover SSH from expired (needs new days and password)
lanun_recover_expired_ssh() {
  local user="$1" days="$2" pass="$3"
  local expired_ip
  expired_ip=$(cat "${LANUN_EXPIRED_DIR}/ssh/${user}.ip" 2>/dev/null || echo "0")
  [[ "$expired_ip" =~ ^[0-9]+$ ]] || expired_ip=0
  lanun_set_limit_ip ssh "$user" "$expired_ip"
  echo "$(date '+%Y-%m-%d %H:%M:%S') RECOVER ssh $user days=$days" >> "${LANUN_LIMIT_LOG}" 2>/dev/null
  local domain
  domain=$(cat /etc/xray/domain 2>/dev/null || echo "vps")
  lanun_tg_send "<b>[SSH RECOVERED]</b>%0AUsername: <code>${user}</code>%0AExpired in: ${days} days%0ADomain: ${domain}%0AStatus: active" 2>/dev/null || true
}
