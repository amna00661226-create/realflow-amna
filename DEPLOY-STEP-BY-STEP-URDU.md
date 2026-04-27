# 🚀 RealFlow Deployment — Simple Step-by-Step Guide (Roman Urdu)

## Aap ko kya chahiye hoga? (Pre-requisites)

| # | Cheez | Kahaan se | Paise |
|---|-------|-----------|-------|
| 1 | Ek **domain name** (e.g. `myapp.com`) | Namecheap / GoDaddy | ~$10/year |
| 2 | **GitHub account** | github.com | Free |
| 3 | **Vercel account** | vercel.com | Free |
| 4 | **Cloudflare account** | cloudflare.com | Free |
| 5 | Apna **Windows home PC** (always-on) ya ek **VPS** (DigitalOcean / Contabo ~$5/mo) | — | — |
| 6 | Windows PC pe **Docker Desktop** installed | docker.com | Free |

⏱️ **Total time: ~45-60 minutes** (pehli baar)

---

## PHASE 1 — Code ko GitHub pe Push karo (5 min)

1. Emergent chat box ke **saath** wala **"Save to GitHub"** button dhundo aur click karo.
2. Ek naya repo name do: `realflow` (ya jo marzi).
3. Confirm karo — code automatic aap ke GitHub pe push ho jayega.
4. GitHub pe jaa kar check karo ke repo ban gayi hai — URL note karo (e.g. `https://github.com/YOUR_USERNAME/realflow`).

✅ **Phase 1 done.**

---

## PHASE 2 — Domain ko Cloudflare se connect karo (10-30 min wait)

1. cloudflare.com pe **Sign up** karo (free).
2. Login ke baad **"Add a Site"** → apna domain (e.g. `myapp.com`) enter karo → **Free plan** choose karo.
3. Cloudflare aap ko **2 nameservers** dega (e.g. `lars.ns.cloudflare.com`, `laura.ns.cloudflare.com`). Inko **copy** karo.
4. Jahan se domain khareeda (Namecheap / GoDaddy) wahan login karo:
   - Apne domain ki DNS / Nameservers settings mein jao
   - "Custom DNS" / "Custom Nameservers" select karo
   - Cloudflare wale 2 nameservers paste karo → **Save**
5. 10 min – 2 hours intezaar karo. Cloudflare dashboard pe aap ka domain **"Active"** ho jayega (email bhi aayega).

✅ **Jab "Active" ho jaye, next phase pe jao.**

---

## PHASE 3 — Frontend Vercel pe deploy karo (5 min)

1. vercel.com pe **Sign up with GitHub** karo.
2. Dashboard pe **"Add New → Project"** click karo.
3. Apna `realflow` repo select karo → **Import**.
4. **Configure Project** screen pe ye settings lagao:
   - **Framework Preset**: `Other`
   - **Root Directory**: `frontend` ← ye zaroori hai!
   - **Build Command**: (default rehne do, `vercel.json` khud handle kar lega)
5. **Environment Variables** section expand karo aur ye add karo:
   ```
   Name:  REACT_APP_BACKEND_URL
   Value: https://api.myapp.com
   ```
   (jahan `myapp.com` aap ki domain hai — `api.` prefix zaroor lagao)
6. **Deploy** click karo → 2-3 min mein Vercel build khatam karega.
7. Deploy ke baad Vercel aap ko ek URL dega (e.g. `realflow-abc.vercel.app`).

### Apni custom domain connect karo:
8. Vercel project → **Settings → Domains** → `myapp.com` add karo.
9. Vercel DNS records dega → Cloudflare dashboard mein ja kar wo add kar do (A record / CNAME jo wo bataye).
10. 5-10 min mein `https://myapp.com` pe aap ka frontend live ho jayega.

✅ **Frontend live. Abhi login page dikhe ga lekin login nahi hoga kyun ke backend abhi live nahi hai.**

---

## PHASE 4 — Home PC / VPS pe Backend deploy karo (15-20 min)

### Option A: Windows Home PC (easiest, one-click)

1. Docker Desktop install karo: https://www.docker.com/products/docker-desktop/ → restart PC → Docker khol ke wait karo jab tak "Engine running" green na ho.

2. **PowerShell ko Administrator mode** mein kholo (Start → "PowerShell" right-click → Run as Administrator).

3. Ye ek line paste karo (apna GitHub username daalo):
   ```powershell
   irm https://raw.githubusercontent.com/YOUR_USERNAME/realflow/main/install.ps1 | iex
   ```

4. Script aap se 3 cheezein puche gi:
   - **Domain**: `myapp.com` (bina https)
   - **Admin email**: `admin@myapp.com`
   - **Admin password**: ek strong password (note kar lo!)

5. Script khud-ba-khud ye sab karegi (~10 min):
   - Git install
   - Repo clone
   - Cloudflared install + tunnel create + DNS route (`api.myapp.com` → aap ka PC)
   - Windows service register (PC reboot ke baad auto-start)
   - Docker containers build + start (MongoDB + Backend + Chromium)
   - Health check verify

6. Jab script khatam ho, browser mein khol:
   ```
   https://api.myapp.com/health
   ```
   Response: `{"status":"ok"}` → **🎉 Backend LIVE!**

### Option B: Linux VPS (DigitalOcean / Contabo / Hetzner ~$5/mo)

1. VPS pe SSH karo. Docker + git install karo:
   ```bash
   curl -fsSL https://get.docker.com | sh
   apt install -y git
   ```

2. Repo clone karo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/realflow.git
   cd realflow
   ```

3. `.env` file banao:
   ```bash
   cp deployment/home-pc/env.template .env
   nano .env
   ```
   Ye values bharo:
   ```
   APP_URL=https://myapp.com
   CORS_ORIGINS=https://myapp.com,https://www.myapp.com
   DB_NAME=realflow
   ADMIN_EMAIL=admin@myapp.com
   ADMIN_PASSWORD=YourStrongPassword123!
   JWT_SECRET_KEY=<generate with: openssl rand -hex 32>
   POSTBACK_TOKEN=<generate with: openssl rand -hex 32>
   ```
   Save karo (Ctrl+O → Enter → Ctrl+X).

4. Docker start karo:
   ```bash
   docker compose up -d --build
   ```
   Pehli baar 5-10 min lagenge (chromium download ho raha hai).

5. Cloudflare Tunnel setup:
   ```bash
   curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
   chmod +x /usr/local/bin/cloudflared
   cloudflared tunnel login
   cloudflared tunnel create realflow
   cloudflared tunnel route dns realflow api.myapp.com
   ```

6. Tunnel config banao `~/.cloudflared/config.yml`:
   ```yaml
   tunnel: realflow
   credentials-file: /root/.cloudflared/<tunnel-id>.json
   ingress:
     - hostname: api.myapp.com
       service: http://localhost:8001
     - service: http_status:404
   ```

7. Tunnel service register karo aur start:
   ```bash
   cloudflared service install
   systemctl start cloudflared
   systemctl enable cloudflared
   ```

8. Verify:
   ```bash
   curl https://api.myapp.com/health
   ```
   Response: `{"status":"ok"}` → **🎉 Backend LIVE!**

✅ **Phase 4 done.**

---

## PHASE 5 — Final Test (2 min)

1. Browser mein khol: `https://myapp.com`
2. Login page aayega → **"Admin Login"** click karo
3. Login karo:
   - Email: `admin@myapp.com`
   - Password: jo step mein set kiya tha

Admin dashboard khul gaya = **🎊 App 100% LIVE HAI!**

---

## 🛠️ Management Commands (Home PC)

`deployment/home-pc/` folder mein ye ready-made batch files hain — bas double-click:

| File | Kaam |
|------|------|
| `start.bat` | Containers + tunnel start |
| `stop.bat` | Sab stop |
| `status.bat` | Health check |
| `logs.bat` | Live backend logs |
| `update.bat` | Latest code pull + rebuild |
| `fix-tunnel.bat` | Tunnel issue fix |

---

## ❓ Agar Kuch Atak Jaye

- **Cloudflare domain "Pending"**: Nameservers Namecheap/GoDaddy pe sahi paste hue? 1-2 hour aur wait karo.
- **Vercel build fail**: Root Directory `frontend` set hai ya nahi check karo.
- **Frontend khula lekin login 500 error**: `REACT_APP_BACKEND_URL` value sahi hai? `api.myapp.com` pe `/health` respond kar raha hai?
- **Docker `chromium install failed`**: `docker compose logs backend` dekho; `docker compose restart backend` karo.
- **Cloudflare Tunnel disconnect**: `deployment/home-pc/fix-tunnel.bat` run karo.

Har step pe atak jao to mujhe error message bata do, main solve karwa dunga.

---

## Optional Improvements (baad mein)

- **Email setup**: Gmail app-password ya Resend API key `.env` mein add karo → password reset emails kaam karengi.
- **Paywall**: Admin approval pe Stripe/PayPal lagao → SaaS business ban jaye ga.
- **Custom branding**: Admin panel → Branding section se logo, colors, app name change karo.

---

**Bus itna hi. Koi bhi step pe atak jaye — screenshot bhej do, main seedha solution dunga.**
