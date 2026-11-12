# RAGLab API-key & `.env` management — UX and security research

**Researched:** 2026-11-12
**Feature:** Direct UI entry, rotation, and deletion of provider & custom API keys persisted in `raglab/.env`
**Purpose:** Satisfy `AGENTS.md` §2 (agentic coding + security research) and §9 (modern web-banking / back-office UX research before changing admin UI).

## Sources consulted

1. [Addy Osmani — `security-and-hardening/SKILL.md`](https://github.com/addyosmani/agent-skills/blob/main/skills/security-and-hardening/SKILL.md) — Threat-model-first workflow (STRIDE over every trust boundary, explicit abuse cases turned into unit tests, never log secrets, never return stored credentials, validate external inputs server-side).
2. [Anthropic — `frontend-design/SKILL.md`](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) — Ground UI structure in real operational content rather than decorative card sprawl; reserve visual emphasis and badges for meaningful state distinctions.
3. [Cinnamon — `kotaemon`](https://github.com/Cinnamon/kotaemon) — Open-source RAG operator workspace separating model selection from vendor credential management while linking missing-credential indicators directly to key configuration.
4. Repository baselines: [`CONSOLE_UI.md`](./CONSOLE_UI.md) (Console RAGLab visual tokens, operational calm, French admin copy), [`ADMIN_ACCESS_CONTROL_UX_RESEARCH.md`](./ADMIN_ACCESS_CONTROL_UX_RESEARCH.md) (Stripe / Bank of America / AWS IAM separation between `RAGLAB_CONSOLE_VIEW` masked inspection and `RAGLAB_CONSOLE_MANAGE` credential mutation), and `RAGLab/raglab/FRONTEND.md` §7 (masking contract: first 8 characters + `…`, write-only secret submission).

> **Network scope note:** In the Arena sandbox, outbound HTTP is restricted to `github.com`, `api.github.com`, `pypi.org`, and `registry.npmjs.org`. GitHub primary sources above were fetched directly; external commercial banking portals outside GitHub could not be fetched live from the sandbox and were cross-checked against the repository's documented Stripe / Bank of America / OWASP baselines in [`ADMIN_ACCESS_CONTROL_UX_RESEARCH.md`](./ADMIN_ACCESS_CONTROL_UX_RESEARCH.md).

## Threat model & security controls applied

- **Trust boundaries:** Browser (`AdminRaglab` settings UI) → Spring Boot BFF (`/api/admin/raglab/env/keys`) → FastAPI `RAGLab` service (`/env/keys`) → `RAGLab/raglab/.env` on disk.
- **Abuse cases & mitigations (tested):**
  1. *Arbitrary `.env` overwrite or deletion (e.g. `RAGLAB_SERVICE_TOKEN`, `PATH`, `PYTHONPATH`, `SUFFICIENCY_FIELDS_ENABLED`):* Server-side validation in `profiles.is_manageable_key_env()` permits only registered provider keys (`KEY_ENV_INFO`) or uppercase ASCII custom API key names matching `^[A-Z][A-Z0-9_]{1,62}_(?:API_KEY|KEY)(?:_[A-Z0-9_]{1,30})?$` and explicitly rejects reserved internal/system prefixes (`RAGLAB_*`, `HARNESS_*`, `PYTHON*`, `LD_*`, `PATH`, proxy/runtime gate variables).
  2. *Secret disclosure via read endpoints or audit logs:* `GET /env/keys` and `POST /env/keys` return only `profiles.masked(val)` (first 8 characters + `…`). `AgentAdminAuditService` records only the variable name (`RAGLAB_ENV_KEY_SET` / `RAGLAB_ENV_KEY_DELETE`) and persistence mode — never the key value.
  3. *Privilege escalation by read-only staff:* `GET /api/admin/raglab/env/keys` requires `RAGLAB_CONSOLE_VIEW`, whereas `POST` and `DELETE` require `RAGLAB_CONSOLE_MANAGE` enforced by Spring `@PreAuthorize`.
  4. *Endpoint-freeze compatibility (`RAGLab/AGENTS.md` §2.7):* Existing `/keys` routes remain untouched (continuing to reject unknown key names with `400 unknown_key_env`), while `/env/keys` is added alongside `SERVICE_VERSION = "1.6.0"`.

## UX patterns adopted

- **Persist to `raglab/.env` by default (`persist = true`):** When an operator enters or changes an API key from the UI, saving to `raglab/.env` is enabled by default so credentials survive process and container restarts (`./raglab/.env:/app/raglab/.env` bind-mounted in Docker Compose). Memory-only override remains available as an explicit opt-out checkbox for temporary testing.
- **Explicit persistence provenance per key:** Every row distinguishes `Dans .env` (`in_env_file: true`), `Mémoire seule` (in-process only), and `Manquante`, plus a header strip showing whether `raglab/.env` exists and is writable.
- **One-click row rotation (`Configurer` / `Modifier`):** Each row in the keys table offers a direct `Configurer` (when missing) or `Modifier` (when set) button that pre-selects that variable in the editor and focuses the secret input, alongside `Supprimer` (which removes from both live memory and `raglab/.env` by default).
- **Registered + custom API keys:** Operators can switch between known provider variables (`NVIDIA_API_KEY`, `XKIRO_API_KEY`, `GEMINI_API_KEY`, etc.) and custom API key variables (e.g. `OPENROUTER_API_KEY`, `GROQ_API_KEY`) with live uppercase normalization and naming guidance.
- **Cross-console deep links & RTL safety:** Clicking `Clés` in the RAGLab status bar, provider key badges in `Modèles & Pipeline`, or the shortcut in `Santé & diagnostic` navigates directly to `/admin/raglab/settings?tab=keys`. Variable names, masked prefixes, and secret inputs carry `dir="ltr"` so Arabic/RTL rendering never reorders characters.

## Explicitly rejected

- **No raw `.env` text-area editor in the browser:** Exposing the entire `raglab/.env` file as free text would leak `RAGLAB_SERVICE_TOKEN`, allow syntax corruption, and permit tampering with pipeline safety gates. Structured key-by-key editing gives full provider + custom API key control without exposing service internals.
- **No "copy existing secret" button:** Once saved, secrets are write-only and masked to 8 characters, matching Stripe, AWS IAM, and `RAGLab/AGENTS.md` §2.4.
