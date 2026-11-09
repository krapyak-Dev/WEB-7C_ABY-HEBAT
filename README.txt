WEBSITE KELAS VII-C — PETUNJUK PEMASANGAN

ISI FOLDER
- index.html: halaman website
- style.css: desain dark gold
- app.js: fungsi login, presensi, jadwal, piket, kas, pengumuman, QR scanner
- supabase-schema.sql: tabel, trigger, dan aturan keamanan database
- logo-kelas.png: taruh gambar logo kelas yang kamu kirim dengan nama ini

LANGKAH 1 — SIAPKAN SUPABASE
1. Buka project Supabase yang sudah kamu buat.
2. Buka SQL Editor > New query.
3. Buka file supabase-schema.sql, salin seluruh isinya, tempel ke SQL Editor, lalu klik Run.
4. Buka Project Settings > API.
5. Salin Project URL dan publishable key (atau anon public key). JANGAN gunakan secret/service_role key.

LANGKAH 2 — MASUKKAN KUNCI SUPABASE
1. Buka app.js.
2. Cari:
   const SUPABASE_URL = "ISI_PROJECT_URL";
   const SUPABASE_ANON_KEY = "ISI_PUBLISHABLE_ATAU_ANON_KEY";
3. Ganti teks di dalam tanda kutip dengan URL dan publishable/anon key milik project kamu.

LANGKAH 3 — BUAT 30 AKUN
1. Supabase > Authentication > Users > Add user.
2. Buat 28 akun siswa dan 2 akun admin. Gunakan email dan password masing-masing.
3. Setelah semua akun dibuat, buka SQL Editor dan jalankan:
   update public.profiles set role='admin'
   where email in ('emailadmin1@contoh.com','emailadmin2@contoh.com');
   Ganti email contoh dengan dua email admin milikmu.
4. Semua akun baru otomatis dibuat sebagai role siswa. Jangan membagikan password admin kepada siswa.

LANGKAH 4 — ISI PROFIL SISWA DAN QR
1. Login sebagai admin.
2. Kelola Kelas > Siswa.
3. Isi email akun, nama siswa, dan kode unik misalnya VIIC-001 sampai VIIC-028.
4. Cetak/generate QR Code yang isi teksnya persis kode unik itu. QR Code hanya untuk identifikasi presensi, bukan rahasia login.

LANGKAH 5 — UPLOAD KE GITHUB
1. Buat repository GitHub, misalnya website-kelas-vii-c.
2. Upload index.html, style.css, app.js, supabase-schema.sql, README.txt, dan logo-kelas.png ke ROOT repository (bukan di dalam folder lain).
3. Repository > Settings > Pages.
4. Build and deployment: Deploy from a branch.
5. Branch: main, folder: /(root), klik Save.
6. Tunggu proses selesai lalu buka URL GitHub Pages.

CATATAN PENTING
- Kamera QR membutuhkan HTTPS. GitHub Pages sudah menggunakan HTTPS.
- Scanner QR hanya tersedia pada akun admin.
- Jangan pernah memasukkan Supabase secret/service_role key ke app.js atau GitHub.
- Presensi otomatis dari QR akan mencatat MASUK pada tanggal hari ini. Admin masih bisa mengubah status manual.
- Website ini adalah starter project. Uji dahulu dengan beberapa akun percobaan sebelum dipakai seluruh kelas.
- Jangan taruh password siswa di repository.
