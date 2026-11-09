// =====================================================================
// kegiatan_pages.dart  -  Halaman-halaman tentang kegiatan
// =====================================================================
// Isi file ini:
//   1. KegiatanBuilder   -> pembantu: mengambil data dari Firestore untuk halaman
//   2. BerandaPage       -> kegiatan terdekat, agenda, tombol usulan
//   3. KegiatanPage      -> tab Mendatang / Selesai
//   4. DaftarKegiatanPage-> form pendaftaran
//   5. JadwalPage        -> kalender + agenda per tanggal
//   6. Absensi dan statistik keaktifan (dimatikan lewat kFiturKehadiran)
//
// Alur data: Firestore -> KegiatanService -> KegiatanBuilder -> halaman -> tampilan.

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../../../usulan/halaman/halaman_usulan.dart';
import '../layanan/kegiatan_service.dart';
import '../pendukung_anggota.dart';


// =====================================================================
// PEMBANTU: ambil data kegiatan + status daftar/hadir milik user (realtime)
// =====================================================================
// typedef = memberi nama pendek untuk 'jenis fungsi'.
// Fungsi ini menerima 4 data dan mengembalikan tampilan (Widget):
//   items  = semua kegiatan
//   daftar = id kegiatan yang sudah didaftar user
//   hadir  = id kegiatan yang sudah di-RSVP user
//   absen  = id kegiatan yang sudah diabsen user
typedef KegiatanWidgetBuilder = Widget Function(
    BuildContext context,
    List<KegiatanItem> items,
    Set<String> daftar,
    Set<String> hadir,
    Set<String> absen,
    );

// Widget pembantu: mengambil 4 sumber data dari Firestore sekaligus,
// lalu menyerahkannya ke halaman yang memanggilnya.
// Dengan begitu Beranda, Kegiatan, Jadwal, dan Galeri tidak mengulang kode yang sama.
class KegiatanBuilder extends StatefulWidget {
  final KegiatanWidgetBuilder builder;
  const KegiatanBuilder({super.key, required this.builder});

  @override
  State<KegiatanBuilder> createState() => _KegiatanBuilderState();
}

class _KegiatanBuilderState extends State<KegiatanBuilder> {
  // Stream dibuat SEKALI di sini (bukan di build) supaya tidak berlangganan ulang
  // setiap kali layar digambar ulang (kalau tidak, layar bisa berkedip).
  late final Stream<List<KegiatanItem>> _kegiatan = KegiatanService.kegiatanStream();
  late final Stream<Set<String>> _daftar = KegiatanService.pendaftaranIds();
  late final Stream<Set<String>> _hadir = KegiatanService.kehadiranIds();
  late final Stream<Set<String>> _absen = KegiatanService.absensiIds();

  @override
  Widget build(BuildContext context) {
    // StreamBuilder = widget yang otomatis menggambar ulang setiap ada data baru dari stream.
    // Di bawah ini StreamBuilder disusun bertingkat: kegiatan -> daftar -> hadir -> absen.
    return StreamBuilder<List<KegiatanItem>>(
      stream: _kegiatan,
      builder: (context, s1) {
        // Kalau terjadi error (contoh: permission-denied karena Rules belum benar), tampilkan pesannya.
        if (s1.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gagal memuat data.\n${s1.error}', textAlign: TextAlign.center),
            ),
          );
        }
        // Data belum datang -> tampilkan lingkaran loading.
        if (!s1.hasData) return const Center(child: CircularProgressIndicator());
        return StreamBuilder<Set<String>>(
          stream: _daftar,
          builder: (context, s2) => StreamBuilder<Set<String>>(
            stream: _hadir,
            builder: (context, s3) => StreamBuilder<Set<String>>(
              stream: _absen,
              builder: (context, s4) => widget.builder(
                context,
                s1.data!,
                s2.data ?? <String>{},
                s3.data ?? <String>{},
                s4.data ?? <String>{},
              ),
            ),
          ),
        );
      },
    );
  }
}

// Tombol 'Konfirmasi Hadir' (RSVP) yang dipakai di Beranda dan Jadwal.
// Kalau sudah dikonfirmasi, tombol berubah menjadi tidak aktif bertuliskan 'Hadir Terkonfirmasi'.
Widget hadirButton(
    BuildContext context,
    KegiatanItem k,
    bool sudah, {
      required String label,
      required ButtonStyle style,
    }) {
  // Fitur RSVP dimatikan sampai Rules Firestore-nya ada (lihat kFiturKehadiran).
  if (!kFiturKehadiran) return const SizedBox.shrink();
  if (sudah) {
    return OutlinedButton.icon(
      style: outlineButton,
      onPressed: null,
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('Hadir Terkonfirmasi'),
    );
  }
  return FilledButton.icon(
    style: style,
    onPressed: () async {
      try {
        await KegiatanService.konfirmasiHadir(k.id);
        if (context.mounted) toast(context, 'Kehadiran dikonfirmasi!');
      } on FirebaseException catch (e) {
        if (context.mounted) toast(context, 'Gagal: ${e.code}');
      }
    },
    icon: const Icon(Icons.how_to_reg, size: 18),
    label: Text(label),
  );
}

// Kartu berisi pesan, ditampilkan kalau tidak ada data (contoh: 'Belum ada kegiatan').
Widget emptyCard(String text) {
  return AppCard(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: const TextStyle(color: WarnaAnggota.grey, fontSize: 13)),
      ),
    ),
  );
}

// =====================================================================
// 1. BERANDA
// =====================================================================
// Halaman Beranda: sapaan, kegiatan terdekat, agenda mendatang, dan tombol usulan.
class BerandaPage extends StatelessWidget {
  final ValueChanged<int> onGoTo;
  const BerandaPage({super.key, required this.onGoTo});

  // Satu baris agenda: kotak tanggal di kiri, judul + jam + lokasi di tengah, panah di kanan.
  Widget _agendaItem(KegiatanItem k) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onGoTo(1),
        child: AppCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    Text(kBulanSingkat[k.tanggal.month - 1].toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: WarnaAnggota.primary)),
                    Text(k.tanggal.day.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WarnaAnggota.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.judul, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${k.jam} • ${k.lokasi}', style: const TextStyle(fontSize: 12, color: WarnaAnggota.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WarnaAnggota.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KegiatanBuilder(
        builder: (context, items, daftar, hadir, absen) {
          // Pisahkan kegiatan yang BELUM lewat. Karena data sudah urut dari tanggal terdekat,
          // yang pertama adalah kegiatan terdekat.
          final mendatang = items.where((k) => !k.sudahLewat).toList();
          // Kegiatan terdekat (null kalau tidak ada kegiatan mendatang).
          final terdekat = mendatang.isEmpty ? null : mendatang.first;
          // Agenda berikutnya: lewati yang pertama (sudah tampil di kartu besar), ambil maksimal 3.
          final lainnya = mendatang.skip(1).take(3).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: WarnaAnggota.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NamaPengguna(prefix: 'Halo, ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Warga RT 03 / RW 08', style: TextStyle(color: WarnaAnggota.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                ],
              ),
              const SizedBox(height: 20),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bagian 'Kegiatan Terdekat'. Pill 'Wajib Hadir' hanya muncul kalau kegiatannya wajib.
                  const Text('Kegiatan Terdekat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (terdekat != null && terdekat.wajib)
                    const Pill('Wajib Hadir', bg: WarnaAnggota.secondarySoft, fg: WarnaAnggota.secondaryDark),
                ],
              ),
              const SizedBox(height: 10),
              // Tidak ada kegiatan -> tampilkan kartu kosong. Kalau ada -> tampilkan kartu detail.
              if (terdekat == null)
                emptyCard('Belum ada kegiatan mendatang')
              else
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(terdekat.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      InfoRow(Icons.calendar_today_outlined,
                          '${terdekat.hari}, ${terdekat.tanggalPanjang} • ${terdekat.jam}'),
                      InfoRow(Icons.place_outlined, terdekat.lokasi),
                      const SizedBox(height: 14),
                      // Tombol kuning 'Konfirmasi Hadir' (RSVP).
                      hadirButton(context, terdekat, hadir.contains(terdekat.id),
                          label: 'Konfirmasi Hadir', style: secondaryButton),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bagian 'Agenda Mendatang'. 'Lihat Semua' berpindah ke tab Kegiatan (tab nomor 1).
                  const Text('Agenda Mendatang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  GestureDetector(
                    onTap: () => onGoTo(1),
                    child: const Text('Lihat Semua >',
                        style: TextStyle(fontSize: 12, color: WarnaAnggota.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (lainnya.isEmpty) emptyCard('Belum ada agenda lain') else ...lainnya.map(_agendaItem),
              const SizedBox(height: 12),
              AppCard(
                // Kartu ajakan: anggota bisa langsung mengusulkan kegiatan ke sekretaris dari Beranda.
                color: WarnaAnggota.secondarySoft,
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: WarnaAnggota.secondaryDark),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Punya ide kegiatan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Usulkan ke sekretaris untuk ditinjau.', style: TextStyle(fontSize: 12, color: WarnaAnggota.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: WarnaAnggota.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => bukaUsulan(context),
                      child: const Text('Usulkan'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// 2. KEGIATAN (Mendatang / Selesai)
// =====================================================================
// Halaman Kegiatan dengan 2 tab: Mendatang dan Selesai.
class KegiatanPage extends StatefulWidget {
  final ValueChanged<int> onGoTo;
  const KegiatanPage({super.key, required this.onGoTo});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  // Tab yang sedang dipilih: 0 = Mendatang, 1 = Selesai.
  int _tab = 0; // 0 = Mendatang, 1 = Selesai

  // Satu tombol tab. Tab yang aktif berwarna primary, yang lain transparan.
  Widget _tabBtn(String label, IconData icon, int index) {
    final aktif = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: aktif ? WarnaAnggota.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: aktif ? Colors.white : WarnaAnggota.grey),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: aktif ? Colors.white : WarnaAnggota.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // Kartu kegiatan MENDATANG: judul, tanggal, lokasi, lalu tombol Daftar / Terdaftar.
  // Kalau kegiatannya hari ini, ditambah tombol Absen.
  Widget _cardMendatang(KegiatanItem k, bool terdaftar, bool sudahAbsen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(k.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                // Label 'Hari ini' pada kegiatan yang berlangsung hari ini.
                if (k.hariIni) const Pill('Hari ini', bg: WarnaAnggota.secondarySoft, fg: WarnaAnggota.secondaryDark),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(Icons.calendar_today_outlined, '${k.tanggalPanjang} • ${k.jam}'),
            InfoRow(Icons.place_outlined, k.lokasi),
            const SizedBox(height: 12),
            // Sudah mendaftar -> tombol 'Terdaftar' (tidak aktif).
            // Belum -> tombol 'Daftar' yang membuka form pendaftaran.
            if (!kFiturKehadiran)
              const SizedBox.shrink()
            else if (terdaftar)
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Terdaftar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: WarnaAnggota.primary,
                  backgroundColor: WarnaAnggota.primarySoft,
                  minimumSize: const Size.fromHeight(40),
                  side: const BorderSide(color: WarnaAnggota.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              FilledButton(
                style: primaryButton,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DaftarKegiatanPage(kegiatan: k)),
                ),
                child: const Text('Daftar'),
              ),
            // Absen hanya muncul di hari kegiatan (dan bila fitur kehadiran aktif).
            if (kFiturKehadiran && k.hariIni) ...[
              const SizedBox(height: 8),
              absenButton(context, k, sudahAbsen),
            ],
          ],
        ),
      ),
    );
  }

  // Kartu kegiatan SELESAI: ada foto, label 'Selesai', dan status kehadiran.
  // 'Kamu Hadir' hanya kalau user benar-benar sudah ABSEN (bukan sekadar RSVP).
  Widget _cardSelesai(KegiatanItem k, int i, bool hadir) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WarnaAnggota.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PhotoPlaceholder(height: 120, seed: i + 1, icon: Icons.groups),
                const Positioned(
                  left: 10,
                  top: 10,
                  child: Pill('Selesai', bg: WarnaAnggota.tertiary, fg: Colors.white, icon: Icons.check_circle),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Pill('${k.tanggalSingkat} • ${k.jam}', bg: WarnaAnggota.overlay, fg: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  InfoRow(Icons.place_outlined, k.lokasi),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (kFiturKehadiran && hadir)
                        const Pill('Kamu Hadir', bg: WarnaAnggota.tertiarySoft, fg: WarnaAnggota.tertiaryDark, icon: Icons.check_circle)
                      else if (kFiturKehadiran)
                        const Pill('Tidak Hadir', bg: WarnaAnggota.bg, fg: WarnaAnggota.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: outlineButton,
                    onPressed: () => widget.onGoTo(3), // buka tab Galeri
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Lihat Dokumentasi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KegiatanBuilder(
        builder: (context, items, daftar, hadir, absen) {
          final mendatang = items.where((k) => !k.sudahLewat).toList();
          // Kegiatan selesai diurutkan dari yang paling baru (dibalik).
          final selesai = items.where((k) => k.sudahLewat).toList().reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(title: 'Kegiatan', icon: Icons.event_note, avatar: true),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: WarnaAnggota.border),
                ),
                child: Row(
                  children: [
                    _tabBtn('Mendatang', Icons.event_outlined, 0),
                    _tabBtn('Selesai', Icons.check_circle_outline, 1),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Tampilkan isi sesuai tab yang dipilih.
              if (_tab == 0) ...[
                if (mendatang.isEmpty) emptyCard('Belum ada kegiatan mendatang'),
                ...mendatang.map((k) => _cardMendatang(k, daftar.contains(k.id), absen.contains(k.id))),
              ] else if (_tab == 1) ...[
                if (selesai.isEmpty) emptyCard('Belum ada kegiatan yang selesai'),
                ...selesai.asMap().entries.map((e) => _cardSelesai(e.value, e.key, absen.contains(e.value.id))),
              ],
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// 3. DAFTAR KEGIATAN (form pendaftaran)
// =====================================================================
// Halaman form pendaftaran kegiatan: info acara + data pendaftar + komitmen.
class DaftarKegiatanPage extends StatefulWidget {
  final KegiatanItem kegiatan;
  const DaftarKegiatanPage({super.key, required this.kegiatan});

  @override
  State<DaftarKegiatanPage> createState() => _DaftarKegiatanPageState();
}

class _DaftarKegiatanPageState extends State<DaftarKegiatanPage> {
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  final _posisi = TextEditingController();
  // Apakah checkbox komitmen sudah dicentang? Tombol Konfirmasi hanya aktif kalau true.
  bool _setuju = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Isi otomatis nama dan nomor WA dari profil, supaya anggota tidak mengetik ulang.
    UserService.getProfil().then((p) {
      if (p == null || !mounted) return;
      _nama.text = p['nama'] ?? '';
      _wa.text = p['wa'] ?? '';
    });
  }

  @override
  void dispose() {
    _nama.dispose();
    _wa.dispose();
    _posisi.dispose();
    super.dispose();
  }

  // Dijalankan saat 'Konfirmasi Pendaftaran' ditekan: cek isian -> simpan ke Firestore -> tutup halaman.
  Future<void> _submit() async {
    if (_nama.text.trim().isEmpty || _wa.text.trim().isEmpty) {
      toast(context, 'Nama dan nomor WhatsApp wajib diisi');
      return;
    }
    setState(() => _loading = true);
    try {
      await KegiatanService.daftar(
        kegiatanId: widget.kegiatan.id,
        nama: _nama.text.trim(),
        wa: _wa.text.trim(),
        posisi: _posisi.text.trim(),
      );
      if (!mounted) return;
      toast(context, 'Pendaftaran berhasil!');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted) toast(context, 'Gagal mendaftar: ${e.code}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Satu baris info acara: kotak ikon + judul + keterangan kecil di bawahnya.
  Widget _infoLine(IconData icon, String title, String? sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: WarnaAnggota.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (sub != null && sub.isNotEmpty)
                  Text(sub, style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kegiatan;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(title: 'Daftar Kegiatan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        const PhotoPlaceholder(height: 160, seed: 0, icon: Icons.event),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Pill('Pendaftaran Terbuka', bg: WarnaAnggota.secondary, fg: WarnaAnggota.neutral),
                              const SizedBox(height: 6),
                              Text(k.judul,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
                        _infoLine(Icons.calendar_today_outlined, '${k.hari}, ${k.tanggalPanjang}', '${k.jam} - Selesai'),
                        _infoLine(Icons.place_outlined, k.lokasi, k.alamat),
                        if (k.kuota > 0) _infoLine(Icons.groups_outlined, 'Kuota Tim/Peserta', '${k.kuota} peserta'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Data Pendaftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Pill('Akun Terverifikasi', bg: WarnaAnggota.tertiarySoft, fg: WarnaAnggota.tertiaryDark, icon: Icons.verified),
                    ],
                  ),
                  const FieldLabel('Nama Lengkap'),
                  TextField(controller: _nama, decoration: fieldDec(icon: Icons.person_outline)),
                  const FieldLabel('Nomor WhatsApp / Kontak'),
                  TextField(
                    controller: _wa,
                    keyboardType: TextInputType.phone,
                    decoration: fieldDec(
                      icon: Icons.phone_outlined,
                      helper: 'Koordinasi grup dan jadwal/briefing akan dikirim ke nomor ini.',
                    ),
                  ),
                  const FieldLabel('Posisi / Keterangan', trailing: 'Opsional'),
                  TextField(
                    controller: _posisi,
                    decoration: fieldDec(
                      icon: Icons.edit_note,
                      hint: 'Misal: Pemain (Kiper/Striker) atau Supporter RT 03',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _setuju,
                          activeColor: WarnaAnggota.primary,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) => setState(() => _setuju = v ?? false),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8, right: 6),
                            child: Text(
                              'Saya berkomitmen untuk hadir tepat waktu, menjunjung sportivitas, serta mematuhi arahan panitia Karang Taruna.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: primaryButton,
                    // onPressed = null artinya tombol tidak aktif.
                    // Aktif hanya kalau checkbox dicentang dan tidak sedang memproses.
                    onPressed: (_setuju && !_loading) ? _submit : null,
                    icon: _loading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Konfirmasi Pendaftaran'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: outlineButton,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 4. JADWAL (kalender + agenda)
// =====================================================================
// Halaman Jadwal: kalender bulanan. Tanggal yang punya kegiatan diberi titik kuning.
// Klik tanggal -> agenda hari itu tampil di bawah.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  // Bulan yang sedang ditampilkan di kalender (selalu tanggal 1).
  late DateTime _month;
  // Tanggal yang sedang dipilih (lingkaran biru).
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
  }

  // Apakah dua tanggal jatuh di hari yang sama? (jam diabaikan)
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // Ganti bulan: delta = -1 (bulan lalu) atau +1 (bulan depan).
  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  // Tombol panah kecil kiri/kanan di atas kalender.
  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: WarnaAnggota.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WarnaAnggota.border),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  // Satu kotak tanggal. Tebal + titik kuning kalau ada kegiatan; lingkaran biru kalau dipilih;
  // abu-abu muda kalau tanggal dari bulan lain.
  Widget _cell(DateTime d, Map<String, List<KegiatanItem>> events) {
    final inMonth = d.month == _month.month;
    final selected = _sameDay(d, _selected);
    final hasEvent = events.containsKey(dateKey(d));

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _selected = d;
          if (!inMonth) _month = DateTime(d.year, d.month, 1);
        }),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? WarnaAnggota.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasEvent ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.white : (inMonth ? WarnaAnggota.neutral : const Color(0xFFC4C9D4)),
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : WarnaAnggota.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Menyusun kalender: judul bulan, nama hari, lalu baris-baris tanggal.
  Widget _calendar(Map<String, List<KegiatanItem>> events) {
    final first = DateTime(_month.year, _month.month, 1);
    // Berapa kotak kosong sebelum tanggal 1? Kalau tanggal 1 jatuh di Rabu, ada 2 kotak (Senin, Selasa).
    final leading = first.weekday - 1; // Senin = 0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Jumlah baris (minggu) yang dibutuhkan bulan ini.
    final weeks = ((leading + daysInMonth) / 7).ceil();
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 18, color: WarnaAnggota.primary),
              const SizedBox(width: 8),
              Text('${kBulan[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              _navBtn(Icons.chevron_left, () => _changeMonth(-1)),
              _navBtn(Icons.chevron_right, () => _changeMonth(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: hari
                .map((h) => Expanded(
              child: Center(
                child: Text(h,
                    style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey, fontWeight: FontWeight.w600)),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Perulangan: buat tiap minggu satu baris, tiap baris berisi 7 hari.
          // DateTime otomatis memajukan bulan kalau tanggalnya melebihi akhir bulan.
          for (int w = 0; w < weeks; w++)
            Row(
              children: [
                for (int c = 0; c < 7; c++) _cell(DateTime(_month.year, _month.month, w * 7 + c - leading + 1), events),
              ],
            ),
        ],
      ),
    );
  }

  // Kartu agenda pada tanggal yang dipilih: judul, jam, lokasi, tombol RSVP, dan tombol Absen.
  Widget _agendaCard(KegiatanItem k, bool sudahHadir, bool sudahAbsen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill(k.wajib ? 'Kegiatan Wajib Anggota' : 'Kegiatan Anggota',
                          bg: WarnaAnggota.secondarySoft, fg: WarnaAnggota.secondaryDark),
                      const SizedBox(height: 8),
                      Text(k.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                ),
                const Icon(Icons.groups_outlined, color: WarnaAnggota.primary),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  InfoRow(Icons.schedule, k.jam),
                  InfoRow(Icons.place_outlined, k.lokasi),
                ],
              ),
            ),
            const SizedBox(height: 12),
            hadirButton(context, k, sudahHadir, label: 'Saya Akan Hadir', style: primaryButton),
            if (kFiturKehadiran && k.hariIni) ...[
              const SizedBox(height: 8),
              absenButton(context, k, sudahAbsen),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KegiatanBuilder(
        builder: (context, items, daftar, hadir, absen) {
          // Kelompokkan kegiatan per tanggal, dengan kunci dari dateKey().
          // Contoh: '2026-11-12' -> [kegiatan A, kegiatan B].
          final events = <String, List<KegiatanItem>>{};
          for (final k in items) {
            events.putIfAbsent(dateKey(k.tanggal), () => []).add(k);
          }
          final agenda = events[dateKey(_selected)] ?? <KegiatanItem>[];
          final label = '${_selected.day} ${kBulan[_selected.month - 1]} ${_selected.year}';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(title: 'Jadwal'),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: WarnaAnggota.secondarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.waving_hand, size: 20, color: WarnaAnggota.secondary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, Rekan Pemuda!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Siap aktif di kegiatan Karang Taruna?',
                              style: TextStyle(fontSize: 12, color: WarnaAnggota.grey)),
                        ],
                      ),
                    ),
                    const Pill('Anggota Aktif', bg: WarnaAnggota.primary, fg: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _calendar(events),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Agenda Tanggal $label',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Pill('${agenda.length} Agenda', bg: WarnaAnggota.primarySoft, fg: WarnaAnggota.primary),
                ],
              ),
              const SizedBox(height: 10),
              if (agenda.isEmpty)
                emptyCard('Belum ada agenda di tanggal ini')
              else
                ...agenda.map((k) => _agendaCard(k, hadir.contains(k.id), absen.contains(k.id))),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// ABSENSI (input kode dari sekretaris)
// =====================================================================
// Tombol absensi dengan 3 kemungkinan tampilan:
//   - sudah absen          -> 'Sudah Absen' (tidak aktif)
//   - kode belum dibuka    -> 'Absensi belum dibuka' (tidak aktif)
//   - siap absen           -> 'Absen Sekarang' (membuka kotak isi kode)
Widget absenButton(BuildContext context, KegiatanItem k, bool sudahAbsen) {
  if (sudahAbsen) {
    return OutlinedButton.icon(
      style: outlineButton,
      onPressed: null,
      icon: const Icon(Icons.verified, size: 18),
      label: const Text('Sudah Absen'),
    );
  }
  if (k.kodeAbsen.isEmpty) {
    return OutlinedButton.icon(
      style: outlineButton,
      onPressed: null,
      icon: const Icon(Icons.lock_clock, size: 18),
      label: const Text('Absensi belum dibuka'),
    );
  }
  return FilledButton.icon(
    style: secondaryButton,
    onPressed: () => _dialogAbsen(context, k),
    icon: const Icon(Icons.pin_outlined, size: 18),
    label: const Text('Absen Sekarang'),
  );
}

// Menampilkan kotak dialog untuk memasukkan kode dari sekretaris, lalu mengecek kodenya.
Future<void> _dialogAbsen(BuildContext context, KegiatanItem k) async {
  final c = TextEditingController();
  final kode = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Absen Kegiatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.judul, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: fieldDec(icon: Icons.pin_outlined, hint: 'Kode dari sekretaris'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: WarnaAnggota.primary),
          onPressed: () => Navigator.pop(ctx, c.text),
          child: const Text('Absen'),
        ),
      ],
    ),
  );
  if (kode == null) return;
  final err = await KegiatanService.absen(k, kode);
  if (context.mounted) toast(context, err ?? 'Absensi berhasil dicatat!');
}

// =====================================================================
// STATISTIK KEAKTIFAN (dipakai di Profil)
// =====================================================================
// Dua kotak statistik di Profil: jumlah kegiatan dihadiri dan poin keaktifan.
// Angkanya dihitung dari jumlah dokumen 'absensi' milik user (1 absen = 10 poin).
class StatKeaktifan extends StatefulWidget {
  const StatKeaktifan({super.key});

  @override
  State<StatKeaktifan> createState() => _StatKeaktifanState();
}

class _StatKeaktifanState extends State<StatKeaktifan> {
  late final Stream<Set<String>> _stream = KegiatanService.absensiIds();

  Widget _stat(String label, String nilai, IconData icon) {
    return Expanded(
      child: AppCard(
        child: Column(
          children: [
            Icon(icon, color: WarnaAnggota.primary),
            const SizedBox(height: 6),
            Text(nilai, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: WarnaAnggota.primary)),
            Text(label, style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _stream,
      builder: (context, snap) {
        final n = snap.data?.length ?? 0;
        return Row(
          children: [
            _stat('Kegiatan Dihadiri', '$n', Icons.event_available),
            const SizedBox(width: 12),
            _stat('Poin Keaktifan', '${n * 10}', Icons.star_outline),
          ],
        );
      },
    );
  }
}

// =====================================================================
// USULAN KEGIATAN -> memakai halaman milik tim (lib/usulan)
// =====================================================================
// Membuka HalamanUsulan yang sudah ada di repo kelompok. Skema Firestore-nya
// (pengusulUid, status, dukungan, dll) diurus oleh halaman itu, bukan kita.
Future<void> bukaUsulan(BuildContext context) async {
  final profil = await UserService.getProfil();
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HalamanUsulan(
        namaPengguna: (profil?['nama'] ?? '').toString(),
        peran: (profil?['role'] ?? 'Anggota').toString(),
      ),
    ),
  );
}