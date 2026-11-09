# KarangKita – Sistem Manajemen dan Informasi Kegiatan Karang Taruna

KarangKita adalah aplikasi mobile berbasis Android yang dirancang untuk membantu organisasi Karang Taruna dalam mengelola kegiatan warga, jadwal, data anggota, usulan kegiatan, iuran taruna, serta dokumentasi secara terpusat. Aplikasi dikembangkan menggunakan Flutter dan Dart dengan dukungan Cloud Firestore, Firebase Auth, dan Cloudinary.

## Struktur Peran Pengguna (Role)

Struktur hak akses pengguna di KarangKita terbagi menjadi beberapa peran terstandarisasi serta mode tamu:

- **Ketua**: Memiliki hak akses penuh organisasi, penetapan jabatan inti, pengelolaan keanggotaan (ACC/kelola anggota), dan persetujuan akhir usulan kegiatan.
- **Sekretaris**: Mengelola dokumentasi administrasi serta meninjau dan meneruskan usulan kegiatan dari anggota ke Ketua.
- **Bendahara**: Mengelola tagihan iuran taruna, memverifikasi bukti pembayaran (ACC Lunas / Tolak), dan melihat ringkasan keuangan.
- **Pengurus**: Mengelola kegiatan, jadwal, galeri dokumentasi, serta memantau perkembangan organisasi.
- **Anggota**: Mengajukan usulan kegiatan (bottom-up), memberikan dukungan pada usulan, melakukan konfirmasi pembayaran iuran, serta mengakses jadwal dan informasi organisasi.
- **Mode Tamu (Tanpa Login)**: Tampilan hanya-lihat (read-only) bagi publik/masyarakat umum untuk memantau pengumuman dan kegiatan Karang Taruna tanpa perlu login.

## Fitur Utama

1. **Autentikasi & Pengelolaan Profil**: Login/Registrasi mandiri, persetujuan akun pengurus, dan serah terima jabatan.
2. **Pengelolaan Kegiatan & Jadwal**: Kalender interaktif, titik lokasi peta (OpenStreetMap & Google Maps Directions), dan pengumuman kegiatan.
3. **Usulan Kegiatan Bottom-Up**: Anggota mengajukan usulan $\rightarrow$ Sekretaris meninjau & meneruskan $\rightarrow$ Ketua menyetujui (ACC) menjadi kegiatan resmi.
4. **Iuran Taruna**: Form tagihan oleh Bendahara, konfirmasi bayar tunai/transfer oleh Anggota (unggah bukti ke Cloudinary), dan verifikasi pembayaran.
5. **Galeri Dokumentasi**: Pengelompokan album dokumentasi kegiatan dengan unggah foto Cloudinary.
6. **Sistem Notifikasi & Pengingat**: Notifikasi in-app terpadu serta pengingat lokal perangkat (H-1 & 1 jam sebelum acara).
