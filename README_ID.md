# CaveDive: Blue Abyss — Expedition Update v0.4

**Project Godot 4.7.2 / Android only / landscape / renderer GL Compatibility.**

> Status: source prototipe v0.4 siap di-review. ZIP belum dipush ke GitHub. Build APK v0.4 **belum** diuji pada runner Godot. Rute terinspirasi karakter gua batu kapur/karst di dunia nyata, namun **sepenuhnya fiktif** dan bukan peta gua nyata, bukan perangkat navigasi atau perencanaan penyelaman.

## Apa yang berubah sejak v0.3

1. **Tidak lagi langsung mulai di gua.** Sekarang title screen berlatarkan dek kapal ekspedisi 3D, kemudian pilih lokasi, briefing, dan animasi transisi turun ke air.
2. **Dua lokasi ekspedisi baru:** Umbral Cenote (fiksi dengan suasana batu kapur bergaya Yucatan) dan Black Karst System (fiksi bergaya karst tropis). Rute panjangnya sekitar 500–700 meter per arah sesuai data jalur di source, dengan 3 beacon, beberapa ruang luas dan area penyempitan. Setiap lokasi punya profil kedalaman, kelokan, dan kesulitan berbeda.
3. **HUD baru:** panel dive computer, tekanan gas, kedalaman, waktu, kompas, status misi, peta sonar lokal, peta survei penuh, peringatan, dan tombol jeda.
4. **Ikon asli vektor dalam Godot:** panah naik, panah turun, lampu senter, peta, pause, play, kedalaman, tabung gas, kompas, waktu, audio, dan tombol kembali. Tidak bergantung pada font emoji.
5. **Audio:** ambience permukaan laut saat di kapal; perpindahan ke suara napas regulator, gelembung, air bawah laut, sirip, dan bunyi checkpoint ketika menyelam. Semua audio offline OGG.
6. **Kontrol mobile:** joystick kiri, drag kanan untuk melihat, ikon naik/turun dan lampu di kanan. Tetap mendukung keyboard/mouse saat uji di PC.
7. **Performa:** guideline disatukan menjadi MultiMesh, tetap memakai material ringan dan GL Compatibility. Ikon digambar vektor. Map redrawn sekitar 8 kali/detik.
8. **Workflow GitHub:** memasukkan pemeriksaan file penting, validasi GDScript, dan smoke test scene awal sebelum ekspor APK ARM64.

## Alur game

`Title → Deck kapal → Pilih Umbral Cenote / Black Karst → Briefing → Descent → Dive POV → 3 beacon → Kembali ke pintu gua → Hasil → Kembali ke kapal`

## Cara build di GitHub Actions

1. Ekstrak ZIP, pastikan `project.godot` berada di direktori root repository.
2. Upload **seluruh isi** proyek, termasuk `.github/workflows/android.yml` dan semua aset `assets/`.
3. Buka **GitHub → Actions → CaveDive Android APK → Run workflow**.
4. Setelah berhasil, unduh artifact `CaveDive-Android-debug-APK`, ekstrak, dan instal APK. Debug APK hanya untuk pengujian, belum siap publikasi Play Store.
5. Jika ada error, salin pesan terakhir dari `Validate scripts`, `Smoke test`, atau `Export Android debug APK`.

Proyek ini tidak memerlukan akun, API, server, atau koneksi internet selama bermain.

## Kontrol

- **Android**: joystick kiri untuk berenang; geser di area kanan untuk memandang; tombol ↑ untuk naik, ↓ untuk turun, ikon senter untuk lampu, ikon peta, ikon jeda.
- **PC untuk pengujian**: WASD, mouse, Space naik, Ctrl turun, Shift berenang cepat, F lampu, M peta, Esc/P jeda.
- Di menu jeda, kontrol **AUDIO** mematikan/menghidupkan semua SFX.

## Catatan dan batasan prototipe

- Dua lokasi bukan rekonstruksi 1:1 gua asli. Panjang jalur di HUD hanya panjang garis pusat yang dihitung dari titik rute.
- Tidak ada sistem dekompresi, nitrox, redundansi tabung, atau simulasi fisika gas yang aman untuk digunakan pada penyelaman sungguhan. Pemakaian gas sengaja dipercepat/diperlambat untuk gameplay.
- Perahu dan batu adalah geometri 3D low-poly/prosedural, bukan aset photogrammetry. Pembenahan kualitas artistik bisa menjadi tahap lanjut.
- Rute samping masih sebatas data desain (`dive_sites.gd`) dan belum merupakan galeri yang bisa dijelajahi; dua jalur utama dan checkpoint aktif.
- Batas performa FPS di berbagai model Android belum diukur. Coba APK debug di perangkat nyata setelah workflow berhasil.
- Paket ini **tidak** memodifikasi atau mengunggah apapun ke `Ihsan113/Cavingdiving` tanpa perintah push.

## Struktur file

- `scenes/main.tscn` — scene induk.
- `scripts/main.gd` — state machine menu, kapal, pilihan map, briefing, dive, HUD, pause dan hasil.
- `scripts/boat_lobby.gd` — lingkungan kapal/perahu riset dan lautan.
- `scripts/dive_sites.gd` — data dua rute dan metadata lokasi.
- `scripts/cave_builder.gd` — gua prosedural batu kapur dengan collision dan guideline.
- `scripts/dive_map.gd` — diagram peta navigasi.
- `scripts/hud_glyph.gd` — gambar ikon vektor.
- `scripts/diver.gd` — gerak penyelam POV.
- `scripts/dive_audio.gd` — sistem SFX bawah air.
- `assets/audio/` — keenam audio OGG termasuk `boat_ocean.ogg`.
- `.github/workflows/android.yml` — ekspor APK debug melalui Actions.
- `tools/verify_project.py` — pemeriksaan statis berkas dan audio sebelum build.
