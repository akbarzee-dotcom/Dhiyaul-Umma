# Dhiyaul Umma

Aplikasi ibadah: jadwal sholat, Al-Qur'an, kiblat, Sirah, dan 6 kitab Maulid (166 halaman).

## Membuat APK (tanpa Android Studio)
1. Buat akun gratis di github.com, lalu buat repositori baru (Private boleh).
2. Unggah **seluruh isi folder ini** (termasuk folder `.github`, `assets`, `tools`) lewat "Add file > Upload files".
3. Buka tab **Actions** > **Bangun APK Dhiyaul Umma** > **Run workflow**. Tunggu sekitar 5-8 menit.
4. Buka proses yang selesai, unduh **dhiyaul-umma-apk** di bagian Artifacts, ekstrak zip-nya, dan salin `app-debug.apk` ke HP.
5. Di HP, buka file APK dan izinkan "Pasang dari sumber ini" jika diminta.

Setelah memasang versi baru: buka aplikasi, di halaman Beranda tekan **Aktifkan** pada kotak notifikasi, lalu pilih **Izinkan**. Jika sebelumnya sudah terpasang versi lama, cukup pasang APK baru di atasnya.

Catatan: APK ini bertanda tangan debug sehingga bisa dipasang langsung di HP, tapi belum untuk Google Play.

## Suara adzan
Taruh dua file MP3 di folder `assets/audio/` sebelum membangun APK, dengan nama persis:
- `adzan.mp3` : adzan untuk Dzuhur, Ashar, Maghrib, Isya
- `adzan_subuh.mp3` : adzan khusus Subuh

Catatan: Android biasanya hanya memutar suara notifikasi yang singkat. Adzan penuh (beberapa menit) bisa terpotong, tergantung merek HP.

## Alternatif: pasang sebagai PWA
Unggah folder ke hosting HTTPS (GitHub Pages, Netlify, dsb), buka di Chrome Android, lalu menu > **Pasang aplikasi**.
Sensor kompas dan GPS hanya bekerja lewat HTTPS atau di dalam APK.

## Alternatif: build di komputer sendiri
Butuh Node 20, JDK 17, Android Studio. Jalankan:
```
mkdir www && cp -r index.html manifest.webmanifest sw.js assets vendor www/
npm install && npx cap add android && bash tools/configure-android.sh && npx cap sync android
cd android && ./gradlew assembleDebug
```
APK ada di `android/app/build/outputs/apk/debug/app-debug.apk`.
