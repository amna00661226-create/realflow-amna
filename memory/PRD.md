# RealFlow — PRD

## Original Problem Statement
"https://github.com/mumair14741-sudo/mumair14741.git — this repo clone to me full project working. This is public, clone it fully, then I want to put it online."

## Project Overview
**RealFlow** — self-hosted traffic-tracking + conversion platform with realistic browser automation.
- Short-link redirector with click tracking
- VPN / proxy detection (multi-provider)
- Real-user-traffic & form-filler automation (Playwright)
- Admin panel with user / sub-user management, feature gating, branding
- Password reset via Gmail SMTP or Resend

## Architecture
- **Frontend**: React 18 + CRACO + Tailwind 3 + Radix UI + react-router 7  (supervisor on :3000)
- **Backend**: FastAPI + Motor + Playwright + Pandas (supervisor on :8001, `/api` prefix)
- **Database**: MongoDB 7 (per-main-user DB pattern: `realflow_user_<uid>`)
- **Ingress**: Emergent preview URL → `/api` → backend, `/` → frontend

## Current Status (2026-01)
- [x] Cloned public repo `mumair14741-sudo/mumair14741` into `/app`
- [x] Installed backend deps (`requirements.txt`) and frontend deps (`yarn install`)
- [x] Configured `backend/.env` (MONGO_URL, DB_NAME, JWT_SECRET_KEY, POSTBACK_TOKEN, ADMIN_EMAIL, ADMIN_PASSWORD, APP_URL)
- [x] Preserved preview URL in `frontend/.env`
- [x] Supervisor services: backend / frontend / mongodb all RUNNING
- [x] `/health` returns `{"status":"ok","mongo_connected":true}`
- [x] Admin login API verified — returns valid JWT
- [x] Frontend loads — RealFlow login page renders correctly

## Access
- App URL: https://dev-mumair.preview.emergentagent.com
- Admin: click **Admin Login** → `admin@realflow.local` / `Admin@12345`
- User: **Register** tab → admin activates from admin panel

## Notes / Deferred
- **Playwright chromium-headless-shell** auto-installs on first use. If needed, run manually: `/root/.venv/bin/playwright install chromium-headless-shell`
- **Email** currently in demo mode (logs only). Add `SMTP_USER`/`SMTP_PASSWORD` or `RESEND_API_KEY` to enable real emails.
- Production deploy scripts (`deployment/`, `docker-compose.yml`, Cloudflare Tunnel) unchanged — use when deploying to home-PC / Vercel per README.

## Backlog
- P1 — Harden Playwright chromium install at startup
- P1 — Configure SMTP / Resend for password reset
- P2 — Production deploy (Vercel frontend + Cloudflare-Tunnel backend)
