// =====================================================================
// pendukung_anggota.dart - Komponen pendukung untuk fitur KEGIATAN ANGGOTA
// =====================================================================
// Berisi warna, tombol, kolom isian, widget kecil, dan UserService yang
// dipakai halaman kegiatan & galeri anggota. Dipisah dari main.dart supaya
// tidak bentrok dengan kode tim (mis. WarnaAnggota di lib/core/theme).
// Catatan: WarnaAnggota milik anggota diganti nama jadi WarnaAnggota.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WarnaAnggota {
  // PRIMARY (biru tua) - warna utama aplikasi: tombol utama, ikon aktif, header
  static const primary = Color(0xFF1E3A8A);
  static const primarySoft = Color(0xFFE8EBF8); // versi sangat muda, untuk latar kotak/chip

  // SECONDARY (kuning) - warna aksen: tombol "Konfirmasi Hadir", label wajib, titik agenda
  static const secondary = Color(0xFFFBBF24);
  static const secondarySoft = Color(0xFFFEF3C7);
  static const secondaryDark = Color(0xFF92400E); // teks di atas secondarySoft

  // TERTIARY (hijau) - status sukses: Selesai, Hadir, Disetujui, Terverifikasi
  static const tertiary = Color(0xFF10B981);
  static const tertiarySoft = Color(0xFFD1FAE5);
  static const tertiaryDark = Color(0xFF047857); // teks di atas tertiarySoft

  // NEUTRAL - warna teks utama & turunannya
  static const neutral = Color(0xFF111827);
  static const grey = Color(0xFF6B7280); // teks pelengkap (keterangan kecil)
  static const border = Color(0xFFE5E7EB); // garis tepi kartu & input
  static const bg = Color(0xFFF5F7FB); // latar belakang halaman

  // Merah - hanya untuk aksi berbahaya (Keluar, Hapus, Ditolak)
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);

  // Lapisan gelap transparan di atas foto (untuk label tanggal / jumlah foto)
  static const overlay = Color(0xB3111827);
}

// Nama bulan dalam bahasa Indonesia. Urutan 0 = Januari. Dipakai untuk menampilkan tanggal.
const List<String> kBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

// =====================================================================
// STYLE TOMBOL & INPUT (dipakai di banyak halaman)
// =====================================================================
// Tombol PRIMARY: isi biru tua, teks putih.
// Untuk aksi utama (Masuk, Daftar, Simpan, Kirim).
final ButtonStyle primaryButton = FilledButton.styleFrom(
  backgroundColor: WarnaAnggota.primary,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

// Tombol SECONDARY: isi kuning.
// Untuk aksi yang ingin ditonjolkan (Konfirmasi Hadir, Absen Sekarang).
final ButtonStyle secondaryButton = FilledButton.styleFrom(
  backgroundColor: WarnaAnggota.secondary,
  foregroundColor: WarnaAnggota.neutral,
  minimumSize: const Size.fromHeight(44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

// Tombol OUTLINED: hanya garis tepi.
// Untuk aksi pendukung (Batal, Lihat Dokumentasi).
final ButtonStyle outlineButton = OutlinedButton.styleFrom(
  foregroundColor: WarnaAnggota.primary,
  minimumSize: const Size.fromHeight(44),
  side: const BorderSide(color: WarnaAnggota.border),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

// Tampilan seragam untuk SEMUA kolom isian (TextField): latar putih, sudut membulat,
// garis biru saat sedang dipilih.
// hint = teks petunjuk, icon = ikon di kiri, helper = teks kecil di bawah kolom.
InputDecoration fieldDec({String? hint, IconData? icon, String? helper}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: WarnaAnggota.border),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: WarnaAnggota.grey),
    helperText: helper,
    helperMaxLines: 2,
    helperStyle: const TextStyle(fontSize: 11, color: WarnaAnggota.grey),
    prefixIcon: icon == null ? null : Icon(icon, size: 18, color: WarnaAnggota.grey),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: WarnaAnggota.primary),
    ),
  );
}

// =====================================================================
// WIDGET UMUM
// =====================================================================
// Kartu putih bersudut membulat dengan garis tepi tipis. Dipakai hampir di semua halaman.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WarnaAnggota.border),
      ),
      child: child,
    );
  }
}

// Label kecil berbentuk kapsul, contoh: "Selesai", "Menunggu", "Wajib Hadir".
// bg = warna latar, fg = warna teks dan ikon, icon (opsional) = ikon kecil di kiri teks.
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const Pill(this.text, {super.key, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// Satu baris info: ikon kecil + teks abu-abu.
// Contoh: ikon kalender + "18 Mei 2025 - 07:00 WIB".
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: WarnaAnggota.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: WarnaAnggota.grey))),
        ],
      ),
    );
  }
}

// Pengganti foto sementara berupa kotak gradasi warna (dipakai di kartu kegiatan dan album).
// seed menentukan pilihan warnanya supaya tiap kartu terlihat berbeda.
class PhotoPlaceholder extends StatelessWidget {
  final double height;
  final int seed;
  final IconData icon;
  const PhotoPlaceholder({super.key, required this.height, this.seed = 0, this.icon = Icons.image});

  static const List<List<Color>> _palettes = [
    [Color(0xFF3B5BA9), Color(0xFF1E3A8A)], // biru (primary)
    [Color(0xFF34D399), Color(0xFF047857)], // hijau (tertiary)
    [Color(0xFFFBBF24), Color(0xFFB45309)], // kuning (secondary)
    [Color(0xFF6366F1), Color(0xFF312E81)], // indigo
    [Color(0xFF475569), Color(0xFF111827)], // abu gelap (neutral)
    [Color(0xFF60A5FA), Color(0xFF1E40AF)], // biru muda
  ];

  @override
  Widget build(BuildContext context) {
    final p = _palettes[seed % _palettes.length];
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: p, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Icon(icon, color: const Color(0x66FFFFFF), size: 40)),
    );
  }
}

// Header di bagian atas halaman utama:  [ikon] Judul ............ [lonceng] [avatar]
class PageHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool bell;
  final bool avatar;
  final Widget? trailing;
  const PageHeader({
    super.key,
    required this.title,
    this.icon,
    this.bell = true,
    this.avatar = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: WarnaAnggota.primary, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
        ],
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (trailing != null) trailing!,
        if (bell) IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        if (avatar)
          const CircleAvatar(
            radius: 16,
            backgroundColor: WarnaAnggota.primary,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
      ],
    );
  }
}

// Header untuk halaman 'dalam' (halaman yang dibuka dari halaman lain).
// Ada tombol panah kembali di kiri.
class SubHeader extends StatelessWidget {
  final String title;
  const SubHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.arrow_back)),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          const CircleAvatar(
            radius: 16,
            backgroundColor: WarnaAnggota.primary,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Tulisan kecil di atas kolom isian, contoh: "Nama Lengkap".
// trailing = tulisan kecil di kanan (misal "Opsional").
class FieldLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
        ],
      ),
    );
  }
}


// =====================================================================
// SERVICE: semua urusan Auth + data user di Firestore
// =====================================================================
// UserService = kumpulan fungsi untuk urusan akun.
// Semua kode Firebase dikumpulkan di sini supaya halaman (UI) tetap bersih dan mudah dibaca.
class UserService {
  // _auth = 'pintu' ke Firebase Authentication (urusan login).
  // Awalan _ artinya hanya boleh dipakai di dalam file ini.
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // _db = 'pintu' ke database Cloud Firestore.
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User yang sedang login. Nilainya null kalau belum login.
  static User? get currentUser => _auth.currentUser;

  // Stream = aliran data REALTIME.
  // Setiap kali profil di Firestore berubah, tampilan ikut berubah otomatis tanpa refresh.
  static Stream<Map<String, dynamic>?> profilStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }

  // Mengambil profil SATU KALI saja (tidak realtime).
  // Future = hasilnya datang nanti, jadi dipakai dengan 'await'.
  static Future<Map<String, dynamic>?> getProfil() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}


// =====================================================================
// HELPER
// =====================================================================
// Menampilkan pesan kecil (SnackBar) di bagian bawah layar.
void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}


// Widget kecil untuk menampilkan SATU data profil secara realtime.
// field = nama kolom di Firestore ('nama' atau 'email'), prefix = teks di depannya (misal 'Halo, ').
// Selama data belum datang, yang tampil adalah '...'.
class NamaPengguna extends StatelessWidget {
  final String prefix;
  final String field;
  final TextStyle? style;
  const NamaPengguna({super.key, this.prefix = '', this.field = 'nama', this.style});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: UserService.profilStream(),
      builder: (context, snap) {
        final v = snap.data?[field];
        return Text('$prefix${v ?? '...'}', style: style);
      },
    );
  }
}