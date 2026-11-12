#!/usr/bin/env bash
# =============================================================================
# End-to-end smoke test for the unified root `docker-compose.yml` stack:
#   frontend (Nginx + Angular) -> backend (Spring Boot) -> postgres + raglab
#
# Verifies without needing paid external LLM keys that:
#   1. Nginx serves the SPA with security headers and proxies /api/* to backend
#   2. Postgres + Flyway + seed + JWT auth + RBAC + governed facts work
#   3. Backend <-> RAGLab (`http://raglab:8000`) are AUTOMATICALLY linked via
#      Docker DNS (`source == "ENV"`, `reachable == True`) with matching
#      `X-Service-Token` — zero manual URL input required in the UI
#   4. `.env` API key management (`/api/admin/raglab/env/keys`) writes and
#      cleans up keys end-to-end on the mounted host directory.
# =============================================================================
set -euo pipefail

BASE="${1:-${SMOKE_BASE_URL:-http://127.0.0.1:8080}}"
ADMIN_EMAIL="${SMOKE_ADMIN_EMAIL:-admin@albaraka.tn}"
ADMIN_PASSWORD="${SMOKE_ADMIN_PASSWORD:-postgres}"

pass=0
fail=0
ok()  { pass=$((pass + 1)); echo "  [OK]   $1"; }
bad() { fail=$((fail + 1)); echo "  [FAIL] $1"; [ -n "${2:-}" ] && echo "         $2"; }
json() { python3 -c 'import json, sys; d = json.load(sys.stdin); print(eval(sys.argv[1], {"d": d}))' "$1"; }

echo "==> 1. Frontend SPA + Nginx security headers ($BASE)"
hdrs=$(curl -sS -D - -o /dev/null "$BASE/")
echo "$hdrs" | grep -qi "^content-security-policy:" && ok "CSP header present" || bad "CSP header missing"
echo "$hdrs" | grep -qi "^x-frame-options: DENY" && ok "X-Frame-Options DENY" || bad "X-Frame-Options missing"
echo "$hdrs" | grep -qi "^server: nginx/" && bad "nginx version leaked" || ok "server_tokens off"
ver_code=$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/version.json")
[ "$ver_code" = "200" ] && ok "SPA /version.json served (200)" || bad "/version.json returned $ver_code"

echo "==> 2. Nginx -> Backend reverse proxy"
curl -fsS "$BASE/api/../actuator/health" >/dev/null 2>&1 \
  && bad "actuator reachable via path traversal" \
  || ok "actuator blocked through public Nginx proxy"
rid=$(curl -sS -D - -o /dev/null "$BASE/api/chat/history?sessionId=none" | grep -i "^x-request-id:" | tr -d '\r' | awk '{print $2}')
[ -n "$rid" ] && ok "X-Request-Id echoed ($rid)" || bad "X-Request-Id missing"

echo "==> 3. Admin authentication + refresh rotation + client RBAC"
login=$(curl -sS -H 'Content-Type: application/json' -X POST "$BASE/api/auth/login" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"motDePasse\":\"$ADMIN_PASSWORD\"}")
tok=$(echo "$login" | json 'd["token"]')
rt=$(echo "$login" | json 'd["refreshToken"]')
[ -n "$tok" ] && ok "Admin JWT issued" || bad "Admin login failed" "$login"

# Keep a second admin session for admin API checks after testing logout rotation
admin_login2=$(curl -sS -H 'Content-Type: application/json' -X POST "$BASE/api/auth/login" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"motDePasse\":\"$ADMIN_PASSWORD\"}")
admin_tok=$(echo "$admin_login2" | json 'd["token"]')
auth=(-H "Authorization: Bearer $admin_tok" -H 'Content-Type: application/json')

ref=$(curl -sS -H 'Content-Type: application/json' -X POST "$BASE/api/auth/refresh" -d "{\"refreshToken\":\"$rt\"}")
rt2=$(echo "$ref" | json 'd["refreshToken"]')
[ -n "$rt2" ] && [ "$rt2" != "$rt" ] && ok "Refresh token rotated" || bad "Refresh token did not rotate" "$ref"
replay_code=$(curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' -X POST "$BASE/api/auth/refresh" -d "{\"refreshToken\":\"$rt\"}")
[ "$replay_code" = "401" ] && ok "Replayed refresh token rejected (401)" || bad "Replay returned $replay_code"
curl -sS -H 'Content-Type: application/json' -X POST "$BASE/api/auth/logout" -d "{\"refreshToken\":\"$rt2\"}" >/dev/null

anon_client=$(curl -sS -o /dev/null -w '%{http_code}' "$BASE/api/client/me")
[ "$anon_client" = "401" ] && ok "Anonymous /api/client/me rejected (401)" || bad "Anonymous /api/client/me returned $anon_client"
staff_client=$(curl -sS -o /dev/null -w '%{http_code}' "${auth[@]}" "$BASE/api/client/me")
[ "$staff_client" = "403" ] && ok "Admin staff blocked from /api/client/me (403)" || bad "Staff /api/client/me returned $staff_client"

echo "==> 4. Automatic Backend <-> RAGLab internal Docker link (http://raglab:8000)"
endpoint_json=$(curl -sS "${auth[@]}" "$BASE/api/admin/agent/endpoint")
echo "$endpoint_json" | json 'd["configured"] is True and d["url"] == "http://raglab:8000" and d["source"] == "ENV"' | grep -q True \
  && ok "RAGLab endpoint auto-configured from Docker env (http://raglab:8000, source=ENV)" \
  || bad "Unexpected /api/admin/agent/endpoint payload" "$endpoint_json"

diag_json=$(curl -sS "${auth[@]}" "$BASE/api/admin/agent/diagnostics")
echo "$diag_json" | json 'd["reachable"] is True and d.get("health", {}).get("status") == "ok"' | grep -q True \
  && ok "Backend -> RAGLab /health reachable with X-Service-Token (status=ok)" \
  || bad "RAGLab diagnostics unreachable" "$diag_json"

inspect_json=$(curl -sS "${auth[@]}" "$BASE/api/admin/raglab/inspect?limit=2")
echo "$inspect_json" | json 'd.get("chunks", {}).get("count", 0) > 0' | grep -q True \
  && ok "Backend -> RAGLab /inspect returned corpus chunks" \
  || bad "RAGLab /inspect failed" "$inspect_json"

echo "==> 5. End-to-end .env API key persistence through UI gateway (/api/admin/raglab/env/keys)"
env_before=$(curl -sS "${auth[@]}" "$BASE/api/admin/raglab/env/keys")
echo "$env_before" | json 'd.get("env_file", {}).get("writable") is True' | grep -q True \
  && ok "RAGLab .env mount is writable from container" \
  || bad "RAGLab .env mount is not writable" "$env_before"

set_key=$(curl -sS "${auth[@]}" -X POST "$BASE/api/admin/raglab/env/keys" \
  -d '{"key_env":"SMOKE_GATEWAY_API_KEY","value":"sk-smoke-compose-verify-987654","persist":true}')
echo "$set_key" | json 'd.get("status") == "set" and d.get("persisted") is True and d.get("in_env_file") is True' | grep -q True \
  && ok "Custom API key saved & persisted via /api/admin/raglab/env/keys" \
  || bad "Saving custom API key failed" "$set_key"

del_key=$(curl -sS "${auth[@]}" -X DELETE "$BASE/api/admin/raglab/env/keys/SMOKE_GATEWAY_API_KEY?persist=true")
echo "$del_key" | json 'd.get("status") == "missing" and d.get("removed_from_env_file") is True' | grep -q True \
  && ok "Custom API key deleted & cleaned from host .env" \
  || bad "Deleting custom API key failed" "$del_key"

echo "==> 6. Governed facts CRUD + audit trail (PostgreSQL)"
fkey="smoke_$(date +%s)"
created=$(curl -sS "${auth[@]}" -X POST "$BASE/api/admin/facts" \
  -d "{\"domain\":\"financement\",\"key\":\"$fkey\",\"value\":\"valeur smoke\",\"factType\":\"terms\",\"language\":\"fr\"}")
fid=$(echo "$created" | json 'd["id"]')
[ -n "$fid" ] && ok "Governed fact created (#$fid)" || bad "Fact creation failed" "$created"
curl -sS "${auth[@]}" -X PUT "$BASE/api/admin/facts/$fid" \
  -d "{\"domain\":\"financement\",\"key\":\"$fkey\",\"value\":\"valeur smoke 2\",\"factType\":\"terms\",\"language\":\"fr\",\"reason\":\"smoke update\"}" >/dev/null
curl -sS "${auth[@]}" -X DELETE "$BASE/api/admin/facts/$fid" \
  -d '{"reason":"smoke cleanup"}' >/dev/null
hist=$(curl -sS "${auth[@]}" "$BASE/api/admin/facts/$fid/history")
echo "$hist" | json '[h["action"] for h in d]' | grep -q "DEACTIVATE.*UPDATE.*CREATE" \
  && ok "Audit trail recorded CREATE -> UPDATE -> DEACTIVATE" \
  || bad "Audit trail incomplete" "$hist"

if [ -n "${SMOKE_METRICS_URL:-}" ]; then
  echo "==> 7. Backend Prometheus metrics"
  metrics=$(curl -fsS "$SMOKE_METRICS_URL" 2>/dev/null || echo "")
  echo "$metrics" | grep -q "jvm_memory_used_bytes" \
    && ok "Actuator Prometheus metrics exported" \
    || bad "Actuator Prometheus metrics missing"
fi

echo
echo "Smoke summary: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
