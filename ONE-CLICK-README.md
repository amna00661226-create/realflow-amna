# 🚀 RealFlow - ULTIMATE Setup Guide (Kisi Bhi PC Ke Liye)

**Ye guide follow karo aur kisi bhi Windows PC pe 20 min mein app live!**

Is setup mein saari galtiyan **already fix ho chuki hain** (container conflicts, cloudflared issues, password mismatch). **Bas double-click aur done!**

---

## 📋 Pre-requisites (Kya Chahiye)

| Cheez | Zaroori? | Note |
|-------|----------|------|
| Windows 10/11 PC | ✅ | Always-on (agar 24/7 app chalana hai) |
| Internet connection | ✅ | |
| Domain (e.g. realflow.online) | ✅ | Pehle se Cloudflare pe Active |
| Cloudflare account | ✅ | Free |
| Docker Desktop | ⚠️ | Installer khud install kar dega |
| Admin access to PC | ✅ | |

**Agar naya computer hai to bas GitHub ZIP download, extract, aur REALFLOW-SETUP.bat double-click. Baki sab automatic!**

---

## ⚡ Full Setup (New PC Par) — 4 Steps

### 🟢 STEP 1 — Project Download karo (1 min)

**Option A: GitHub se ZIP**  
1. Browser mein: `https://github.com/amna00661226-create/realflow-amna`
2. Green **`<> Code`** → **Download ZIP**
3. Apni desired location pe extract karo (e.g., `C:\RealFlow`)

**Option B: USB se copy**  
Aap ke current PC se pura folder `realflow-amna-main` USB mein copy karo, new PC pe paste karo.

---

### 🟢 STEP 2 — Docker Desktop (Sirf pehli baar, baad mein nahi)

**Agar naye PC pe Docker nahi hai:**

1. https://www.docker.com/products/docker-desktop → Download
2. Install karo → **PC RESTART karo** (important!)
3. Docker Desktop kholo → green **"Engine running"** wait karo

**Agar Docker pehle se hai** → bas open karo + green wait karo.

---

### 🟢 STEP 3 — Ek Baar Installer Chalao (15-20 min)

1. Extracted folder kholo (e.g., `C:\RealFlow\realflow-amna-main`)
2. **`REALFLOW-SETUP.bat`** pe **right-click → "Run as administrator"**
3. UAC prompt → **"Yes"**

### Pehli baar ye prompts aayenge:
```
  Domain [realflow.online]: <Enter>
  Admin email [admin@realflow.online]: <Enter>
  Admin password (auto-generate if blank): <Enter> (recommended: auto-gen)
```

### Installer automatically ye sab karega:
```
Phase 1/7 : Prerequisites (Git, Docker, cloudflared)     ✅
Phase 2/7 : Configuration (.env with strong secrets)      ✅
Phase 3/7 : CRITICAL CLEANUP (no container conflicts)     ✅
Phase 4/7 : Docker containers (--force-recreate)         ✅
Phase 5/7 : Admin user seed (guaranteed fresh password)  ✅
Phase 6/7 : Cloudflare Tunnel (service + registry clean) ✅
             ⚠️ Browser opens ONCE for Cloudflare auth
             ⚠️ Click "Authorize" for your domain
Phase 7/7 : Verification + Desktop shortcuts              ✅
```

### End Result:
```
=====================================================
  SETUP COMPLETE
=====================================================
  Frontend : https://realflow.online
  Backend  : https://api.realflow.online
  
  ADMIN LOGIN:
     Email    : admin@realflow.online
     Password : Ax7@kLm9Pqr2sTvW   (auto-generated)
  
  Desktop shortcuts created:
     RealFlow-START.bat
     RealFlow-STOP.bat
     RealFlow-RESTART.bat
     RealFlow-LOGS.bat
     RealFlow-STATUS.bat
  
  Auto-start on boot: ENABLED
=====================================================
```

---

### 🟢 STEP 4 — Browser Mein Login Karo (1 min)

1. Browser mein `https://realflow.online` kholo
2. **"Admin Login"** click karo
3. Credentials paste karo (Desktop\realflow-LOGIN.txt se copy karo)
4. **Sign In as Admin** → Dashboard! 🎉

---

## 🎛️ Management (Daily Use)

Desktop pe **5 shortcut files** auto-ban gayi hain. Bas double-click:

| Shortcut | Kaam |
|----------|------|
| 🟢 **RealFlow-START.bat** | Containers + tunnel start (PC boot pe auto hota hai) |
| 🔴 **RealFlow-STOP.bat** | Sab stop karo (PC off karne se pehle) |
| 🔁 **RealFlow-RESTART.bat** | Full nuclear restart (issue aaye to) |
| 📜 **RealFlow-LOGS.bat** | Live backend logs dekho |
| 📊 **RealFlow-STATUS.bat** | Health + service status |

---

## 🔄 PC Restart Ke Baad

**Ab aap ko kuch karna nahi!** Auto-start enabled hai:
- Docker Desktop auto-start hota hai
- Cloudflared service auto-start hoti hai (Windows service)
- Container auto-restart (Docker `restart: unless-stopped`)

**Bas PC on karo → 1-2 min baad app live!**

Agar kuch na chale to **`RealFlow-START.bat`** double-click karo — instant fix.

---

## 🆘 Troubleshooting

### "App down / Can't login"
```
1. RealFlow-STATUS.bat double-click karo → dekho kya red/stopped hai
2. Agar containers down → RealFlow-START.bat
3. Agar phir bhi issue → RealFlow-RESTART.bat
```

### "Password bhool gaya / Change karna hai"
```
1. Project folder mein .env file open karo Notepad se
2. ADMIN_PASSWORD=NewPassword123 set karo
3. Save karo → RealFlow-RESTART.bat double-click karo
4. 30 sec baad naya password se login karo
```

### "Tunnel offline (error 1033)"
```
Command Prompt Admin mein:
   net stop Cloudflared
   net start Cloudflared
```

### "Kuch samjh nahi aa raha"
```
RealFlow-SETUP.bat dobara right-click → Run as administrator
Installer smart hai — existing config reuse karega, naye issues fix karega.
```

---

## 🌟 Advanced: Naye PC Par Migration

Same domain (realflow.online) ko doosre PC pe move karna?

1. Purane PC pe: **RealFlow-STOP.bat** → Docker Desktop band → Cloudflared service stop
2. Cloudflare dashboard pe tunnel delete karo (optional — installer nayi banayega)
3. Naye PC pe: Ye guide follow karo Step 1 se
4. Pehli baar wahi domain daalo — installer naya tunnel create karega

**Data migration**: MongoDB data naye PC pe nahi aayega (fresh install hoga). Agar data chahiye:
```powershell
# Purane PC pe (backup)
docker exec realflow-mongo mongodump --out=/backup
docker cp realflow-mongo:/backup C:\mongo-backup

# Naye PC pe (restore, setup ke baad)
docker cp C:\mongo-backup realflow-mongo:/backup
docker exec realflow-mongo mongorestore /backup
```

---

## 💡 Pro Tips

### 🔒 Security
- Auto-generated password bahut strong hai (16 chars)
- Login hone ke baad Admin Panel → Settings → Change Password se apna yaad karne wala strong password set karo
- `.env` file **NEVER commit** GitHub pe (already .gitignore mein hai)

### 📈 Performance
- Docker Desktop → Settings → Resources: RAM 4GB+, CPU 4 cores minimum
- Mongo volume regular backup karo (important data hai)

### 🌐 Domain Management
- Cloudflare dashboard pe DNS records check karo — `api.realflow.online` CNAME tunnel pe point hona chahiye
- Frontend Vercel pe hai — woh alag hai, backend se independent

### 📧 Email Setup (Password Reset Feature)
`.env` mein:
```
RESEND_API_KEY=re_xxxxx  ← https://resend.com se free lo (3000 emails/month)
```
Phir `RealFlow-RESTART.bat` → emails work karenge.

---

## ✅ Is Setup Mein Kya-Kya Fix Hai (v2.0)

Ye installer **real-world deployment** mein milne wali har galti handle karta hai:

| Issue (purane installer mein) | Fix (v2.0 mein) |
|-------------------------------|-----------------|
| Container name conflict | Pre-deploy mein force remove |
| `docker compose restart` .env miss karta | `--force-recreate` flag use hota hai |
| Admin password mismatch | DB admin delete + force-recreate |
| Cloudflared "registry key already exists" | Service + registry pre-cleanup |
| Tunnel offline (error 1033) | Auto install service + auto-start |
| "All done - LIVE" when actually failed | Proper exit codes + clear errors |
| PC reboot = app dead | Windows service + Docker auto-start |
| Password regenerated every run | Existing password preserved |

---

## 🎉 Summary

**New PC setup:**
1. ZIP download + extract
2. Docker Desktop install (if not already)
3. `REALFLOW-SETUP.bat` → Run as administrator
4. Login → Enjoy!

**Daily use:**
- App auto-live on boot
- Management via Desktop shortcuts
- Login info in `Desktop\realflow-LOGIN.txt`

**That's it bhai! Kisi bhi PC pe copy karo, double-click karo, 20 min mein live!** 🚀
