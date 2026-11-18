import 'package:cloud_firestore/cloud_firestore.dart';

// Model Data Patungan (Informasi Patungan Seikhlasnya / Penggalangan Dana)
class ModelPatungan {
  final String id;
  final String judul;
  final String deskripsi;
  final String metode; // 'Transfer Bank' | 'E-Wallet' | 'Tunai ke Bendahara'
  final String namaPenyedia; // mis. BCA / DANA / Bank Mandiri
  final String nomorRekening;
  final String atasNama;
  final String? kontakWa; // opsional
  final int targetDana; // 0 = tanpa target
  final int terkumpul; // default 0 (diisi manual oleh Bendahara)
  final String? batasWaktu; // ISO string, boleh kosong
  final bool aktif; // default true
  final DateTime? createdAt;

  ModelPatungan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.metode,
    required this.namaPenyedia,
    required this.nomorRekening,
    required this.atasNama,
    this.kontakWa,
    this.targetDana = 0,
    this.terkumpul = 0,
    this.batasWaktu,
    this.aktif = true,
    this.createdAt,
  });

  // Factory tangguh terhadap field kosong / null dari Cloud Firestore
  factory ModelPatungan.dariDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return ModelPatungan(
      id: data['id'] ?? doc.id,
      judul: (data['judul'] ?? '').toString(),
      deskripsi: (data['deskripsi'] ?? '').toString(),
      metode: (data['metode'] ?? 'Transfer Bank').toString(),
      namaPenyedia: (data['namaPenyedia'] ?? '').toString(),
      nomorRekening: (data['nomorRekening'] ?? '').toString(),
      atasNama: (data['atasNama'] ?? '').toString(),
      kontakWa: data['kontakWa']?.toString(),
      targetDana: (data['targetDana'] is num)
          ? (data['targetDana'] as num).toInt()
          : int.tryParse(data['targetDana']?.toString() ?? '0') ?? 0,
      terkumpul: (data['terkumpul'] is num)
          ? (data['terkumpul'] as num).toInt()
          : int.tryParse(data['terkumpul']?.toString() ?? '0') ?? 0,
      batasWaktu: data['batasWaktu']?.toString(),
      aktif: data['aktif'] ?? true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'metode': metode,
      'namaPenyedia': namaPenyedia,
      'nomorRekening': nomorRekening,
      'atasNama': atasNama,
      'kontakWa': kontakWa,
      'targetDana': targetDana,
      'terkumpul': terkumpul,
      'batasWaktu': batasWaktu,
      'aktif': aktif,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
