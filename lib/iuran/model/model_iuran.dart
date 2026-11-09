import 'package:cloud_firestore/cloud_firestore.dart';

// Model Data Tagihan Iuran Taruna
class ModelIuran {
  final String id;
  final String judul;
  final int nominal;
  final DateTime jatuhTempo;
  final String dibuatOleh;
  final DateTime dibuat;

  ModelIuran({
    required this.id,
    required this.judul,
    required this.nominal,
    required this.jatuhTempo,
    required this.dibuatOleh,
    DateTime? dibuat,
  }) : dibuat = dibuat ?? DateTime.now();

  factory ModelIuran.dariDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final tglJatuhTempo = DateTime.tryParse(d['jatuhTempo'] ?? '') ?? DateTime.now();
    return ModelIuran(
      id: d['id'] ?? doc.id,
      judul: d['judul'] ?? '',
      nominal: (d['nominal'] as num?)?.toInt() ?? 0,
      jatuhTempo: tglJatuhTempo,
      dibuatOleh: d['dibuatOleh'] ?? '',
      dibuat: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> keMap() => {
        'id': id,
        'judul': judul,
        'nominal': nominal,
        'jatuhTempo': jatuhTempo.toIso8601String(),
        'dibuatOleh': dibuatOleh,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// Model Data Pembayaran Iuran Anggota
class ModelPembayaran {
  final String id;
  final String iuranId;
  final String uidAnggota;
  final String namaAnggota;
  final String metode; // 'Transfer' | 'Tunai'
  final String buktiUrl; // opsional untuk tunai
  final String status; // 'Menunggu' | 'Lunas' | 'Ditolak'
  final String catatan;
  final DateTime dibuat;

  ModelPembayaran({
    required this.id,
    required this.iuranId,
    required this.uidAnggota,
    required this.namaAnggota,
    required this.metode,
    this.buktiUrl = '',
    this.status = 'Menunggu',
    this.catatan = '',
    DateTime? dibuat,
  }) : dibuat = dibuat ?? DateTime.now();

  factory ModelPembayaran.dariDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ModelPembayaran(
      id: d['id'] ?? doc.id,
      iuranId: d['iuranId'] ?? '',
      uidAnggota: d['uidAnggota'] ?? '',
      namaAnggota: d['namaAnggota'] ?? '',
      metode: d['metode'] ?? 'Transfer',
      buktiUrl: d['buktiUrl'] ?? '',
      status: d['status'] ?? 'Menunggu',
      catatan: d['catatan'] ?? '',
      dibuat: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> keMap() => {
        'id': id,
        'iuranId': iuranId,
        'uidAnggota': uidAnggota,
        'namaAnggota': namaAnggota,
        'metode': metode,
        'buktiUrl': buktiUrl,
        'status': status,
        'catatan': catatan,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
