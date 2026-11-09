// =====================================================================
// galeri_pages.dart  -  Galeri dokumentasi kegiatan
// =====================================================================
// Isi file ini:
//   1. GaleriPage      -> daftar album (1 kegiatan = 1 album)
//   2. AlbumPage       -> isi album + tombol 'Tambah Foto'
//   3. FotoViewerPage  -> melihat foto layar penuh (geser, zoom, hapus)
//
// Foto disimpan di Firestore sebagai teks (base64), BUKAN di Firebase Storage,
// supaya gratis tanpa kartu kredit. Cocok untuk demo, tapi tidak untuk ratusan foto.

import 'package:flutter/material.dart';
// Paket untuk memilih foto dari galeri HP.
import 'package:image_picker/image_picker.dart';

import 'kegiatan_pages.dart';
import '../layanan/kegiatan_service.dart';
import '../pendukung_anggota.dart';

// =====================================================================
// GALERI: daftar album (1 kegiatan = 1 album)
// =====================================================================
// Halaman Galeri: ringkasan total foto dan grid album.
class GaleriPage extends StatelessWidget {
  const GaleriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KegiatanBuilder(
        builder: (context, items, daftar, hadir, absen) {
          // Album = kegiatan yang sudah atau sedang berlangsung, yang terbaru di atas.
          final albums = items.where((k) => k.sudahMulai).toList().reversed.toList();
          // Menjumlahkan jumlahFoto dari semua album (fold = menggabungkan list menjadi satu nilai).
          final totalFoto = albums.fold<int>(0, (sum, k) => sum + k.jumlahFoto);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(
                title: 'Galeri',
                bell: false,
                trailing: Icon(Icons.collections_outlined, color: WarnaAnggota.grey),
              ),
              const SizedBox(height: 14),
              const Text('Dokumentasi Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.collections, color: WarnaAnggota.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Flexible(
                                child: Text('Semangat Gotong Royong',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.star, size: 14, color: WarnaAnggota.secondary),
                            ],
                          ),
                          Text('Total $totalFoto foto dokumentasi anggota',
                              style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
                        ],
                      ),
                    ),
                    Text('${albums.length} Album', style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (albums.isEmpty)
                emptyCard('Belum ada album')
              else
              // Grid 2 kolom. childAspectRatio mengatur perbandingan lebar dan tinggi tiap kartu.
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    for (int i = 0; i < albums.length; i++)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AlbumPage(kegiatan: albums[i])),
                        ),
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: WarnaAnggota.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  PhotoPlaceholder(height: 110, seed: i, icon: Icons.photo),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Pill('${albums[i].jumlahFoto} Foto',
                                        bg: WarnaAnggota.overlay, fg: Colors.white, icon: Icons.photo_camera_outlined),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      albums[i].judul,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(albums[i].tanggalSingkat,
                                        style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 16, color: WarnaAnggota.primary),
                    SizedBox(width: 6),
                    Text('Dokumentasi Terverifikasi RW',
                        style: TextStyle(fontSize: 12, color: WarnaAnggota.primary, fontWeight: FontWeight.w600)),
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
// ISI ALBUM + UNGGAH FOTO
// =====================================================================
// Isi satu album: info kegiatan, tombol Tambah Foto, dan grid foto.
class AlbumPage extends StatefulWidget {
  final KegiatanItem kegiatan;
  const AlbumPage({super.key, required this.kegiatan});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  // Stream foto album ini (realtime): kalau ada yang mengunggah, langsung muncul.
  late final Stream<List<FotoItem>> _stream = KegiatanService.fotoStream(widget.kegiatan.id);
  // Sedang mengunggah? Dipakai untuk menampilkan loading dan menonaktifkan tombol.
  bool _uploading = false;

  // Alur tambah foto: pilih foto -> kecilkan -> baca isinya -> simpan ke Firestore -> tampilkan hasilnya.
  Future<void> _tambahFoto() async {
    try {
      // Buka galeri HP. maxWidth dan imageQuality mengecilkan foto otomatis
      // supaya ukurannya muat di batas 1 MB Firestore.
      final files = await ImagePicker().pickMultiImage(maxWidth: 1000, imageQuality: 60);
      if (files.isEmpty) return;
      if (mounted) setState(() => _uploading = true);

      int ok = 0;
      int gagal = 0;
      // Maksimal 5 foto sekali unggah. Tiap foto diproses satu per satu;
      // yang gagal (misal terlalu besar) dihitung, tidak membatalkan yang lain.
      for (final f in files.take(5)) {
        try {
          final bytes = await f.readAsBytes();
          await KegiatanService.uploadFoto(kegiatanId: widget.kegiatan.id, bytes: bytes);
          ok++;
        } catch (_) {
          gagal++;
        }
      }
      if (mounted) {
        toast(context, gagal == 0 ? '$ok foto berhasil diunggah' : '$ok berhasil, $gagal gagal (foto terlalu besar?)');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kegiatan;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(title: 'Dokumentasi'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text(k.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  InfoRow(Icons.calendar_today_outlined, '${k.tanggalPanjang} • ${k.jam}'),
                  InfoRow(Icons.place_outlined, k.lokasi),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: primaryButton,
                    onPressed: _uploading ? null : _tambahFoto,
                    icon: _uploading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(_uploading ? 'Mengunggah...' : 'Tambah Foto'),
                  ),
                  const SizedBox(height: 4),
                  const Text('Maksimal 5 foto sekali unggah. Foto otomatis dikecilkan.',
                      style: TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
                  const SizedBox(height: 14),
                  StreamBuilder<List<FotoItem>>(
                    stream: _stream,
                    builder: (context, snap) {
                      if (snap.hasError) return emptyCard('Gagal memuat foto');
                      if (!snap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final fotos = snap.data!;
                      if (fotos.isEmpty) return emptyCard('Belum ada foto. Jadilah yang pertama!');
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: fotos.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FotoViewerPage(kegiatanId: k.id, fotos: fotos, index: i),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(fotos[i].bytes, fit: BoxFit.cover, gaplessPlayback: true),
                          ),
                        ),
                      );
                    },
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
// PENAMPIL FOTO PENUH (geser kiri/kanan, zoom)
// =====================================================================
// Penampil foto layar penuh: geser kiri/kanan untuk foto lain, cubit untuk zoom.
class FotoViewerPage extends StatefulWidget {
  final String kegiatanId;
  final List<FotoItem> fotos;
  final int index;
  const FotoViewerPage({super.key, required this.kegiatanId, required this.fotos, required this.index});

  @override
  State<FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<FotoViewerPage> {
  // PageController = pengatur halaman geser. initialPage = foto yang diketuk tadi.
  late final PageController _ctrl = PageController(initialPage: widget.index);
  // Nomor foto yang sedang tampil (untuk teks '2 / 7' dan tombol hapus).
  late int _current = widget.index;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Hapus foto (hanya muncul kalau itu foto milik sendiri): tanya konfirmasi dulu, lalu hapus.
  Future<void> _hapus() async {
    final f = widget.fotos[_current];
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: const Text('Foto ini akan dihapus dari album.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: WarnaAnggota.danger)),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    await KegiatanService.hapusFoto(widget.kegiatanId, f.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fotos[_current];
    final milikSaya = f.uid == UserService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.fotos.length}', style: const TextStyle(fontSize: 14)),
        actions: [
          if (milikSaya) IconButton(onPressed: _hapus, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // PageView = daftar yang bisa digeser per halaman. builder membuat halaman sesuai kebutuhan.
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _current = i),
              // InteractiveViewer = foto bisa di-zoom dan digeser dengan jari.
              itemBuilder: (context, i) => InteractiveViewer(
                child: Center(child: Image.memory(widget.fotos[i].bytes, fit: BoxFit.contain)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              f.nama.isEmpty ? 'Diunggah anggota' : 'Diunggah oleh ${f.nama}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}