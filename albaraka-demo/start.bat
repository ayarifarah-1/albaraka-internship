@echo off
cd /d "%~dp0"

echo ==^> Pulling latest Al Baraka images from Docker Hub (elayarifarah)...
docker compose pull
if errorlevel 1 exit /b 1

echo ==^> Starting all 4 services (postgres, raglab, backend, frontend)...
docker compose up -d
if errorlevel 1 exit /b 1

echo.
echo ==================================================================
echo  Al Baraka Bank Assistant is starting!
echo  URL      : http://localhost:8080
echo  Admin    : admin@albaraka.tn  /  postgres
echo  Customer : client@albaraka.tn /  client123
echo  API Keys : config\api-keys.env (or /admin/raglab/settings?tab=keys)
echo ==================================================================
pause
