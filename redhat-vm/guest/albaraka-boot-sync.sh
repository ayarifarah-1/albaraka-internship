#!/usr/bin/env bash
# =============================================================================
# Al Baraka Appliance — Dynamic IP, CORS & Console Banner Synchroniser
# =============================================================================
# Triggered at boot (`ExecStartPre` of albaraka-stack.service) and on DHCP
# interface changes (`/etc/NetworkManager/dispatcher.d/90-albaraka-ip`).
# =============================================================================
set -euo pipefail

STACK_DIR="/opt/albaraka"
ENV_FILE="${STACK_DIR}/.env"
PORT="8080"

if [ -f "${ENV_FILE}" ]; then
  PORT_VAL="$(grep -E '^FRONTEND_PORT=' "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"
  if [ -n "${PORT_VAL}" ]; then
    PORT="${PORT_VAL}"
  fi
fi

# Collect all active IPv4 addresses excluding loopback and Docker bridges.
IPS=()
while IFS= read -r line; do
  dev="$(awk '{print $2}' <<<"$line")"
  cidr="$(awk '{print $4}' <<<"$line")"
  ip="${cidr%/*}"
  case "$dev" in
    lo|docker*|br-*|veth*|virbr*) continue ;;
  esac
  if [ -n "$ip" ]; then
    IPS+=("$ip")
  fi
done < <(ip -4 -o addr show up scope global 2>/dev/null || true)

ORIGINS=("http://localhost:${PORT}" "http://127.0.0.1:${PORT}" "http://localhost:4200")
URLS=()
for ip in "${IPS[@]}"; do
  ORIGINS+=("http://${ip}:${PORT}" "http://${ip}")
  URLS+=("http://${ip}:${PORT}")
done

HN_SHORT="$(hostname -s 2>/dev/null || true)"
HN_FQDN="$(hostname -f 2>/dev/null || true)"
for hn in "$HN_SHORT" "$HN_FQDN"; do
  if [ -n "$hn" ] && [ "$hn" != "localhost" ] && [ "$hn" != "localhost.localdomain" ]; then
    ORIGINS+=("http://${hn}:${PORT}" "http://${hn}")
  fi
done

# Deduplicate comma-separated origins.
NEW_CORS="$(printf '%s\n' "${ORIGINS[@]}" | awk '!seen[$0]++' | paste -sd, -)"

CORS_CHANGED=0
if [ -f "${ENV_FILE}" ]; then
  OLD_CORS="$(grep -E '^CORS_ALLOWED_ORIGINS=' "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"
  if [ "${OLD_CORS}" != "${NEW_CORS}" ]; then
    CORS_CHANGED=1
    if grep -qE '^CORS_ALLOWED_ORIGINS=' "${ENV_FILE}"; then
      sed -i "s|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=${NEW_CORS}|" "${ENV_FILE}"
    else
      echo "CORS_ALLOWED_ORIGINS=${NEW_CORS}" >> "${ENV_FILE}"
    fi
  fi
fi

PRIMARY_URL="http://<VM-IP>:${PORT}"
if [ "${#URLS[@]}" -gt 0 ]; then
  PRIMARY_URL="${URLS[0]}"
fi

cat > /etc/issue <<EOF
========================================================================
  Al Baraka Bank Tunisia — Governed AI Platform (Red Hat / Rocky 9 VM)
------------------------------------------------------------------------
  Web Portal & Admin Console : ${PRIMARY_URL}
  API Keys Setup (Web UI)    : ${PRIMARY_URL}/admin/raglab/settings?tab=keys
  VM Console / SSH Login     : albaraka  (initial pass: ChangeMe-AlBaraka-2026!)
  Stack Management CLI       : sudo albaraka-ctl status
========================================================================

EOF

cat > /etc/motd <<EOF
========================================================================
  Al Baraka Bank Tunisia — Governed AI Platform Appliance
------------------------------------------------------------------------
  Portal URL       : ${PRIMARY_URL}
  Demo Admin Web   : admin@albaraka.tn  / postgres
  Demo Client Web  : client@albaraka.tn / client123
  API Keys File    : /opt/albaraka/config/api-keys.env
  Helper Commands  :
    sudo albaraka-ctl status         # Show IP, URL & container health
    sudo albaraka-ctl logs           # Tail live container logs
    sudo albaraka-ctl set-keys       # Configure NVIDIA / xKiro API keys
    sudo albaraka-ctl restart        # Restart all 4 containers
========================================================================
EOF

# If called with --refresh-running and CORS changed while backend is up, recreate backend cleanly.
if [ "${1:-}" = "--refresh-running" ] && [ "${CORS_CHANGED}" -eq 1 ]; then
  if systemctl is-active --quiet albaraka-stack.service 2>/dev/null; then
    /usr/bin/docker compose --project-directory "${STACK_DIR}" -f "${STACK_DIR}/docker-compose.yml" \
      up -d --no-build --pull never backend >/dev/null 2>&1 || true
  fi
fi
