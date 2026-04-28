# 🔄 RealFlow - Update Workflow (Roman Urdu)

**Tumhara workflow simple banaya hai!** Ab jab bhi main koi changes karun, tumhe sirf 4 simple steps karne hain.

---

## 📋 Tumhara Permanent Update Workflow

### Whenever I (AI) make code changes, you do this:

```
1. ✅ Emergent chat mein "Save to GitHub" button click
2. ✅ GitHub se ZIP download
3. ✅ Existing project folder pe extract (REPLACE files when asked)
4. ✅ REALFLOW-UPDATE.bat double-click (Run as administrator)
```

**Bas itna! 5 minutes mein update done!** ✨

---

## 🎯 Step-by-Step Detail

### STEP 1 — Save to GitHub (30 sec)

Emergent chat mein **"Save to GitHub"** button click karo → updated code `realflow-amna` repo pe push ho jayega.

---

### STEP 2 — Fresh ZIP Download (30 sec)

Browser mein:
```
https://github.com/amna00661226-create/realflow-amna
```

Green **`<> Code`** → **Download ZIP**

`realflow-amna-main.zip` download ho jayega.

---

### STEP 3 — Extract (REPLACE Files) (1 min)

⚠️ **VERY IMPORTANT — Extract to SAME existing folder, NOT a new one!**

1. ZIP pe **right-click → "Extract All..."**
2. Destination mein **apna existing project folder** select karo:
   ```
   F:\online\real flow\real flow amna\realflow-amna-main\realflow-amna-main
   ```
   (ya jahan bhi tumne pehle extract kiya tha)

3. **"Extract"** click karo

4. **Windows pucchega: "Replace or Skip Files?"** → **"Replace the files in the destination"** click karo

   ✅ Ye CRITICAL hai! "Replace" karne se:
   - Naya code aa jayega (server.py, frontend, etc.)
   - **`.env` file safe rahegi** (ZIP mein nahi hai, isliye delete nahi hogi)
   - **Cloudflare config safe rahegi** (Windows mein hai, project mein nahi)
   - **MongoDB data safe rahega** (Docker volume mein hai)

---

### STEP 4 — REALFLOW-UPDATE.bat Run karo (3-5 min)

1. Project folder mein `REALFLOW-UPDATE.bat` dhundo
2. **Right-click → "Run as administrator"** → UAC **Yes**
3. PowerShell window khulegi → automatic update chalega:

```
[1/5] Checking Docker engine...        ✅
[2/5] Stopping existing containers...   ✅
[3/5] Cleaning up stuck containers...   ✅
[4/5] Rebuilding (3-5 min)...           ⏳
[5/5] Waiting for backend health...     ✅
```

End pe:
```
============================================================================
  UPDATE COMPLETE!
  
  Your existing .env, admin password, Cloudflare tunnel, and MongoDB data
  are all preserved. Only the application code was refreshed.
============================================================================
```

---

### Browser Refresh karo (Ctrl+F5) → Changes dikhenge!

---

## 🆚 SETUP vs UPDATE — Kab Konsa Use karo?

| Situation | File |
|-----------|------|
| **Pehli baar new PC pe install** | `REALFLOW-SETUP.bat` |
| **Code update aaya, sirf rebuild chahiye** | `REALFLOW-UPDATE.bat` ⭐ |
| **App stuck/down hai, full restart** | `RealFlow-RESTART.bat` (Desktop pe) |
| **Container conflict / weird issue** | `REALFLOW-SETUP.bat` (full re-run safe hai) |

---

## ✅ Update Mein Kya-Kya Preserve Hota Hai

UPDATE.bat **sirf code refresh** karta hai, baki sab safe rehta hai:

| Cheez | Status |
|-------|--------|
| ✅ Admin email + password (.env) | Preserved |
| ✅ JWT secrets, postback tokens | Preserved |
| ✅ Cloudflare tunnel config | Preserved |
| ✅ Cloudflare Windows service | Preserved |
| ✅ MongoDB data (users, links, clicks) | Preserved |
| ✅ Domain settings | Preserved |
| 🔄 server.py / frontend code | **Updated** ⭐ |
| 🔄 dependencies (requirements.txt, package.json) | **Updated** |

---

## 🚨 Common Issues & Quick Fixes

### Problem: "Replace files" prompt nahi aaya
**Solution:** Tumne extract NEW folder mein kiya. Files SAME existing folder mein extract karo (overwrite).

### Problem: ".env file missing!" error
**Solution:** Extract galat folder mein ho gaya. Project folder mein hi extract karo (jahan pehle kiya tha).

### Problem: Frontend mein purana UI dikh raha
**Solution:** Browser hard refresh karo: **Ctrl+F5** ya **Ctrl+Shift+R**

### Problem: Login nahi ho raha update ke baad
**Solution:** `Desktop\realflow-LOGIN.txt` file kholo — current password wahi hai. Browser cache clear karo.

---

## 💡 Pro Tip — Update ke Pehle Backup

Bahut important update se pehle backup le lo:

```powershell
# .env backup
Copy-Item "F:\online\real flow\real flow amna\realflow-amna-main\realflow-amna-main\.env" "$env:USERPROFILE\Desktop\env-backup-$(Get-Date -Format 'yyyyMMdd').txt"

# MongoDB backup
docker exec realflow-mongo mongodump --out=/backup
docker cp realflow-mongo:/backup "$env:USERPROFILE\Desktop\mongo-backup-$(Get-Date -Format 'yyyyMMdd')"
```

Agar update mein kuch break ho jaye, ye backups se restore kar sakte ho.

---

## 🎯 Summary — Aaj se Tumhara Process

Jab bhi main code update karun aur tumhe bataun "ye fix apply karo":

```
┌─────────────────────────────────────────┐
│  1. "Save to GitHub" click              │
│  2. GitHub se ZIP download              │
│  3. Existing folder pe extract (Replace)│
│  4. REALFLOW-UPDATE.bat Run as admin    │
│  5. Browser Ctrl+F5                     │
└─────────────────────────────────────────┘
```

**Bas itna hi! 5 min mein latest version live hoga.** 🚀

---

## 📝 Abhi Karo (Upload Limit Fix Apply karne ke liye):

Maine tumhare liye upload limit fix kar diya hai (1MB → 1GB). Ab upar wala 4-step workflow follow karo:

1. ✅ "Save to GitHub" click karo
2. ✅ GitHub ZIP download
3. ✅ Existing folder pe extract (Replace files)
4. ✅ `REALFLOW-UPDATE.bat` → Run as administrator
5. ✅ Ctrl+F5 → "Uploaded Things" mein bada batch upload try karo

**Done! Ab tum easily future updates apply kar sakte ho!** 💪
