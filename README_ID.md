# CaveDive: Blue Abyss — Expedition Update v0.5

**Android-only (landscape), Godot 4.7.2, GDScript, offline, ARM64 debug export.**

## Apa yang berubah dari v0.4?

### Peta 01 — UMBRAL CENOTE (pembaruan utama)

- Rute utama 3D sekitar **678 meter (satu arah)** dengan perubahan kedalaman sampai **47 m (skala gameplay)**.
- **6 lorong samping yang benar-benar dibuat sebagai mesh 3D dengan collision** — bukan hanya garis dalam peta.
- **3 rute alternatif yang menyambung kembali** ke jalur utama serta **3 jalan buntu** untuk eksplorasi dan risiko tersesat.
- **Shaft naik hampir vertikal**, penurunan tajam, ruang junction besar yang terbuka, ruang lebar dan tiga restriction sempit.
- Geometri junction dirancang memiliki portal/holes agar perpindahan antarlorong bisa dilakukan.
- Guideline kuning hanya berada di jalur utama. Galeri samping baru diperlihatkan di peta setelah ditemukan. Peta penuh juga memiliki grafik profil kedalaman.
- **Batu tajam** berupa mesh runcing dan `Area3D` yang mendeteksi pemain dan menyebabkan cedera.

### Peta 02 — BLACK KARST SYSTEM

Rute utama tetap dari v0.4. Tiga galeri sampingnya kini juga dibentuk secara fisik dan disambungkan melalui junction terbuka (meskipun fokus desain v0.5 berada pada map 01).

### Penyakit/cedera = mekanik gameplay, bukan model medis

- HP dipisahkan menjadi **kepala, torso, lengan, dan kaki**; terlihat pada siluet dan bar status.
- Benturan batu menurunkan HP bagian tubuh tertentu dan integritas suit. Kontak berulang memiliki cooldown supaya satu batu tidak menghabiskan HP dalam satu frame.
- Suit rusak mengakibatkan konsumsi gas lebih cepat; dua **SEAL SUIT** patch bisa memperbaiki kebocoran, tetapi **tidak menyembuhkan cedera**.
- Cedera kaki memperlambat renang, torso menaikkan konsumsi gas, tangan melemahkan penerangan, dan kepala membatasi visibilitas.
- Misi tetap dapat diakhiri dengan kembali ke pintu masuk setelah memperoleh sebagian checkpoint: *safe partial extraction*.

### Instruktur NPC

- **Instructor Maya** hadir sebagai model penyelam 3D dengan perlengkapan, sirip animasi, dan lampu cadangan.
- Maya berenang mengikuti rute panduan utama, bukan menyelusup menembus dinding, dan menunggu ketika pemain mengambil cabang yang jauh.
- Sebelum bergerak ada **tutorial 4 langkah** dengan tombol NEXT, SKIP, dan DIVE NOW.
- Instruksi situasional berupa **subtitle radio** dan bunyi komunikasi orisinal: saat menemukan junction, menyimpang dari jalur, terkena batu, atau gas rendah. **Belum ada voice acting narasi NPC**.

### Audio

Mempertahankan SFX offline v0.4 (kapal, ambience gua, napas, gelembung, sirip, beacon) dan menambah suara orisinal **gesekan/benturan batu** serta **chirp radio instruktur**.

## Cara build melalui GitHub Actions

1. Upload SELURUH isi folder proyek (termasuk `.github/workflows/android.yml`, `scripts/`, `tools/`, dan `assets/`) ke repository yang kamu pilih.
2. GitHub → **Actions → CaveDive Android APK → Run workflow**, atau push ke `main` agar workflow berjalan otomatis.
3. Workflow menjalankan: preflight file/aset, validasi geometri authored cave, import Godot, *title smoke test*, **dua-map gameplay smoke test** untuk NPC + cedera, lalu Android debug export.
4. Bila hijau, download artifact `CaveDive-Android-debug-APK`, ekstrak lalu instal file APK di ponsel ARM64.
5. Bila merah, kirim URL job error. **Belum ada APK v0.5 terverifikasi dari runner.**

## Kontrol

- **Joystick kiri** = berenang maju/mundur/samping.
- **Drag layar kanan** = kamera POV.
- **Panah atas / bawah** = naik/turun.
- **Senter** = nyalakan/matikan lampu.
- **Map** = peta penuh + profil vertikal.
- **SEAL SUIT** = memperbaiki kebocoran bila terluka, stok dua kali.
- **Pause** = lanjut atau kembali ke kapal.

## Catatan teknis dan keselamatan

- **Bukan simulator prosedur penyelaman sungguhan.** Tekanan tabung, HP, jarak, narasi instruktur, gas consumption, dan risikonya memakai aturan gameplay buatan.
- Map adalah **fiksi orisinal yang terinspirasi bentang karst**, bukan rekonstruksi gua nyata atau peta navigasi.
- Visual gua dibuat dari mesh prosedural dan tekstur murah untuk GPU Android. Performa harus diuji pada perangkat fisik.
- Rilis ini **source review ZIP, belum di-push ke GitHub oleh asisten**. Pemilik repository dapat memeriksa diff dahulu.
