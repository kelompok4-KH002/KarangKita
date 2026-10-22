import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // Storage memori lokal
  static final List<ModelPengguna> _daftarPenggunaLokal = [
    ModelPengguna(
      nama: 'Administrator',
      username: 'admin',
      whatsapp: '081234567890',
      password: 'admin123',
      role: RolePengguna.admin,
    ),
  ];

  // Registrasi Akun ke Firebase Auth & Cloud Firestore
  static Future<HasilAutentikasi> daftar({
    required String nama,
    required String username,
    required String whatsapp,
    required String password,
    required String peranString,
  }) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Data pendaftaran tidak boleh kosong.',
      );
    }

    RolePengguna role = RolePengguna.anggota;
    if (peranString == 'Pengurus') {
      role = RolePengguna.admin;
    } else if (peranString == 'Warga') {
      role = RolePengguna.warga;
    }

    // Format email sintetis untuk Firebase Auth jika input berupa username
    final emailSynthetis = u.contains('@') ? u : '$u@karangkita.app';

    try {
      // 1. Buat User di Firebase Authentication
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailSynthetis,
        password: p,
      );

      // 2. Simpan Data Profil Pengguna ke Cloud Firestore
      if (cred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'nama': nama,
          'username': u,
          'whatsapp': whatsapp,
          'role': peranString,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Fallback ke penyimpanan memori lokal jika Firebase offline
      _daftarPenggunaLokal.add(ModelPengguna(
        nama: nama,
        username: u,
        whatsapp: whatsapp,
        password: p,
        role: role,
      ));
    }

    return HasilAutentikasi(
      sukses: true,
      pesan: 'Registrasi akun berhasil!',
      role: role,
    );
  }

  // Login Akun via Firebase Auth & Firestore
  static Future<HasilAutentikasi> login({
    required String username,
    required String password,
  }) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Username dan password wajib diisi.',
      );
    }

    final emailSynthetis = u.contains('@') ? u : '$u@karangkita.app';

    try {
      // 1. Coba Login via Firebase Auth Cloud
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailSynthetis,
        password: p,
      );

      if (cred.user != null) {
        // Ambil data role dari Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
        RolePengguna role = RolePengguna.admin;
        if (doc.exists) {
          final roleStr = doc.data()?['role'] ?? 'Pengurus';
          if (roleStr == 'Warga') role = RolePengguna.warga;
          if (roleStr == 'Anggota') role = RolePengguna.anggota;
        }

        return HasilAutentikasi(
          sukses: true,
          pesan: 'Login berhasil via Firebase Cloud!',
          role: role,
        );
      }
    } catch (e) {
      // Fallback pengecekan lokal & admin default
      final userIdx = _daftarPenggunaLokal.indexWhere(
        (acc) => acc.username.toLowerCase() == u && acc.password == p,
      );

      if (userIdx != -1) {
        final user = _daftarPenggunaLokal[userIdx];
        return HasilAutentikasi(
          sukses: true,
          pesan: 'Login berhasil sebagai ${user.nama}',
          role: user.role,
        );
      }

      if ((u == 'admin' && p == 'admin123') || (u == 'admin' && p == 'admin')) {
        return HasilAutentikasi(
          sukses: true,
          pesan: 'Login berhasil sebagai Admin',
          role: RolePengguna.admin,
        );
      }
    }

    return HasilAutentikasi(
      sukses: false,
      pesan: 'Username atau password tidak cocok.',
    );
  }
}
