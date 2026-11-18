import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/model_patungan.dart';

// Layanan Cloud Firestore untuk Koleksi 'patungan'
class LayananPatungan {
  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('patungan');

  // Stream semua data patungan diurutkan dari yang terbaru
  static Stream<List<ModelPatungan>> streamSemua() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(ModelPatungan.dariDoc).toList();
      list.sort((a, b) {
        final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tB.compareTo(tA);
      });
      return list;
    });
  }

  // Stream data patungan yang berstatus aktif (aktif == true)
  static Stream<List<ModelPatungan>> streamAktif() {
    return streamSemua().map((list) => list.where((p) => p.aktif).toList());
  }

  // Tambah data patungan baru
  static Future<void> tambah(ModelPatungan patungan) async {
    final ref = _col.doc(patungan.id.isNotEmpty ? patungan.id : null);
    final idBaru = ref.id;
    final Map<String, dynamic> data = patungan.toMap();
    data['id'] = idBaru;
    await ref.set(data);
  }

  // Ubah data patungan
  static Future<void> ubah(ModelPatungan patungan) async {
    await _col.doc(patungan.id).set(patungan.toMap(), SetOptions(merge: true));
  }

  // Hapus data patungan
  static Future<void> hapus(String id) async {
    await _col.doc(id).delete();
  }

  // Ubah status aktif/nonaktif patungan
  static Future<void> ubahStatusAktif(String id, bool aktif) async {
    await _col.doc(id).update({'aktif': aktif});
  }
}
