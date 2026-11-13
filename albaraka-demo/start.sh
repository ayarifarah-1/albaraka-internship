#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Pulling latest Al Baraka images from Docker Hub (elayarifarah)..."
docker compose pull

echo "==> Starting all 4 services (postgres, raglab, backend, frontend)..."
docker compose up -d

echo ""
echo "=================================================================="
echo " Al Baraka Bank Assistant is starting!"
echo " URL      : http://localhost:8080"
echo " Admin    : admin@albaraka.tn  /  postgres"
echo " Customer : client@albaraka.tn /  client123"
echo " API Keys : config/api-keys.env (or /admin/raglab/settings?tab=keys)"
echo "=================================================================="
