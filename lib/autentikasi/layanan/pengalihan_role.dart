enum RolePengguna { admin, anggota, warga }

class ModelPengguna {
  final String nama;
  final String username;
  final String whatsapp;
  final String password;
  final RolePengguna role;

  ModelPengguna({
    required this.nama,
    required this.username,
    required this.whatsapp,
    required this.password,
    required this.role,
  });
}

class HasilAutentikasi {
  final bool sukses;
  final String pesan;
  final RolePengguna? role;

  HasilAutentikasi({
    required this.sukses,
    required this.pesan,
    this.role,
  });
}

class LayananAutentikasi {
  // Storage memori akun terdaftar
  static final List<ModelPengguna> _daftarPengguna = [
    ModelPengguna(
      nama: 'Administrator',
      username: 'admin',
      whatsapp: '081234567890',
      password: 'admin123',
      role: RolePengguna.admin,
    ),
  ];

  // Registrasi Akun Baru secara Dinamis
  static Future<HasilAutentikasi> daftar({
    required String nama,
    required String username,
    required String whatsapp,
    required String password,
    required String peranString,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final u = username.trim().toLowerCase();
    if (u.isEmpty || password.trim().isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Data pendaftaran tidak boleh kosong.',
      );
    }

    // Pengecekan username apakah sudah ada
    final sudahAda = _daftarPengguna.any((p) => p.username.toLowerCase() == u);
    if (sudahAda) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Username "$u" sudah terdaftar. Silakan gunakan username lain.',
      );
    }

    // Konversi string peran ke enum RolePengguna
    RolePengguna role = RolePengguna.anggota;
    if (peranString == 'Pengurus') {
      role = RolePengguna.admin;
    } else if (peranString == 'Warga') {
      role = RolePengguna.warga;
    }

    _daftarPengguna.add(ModelPengguna(
      nama: nama,
      username: username.trim(),
      whatsapp: whatsapp.trim(),
      password: password.trim(),
      role: role,
    ));

    return HasilAutentikasi(
      sukses: true,
      pesan: 'Registrasi akun berhasil!',
      role: role,
    );
  }

  // Login Akun Dinamis
  static Future<HasilAutentikasi> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Username dan password wajib diisi.',
      );
    }

    // Cari di memori akun terdaftar
    final userIdx = _daftarPengguna.indexWhere(
      (acc) => acc.username.toLowerCase() == u && acc.password == p,
    );

    if (userIdx != -1) {
      final user = _daftarPengguna[userIdx];
      return HasilAutentikasi(
        sukses: true,
        pesan: 'Login berhasil sebagai ${user.nama}',
        role: user.role,
      );
    }

    // Bypass default admin untuk cadangan
    if ((u == 'admin' && p == 'admin123') || (u == 'admin' && p == 'admin')) {
      return HasilAutentikasi(
        sukses: true,
        pesan: 'Login berhasil sebagai Admin',
        role: RolePengguna.admin,
      );
    }

    return HasilAutentikasi(
      sukses: false,
      pesan: 'Username atau password tidak cocok.',
    );
  }
}
