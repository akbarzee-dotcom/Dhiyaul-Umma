# Memasang Ustadz AI (gratis)

1. Buat kunci gratis di https://aistudio.google.com/apikey (login akun Google, klik "Create API key").
2. Buka https://dash.cloudflare.com, daftar gratis, lalu **Workers & Pages > Create > Create Worker**, beri nama `dhiyaul-umma-ai`, klik **Deploy**.
3. Klik **Edit code**, hapus isinya, tempel seluruh isi `worker.js`, klik **Deploy**.
4. Di Worker itu: **Settings > Variables and Secrets > Add**, tipe **Secret**, nama `GEMINI_API_KEY`, isi kunci dari langkah 1. Simpan dan deploy.
5. Salin alamat Worker (contoh `https://dhiyaul-umma-ai.namaanda.workers.dev`).
6. Di aplikasi: tab **Tanya** > ikon pengaturan > tempel alamat tadi > Simpan.
   (Agar permanen untuk semua pengguna, isi `AI_ENDPOINT` di bagian atas script `index.html` lalu bangun ulang APK.)

Catatan: model bawaan `gemini-2.5-flash`. Bila Google menghentikannya, tambah variabel `GEMINI_MODEL` di Worker dengan nama model baru. Batas gratis ditentukan Google per proyek dan bisa berubah; lihat angkanya di AI Studio.
