enum RolePengguna { admin, anggota, warga }

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
  static Future<HasilAutentikasi> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Username dan password wajib diisi.',
      );
    }

    // Validasi akun
    if ((u == 'admin' && p == 'admin123') || (u == 'admin' && p == 'admin')) {
      return HasilAutentikasi(
        sukses: true,
        pesan: 'Login berhasil sebagai Admin',
        role: RolePengguna.admin,
      );
    }

    return HasilAutentikasi(
      sukses: false,
      pesan: 'Username atau password salah.',
    );
  }
}
