# CaveDive: Blue Abyss — Game Godot 3D khusus Android

**Versi:** Prototipe v0.2 (Android-only output)
**Engine:** Godot 4.7.2 stable, GDScript, GL Compatibility
**APK:** Dibuat otomatis oleh GitHub Actions. ZIP ini adalah *source project*, bukan APK.

## Isi game saat ini
- 3D first-person / POV penyelam.
- Mulut gua dan lorong terendam, bentukan batu procedurally generated, dan collision dinding.
- Tali navigasi kuning, 3 checkpoint survei, lalu kembali ke pintu gua.
- Konsumsi gas tabung (bar) yang lebih cepat saat penyelam semakin dalam.
- Depth gauge, dive timer, compass, jarak tujuan, dan peringatan gas.
- Mini-map, peta besar, senter, silt-out saat mendekati dasar.
- Statistik dan layar misi selesai / gagal.
- HUD mobile landscape; joystick kiri + geser sisi kanan untuk kamera, tombol ASCEND, DESCEND, TORCH, MAP dan PAUSE.
- Renderer GL Compatibility, ARM64 untuk Android.

## Build via GitHub Actions (langsung dari HP)
1. Ekstrak ZIP ke sebuah folder di HP (misalnya `Download/CaveDive_Android_Godot`).
2. Buat repository GitHub baru (contoh `cavedive-android`, gunakan branch `main`).
3. Upload **isi** folder proyek ke **root** repo GitHub, termasuk folder tersembunyi `.github/workflows/android.yml`.
   Jangan cuma upload file `.zip` sebagai satu file, karena GitHub Actions memerlukan file `.yml` di root repository.
4. Di halaman GitHub, buka **Actions** -> **CaveDive Android APK** -> **Run workflow** -> Run workflow.
5. Saat job sukses, buka halaman run tersebut -> bagian **Artifacts** -> `CaveDive-Android-debug-APK`.
6. Unduh ZIP artifact, ekstrak, kemudian instal `CaveDive-Android-debug.apk` pada perangkat Android.

## Upload GitHub melalui Termux (mudah untuk struktur folder tersembunyi)
Jika folder sudah diekstrak ke `~/cavedive-android` dan GitHub CLI sudah login (`gh auth login`), jalankan:

```sh
cd ~/cavedive-android
git init -b main
git add .
git commit -m "Initial CaveDive Android prototype"
gh repo create cavedive-android --private --source=. --remote=origin --push
```

Catatan: `gh repo create` hanya untuk repo baru; jika repo sudah dibuat di web, pakai `git remote add origin https://github.com/USER/REPO.git` lalu `git push -u origin main`.
Untuk memasang alat di Termux: `pkg install git gh unzip -y`.

## Kendala yang mungkin muncul
- **Workflow tak muncul:** pastikan `.github/workflows/android.yml` ikut di-push pada branch `main`.
- **Build gagal:** buka job -> lihat langkah yang merah dan kirim screenshot/log kesalahannya.
- **Tidak ada tombol Run workflow:** pastikan sedang melihat workflow di branch default.
- **APK tidak bisa di-update dari versi sebelumnya:** kunci debug dibuat baru setiap run. Uninstall APK prototipe lama, lalu instal hasil build baru. Untuk update tanpa uninstall perlu debug keystore persisten; untuk rilis resmi gunakan keystore release pribadi yang aman.
- **APK terlalu besar:** APK mengandung runtime Godot; ZIP source kecil tidak mencerminkan ukuran APK.

## Rencana setelah prototipe
Tahap berikut: 2-3 cabang gua, bagian gua sempit, peta yang dibuka dengan eksplorasi, indikator arah pulang, suara napas dan gelembung, optimasi FPS, efek kekeruhan, dan peningkatan visual material batu.

**Penting:** Indikator gas/kedalaman dalam prototipe adalah mekanik game yang disederhanakan; **tidak** cocok untuk merencanakan penyelaman sungguhan. Cave diving nyata berisiko tinggi dan membutuhkan pelatihan serta redundansi gas.

**Status verifikasi:** integritas dan struktur ZIP diperiksa lokal. Engine Godot dan akses runner GitHub tidak tersedia di lingkungan pembuat, jadi APK belum di-build/diuji pada perangkat. Workflow disiapkan menurut persyaratan ekspor resmi Godot 4.7.
