#!/usr/bin/env bash
# ========================================================
# Project: Lanun-script
# Service entrypoint for VLESS IP limit
# ========================================================
exec /usr/local/bin/limit-ip-vless 2>/dev/null || exec "$(dirname "$0")/limit-ip-vless.sh"
