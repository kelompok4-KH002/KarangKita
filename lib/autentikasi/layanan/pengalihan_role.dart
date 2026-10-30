import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../core/theme/app_constants.dart';
import '../../notifikasi/layanan/layanan_notifikasi.dart';

enum RolePengguna { admin, anggota }

class ModelPengguna {
  final String nama;
  final String username;
  final String whatsapp;
  final RolePengguna role;

  ModelPengguna({
    required this.nama,
    required this.username,
    required this.whatsapp,
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

// Ringkasan profil pengguna yang sedang login
class ProfilSaya {
  final String uid;
  final String nama;
  final String peran;

  ProfilSaya({required this.uid, required this.nama, required this.peran});
}

class LayananAutentikasi {
  // Selama proses daftar/login berlangsung, gerbang di main.dart menahan pengguna
  // di halaman tamu supaya akun yang belum disetujui (ACC) tidak sempat masuk.
  static final ValueNotifier<bool> sesiDitahan = ValueNotifier<bool>(false);

  // Keluar dari akun (benar-benar mengakhiri sesi Firebase)
  static Future<void> keluar() => FirebaseAuth.instance.signOut();

  // Instance Firebase Auth kedua, dipakai Ketua saat membuatkan akun anggota
  // supaya sesi Ketua yang sedang login tidak tertukar dengan akun baru.
  static Future<FirebaseAuth> _authSekunder() async {
    FirebaseApp app;
    try {
      app = Firebase.app('sekunder');
    } catch (_) {
      app = await Firebase.initializeApp(
        name: 'sekunder',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  // Mengambil peran terdaftar user yang sedang login dari Firestore
  static Future<String> getPeranUserLogin() async {
    final profil = await muatProfilSaya();
    return profil?.peran ?? 'Anggota';
  }

  // Memuat uid, nama, dan peran user yang sedang login (null jika belum login)
  static Future<ProfilSaya?> muatProfilSaya() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      return ProfilSaya(
        uid: user.uid,
        nama: (data?['nama'] ?? data?['username'] ?? 'Pengguna').toString(),
        peran: AppConstants.normalisasiPeran(data?['role'] ?? data?['jabatan']),
      );
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
      return ProfilSaya(uid: user.uid, nama: 'Pengguna', peran: 'Anggota');
    }
  }

  // daftarkan akun baru murni via Firebase Auth & Firestore
  static Future<HasilAutentikasi> daftar({
    required String nama,
    required String username,
    required String whatsapp,
    required String password,
    required String peranString,
    // true jika akun dibuat oleh Ketua: sesi Ketua dipertahankan
    bool pertahankanSesi = false,
  }) async {
    if (!pertahankanSesi) sesiDitahan.value = true;
    try {
      return await _daftar(
        nama: nama,
        username: username,
        whatsapp: whatsapp,
        password: password,
        peranString: peranString,
        pertahankanSesi: pertahankanSesi,
      );
    } finally {
      if (!pertahankanSesi) {
        // Akun yang baru dibuat tidak boleh langsung masuk ke aplikasi
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        sesiDitahan.value = false;
      }
    }
  }

  static Future<HasilAutentikasi> _daftar({
    required String nama,
    required String username,
    required String whatsapp,
    required String password,
    required String peranString,
    required bool pertahankanSesi,
  }) async {
    final u = username.trim().toLowerCase();
    final p = password.trim();

    if (u.isEmpty || p.isEmpty) {
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Data pendaftaran tidak boleh kosong.',
      );
    }

    // Pendaftaran mandiri hanya untuk Pengurus atau Anggota; selain itu dianggap Anggota
    if (!AppConstants.kPeranRegistrasi.contains(peranString)) {
      peranString = 'Anggota';
    }

    bool butuhPersetujuanAdmin = (peranString == 'Pengurus');

    RolePengguna role = peranString == 'Pengurus' ? RolePengguna.admin : RolePengguna.anggota;

    final emailSynthetis = u.contains('@') ? u : '$u@karangkita.app';

    try {
      // simpan ke firebase auth (instance kedua jika sesi Ketua harus dipertahankan)
      final auth = pertahankanSesi ? await _authSekunder() : FirebaseAuth.instance;
      final cred = await auth.createUserWithEmailAndPassword(
        email: emailSynthetis,
        password: p,
      );
      if (pertahankanSesi) await auth.signOut();

      // simpan data profil ke firestore
      if (cred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'nama': nama,
          'username': u,
          'whatsapp': whatsapp,
          'role': peranString,
          'disetujui': !butuhPersetujuanAdmin,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Notifikasi keanggotaan: Ketua perlu ACC pengurus baru, pengurus tahu ada anggota baru
        if (butuhPersetujuanAdmin) {
          await LayananNotifikasi.kirim(
            penerima: [LayananNotifikasi.kePeran('Ketua'), LayananNotifikasi.kePeran('Admin')],
            judul: 'Pendaftaran pengurus baru',
            isi: '$nama mendaftar sebagai Pengurus dan menunggu persetujuan (ACC) Anda.',
            tipe: 'anggota',
          );
        } else {
          await LayananNotifikasi.kirim(
            penerima: [LayananNotifikasi.kePengurus],
            judul: 'Anggota baru bergabung',
            isi: '$nama bergabung sebagai $peranString.',
            tipe: 'anggota',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanErr = 'Gagal mendaftar. Silakan coba lagi.';
      if (e.code == 'email-already-in-use') {
        pesanErr = 'Username/Email sudah terdaftar. Gunakan username lain.';
      } else if (e.code == 'weak-password') {
        pesanErr = 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.code == 'network-request-failed') {
        pesanErr = 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
      }
      return HasilAutentikasi(
        sukses: false,
        pesan: pesanErr,
      );
    } catch (e) {
      debugPrint('Error autentikasi: $e');
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    String pesanSukses = 'Registrasi akun berhasil!';
    if (butuhPersetujuanAdmin) {
      pesanSukses = 'Registrasi berhasil! Akun Pengurus Anda sedang menunggu persetujuan (ACC) dari Admin Utama.';
    }

    return HasilAutentikasi(
      sukses: true,
      pesan: pesanSukses,
      role: role,
    );
  }

  // verifikasi login murni via Firebase Auth & Firestore
  static Future<HasilAutentikasi> login({
    required String username,
    required String password,
  }) async {
    sesiDitahan.value = true;
    try {
      return await _login(username: username, password: password);
    } finally {
      sesiDitahan.value = false;
    }
  }

  static Future<HasilAutentikasi> _login({
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
      // login auth
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailSynthetis,
        password: p,
      );

      if (cred.user != null) {
        // cek status disetujui di firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();

        if (doc.exists) {
          final isDisetujui = doc.data()?['disetujui'] ?? true;
          final roleStr = AppConstants.normalisasiPeran(doc.data()?['role'] ?? 'Pengurus');

          if (!isDisetujui && roleStr == 'Pengurus') {
            // Wajib signOut() terlebih dahulu jika belum disetujui
            await FirebaseAuth.instance.signOut();
            return HasilAutentikasi(
              sukses: false,
              pesan: 'Akun Pengurus Anda belum disetujui (ACC) oleh Admin Utama. Silakan hubungi Ketua Karang Taruna.',
            );
          }

          RolePengguna role = RolePengguna.admin;
          if (roleStr == 'Anggota') role = RolePengguna.anggota;

          return HasilAutentikasi(
            sukses: true,
            pesan: 'Login berhasil!',
            role: role,
          );
        } else {
          // Dokumen users tidak ditemukan di Firestore: Wajib signOut()
          await FirebaseAuth.instance.signOut();
          return HasilAutentikasi(
            sukses: false,
            pesan: 'Data profil akun tidak ditemukan di server.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String pesanErr = 'Username atau password tidak cocok.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanErr = 'Username atau password tidak cocok.';
      } else if (e.code == 'network-request-failed') {
        pesanErr = 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
      }
      return HasilAutentikasi(
        sukses: false,
        pesan: pesanErr,
      );
    } catch (e) {
      debugPrint('Error autentikasi: $e');
      return HasilAutentikasi(
        sukses: false,
        pesan: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }

    return HasilAutentikasi(
      sukses: false,
      pesan: 'Username atau password tidak cocok.',
    );
  }
}
