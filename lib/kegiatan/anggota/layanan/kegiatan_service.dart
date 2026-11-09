// =====================================================================
// kegiatan_service.dart  -  Semua urusan DATABASE untuk kegiatan
// =====================================================================
// Isi file ini:
//   1. Model (KegiatanItem, UsulanItem, FotoItem) -> 'cetakan' data
//   2. KegiatanService -> fungsi baca/tulis ke Cloud Firestore
//
// Collection (tabel) yang dipakai di Firestore:
//   kegiatan     : daftar kegiatan (dibuat pengurus)
//   pendaftaran  : anggota yang mendaftar ke sebuah kegiatan
//   kehadiran    : RSVP 'Saya akan hadir'
//   absensi      : bukti hadir (anggota memasukkan kode dari sekretaris)
//   usulan       : usulan kegiatan dari anggota
//   foto         : foto dokumentasi (disimpan sebagai teks base64)
//   users        : profil anggota (ada di auth.dart)

// dart:convert dipakai untuk mengubah foto menjadi teks (base64) dan sebaliknya.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pendukung_anggota.dart';

// Nama hari. Index 0 = Senin (sesuai DateTime.weekday - 1).
const List<String> kHariNama = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
// Singkatan bulan untuk tampilan ringkas, contoh: "17 Agu 2024".
const List<String> kBulanSingkat = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

// Mengubah tanggal menjadi teks kunci 'tahun-bulan-tanggal'.
// Dipakai untuk mengelompokkan kegiatan per hari di kalender.
String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

// =====================================================================
// MODEL
// =====================================================================
// MODEL = 'cetakan' data. Satu KegiatanItem mewakili SATU dokumen di collection 'kegiatan'.
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
  // Kode absensi dari sekretaris (kosong = absensi belum dibuka).
  final String kodeAbsen; // diisi sekretaris saat acara dimulai
  final int jumlahFoto;

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
    required this.jumlahFoto,
  });

  // Mengubah dokumen Firestore (data mentah) menjadi objek KegiatanItem.
  // Tanda '?? ""' artinya: kalau field-nya kosong, pakai nilai cadangan.
  factory KegiatanItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return KegiatanItem(
      id: d.id,
      judul: m['judul'] ?? '',
      tanggal: (m['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jam: m['jam'] ?? '',
      lokasi: m['lokasi'] ?? '',
      alamat: m['alamat'] ?? '',
      kategori: m['kategori'] ?? '',
      wajib: m['wajib'] ?? false,
      kuota: (m['kuota'] ?? 0) as int,
      kodeAbsen: m['kodeAbsen'] ?? '',
      jumlahFoto: (m['jumlahFoto'] ?? 0) as int,
    );
  }

  // Kegiatan dianggap SELESAI kalau tanggalnya sebelum hari ini.
  bool get sudahLewat {
    final n = DateTime.now();
    return tanggal.isBefore(DateTime(n.year, n.month, n.day));
  }

  // Apakah kegiatan ini berlangsung hari ini? (syarat untuk bisa absen)
  bool get hariIni {
    final n = DateTime.now();
    return tanggal.year == n.year && tanggal.month == n.month && tanggal.day == n.day;
  }

  // Sudah/sedang berlangsung -> boleh punya album foto.
  bool get sudahMulai {
    final n = DateTime.now();
    return tanggal.isBefore(DateTime(n.year, n.month, n.day + 1));
  }

  // Teks siap pakai untuk tampilan, contoh: hari = "Minggu", tanggalPanjang = "18 Mei 2025".
  String get hari => kHariNama[tanggal.weekday - 1];
  String get tanggalPanjang => '${tanggal.day} ${kBulan[tanggal.month - 1]} ${tanggal.year}';
  String get tanggalSingkat => '${tanggal.day} ${kBulanSingkat[tanggal.month - 1]} ${tanggal.year}';
}

// Satu usulan kegiatan dari anggota (collection 'usulan').
class UsulanItem {
  final String id;
  final String judul;
  final String deskripsi;
  final DateTime tanggal;
  final String lokasi;
  final int peserta;
  // Status usulan: menunggu -> disetujui / ditolak (diubah oleh sekretaris).
  final String status; // menunggu | disetujui | ditolak
  final String catatan;
  final DateTime createdAt;

  UsulanItem({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.tanggal,
    required this.lokasi,
    required this.peserta,
    required this.status,
    required this.catatan,
    required this.createdAt,
  });

  factory UsulanItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return UsulanItem(
      id: d.id,
      judul: m['judul'] ?? '',
      deskripsi: m['deskripsi'] ?? '',
      tanggal: (m['tanggal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lokasi: m['lokasi'] ?? '',
      peserta: (m['peserta'] ?? 0) as int,
      status: m['status'] ?? 'menunggu',
      catatan: m['catatan'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get tanggalTeks => '${tanggal.day} ${kBulan[tanggal.month - 1]} ${tanggal.year}';
}

// Satu foto dokumentasi. 'bytes' = isi foto yang sudah dikembalikan dari teks base64.
class FotoItem {
  final String id;
  final String uid;
  final String nama;
  final Uint8List bytes;
  final DateTime createdAt;

  FotoItem({
    required this.id,
    required this.uid,
    required this.nama,
    required this.bytes,
    required this.createdAt,
  });

  factory FotoItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return FotoItem(
      id: d.id,
      uid: m['uid'] ?? '',
      nama: m['nama'] ?? '',
      bytes: base64Decode(m['data'] ?? ''),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// =====================================================================
// SERVICE
// =====================================================================
// KegiatanService = kumpulan fungsi untuk membaca dan menulis data kegiatan di Firestore.
class KegiatanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  // uid = ID unik user yang sedang login. Dipakai agar tiap anggota hanya mengakses datanya sendiri.
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Mengambil nama user dari profil (untuk dicatat di absensi, usulan, dan foto).
  static Future<String> _namaUser() async {
    final uid = _uid;
    if (uid == null) return '';
    final d = await _db.collection('users').doc(uid).get();
    return (d.data()?['nama'] ?? '') as String;
  }

  // ---------------- Kegiatan ----------------
  // Semua kegiatan, urut dari tanggal terdekat. Berupa Stream = REALTIME:
  // kalau pengurus menambah kegiatan, layar anggota langsung ikut berubah.
  static Stream<List<KegiatanItem>> kegiatanStream() {
    return _db
        .collection('kegiatan')
        .orderBy('tanggal')
        .snapshots()
        .map((s) => s.docs.map(KegiatanItem.fromDoc).toList());
  }

  // ---------------- Pendaftaran / RSVP / Absensi milik user ----------------
  // Tiga fungsi ini mengembalikan 'kumpulan id kegiatan' milik user yang login:
  //   pendaftaran -> sudah mendaftar
  //   kehadiran   -> sudah menekan 'Saya Akan Hadir' (RSVP)
  //   absensi     -> sudah absen di lokasi (bukti hadir)
  static Stream<Set<String>> pendaftaranIds() => _idsMilikUser('pendaftaran');
  static Stream<Set<String>> kehadiranIds() => _idsMilikUser('kehadiran'); // RSVP "akan hadir"
  static Stream<Set<String>> absensiIds() => _idsMilikUser('absensi'); // sudah absen di lokasi

  // Fungsi bersama untuk tiga fungsi di atas:
  // cari dokumen di collection tersebut yang uid-nya = uid user, lalu ambil kegiatanId-nya.
  static Stream<Set<String>> _idsMilikUser(String collection) {
    final uid = _uid;
    if (uid == null) return Stream.value(<String>{});
    return _db
        .collection(collection)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['kegiatanId'] as String).toSet());
  }

  // Mendaftar ke sebuah kegiatan.
  // ID dokumen dibuat '<idKegiatan>_<uid>' sehingga satu anggota tidak bisa mendaftar dua kali ke kegiatan yang sama.
  static Future<void> daftar({
    required String kegiatanId,
    required String nama,
    required String wa,
    required String posisi,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('pendaftaran').doc('${kegiatanId}_$uid').set({
      'kegiatanId': kegiatanId,
      'uid': uid,
      'nama': nama,
      'wa': wa,
      'posisi': posisi,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Konfirmasi 'Saya akan hadir' (RSVP). Ini BUKAN absensi, hanya rencana datang.
  static Future<void> konfirmasiHadir(String kegiatanId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('kehadiran').doc('${kegiatanId}_$uid').set({
      'kegiatanId': kegiatanId,
      'uid': uid,
      'status': 'akan_hadir',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Absen dengan kode dari sekretaris. Hasilnya: null = berhasil, atau teks pesan kalau gagal.
  // Syarat: hari kegiatan, absensi sudah dibuka, dan kodenya benar.
  static Future<String?> absen(KegiatanItem k, String kode) async {
    final uid = _uid;
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

  // ---------------- Usulan kegiatan ----------------
  // Daftar usulan milik user ini. Diurutkan di aplikasi (terbaru di atas)
  // supaya tidak butuh pengaturan index tambahan di Firestore.
  static Stream<List<UsulanItem>> usulanStream() {
    final uid = _uid;
    if (uid == null) return Stream.value(<UsulanItem>[]);
    return _db.collection('usulan').where('uid', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(UsulanItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Mengirim usulan baru. Status awal selalu 'menunggu' sampai ditinjau sekretaris.
  static Future<void> kirimUsulan({
    required String judul,
    required String deskripsi,
    required DateTime tanggal,
    required String lokasi,
    required int peserta,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final nama = await _namaUser();
    await _db.collection('usulan').add({
      'uid': uid,
      'nama': nama,
      'judul': judul,
      'deskripsi': deskripsi,
      'tanggal': Timestamp.fromDate(tanggal),
      'lokasi': lokasi,
      'peserta': peserta,
      'status': 'menunggu',
      'catatan': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Membatalkan usulan (hanya bisa kalau statusnya masih 'menunggu', diatur di Rules Firestore).
  static Future<void> hapusUsulan(String id) => _db.collection('usulan').doc(id).delete();

  // ---------------- Foto dokumentasi (disimpan base64 di Firestore, gratis) ----------------
  // Semua foto pada satu album (kegiatan), realtime.
  static Stream<List<FotoItem>> fotoStream(String kegiatanId) {
    return _db.collection('foto').where('kegiatanId', isEqualTo: kegiatanId).snapshots().map((s) {
      final list = s.docs.map(FotoItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Mengunggah foto. Karena memakai paket gratis, foto disimpan SEBAGAI TEKS (base64) di Firestore.
  // Batas satu dokumen Firestore 1 MB, jadi foto harus kecil.
  static Future<void> uploadFoto({required String kegiatanId, required Uint8List bytes}) async {
    final uid = _uid;
    if (uid == null) return;
    // Tolak foto yang terlalu besar.
    if (bytes.length > 650 * 1024) throw StateError('Foto terlalu besar');
    final nama = await _namaUser();
    // Batch = beberapa operasi dijalankan SEKALIGUS: semuanya berhasil, atau semuanya dibatalkan.
    // Di sini: simpan foto + tambah hitungan jumlahFoto di kegiatan.
    final batch = _db.batch();
    batch.set(_db.collection('foto').doc(), {
      'kegiatanId': kegiatanId,
      'uid': uid,
      'nama': nama,
      'data': base64Encode(bytes),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('kegiatan').doc(kegiatanId), {'jumlahFoto': FieldValue.increment(1)});
    await batch.commit();
  }

  // Menghapus foto dan mengurangi hitungan jumlahFoto.
  static Future<void> hapusFoto(String kegiatanId, String fotoId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('foto').doc(fotoId));
    batch.update(_db.collection('kegiatan').doc(kegiatanId), {'jumlahFoto': FieldValue.increment(-1)});
    await batch.commit();
  }

  // ---------------- Alat pengembangan (SEMENTARA) ----------------
  // ALAT PENGEMBANGAN (hanya dipakai saat kModeDev = true): mengisi data contoh.
  // Tanggalnya dihitung dari hari ini. Tidak akan menggandakan data kalau sudah ada isinya.
  static Future<bool> isiDataContoh() async {
    final cek = await _db.collection('kegiatan').limit(1).get();
    if (cek.docs.isNotEmpty) return false;

    final hariIni = _hariIni();
    DateTime d(int offset) => hariIni.add(Duration(days: offset));

    final data = <Map<String, Object>>[
      {
        'judul': 'Kerja Bakti Lingkungan RW 08',
        'tanggal': d(3),
        'jam': '07:00 WIB',
        'lokasi': 'Balai Warga RW 08',
        'alamat': 'Jl. Melati, RW 08',
        'kategori': 'Sosial',
        'wajib': true,
        'kuota': 50,
      },
      {
        'judul': 'Turnamen Futsal Antar-RT',
        'tanggal': d(10),
        'jam': '15:30 WIB',
        'lokasi': 'Lapangan Futsal Garuda Arena',
        'alamat': 'Komplek Olahraga Pemuda',
        'kategori': 'Olahraga',
        'wajib': false,
        'kuota': 12,
      },
      {
        'judul': 'Workshop Desain & Kreatif',
        'tanggal': d(20),
        'jam': '19:30 WIB',
        'lokasi': 'Aula Sekretariat Karang Taruna',
        'alamat': 'Jl. Mawar No. 5',
        'kategori': 'Pelatihan',
        'wajib': false,
        'kuota': 30,
      },
      {
        'judul': 'Kerja Bakti Bersih Saluran Air',
        'tanggal': d(-30),
        'jam': '07:00 WIB',
        'lokasi': 'Jl. Pondok RT 02',
        'alamat': 'RT 02 / RW 08',
        'kategori': 'Sosial',
        'wajib': true,
        'kuota': 40,
      },
      {
        'judul': 'Rapat Pleno Pemuda & Musyawarah',
        'tanggal': d(-60),
        'jam': '19:30 WIB',
        'lokasi': 'Balai Warga RW 08',
        'alamat': 'Jl. Melati, RW 08',
        'kategori': 'Rapat',
        'wajib': true,
        'kuota': 60,
      },
      {
        'judul': 'Peringatan Hari Kemerdekaan RI',
        'tanggal': d(-85),
        'jam': '08:00 WIB',
        'lokasi': 'Lapangan Garuda',
        'alamat': 'Lapangan Garuda',
        'kategori': 'Peringatan',
        'wajib': false,
        'kuota': 100,
      },
    ];

    final batch = _db.batch();
    for (final m in data) {
      final ref = _db.collection('kegiatan').doc();
      batch.set(ref, {...m, 'tanggal': Timestamp.fromDate(m['tanggal'] as DateTime)});
    }
    await batch.commit();
    return true;
  }

  // ALAT PENGEMBANGAN: menambah kegiatan di hari ini dengan kode absen 123456 untuk menguji absensi.
  static Future<void> tambahKegiatanHariIni() async {
    await _db.collection('kegiatan').add({
      'judul': 'Rapat Koordinasi Panitia',
      'tanggal': Timestamp.fromDate(_hariIni()),
      'jam': '19:00 WIB',
      'lokasi': 'Sekretariat Karang Taruna',
      'alamat': 'Jl. Mawar No. 5',
      'kategori': 'Rapat',
      'wajib': true,
      'kuota': 30,
      'kodeAbsen': '123456',
    });
  }

  static DateTime _hariIni() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}