import 'package:cloud_firestore/cloud_firestore.dart';

class HasilMigrasiAgenda {
  final int totalJadwal;
  final int disalin;
  final int dilewati;

  HasilMigrasiAgenda({
    required this.totalJadwal,
    required this.disalin,
    required this.dilewati,
  });
}

class LayananMigrasiAgenda {
  // Migrasi manual sekali jalan dari koleksi 'jadwal' ke koleksi terpadu 'kegiatan'
  static Future<HasilMigrasiAgenda> migrasikanJadwalKeKegiatan() async {
    final snapJadwal = await FirebaseFirestore.instance.collection('jadwal').get();
    final snapKegiatan = await FirebaseFirestore.instance.collection('kegiatan').get();

    final Set<String> existingKeys = {};
    for (var doc in snapKegiatan.docs) {
      final data = doc.data();
      final j = (data['judul'] ?? '').toString().trim().toLowerCase();
      final l = (data['lokasi'] ?? '').toString().trim().toLowerCase();
      final tglRaw = DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now();
      final tglOnly = '${tglRaw.year}-${tglRaw.month}-${tglRaw.day}';
      existingKeys.add('${j}_${tglOnly}_$l');
    }

    int disalin = 0;
    int dilewati = 0;
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapJadwal.docs) {
      final data = doc.data();
      final oldId = doc.id;
      final newDocId = 'jadwal_$oldId';

      final j = (data['judul'] ?? '').toString().trim().toLowerCase();
      final l = (data['lokasi'] ?? '').toString().trim().toLowerCase();
      final tglRaw = DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now();
      final tglOnly = '${tglRaw.year}-${tglRaw.month}-${tglRaw.day}';
      final keyCheck = '${j}_${tglOnly}_$l';

      if (existingKeys.contains(keyCheck)) {
        dilewati++;
      } else {
        existingKeys.add(keyCheck);
        disalin++;

        final docRef = FirebaseFirestore.instance.collection('kegiatan').doc(newDocId);
        batch.set(
          docRef,
          {
            'id': newDocId,
            'judul': data['judul'] ?? '',
            'tanggal': tglRaw.toIso8601String(),
            'waktu': data['waktu'] ?? data['jam'] ?? '07:30 WIB',
            'lokasi': data['lokasi'] ?? '',
            'kategori': data['kategori'] ?? 'Rapat',
            'deskripsi': data['deskripsi'] ?? '',
          },
          SetOptions(merge: true),
        );
      }
    }

    if (disalin > 0) {
      await batch.commit();
    }

    return HasilMigrasiAgenda(
      totalJadwal: snapJadwal.docs.length,
      disalin: disalin,
      dilewati: dilewati,
    );
  }
}
