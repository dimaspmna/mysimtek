# Firebase Push Notification — FCM V1 API Setup Guide

> Menggunakan **Firebase Cloud Messaging API (V1)** dengan OAuth2 service account.  
> Legacy API (server key) hanya sebagai fallback jika hosting blokir `oauth2.googleapis.com`.

---

## Yang Sudah Dikonfigurasi (Tidak Perlu Diubah)

### Flutter (mysimtek)
| File | Keterangan |
|------|-----------|
| `lib/firebase_options.dart` | Auto-generated oleh FlutterFire CLI |
| `pubspec.yaml` | firebase_core, firebase_messaging, flutter_local_notifications |
| `lib/main.dart` | Inisialisasi Firebase + FcmService.initialize() |
| `lib/core/services/fcm_service.dart` | Lengkap: permission, token, sync backend, foreground/background handler |
| `android/app/src/main/AndroidManifest.xml` | POST_NOTIFICATIONS + channel ID `mysimtek_high_importance` |

### Laravel (simtek-billing)
| File/Lokasi | Keterangan |
|-------------|-----------|
| `app/Services/FcmService.php` | FCM V1 primary, Legacy fallback |
| `config/services.php` | Key `firebase.credentials` & `firebase.server_key` |
| `routes/api.php` | POST `/api/fcm-token` (auth:sanctum) |
| `app/Http/Controllers/Api/AuthController.php` | Method `updateFcmToken` |
| `app/Models/User.php` & `Customer.php` | `fcm_token` di `$fillable` |
| `app/Observers/CustomerNotificationObserver.php` | Otomatis kirim notif saat CustomerNotification dibuat |
| `app/Console/Commands/TestFcmNotification.php` | Artisan command `php artisan fcm:test` |

---

## A. Firebase Console — Pastikan V1 API Aktif

1. Buka [console.firebase.google.com](https://console.firebase.google.com) → pilih project **mysimtek-pelanggan**
2. **Project Settings** → tab **Cloud Messaging**
3. Pastikan **Firebase Cloud Messaging API (V1)** → statusnya **Enabled**
   - Jika ada tombol "Enable", klik

### Download Service Account JSON

4. **Project Settings** → tab **Service Accounts**
5. Klik **Generate new private key** → file JSON ter-download (misal: `mysimtek-pelanggan-firebase-adminsdk-xxxx.json`)
6. **Simpan file ini** — akan di-upload ke server Hostinger

---

## B. Deploy ke Server Hostinger via SSH

### 1. Masuk SSH & Navigasi ke Laravel Root

```bash
# Dari prompt: [u655654846@id-dci-web1321 public_html]$
cd ~/public_html
```

### 2. Upload & Simpan firebase-credentials.json

Dari local machine (terminal baru di laptop):
```bash
# Upload dari laptop ke Hostinger
scp /path/ke/mysimtek-pelanggan-firebase-adminsdk-xxxx.json \
  u655654846@id-dci-web1321.id-dci.shared-hosting.com:~/public_html/storage/app/firebase-credentials.json
```

Atau via SSH langsung (copy-paste isi JSON):
```bash
# Di SSH server
nano ~/public_html/storage/app/firebase-credentials.json
# Paste isi JSON, lalu Ctrl+X → Y → Enter
```

### 3. Set Permission File Credentials

```bash
chmod 600 ~/public_html/storage/app/firebase-credentials.json
ls -la ~/public_html/storage/app/firebase-credentials.json
# Harus tampil: -rw------- (hanya owner yang bisa baca)
```

### 4. Update .env di Server

```bash
nano ~/public_html/.env
```

Tambah/ubah baris berikut (WAJIB path absolut):
```env
# Firebase Cloud Messaging V1 API
FIREBASE_CREDENTIALS=/home/u655654846/public_html/storage/app/firebase-credentials.json
```

Simpan: `Ctrl+X → Y → Enter`

### 5. Clear Config Cache

```bash
cd ~/public_html
php artisan config:clear
php artisan cache:clear
```

---

## C. Test Notifikasi via Artisan

### Cek konektivitas & konfigurasi sekaligus:
```bash
cd ~/public_html
php artisan fcm:test
```

Output yang diharapkan:
```
Mengecek konektivitas ke fcm.googleapis.com...
  fcm.googleapis.com   : REACHABLE
  oauth2.googleapis.com: REACHABLE

Konfigurasi:
  FIREBASE_CREDENTIALS : OK (/home/u655654846/public_html/storage/app/firebase-credentials.json)
  FIREBASE_SERVER_KEY  : NOT SET (v1 only)

Mengirim ke: Nama Customer (email@example.com)
Token: eyJhbGci...
Perintah kirim selesai. Cek HP dan periksa log:
  tail -30 storage/logs/laravel.log | grep FCM
```

### Test ke email customer tertentu:
```bash
php artisan fcm:test --email=customer@email.com --type=paid
```

---

## D. Troubleshooting di Server

### 1. Cek Log FCM
```bash
tail -50 ~/public_html/storage/logs/laravel.log | grep -i fcm
```

Log sukses FCM V1:
```
[FCM v1] Sent OK to eyJhbGci...
```

Log gagal & fallback ke Legacy:
```
[FCM v1] Token exchange failed: ...
[FCM v1] Exception: ...
[FCM Legacy] Sent OK: ...
```

### 2. Cek Apakah oauth2.googleapis.com Bisa Diakses
```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://oauth2.googleapis.com/token
# Harusnya: 404 atau 400 (server merespons = OK, bukan 000)
# Jika 000 = BLOCKED
```

### 3. Cek Apakah FCM Endpoint Bisa Diakses
```bash
curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://fcm.googleapis.com/fcm/send
# Harusnya: 401 (server merespons = OK)
# Jika 000 = BLOCKED
```

### 4. Jika oauth2.googleapis.com BLOCKED (Hostinger Shared Hosting)

Tambahkan fallback Legacy Server Key di `.env`:
```bash
nano ~/public_html/.env
```

```env
# FCM Legacy fallback — ambil dari Firebase Console > Project Settings > Cloud Messaging > Server key
# CATATAN: Server key (legacy) sudah deprecated Feb 2024. Gunakan ini hanya sebagai darurat.
FIREBASE_SERVER_KEY=AAAAxxxxxxxx...
```

Lalu:
```bash
php artisan config:clear
php artisan fcm:test
```

### 5. Cek Apakah openssl Tersedia (Dibutuhkan untuk JWT Signing)
```bash
php -r "echo extension_loaded('openssl') ? 'openssl: OK' : 'openssl: MISSING'; echo PHP_EOL;"
```

### 6. Cek File Credentials Valid
```bash
php -r "
\$data = json_decode(file_get_contents('/home/u655654846/public_html/storage/app/firebase-credentials.json'), true);
echo 'type: ' . (\$data['type'] ?? 'MISSING') . PHP_EOL;
echo 'project_id: ' . (\$data['project_id'] ?? 'MISSING') . PHP_EOL;
echo 'client_email: ' . (\$data['client_email'] ?? 'MISSING') . PHP_EOL;
echo 'private_key: ' . (isset(\$data['private_key']) ? 'OK' : 'MISSING') . PHP_EOL;
"
```

Output yang benar:
```
type: service_account
project_id: mysimtek-pelanggan
client_email: firebase-adminsdk-xxxx@mysimtek-pelanggan.iam.gserviceaccount.com
private_key: OK
```

### 7. Cek FCM Token Tersimpan di Database
```bash
php artisan tinker --execute="
  echo App\Models\Customer::whereNotNull('fcm_token')->count() . ' customers punya FCM token' . PHP_EOL;
  \$c = App\Models\Customer::whereNotNull('fcm_token')->first();
  if (\$c) echo 'Contoh: ' . \$c->email . ' — token: ' . substr(\$c->fcm_token, 0, 30) . '...' . PHP_EOL;
"
```

### 8. Cek Laravel Log Real-time
```bash
tail -f ~/public_html/storage/logs/laravel.log | grep -i "fcm\|notification\|firebase"
# Ctrl+C untuk berhenti
```

---

## E. Test Manual via Firebase Console

1. [console.firebase.google.com](https://console.firebase.google.com) → **mysimtek-pelanggan**
2. Menu **Messaging** → **Create your first campaign** → **Firebase Notification messages**
3. Isi **Title** dan **Body**
4. **Send test message** → paste FCM token device
   - Cara ambil token dari logcat: cari `[FCM] Token:` atau `[FCM] Syncing token after login:`
5. Klik **Test**

---

## F. Flow Kerja Sistem

```
Flutter App (login)
  └─▶ FcmService.syncToken()
        └─▶ POST /api/fcm-token  {fcm_token: "..."}
              └─▶ AuthController::updateFcmToken()
                    └─▶ customers.fcm_token = "..."

Event di Laravel (invoice/tiket/complaint)
  └─▶ CustomerNotification::create(...)
        └─▶ CustomerNotificationObserver::created()
              └─▶ FcmService::sendToToken(token, title, body, data)
                    ├─▶ [Primary]  FCM V1 API (OAuth2 JWT → Bearer Token → POST fcm.googleapis.com/v1/...)
                    └─▶ [Fallback] FCM Legacy API (hanya jika V1 gagal & FIREBASE_SERVER_KEY di-set)
```

---

## G. Checklist Deploy Production

- [ ] Firebase Console: **FCM API (V1)** → Enabled
- [ ] Firebase Console: Service Account JSON di-download
- [ ] JSON di-upload ke `/home/u655654846/public_html/storage/app/firebase-credentials.json`
- [ ] Permission file: `chmod 600`
- [ ] `.env` server: `FIREBASE_CREDENTIALS=/home/u655654846/public_html/storage/app/firebase-credentials.json`
- [ ] `php artisan config:clear && php artisan cache:clear`
- [ ] `php artisan fcm:test` → sukses (log: `[FCM v1] Sent OK`)
- [ ] Flutter app login → cek logcat `[FCM] Token synced to server.`
- [ ] Cek database: `customers.fcm_token` terisi

