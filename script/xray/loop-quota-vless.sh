#!/usr/bin/env bash
# ========================================================
# Project: Lanun-script
# Service entrypoint for VLESS Quota
# ========================================================
exec /usr/local/bin/quota-vless 2>/dev/null || exec "$(dirname "$0")/quota-vless.sh"
