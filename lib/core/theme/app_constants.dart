// Konstanta Terpusat Aplikasi KarangKita
class AppConstants {
  // Cloudinary Configuration (Unsigned Upload Preset)
  static const String kCloudinaryCloudName = 'e2o62ft2';
  static const String kCloudinaryUploadPreset = 'karangkita_galeri';

  // Daftar 6 Kategori Kegiatan Utama Terstandarisasi
  static const List<String> kDaftarKategoriUtama = [
    'Rapat',
    'Sosial',
    'Olahraga',
    'Edukasi',
    'Kerja Bakti',
    'Acara',
  ];

  // Jabatan inti organisasi: masing-masing hanya boleh dijabat satu orang
  static const List<String> kJabatanInti = [
    'Ketua',
    'Sekretaris',
    'Bendahara',
  ];

  // Daftar Peran/Jabatan Anggota Terstandarisasi (Warga sudah dihapus)
  static const List<String> kDaftarPeranUtama = [
    'Ketua',
    'Sekretaris',
    'Bendahara',
    'Pengurus',
    'Anggota',
  ];

  // Peran yang boleh dipilih saat mendaftar sendiri.
  // Jabatan inti (Ketua/Sekretaris/Bendahara) hanya ditetapkan oleh Ketua.
  static const List<String> kPeranRegistrasi = [
    'Pengurus',
    'Anggota',
  ];

  // Data lama bisa berisi 'Warga' atau kosong -> dianggap Anggota
  static String normalisasiPeran(Object? peran) {
    final p = (peran ?? '').toString().trim();
    if (p.isEmpty || p == 'Warga') return 'Anggota';
    return p;
  }

  // Semua peran selain Anggota termasuk jajaran pengurus
  static bool isPengurus(String peran) => normalisasiPeran(peran) != 'Anggota';

  // Hanya Ketua (dan Admin lama) yang mengelola keanggotaan
  static bool bolehKelolaKeanggotaan(String peran) => peran == 'Ketua' || peran == 'Admin';
}
