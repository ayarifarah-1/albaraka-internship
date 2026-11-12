# Al Baraka Bank Assistant & RAGLab — Monorepo

Unified repository combining:

- **`bank-assistant/`** — Angular 21 customer/back-office web portal (`frontend`), Spring Boot 4 / Java 21 API gateway (`backend`), and PostgreSQL + `pgvector` (`postgres`).
- **`RAGLab/`** — FastAPI multilingual RAG microservice (`raglab`) with ChromaDB vector indexing, governed chunking, hybrid retrieval, citation verification, and runtime `.env` API-key management.

---

## Unified Docker Compose Architecture (Zero Manual Wiring)

Running `docker compose up --build -d` from the repository root launches all four containers on a shared internal bridge network (`albaraka-net`) with **automatic service-to-service discovery and authentication**:

```text
Browser (http://localhost:8080)
   │
   ▼
┌──────────────────────────────┐
│ frontend (Nginx + Angular)   │  Port 8080 -> 80
│ Proxies /api/* automatically │
└──────────────┬───────────────┘
               │ http://backend:8081
               ▼
┌──────────────────────────────┐      jdbc:postgresql://postgres:5432/banque_assistant
│ backend (Spring Boot 4)      │ ─────────────────────────────────────────────────────► ┌──────────────────────────┐
│ Auto-wired with:             │                                                        │ postgres (pgvector:pg16) │
│ RAGLAB_URL=http://raglab:8000│                                                        └──────────────────────────┘
│ RAGLAB_TOKEN=<shared-token>  │
└──────────────┬───────────────┘
               │ http://raglab:8000 (X-Service-Token)
               ▼
┌──────────────────────────────┐
│ raglab (FastAPI RAG Engine)  │  Mounts ./RAGLab/raglab:/host-raglab
│ Persists UI keys to .env     │  Named volumes: index, caches, documents
└──────────────────────────────┘
```

### Why no manual URL setup is needed
1. **`frontend` → `backend`**: Nginx (`bank-assistant/frontend/nginx.conf`) proxies `/api/` directly to `http://backend:8081`.
2. **`backend` → `raglab`**: `docker-compose.yml` pre-configures `RAGLAB_URL=http://raglab:8000` and synchronizes `RAGLAB_TOKEN` with `raglab`'s `RAGLAB_SERVICE_TOKEN`. As soon as the stack starts, `/admin/agent/health` and `/admin/raglab/*` communicate with `raglab` automatically (`source = ENV`).
3. **UI → `RAGLab/raglab/.env` persistence**: `raglab` mounts `./RAGLab/raglab` and points `RAGLAB_ENV_FILE` to `/host-raglab/.env`, so no `.env` file has to be created manually before `docker compose up`, and API keys added from the back-office UI are saved directly to `RAGLab/raglab/.env` on the host.

---

## Quickstart

```bash
# 1. Build and start all 4 services (postgres, raglab, backend, frontend)
docker compose up --build -d

# 2. Check container health
docker compose ps

# 3. Open the web application
#    http://localhost:8080
```

### Default Local Accounts (`DEV_SEED=true`)

| Role | Email | Password |
| :--- | :--- | :--- |
| Back-office Admin | `admin@albaraka.tn` | `postgres` |
| Customer Portal | `client@albaraka.tn` | `client123` |

> Set `DEV_SEED=false` and configure strong secrets in `.env` (copied from `.env.example`) for any non-local deployment.

### Configuring LLM & Embedding API Keys (No Container Restart Needed)

1. Sign in at `http://localhost:8080` as `admin@albaraka.tn`.
2. Navigate to **Administration → RAGLab → Paramètres → Clés API (`.env`)** (`/admin/raglab/settings?tab=keys`).
3. Enter your provider keys (e.g., `NVIDIA_API_KEY`, `XKIRO_API_KEY`) or custom keys (`*_API_KEY` / `*_KEY`) and click **Enregistrer**. Keys are applied immediately in memory and persisted to `RAGLab/raglab/.env`.
4. Trigger corpus indexing from **Administration → RAGLab → Corpus / Statut** once your embedding key is set.

---

## Useful Commands

```bash
# Run the end-to-end 4-container smoke suite (verifies UI + Backend + Postgres + auto-linked RAGLab)
docker compose --profile smoke run --rm smoke

# Stream logs
docker compose logs -f backend raglab

# Stop containers (keep volumes, database, and indexed vectors)
docker compose down

# Stop containers and wipe volumes (clean slate)
docker compose down -v
```

---

## Ports Summary

| Service | Container Name / DNS | Host Binding | Purpose |
| :--- | :--- | :--- | :--- |
| `frontend` | `http://frontend:80` | `0.0.0.0:8080` (`FRONTEND_PORT`) | Angular SPA + `/api/*` reverse proxy |
| `backend` | `http://backend:8081` | `127.0.0.1:8081` (`BACKEND_PORT`) | Spring Boot REST API + Actuator |
| `raglab` | `http://raglab:8000` | `127.0.0.1:8000` (`RAGLAB_PORT`) | FastAPI RAG Engine (`/health`, `/docs`) |
| `postgres` | `postgres:5432` | `127.0.0.1:5433` (`POSTGRES_PORT`) | PostgreSQL 16 + `pgvector` |
