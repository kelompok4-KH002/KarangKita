import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/theme/app_constants.dart';

// Model satu notifikasi untuk pengguna yang sedang login
class ModelNotifikasi {
  final String id;
  final String judul;
  final String isi;
  final String tipe; // 'anggota' | 'jabatan' | 'usulan'
  final DateTime waktu;
  final bool dibaca;

  ModelNotifikasi({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.waktu,
    required this.dibaca,
  });
}

// Notifikasi in-app berbasis Cloud Firestore (koleksi 'notifikasi').
//
// Setiap dokumen punya field `penerima` berisi kunci tujuan:
//   'uid:<uid>'   -> satu orang tertentu
//   'role:<Peran>' -> semua pemegang peran/jabatan tertentu (mis. 'role:Ketua')
//   'pengurus'    -> seluruh jajaran pengurus (semua peran selain Anggota)
// Status baca disimpan per orang di `dibacaOleh` (array uid).
class LayananNotifikasi {
  static CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('notifikasi');

  // Pembuat kunci penerima
  static String keUid(String uid) => 'uid:$uid';
  static String kePeran(String peran) => 'role:$peran';
  static const String kePengurus = 'pengurus';

  // Kirim notifikasi. Kegagalan kirim tidak boleh menggagalkan aksi utama,
  // jadi hanya dicatat ke log.
  static Future<void> kirim({
    required List<String> penerima,
    required String judul,
    required String isi,
    required String tipe,
  }) async {
    try {
      await _col.add({
        'penerima': penerima,
        'judul': judul,
        'isi': isi,
        'tipe': tipe,
        'dibacaOleh': <String>[],
        'dibuatOleh': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gagal mengirim notifikasi: $e');
    }
  }

  // Aliran notifikasi milik pengguna (terbaru di atas)
  static Stream<List<ModelNotifikasi>> alirkan(String uid, String peran) {
    final kunci = <String>[
      keUid(uid),
      kePeran(peran),
      if (AppConstants.isPengurus(peran)) kePengurus,
    ];

    return _col.where('penerima', arrayContainsAny: kunci).snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final d = doc.data();
        final dibacaOleh = List<String>.from(d['dibacaOleh'] ?? const []);
        return ModelNotifikasi(
          id: doc.id,
          judul: d['judul'] ?? '',
          isi: d['isi'] ?? '',
          tipe: d['tipe'] ?? '',
          waktu: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          dibaca: dibacaOleh.contains(uid),
        );
      }).toList();
      list.sort((a, b) => b.waktu.compareTo(a.waktu));
      return list;
    });
  }

  static Future<void> tandaiDibaca(String id, String uid) async {
    try {
      await _col.doc(id).update({
        'dibacaOleh': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      debugPrint('Gagal menandai notifikasi dibaca: $e');
    }
  }

  static Future<void> tandaiSemuaDibaca(List<ModelNotifikasi> daftar, String uid) async {
    final belumDibaca = daftar.where((n) => !n.dibaca).toList();
    if (belumDibaca.isEmpty) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in belumDibaca) {
        batch.update(_col.doc(n.id), {
          'dibacaOleh': FieldValue.arrayUnion([uid]),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Gagal menandai semua notifikasi dibaca: $e');
    }
  }
}
