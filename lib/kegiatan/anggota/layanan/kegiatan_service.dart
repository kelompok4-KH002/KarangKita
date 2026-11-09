// =====================================================================
// kegiatan_service.dart  -  Semua urusan DATABASE untuk kegiatan & galeri (anggota)
// =====================================================================
// Isi file ini:
//   1. Model (KegiatanItem, GaleriFoto, AlbumGaleri) -> 'cetakan' data
//   2. KegiatanService -> fungsi BACA dari Cloud Firestore milik kelompok
//
// Collection yang dipakai (sesuai docs/firestore.rules repo kelompok):
//   kegiatan : daftar kegiatan (dibuat pengurus). Anggota hanya MEMBACA.
//              tanggal = String ISO (toIso8601String), jam disimpan di field 'waktu'.
//   galeri   : foto dokumentasi (diunggah pengurus ke Cloudinary). Anggota hanya MEMBACA.
//   users    : profil (dibaca lewat UserService di pendukung_anggota.dart)
//
// Fitur pendaftaran / kehadiran (RSVP) / absensi BELUM ada di Firestore Rules,
// jadi dimatikan lewat saklar kFiturKehadiran di bawah (menunggu keputusan tim).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pendukung_anggota.dart';

// SAKLAR FITUR: pendaftaran, RSVP 'Saya Akan Hadir', dan absensi kode.
//   false = fitur disembunyikan & tidak menyentuh Firestore (aman untuk rules sekarang).
//   true  = aktifkan, TAPI baru boleh setelah Rules untuk 'pendaftaran', 'kehadiran',
//           'absensi' ditambahkan dan ada layar sekretaris untuk kode absen.
const bool kFiturKehadiran = false;

// Nama hari. Index 0 = Senin (sesuai DateTime.weekday - 1).
const List<String> kHariNama = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
// Singkatan bulan untuk tampilan ringkas, contoh: "17 Agu 2024".
const List<String> kBulanSingkat = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

// Mengubah tanggal menjadi teks kunci 'tahun-bulan-tanggal'.
// Dipakai untuk mengelompokkan kegiatan per hari di kalender.
String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

// Membaca tanggal dari Firestore. Di database kelompok tanggal disimpan sebagai
// String ISO, tapi fungsi ini juga mengerti Timestamp supaya aman untuk data lama.
DateTime bacaTanggal(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

// =====================================================================
// MODEL
// =====================================================================
// Satu KegiatanItem mewakili SATU dokumen di collection 'kegiatan'.
class KegiatanItem {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String jam;
  final String lokasi;
  final String alamat;
  final String kategori;
  final bool wajib;
  final int kuota;
  // Kode absensi dari sekretaris (kosong = absensi belum dibuka). Dipakai bila kFiturKehadiran = true.
  final String kodeAbsen;

  KegiatanItem({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.alamat,
    required this.kategori,
    required this.wajib,
    required this.kuota,
    required this.kodeAbsen,
  });

  // Mengubah dokumen Firestore menjadi KegiatanItem.
  // Jam dibaca dari 'waktu' (standar kelompok), cadangan 'jam' (data lama).
  factory KegiatanItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return KegiatanItem(
      id: d.id,
      judul: (m['judul'] ?? '').toString(),
      tanggal: bacaTanggal(m['tanggal']),
      jam: (m['waktu'] ?? m['jam'] ?? '').toString(),
      lokasi: (m['lokasi'] ?? '').toString(),
      alamat: (m['alamat'] ?? '').toString(),
      kategori: (m['kategori'] ?? '').toString(),
      wajib: m['wajib'] == true,
      kuota: (m['kuota'] as num?)?.toInt() ?? 0,
      kodeAbsen: (m['kodeAbsen'] ?? '').toString(),
    );
  }

  // Kegiatan dianggap SELESAI kalau tanggalnya sebelum hari ini.
  bool get sudahLewat {
    final n = DateTime.now();
    return tanggal.isBefore(DateTime(n.year, n.month, n.day));
  }

  // Apakah kegiatan ini berlangsung hari ini?
  bool get hariIni {
    final n = DateTime.now();
    return tanggal.year == n.year && tanggal.month == n.month && tanggal.day == n.day;
  }

  // Teks siap pakai untuk tampilan.
  String get hari => kHariNama[tanggal.weekday - 1];
  String get tanggalPanjang => '${tanggal.day} ${kBulan[tanggal.month - 1]} ${tanggal.year}';
  String get tanggalSingkat => '${tanggal.day} ${kBulanSingkat[tanggal.month - 1]} ${tanggal.year}';
}

// Satu foto di collection 'galeri' (gambar ada di Cloudinary, di sini hanya alamat URL-nya).
class GaleriFoto {
  final String id;
  final String albumId;
  final String album;
  final String tanggalAlbum;
  final int urutan;
  final String deskripsi;
  final String url;

  GaleriFoto({
    required this.id,
    required this.albumId,
    required this.album,
    required this.tanggalAlbum,
    required this.urutan,
    required this.deskripsi,
    required this.url,
  });

  factory GaleriFoto.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final album = (m['album'] ?? 'Umum').toString();
    return GaleriFoto(
      id: d.id,
      albumId: (m['albumId'] ?? album).toString(),
      album: album,
      tanggalAlbum: (m['tanggalAlbum'] ?? '').toString(),
      urutan: (m['urutan'] as num?)?.toInt() ?? 0,
      deskripsi: (m['deskripsi'] ?? m['keterangan'] ?? '').toString(),
      url: (m['downloadURL'] ?? m['imageUrl'] ?? '').toString(),
    );
  }
}

// Satu album = kumpulan foto dengan albumId yang sama.
class AlbumGaleri {
  final String albumId;
  final String judul;
  final String tanggal; // teks siap tampil, contoh "17 Agu 2026"
  final List<GaleriFoto> fotos;

  AlbumGaleri({required this.albumId, required this.judul, required this.tanggal, required this.fotos});

  String? get sampul => fotos.isEmpty || fotos.first.url.isEmpty ? null : fotos.first.url;
}

// =====================================================================
// SERVICE
// =====================================================================
class KegiatanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Mengambil nama user dari profil (untuk dicatat di absensi).
  static Future<String> _namaUser() async {
    final uid = _uid;
    if (uid == null) return '';
    final d = await _db.collection('users').doc(uid).get();
    return (d.data()?['nama'] ?? '') as String;
  }

  // ---------------- Kegiatan (baca saja) ----------------
  // Semua kegiatan, REALTIME. Diurutkan di aplikasi (bukan di Firestore) karena
  // tanggal berupa String ISO.
  static Stream<List<KegiatanItem>> kegiatanStream() {
    return _db.collection('kegiatan').snapshots().map((s) {
      final list = s.docs.map(KegiatanItem.fromDoc).toList();
      list.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      return list;
    });
  }

  // ---------------- Galeri (baca saja) ----------------
  // Semua foto dari collection 'galeri', dikelompokkan per album (albumId).
  static Stream<List<AlbumGaleri>> albumStream() {
    return _db.collection('galeri').orderBy('createdAt', descending: true).snapshots().map((s) {
      final peta = <String, List<GaleriFoto>>{};
      for (final d in s.docs) {
        final f = GaleriFoto.fromDoc(d);
        peta.putIfAbsent(f.albumId, () => []).add(f);
      }
      return peta.values.map((fotos) {
        fotos.sort((a, b) => a.urutan.compareTo(b.urutan));
        final f = fotos.first;
        final t = DateTime.tryParse(f.tanggalAlbum);
        final teksTanggal = t == null ? f.tanggalAlbum : '${t.day} ${kBulanSingkat[t.month - 1]} ${t.year}';
        return AlbumGaleri(albumId: f.albumId, judul: f.album, tanggal: teksTanggal, fotos: fotos);
      }).toList();
    });
  }

  // ---------------- Pendaftaran / RSVP / Absensi (DITUNDA) ----------------
  // Selama kFiturKehadiran = false, tiga stream ini langsung mengembalikan himpunan kosong
  // dan TIDAK menyentuh Firestore (collection-nya belum ada di Rules).
  static Stream<Set<String>> pendaftaranIds() => _idsMilikUser('pendaftaran');
  static Stream<Set<String>> kehadiranIds() => _idsMilikUser('kehadiran');
  static Stream<Set<String>> absensiIds() => _idsMilikUser('absensi');

  static Stream<Set<String>> _idsMilikUser(String collection) {
    final uid = _uid;
    if (!kFiturKehadiran || uid == null) return Stream.value(<String>{});
    return _db
        .collection(collection)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['kegiatanId'] as String).toSet());
  }

  // Mendaftar ke sebuah kegiatan (butuh Rules baru, lihat kFiturKehadiran).
  static Future<void> daftar({
    required String kegiatanId,
    required String nama,
    required String wa,
    required String posisi,
  }) async {
    final uid = _uid;
    if (!kFiturKehadiran || uid == null) return;
    await _db.collection('pendaftaran').doc('${kegiatanId}_$uid').set({
      'kegiatanId': kegiatanId,
      'uid': uid,
      'nama': nama,
      'wa': wa,
      'posisi': posisi,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Konfirmasi 'Saya akan hadir' (RSVP).
  static Future<void> konfirmasiHadir(String kegiatanId) async {
    final uid = _uid;
    if (!kFiturKehadiran || uid == null) return;
    await _db.collection('kehadiran').doc('${kegiatanId}_$uid').set({
      'kegiatanId': kegiatanId,
      'uid': uid,
      'status': 'akan_hadir',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Absen dengan kode dari sekretaris. null = berhasil, selain itu pesan gagal.
  static Future<String?> absen(KegiatanItem k, String kode) async {
    final uid = _uid;
    if (!kFiturKehadiran) return 'Fitur absensi belum tersedia';
    if (uid == null) return 'Kamu belum login';
    if (!k.hariIni) return 'Absensi hanya bisa dilakukan di hari kegiatan';
    if (k.kodeAbsen.isEmpty) return 'Absensi belum dibuka oleh sekretaris';
    if (kode.trim() != k.kodeAbsen) return 'Kode absen salah';
    try {
      final nama = await _namaUser();
      await _db.collection('absensi').doc('${k.id}_$uid').set({
        'kegiatanId': k.id,
        'uid': uid,
        'nama': nama,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return 'Gagal: ${e.code}';
    }
  }
}