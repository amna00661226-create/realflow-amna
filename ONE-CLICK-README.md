# 🚀 RealFlow One-Click Deploy - Bilkul Simple!

Sab kuch pre-configured hai:
- **Domain**: realflow.online
- **Admin Email**: admin@realflow.online
- **Admin Password**: automatic generate ho jayega (installer end pe dikhayega + Desktop pe save karega)

---

## Sirf 3 steps:

### 1️⃣ Code ko GitHub pe Update karo (1 min)

Emergent chat ke saath **"Save to GitHub"** button click karo → apni existing `realflow-amna` repo pe push karo. Ye zaroori hai kyunke main ne naye 2 files banayi hain:
- `REALFLOW-1-CLICK-DEPLOY.bat`
- `ONECLICK.ps1`

### 2️⃣ Installer File Download karo (30 sec)

Browser mein ye link kholo (tumhari GitHub repo ka raw URL):

```
https://raw.githubusercontent.com/amna00661226-create/realflow-amna/main/REALFLOW-1-CLICK-DEPLOY.bat
```

Ya direct click karo: **[Download REALFLOW-1-CLICK-DEPLOY.bat](https://raw.githubusercontent.com/amna00661226-create/realflow-amna/main/REALFLOW-1-CLICK-DEPLOY.bat)**

Browser file save karega → **Desktop** pe save karo.

### 3️⃣ Double-Click karo → Bas ho gaya! 🎉

1. Desktop pe `REALFLOW-1-CLICK-DEPLOY.bat` file dhundo
2. **Double-click** karo
3. UAC prompt aaye → **"Yes"** click karo
4. Chai/coffee bana lo — **10-15 min** mein sab kuch automatic ho jayega

---

## Installer Kya Kya Karega (Automatic):

- ✅ Git install (agar nahi hai)
- ✅ Docker Desktop install (agar nahi hai)
- ✅ Cloudflared install (agar nahi hai)
- ✅ Aap ki GitHub repo clone karega Desktop\realflow mein
- ✅ Strong random admin password generate karega
- ✅ `.env` file banayega sab secrets ke saath
- ✅ Cloudflare Tunnel setup karega (sirf 1 baar browser open hoga — "Authorize" click karo)
- ✅ DNS route karega: `api.realflow.online` → aap ka PC
- ✅ Windows service register karega (PC reboot pe auto-start)
- ✅ Docker containers start karega (MongoDB + Backend + Chromium)
- ✅ Health check verify karega

## End pe Screen pe Dikhega:

```
================================================================
  All done - RealFlow is LIVE!
================================================================

  Frontend : https://realflow.online
  Backend  : https://api.realflow.online
  Health   : https://api.realflow.online/health

  ADMIN LOGIN (save these - you'll need them!):
     Email    : admin@realflow.online
     Password : Xk7$mPqR9nL2@jVw    ← auto-generated, unique for you

  Credentials also saved to: Desktop\realflow-LOGIN.txt
```

**Saath mein Desktop pe `realflow-LOGIN.txt` file bhi create ho jayegi** jismein aap ka email + password save hoga. Bhoolna mushkil!

---

## Sirf 1 Manual Step (Unavoidable):

Installer ke **Phase 4** mein ek baar browser khulega — Cloudflare login screen aayegi:
1. Aap ka `realflow.online` domain select karo
2. **"Authorize"** button click karo
3. Tab band karo
4. Installer automatic aage badhega

**Bas itna hi. Baaki sab automatic!**

---

## Agar Kuch Error Aaye:

| Error | Fix |
|-------|-----|
| "Docker Desktop installed - REBOOT required" | PC restart karo, phir .bat double-click karo |
| "winget not found" | Microsoft Store se "App Installer" install karo |
| "Docker did not start" | Docker Desktop manually kholo, green icon ka wait karo, phir rerun |
| "git clone failed" | Internet check karo + GitHub repo public hai confirm karo |
| Cloudflare authorize page nahi khuli | Browser manually kholo, script ka wait karo |

Koi aur error aaye to **screenshot** bhejo — main turant solve kar dunga.

---

## Deploy Hone Ke Baad Management:

Sab commands `C:\Users\<YourName>\Desktop\realflow\deployment\home-pc\` folder mein hain:

| File | Kaam |
|------|------|
| `start.bat` | Containers + tunnel start karo |
| `stop.bat` | Sab stop karo |
| `status.bat` | Health check karo |
| `logs.bat` | Live logs dekho |
| `update.bat` | Latest code pull + rebuild |

Bas double-click koi bhi!
