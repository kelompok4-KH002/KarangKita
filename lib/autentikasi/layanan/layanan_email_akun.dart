import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ubah email akun dengan aman lewat tautan verifikasi dari Firebase.
// Email di Auth berubah SETELAH tautan diklik; Firestore disinkronkan sesudahnya.
class LayananEmailAkun {
  LayananEmailAkun._();

  // Kirim tautan verifikasi ke email baru. Mengembalikan null jika sukses,
  // atau pesan error untuk ditampilkan.
  static Future<String?> mintaUbahEmail({
    required String emailBaru,
    required String passwordSaatIni,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final emailLama = user?.email;
    if (user == null || emailLama == null) return 'Kamu belum login';

    final baru = emailBaru.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(baru)) {
      return 'Format email tidak valid';
    }
    if (baru.endsWith('@karangkita.app')) return 'Gunakan email asli';
    if (baru == emailLama.toLowerCase()) return 'Email sama dengan yang sekarang';

    try {
      // Operasi sensitif: butuh login baru, jadi konfirmasi kata sandi dulu.
      final cred = EmailAuthProvider.credential(email: emailLama, password: passwordSaatIni);
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(baru);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Kata sandi salah';
        case 'email-already-in-use':
          return 'Email itu sudah dipakai akun lain';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
        default:
          return 'Gagal: ${e.code}';
      }
    }
  }

  // Panggil setelah profil dimuat. Jika email di Auth sudah berubah (dan terverifikasi),
  // salin ke users dan kontak. Tidak pernah melempar error.
  static Future<void> sinkronkanEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      final emailAuth = user?.email;
      if (user == null || emailAuth == null) return;
      if (emailAuth.endsWith('@karangkita.app') || !user.emailVerified) return;

      final db = FirebaseFirestore.instance;
      final ref = db.collection('users').doc(user.uid);
      final doc = await ref.get();
      if (!doc.exists || (doc.data()?['email'] ?? '') == emailAuth) return;

      await ref.update({'email': emailAuth});
      try {
        await db.collection('kontak').doc(user.uid).update({'email': emailAuth});
      } catch (_) {
        // Dokumen kontak mungkin belum ada; tidak masalah.
      }
    } catch (_) {}
  }
}
