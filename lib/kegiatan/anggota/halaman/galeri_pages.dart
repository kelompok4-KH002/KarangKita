// =====================================================================
// galeri_pages.dart  -  Galeri dokumentasi kegiatan (BACA SAJA untuk anggota)
// =====================================================================
// Isi file ini:
//   1. GaleriPage      -> daftar album (dari collection 'galeri' milik kelompok)
//   2. AlbumPage       -> isi satu album (grid foto)
//   3. FotoViewerPage  -> melihat foto layar penuh (geser, zoom)
//
// Foto diunggah pengurus ke Cloudinary dan alamatnya disimpan di Firestore.
// Anggota hanya melihat; mengunggah/menghapus foto hanya untuk pengurus (sesuai Rules).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utilitas/layanan_cloudinary.dart';

import '../layanan/kegiatan_service.dart';
import '../pendukung_anggota.dart';
import 'kegiatan_pages.dart';

// Gambar dari internet dengan loading dan cadangan kalau gagal dimuat.
Widget _gambar(String url, {BoxFit fit = BoxFit.cover}) {
  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, progress) =>
    progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorBuilder: (context, error, stack) =>
    const Center(child: Icon(Icons.broken_image_outlined, color: WarnaAnggota.grey)),
  );
}

// =====================================================================
// GALERI: daftar album
// =====================================================================
class GaleriPage extends StatefulWidget {
  const GaleriPage({super.key});

  @override
  State<GaleriPage> createState() => _GaleriPageState();
}

class _GaleriPageState extends State<GaleriPage> {
  late final Stream<List<AlbumGaleri>> _stream = KegiatanService.albumStream();

  Future<void> _bukaModalTambahFoto(BuildContext context, List<AlbumGaleri> albums) async {
    String albumIdTerpilih = albums.isNotEmpty ? albums.first.albumId : '+_buat_album_baru';
    XFile? fileFotoBaru;
    final captionCtrl = TextEditingController();
    final namaAlbumBaruCtrl = TextEditingController();
    bool mengunggah = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: WarnaAnggota.primarySoft, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add_a_photo_outlined, color: WarnaAnggota.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Tambah Foto Dokumentasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Pilih Album Kegiatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaAnggota.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: albumIdTerpilih,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    ...albums.map((a) => DropdownMenuItem(value: a.albumId, child: Text(a.judul, overflow: TextOverflow.ellipsis))),
                    const DropdownMenuItem(value: '+_buat_album_baru', child: Text('+ Buat Album Baru', style: TextStyle(fontWeight: FontWeight.bold, color: WarnaAnggota.primary))),
                  ],
                  onChanged: mengunggah ? null : (val) {
                    if (val != null) setModalState(() => albumIdTerpilih = val);
                  },
                ),
                const SizedBox(height: 14),

                if (albumIdTerpilih == '+_buat_album_baru') ...[
                  const Text('Nama Album / Kegiatan Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaAnggota.grey)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: namaAlbumBaruCtrl,
                    enabled: !mengunggah,
                    decoration: InputDecoration(
                      hintText: 'Misal: Latihan Futsal RT / Kerja Bakti RW',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text('Pilih Foto dari HP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaAnggota.grey)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: mengunggah
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (img != null) {
                            setModalState(() => fileFotoBaru = img);
                          }
                        },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: WarnaAnggota.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: fileFotoBaru != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: WarnaAnggota.primary, size: 28),
                                const SizedBox(height: 4),
                                Text('Foto Terpilih: ${fileFotoBaru!.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 32, color: WarnaAnggota.primary),
                              SizedBox(height: 6),
                              Text('Ketuk untuk memilih foto dokumentasi', style: TextStyle(fontSize: 12, color: WarnaAnggota.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Keterangan / Caption Foto (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: WarnaAnggota.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: captionCtrl,
                  enabled: !mengunggah,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Foto kebersamaan warga saat kegiatan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WarnaAnggota.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: mengunggah
                        ? null
                        : () async {
                            if (fileFotoBaru == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Silakan pilih foto terlebih dahulu!')),
                              );
                              return;
                            }

                            if (albumIdTerpilih == '+_buat_album_baru' && namaAlbumBaruCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Silakan isi nama album baru terlebih dahulu!')),
                              );
                              return;
                            }

                            setModalState(() => mengunggah = true);

                            final res = await LayananCloudinary.unggahGambar(fileFotoBaru!);
                            if (res == null || res['secure_url'] == null) {
                              setModalState(() => mengunggah = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gagal mengunggah foto ke Cloudinary')),
                                );
                              }
                              return;
                            }

                            final fotoUrl = res['secure_url'].toString();
                            final caption = captionCtrl.text.trim();
                            final idFoto = 'foto_${DateTime.now().millisecondsSinceEpoch}';

                            try {
                              if (albumIdTerpilih == '+_buat_album_baru') {
                                final namaAlbum = namaAlbumBaruCtrl.text.trim();
                                final docBaruRef = FirebaseFirestore.instance.collection('galeri').doc();
                                final nowStr = DateTime.now().toIso8601String().split('T').first;

                                await docBaruRef.set({
                                  'album': namaAlbum,
                                  'albumId': docBaruRef.id,
                                  'tanggalAlbum': nowStr,
                                  'fotos': [
                                    {
                                      'id': idFoto,
                                      'url': fotoUrl,
                                      'caption': caption,
                                    }
                                  ],
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              } else {
                                await FirebaseFirestore.instance.collection('galeri').doc(albumIdTerpilih).update({
                                  'fotos': FieldValue.arrayUnion([
                                    {
                                      'id': idFoto,
                                      'url': fotoUrl,
                                      'caption': caption,
                                    }
                                  ]),
                                });
                              }

                              if (context.mounted) Navigator.pop(context);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Foto dokumentasi berhasil ditambahkan!')),
                                );
                              }
                            } catch (e) {
                              setModalState(() => mengunggah = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menyimpan foto ke album: $e')),
                                );
                              }
                            }
                          },
                    icon: mengunggah
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.upload, size: 18),
                    label: const Text('Unggah Foto', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<AlbumGaleri>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat galeri.\n${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final albums = snap.data!;
          final totalFoto = albums.fold<int>(0, (sum, a) => sum + a.fotos.length);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const PageHeader(
                title: 'Galeri',
                bell: false,
                trailing: Icon(Icons.collections_outlined, color: WarnaAnggota.grey),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dokumentasi Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: WarnaAnggota.primary,
                      side: const BorderSide(color: WarnaAnggota.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () => _bukaModalTambahFoto(context, albums),
                    icon: const Icon(Icons.add_a_photo, size: 14),
                    label: const Text('+ Tambah Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
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
                      child: Text('Total $totalFoto foto dokumentasi',
                          style: const TextStyle(fontSize: 12, color: WarnaAnggota.grey)),
                    ),
                    Text('${albums.length} Album', style: const TextStyle(fontSize: 11, color: WarnaAnggota.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (albums.isEmpty)
                emptyCard('Belum ada album')
              else
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
                          MaterialPageRoute(builder: (_) => AlbumPage(album: albums[i])),
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
                                  SizedBox(
                                    height: 110,
                                    width: double.infinity,
                                    child: albums[i].sampul == null
                                        ? PhotoPlaceholder(height: 110, seed: i, icon: Icons.photo)
                                        : _gambar(albums[i].sampul!),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Pill('${albums[i].fotos.length} Foto',
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
                                    Text(albums[i].tanggal,
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
            ],
          );
        },
      ),
    );
  }
}

// =====================================================================
// ISI ALBUM
// =====================================================================
class AlbumPage extends StatelessWidget {
  final AlbumGaleri album;
  const AlbumPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final fotos = album.fotos;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubHeader(title: 'Dokumentasi'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Text(album.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  InfoRow(Icons.calendar_today_outlined, album.tanggal),
                  const SizedBox(height: 14),
                  if (fotos.isEmpty)
                    emptyCard('Belum ada foto')
                  else
                    GridView.builder(
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
                          MaterialPageRoute(builder: (_) => FotoViewerPage(fotos: fotos, index: i)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _gambar(fotos[i].url),
                        ),
                      ),
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
class FotoViewerPage extends StatefulWidget {
  final List<GaleriFoto> fotos;
  final int index;
  const FotoViewerPage({super.key, required this.fotos, required this.index});

  @override
  State<FotoViewerPage> createState() => _FotoViewerPageState();
}

class _FotoViewerPageState extends State<FotoViewerPage> {
  late final PageController _ctrl = PageController(initialPage: widget.index);
  late int _current = widget.index;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fotos[_current];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.fotos.length}', style: const TextStyle(fontSize: 14)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: widget.fotos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) => InteractiveViewer(
                child: Center(child: _gambar(widget.fotos[i].url, fit: BoxFit.contain)),
              ),
            ),
          ),
          if (f.deskripsi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(f.deskripsi, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}