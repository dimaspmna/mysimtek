Karena Anda menggunakan **Linux**, prosesnya sangat efisien lewat terminal. Untuk nama aplikasi `mysimtek-pelanggan`, berikut adalah langkah-langkah spesifiknya:

### 1. Generate Keystore di Linux
Buka terminal di dalam folder project Flutter Anda dan jalankan perintah ini. Saya sarankan simpan langsung di folder `android/app` agar mudah dibaca oleh Gradle:

```bash
keytool -genkey -v -keystore android/app/mysimtek-keystore.jks \
        -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
        -alias mysimtek-key
```

Password keystore: R4h4s1a@cogline

**Penting:**
* **Password:** Gunakan password yang kuat dan catat!
* **Data Diri:** Isi Nama, Organisasi (PT Pasukan Telekomunikasi Indonesia), dan Lokasi sesuai data yang Anda daftarkan di DUNS agar konsisten.

---

### 2. Konfigurasi `key.properties`
Buat file di `android/key.properties`:

```properties
storePassword=isi_password_anda
keyPassword=isi_password_anda
keyAlias=mysimtek-key
storeFile=mysimtek-keystore.jks
```

---

### 3. Update `build.gradle`
Edit file `android/app/build.gradle`. Pastikan bagian `signingConfigs` merujuk ke file `.jks` yang baru saja kita buat:

```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias 'mysimtek-key'
            keyPassword 'isi_password_anda'
            storeFile file('mysimtek-keystore.jks')
            storePassword 'isi_password_anda'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // Tambahkan ini untuk optimasi ukuran
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

### 4. Build App Bundle (AAB)
Untuk rilis ke Play Store, Google mewajibkan format **.aab**. Jalankan perintah ini:

```bash
# Bersihkan build lama
flutter clean

# Ambil dependencies terbaru
flutter pub get

# Build bundle untuk rilis
flutter build appbundle --release

# Build apk untuk rilis
flutter build apk --release
```

Jika Anda ingin melakukan **obfuscation** (agar kode aplikasi tidak mudah dibaca/di-decompile orang lain), gunakan perintah ini:
```bash
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
```

---

### 5. Lokasi File Final
Setelah selesai, file yang akan Anda upload ke Google Play Console berada di:
`[project_folder]/build/app/outputs/bundle/release/app-release.aab`

---

### Tips Khusus Linux User:
1.  **Backup Keystore:** Di Linux, file `.jks` Anda sangat krusial. Segera salin file `mysimtek-keystore.jks` ke tempat yang aman (misal: Cloud Storage atau External Drive). Jika file ini hilang, Anda **tidak akan pernah bisa** mengupdate aplikasi `mysimtek-pelanggan` di Play Store.
2.  **Permission:** Jika terjadi error *Permission Denied* saat build, pastikan folder project memiliki hak akses yang benar: `chmod -R 755 android/`.
3.  **Git Ignore:** Jangan lupa tambahkan `android/app/*.jks` dan `android/key.properties` ke file `.gitignore` agar rahasia dapur tidak bocor ke repository.

Sudah berhasil generate file `.aab`-nya?