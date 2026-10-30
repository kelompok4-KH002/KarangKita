import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RolePengguna { admin, anggota, warga }

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

class LayananAutentikasi {
  // Mengambil peran terdaftar user yang sedang login dari Firestore
  static Future<String> getPeranUserLogin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Anggota';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'Anggota';
      }
    } catch (e) {
      // Biarkan mengembalikan fallback jika gagal
    }
    return 'Anggota';
  }

  // daftarkan akun baru murni via Firebase Auth & Firestore
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

    bool butuhPersetujuanAdmin = (peranString == 'Pengurus');

    RolePengguna role = RolePengguna.anggota;
    if (peranString == 'Pengurus') {
      role = RolePengguna.admin;
    } else if (peranString == 'Warga') {
      role = RolePengguna.warga;
    }

    final emailSynthetis = u.contains('@') ? u : '$u@karangkita.app';

    try {
      // simpan ke firebase auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailSynthetis,
        password: p,
      );

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
          final roleStr = doc.data()?['role'] ?? 'Pengurus';

          if (!isDisetujui && roleStr == 'Pengurus') {
            // Wajib signOut() terlebih dahulu jika belum disetujui
            await FirebaseAuth.instance.signOut();
            return HasilAutentikasi(
              sukses: false,
              pesan: 'Akun Pengurus Anda belum disetujui (ACC) oleh Admin Utama. Silakan hubungi Ketua Karang Taruna.',
            );
          }

          RolePengguna role = RolePengguna.admin;
          if (roleStr == 'Warga') role = RolePengguna.warga;
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