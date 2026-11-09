import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_constants.dart';

// Pengirim email notifikasi lewat EmailJS.
//
// Catatan:
// - Kuota gratis EmailJS: 200 request/bulan. Satu penerima = satu request.
// - Public Key EmailJS ikut terpasang di aplikasi (bukan rahasia).
//   Private Key JANGAN pernah ditaruh di kode.
// - Alamat penerima dibaca dari koleksi 'kontak' (salinan minimal data pengguna).
class LayananEmail {
  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';
  static const int _maksPenerima = 20;
  static const Set<String> _tipeDiemail = {
    'usulan',
    'anggota',
    'jabatan',
    'kegiatan',
    'iuran',
  };

  // Kirim email ke semua penerima dari daftar kunci notifikasi
  // ('uid:..', 'role:..', 'pengurus', 'semua'). Tidak pernah melempar error.
  static Future<void> kirimKeEmail({
    required List<String> penerima,
    required String judul,
    required String isi,
    required String tipe,
  }) async {
    if (!_tipeDiemail.contains(tipe)) return;
    try {
      final daftar = await _cariPenerima(penerima);
      for (final p in daftar) {
        await _kirimSatu(p, judul, isi);
      }
    } catch (e) {
      debugPrint('Gagal menyiapkan email notifikasi: $e');
    }
  }

  static Future<List<_Tujuan>> _cariPenerima(List<String> kunci) async {
    final db = FirebaseFirestore.instance;
    final uidPengirim = FirebaseAuth.instance.currentUser?.uid;
    final hasil = <String, _Tujuan>{};

    void tambah(String uid, Map<String, dynamic> d, {required bool wajibDisetujui}) {
      if (uid == uidPengirim) return; // jangan kirim ke diri sendiri
      if (wajibDisetujui && d['disetujui'] != true) return;
      final email = (d['email'] ?? '').toString().trim();
      if (email.isEmpty || email.endsWith('@karangkita.app')) return;
      hasil[uid] = _Tujuan(nama: (d['nama'] ?? 'Anggota').toString(), email: email);
    }

    for (final k in kunci) {
      if (hasil.length >= _maksPenerima) break;
      if (k.startsWith('uid:')) {
        final uid = k.substring(4);
        final doc = await db.collection('kontak').doc(uid).get();
        if (doc.exists) tambah(uid, doc.data()!, wajibDisetujui: false);
      } else if (k.startsWith('role:')) {
        final snap = await db
            .collection('kontak')
            .where('role', isEqualTo: k.substring(5))
            .where('disetujui', isEqualTo: true)
            .get();
        for (final d in snap.docs) {
          tambah(d.id, d.data(), wajibDisetujui: true);
        }
      } else if (k == 'pengurus' || k == 'semua') {
        final snap =
        await db.collection('kontak').where('disetujui', isEqualTo: true).get();
        for (final d in snap.docs) {
          if (k == 'pengurus' && d.data()['role'] == 'Anggota') continue;
          tambah(d.id, d.data(), wajibDisetujui: true);
        }
      }
    }
    return hasil.values.take(_maksPenerima).toList();
  }

  static Future<void> _kirimSatu(_Tujuan p, String judul, String isi) async {
    try {
      final res = await http
          .post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': AppConstants.kEmailJsServiceId,
          'template_id': AppConstants.kEmailJsTemplateId,
          'user_id': AppConstants.kEmailJsPublicKey,
          'template_params': {
            'to_email': p.email,
            'to_nama': p.nama,
            'judul': judul,
            'isi': isi,
          },
        }),
      )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        debugPrint('EmailJS gagal (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('EmailJS error: $e');
    }
  }
}

class _Tujuan {
  final String nama;
  final String email;
  const _Tujuan({required this.nama, required this.email});
}