import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';

// Model Data Dokumentasi Foto Galeri Individual
class ModelFotoGaleri {
  final String id;
  final String albumId;
  final String album;
  final String tanggalAlbum; // Format ISO: yyyy-MM-dd
  final int urutan;
  final String deskripsi;
  final String downloadUrl;
  final String publicId;
  final String uploadedBy;
  final DateTime createdAt;

  ModelFotoGaleri({
    required this.id,
    required this.albumId,
    required this.album,
    required this.tanggalAlbum,
    required this.urutan,
    required this.deskripsi,
    required this.downloadUrl,
    required this.publicId,
    required this.uploadedBy,
    required this.createdAt,
  });
}

// Model Data Kelompok Album Galeri
class ModelAlbumGaleri {
  final String albumId;
  final String album;
  final String tanggalAlbum;
  final List<ModelFotoGaleri> fotoList;

  ModelAlbumGaleri({
    required this.albumId,
    required this.album,
    required this.tanggalAlbum,
    required this.fotoList,
  });

  int get jumlahFoto => fotoList.length;

  String get sampulUrl {
    if (fotoList.isEmpty) return '';
    // Cari foto dengan urutan 0 atau foto pertama
    final fotoSampul = fotoList.firstWhere(
      (f) => f.urutan == 0,
      orElse: () => fotoList.first,
    );
    final url = fotoSampul.downloadUrl;
    if (url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/w_400,q_auto,f_auto/');
    }
    return url;
  }
}

// Halaman Utama Kelola Dokumentasi Galeri Admin (`admin_pengurus_kelola_dokumentasi.png`)
class HalamanGaleriAdmin extends StatefulWidget {
  const HalamanGaleriAdmin({super.key});

  @override
  State<HalamanGaleriAdmin> createState() => _HalamanGaleriAdminState();
}

class _HalamanGaleriAdminState extends State<HalamanGaleriAdmin> {
  late List<ModelFotoGaleri> _semuaFoto;
  late List<ModelAlbumGaleri> _daftarAlbum;
  bool _sedangMemuat = true;
  bool _adaErrorMemuat = false;
  String _pesanErrorMemuat = '';

  @override
  void initState() {
    super.initState();
    _semuaFoto = [];
    _daftarAlbum = [];
    _muatGaleriDariFirestore();
  }

  // Muat data foto dari Cloud Firestore & kelompokkan ke dalam Album
  Future<void> _muatGaleriDariFirestore() async {
    setState(() {
      _sedangMemuat = true;
      _adaErrorMemuat = false;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('galeri')
          .orderBy('createdAt', descending: true)
          .get();

      final List<ModelFotoGaleri> listCloud = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final tglRaw = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        final String tglAlbumStr = data['tanggalAlbum'] ??
            '${tglRaw.year}-${tglRaw.month.toString().padLeft(2, '0')}-${tglRaw.day.toString().padLeft(2, '0')}';

        listCloud.add(ModelFotoGaleri(
          id: doc.id,
          albumId: data['albumId'] ?? (data['album'] ?? doc.id),
          album: data['album'] ?? 'Umum',
          tanggalAlbum: tglAlbumStr,
          urutan: data['urutan'] ?? 0,
          deskripsi: data['deskripsi'] ?? data['keterangan'] ?? '',
          downloadUrl: data['downloadURL'] ?? data['imageUrl'] ?? '',
          publicId: data['publicId'] ?? '',
          uploadedBy: data['uploadedBy'] ?? '',
          createdAt: tglRaw,
        ));
      }

      final albumGrouped = _kelompokkanKeAlbum(listCloud);

      if (mounted) {
        setState(() {
          _semuaFoto = listCloud;
          _daftarAlbum = albumGrouped;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
          _adaErrorMemuat = true;
          _pesanErrorMemuat = e is FirebaseException && e.code == 'permission-denied'
              ? 'Anda tidak punya izin untuk membaca galeri'
              : 'Gagal memuat galeri, periksa koneksi internet';
        });
      }
    }
  }

  // Kelompokkan foto berdasarkan albumId (atau nama album sebagai fallback)
  List<ModelAlbumGaleri> _kelompokkanKeAlbum(List<ModelFotoGaleri> fotoList) {
    final Map<String, List<ModelFotoGaleri>> mapAlbum = {};

    for (var foto in fotoList) {
      final key = foto.albumId.isNotEmpty ? foto.albumId : foto.album;
      mapAlbum.putIfAbsent(key, () => []).add(foto);
    }

    final List<ModelAlbumGaleri> hasil = [];
    mapAlbum.forEach((key, list) {
      // Urutkan foto dalam album berdasarkan field urutan ascending
      list.sort((a, b) => a.urutan.compareTo(b.urutan));

      final judulAlbum = list.first.album;
      final tglAlbum = list.first.tanggalAlbum;

      hasil.add(ModelAlbumGaleri(
        albumId: key,
        album: judulAlbum,
        tanggalAlbum: tglAlbum,
        fotoList: list,
      ));
    });

    // Urutkan album berdasarkan tanggalAlbum terbaru di atas
    hasil.sort((a, b) => b.tanggalAlbum.compareTo(a.tanggalAlbum));
    return hasil;
  }

  String _formatTanggalIndonesia(String rawDateIso) {
    try {
      final parts = rawDateIso.split('-');
      if (parts.length != 3) return rawDateIso;
      final year = parts[0];
      final monthInt = int.tryParse(parts[1]) ?? 1;
      final day = parts[2];

      const namaBulan = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final bulanStr = monthInt >= 1 && monthInt <= 12 ? namaBulan[monthInt] : parts[1];
      return '$day $bulanStr $year';
    } catch (e) {
      return rawDateIso;
    }
  }

  void _bukaHalamanTambahDokumentasi() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HalamanTambahDokumentasi(),
      ),
    ).then((_) {
      _muatGaleriDariFirestore();
    });
  }

  void _bukaDetailAlbum(ModelAlbumGaleri album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanDetailAlbum(album: album),
      ),
    ).then((_) {
      _muatGaleriDariFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_adaErrorMemuat) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pesanErrorMemuat, style: AppTextStyles.statLabel),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                ),
                onPressed: _muatGaleriDariFirestore,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _daftarAlbum.isEmpty
          ? const Center(
              child: Text(
                'Belum ada album galeri dokumentasi',
                textAlign: TextAlign.center,
                style: AppTextStyles.statLabel,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _daftarAlbum.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final album = _daftarAlbum[index];
                return _buildAlbumCard(album);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaHalamanTambahDokumentasi,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlbumCard(ModelAlbumGaleri album) {
    return InkWell(
      onTap: () => _bukaDetailAlbum(album),
      borderRadius: AppRadius.r16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Sampul Foto dengan Badge "N Foto"
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.r16,
                border: Border.all(color: AppColors.cardBorder),
                color: AppColors.background,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  album.sampulUrl.isNotEmpty
                      ? Image.network(
                          album.sampulUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.photo_library_outlined, size: 36, color: AppColors.textMuted),
                        ),
                  // Badge jumlah foto di pojok kanan atas
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.75),
                        borderRadius: AppRadius.r6,
                      ),
                      child: Text(
                        '${album.jumlahFoto} Foto',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Judul Album & Tanggal Album
          Text(
            album.album,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 2),
          Text(
            _formatTanggalIndonesia(album.tanggalAlbum),
            style: AppTextStyles.cardSubtitle,
          ),
        ],
      ),
    );
  }
}

// Halaman Detail Album untuk Menampilkan Grid Foto 3 Kolom & Opsi Hapus Album
class HalamanDetailAlbum extends StatefulWidget {
  final ModelAlbumGaleri album;

  const HalamanDetailAlbum({
    super.key,
    required this.album,
  });

  @override
  State<HalamanDetailAlbum> createState() => _HalamanDetailAlbumState();
}

class _HalamanDetailAlbumState extends State<HalamanDetailAlbum> {
  late List<ModelFotoGaleri> _fotoList;

  @override
  void initState() {
    super.initState();
    _fotoList = List.from(widget.album.fotoList);
  }

  String _getThumbnailUrl(String originalUrl) {
    if (originalUrl.contains('/upload/')) {
      return originalUrl.replaceFirst('/upload/', '/upload/w_400,q_auto,f_auto/');
    }
    return originalUrl;
  }

  void _konfirmasiHapusAlbum() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus Album Ini?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus album "${widget.album.album}" beserta seluruh ${_fotoList.length} foto di dalamnya? Tindakan ini tidak dapat dibatalkan.\n\n(Catatan: Berkas foto di Cloudinary tetap tersimpan).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: AppTextStyles.cardSubtitle),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
            ),
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog konfirmasi
              await _prosesHapusAlbumBatch();
            },
            child: const Text('Hapus Album'),
          ),
        ],
      ),
    );
  }

  Future<void> _prosesHapusAlbumBatch() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Ambil seluruh dokumen foto yang termasuk dalam album ini
      final snap = await firestore
          .collection('galeri')
          .where('albumId', isEqualTo: widget.album.albumId)
          .get();

      List<DocumentSnapshot> docsToDelete = snap.docs;

      // Fallback jika dokumen lama tidak memiliki albumId
      if (docsToDelete.isEmpty) {
        final snapFallback = await firestore
            .collection('galeri')
            .where('album', isEqualTo: widget.album.album)
            .get();
        docsToDelete = snapFallback.docs;
      }

      // Hapus dokumen dengan WriteBatch (pecah per 400 dokumen)
      const int batchSize = 400;
      for (int i = 0; i < docsToDelete.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < docsToDelete.length) ? i + batchSize : docsToDelete.length;
        for (int j = i; j < end; j++) {
          batch.delete(docsToDelete[j].reference);
        }
        await batch.commit();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Album "${widget.album.album}" berhasil dihapus!'),
        ),
      );
      Navigator.pop(context); // Kembali ke halaman utama galeri
    } catch (e) {
      if (!mounted) return;
      final pesanErr = e is FirebaseException && e.code == 'permission-denied'
          ? 'Anda tidak punya izin untuk menghapus album ini'
          : 'Gagal menghapus album, periksa koneksi internet';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanErr), backgroundColor: AppColors.danger),
      );
    }
  }

  void _hapusFotoSatuan(ModelFotoGaleri item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus foto ini?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus foto ini dari album "${widget.album.album}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: AppTextStyles.cardSubtitle),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance.collection('galeri').doc(item.id).delete();

                setState(() {
                  _fotoList.removeWhere((f) => f.id == item.id);
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Foto berhasil dihapus dari album.')),
                );

                // Jika foto terakhir dihapus, otomatis kembali ke halaman daftar album
                if (_fotoList.isEmpty) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (!mounted) return;
                final pesanErr = e is FirebaseException && e.code == 'permission-denied'
                    ? 'Anda tidak punya izin untuk tindakan ini'
                    : 'Gagal menghapus foto, periksa koneksi internet';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(pesanErr), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _bukaFullscreenViewer(ModelFotoGaleri item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                item.downloadUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textWhite,
                  size: 48,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  backgroundColor: AppColors.textPrimary.withOpacity(0.7),
                  child: const Icon(Icons.close, color: AppColors.textWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.album, style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'hapus_album') {
                _konfirmasiHapusAlbum();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'hapus_album',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus Album Ini', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _fotoList.isEmpty
          ? const Center(
              child: Text('Album ini tidak memiliki foto', style: AppTextStyles.statLabel),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _fotoList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final item = _fotoList[index];
                final thumbUrl = _getThumbnailUrl(item.downloadUrl);

                return InkWell(
                  onTap: () => _bukaFullscreenViewer(item),
                  borderRadius: AppRadius.r12,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.r12,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                          ),
                        ),
                        // Tombol Hapus Satuan (X)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () => _hapusFotoSatuan(item),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.textPrimary.withOpacity(0.6),
                              child: const Icon(Icons.close, size: 14, color: AppColors.textWhite),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Halaman Penuh Form Tambah Dokumentasi Presisi Sesuai Mockup (`admin_pengurus_tambah_dokumentasi.png`)
class HalamanTambahDokumentasi extends StatefulWidget {
  const HalamanTambahDokumentasi({super.key});

  @override
  State<HalamanTambahDokumentasi> createState() => _HalamanTambahDokumentasiState();
}

class _HalamanTambahDokumentasiState extends State<HalamanTambahDokumentasi> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _keteranganController;

  final List<XFile> _fotoAntrean = [];
  final List<String> _gagalUnggahPaths = [];

  bool _sedangMengunggah = false;
  String _statusUnggah = '';
  DateTime? _tanggalTerpilih;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController();
    _tanggalController = TextEditingController();
    _keteranganController = TextEditingController();

    // Default tanggal hari ini
    _tanggalTerpilih = DateTime.now();
    _tanggalController.text = _formatIsoDate(_tanggalTerpilih!);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  String _formatIsoDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTanggalIndonesiaDisplay(DateTime date) {
    const namaBulan = [
      '',
      'Agu',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final bln = date.month >= 1 && date.month <= 12 ? namaBulan[date.month] : '${date.month}';
    return '${date.day} $bln ${date.year}';
  }

  Future<void> _pilihBanyakFoto() async {
    if (_fotoAntrean.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 10 foto yang dapat dipilih sekaligus!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      final int sisaKuota = 10 - _fotoAntrean.length;
      final List<XFile> selected = await _picker.pickMultiImage(
        limit: sisaKuota,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (selected.isNotEmpty) {
        final List<XFile> validFiles = [];

        for (var file in selected) {
          // Validasi tipe ekstensi foto (hanya .jpg, .jpeg, .png)
          final pathLower = file.path.toLowerCase();
          if (!pathLower.endsWith('.jpg') &&
              !pathLower.endsWith('.jpeg') &&
              !pathLower.endsWith('.png')) {
            if (!mounted) continue;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berkas "${file.name}" ditolak! Hanya mendukung format JPG, JPEG, dan PNG.'),
                backgroundColor: AppColors.danger,
              ),
            );
            continue;
          }

          // Validasi ukuran berkas <= 5 MB
          final int fileBytes = await file.length();
          if (fileBytes > 5 * 1024 * 1024) {
            if (!mounted) continue;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ukuran foto "${file.name}" melebihi batas 5 MB!'),
                backgroundColor: AppColors.danger,
              ),
            );
            continue;
          }

          validFiles.add(file);
        }

        setState(() {
          for (var f in validFiles) {
            if (_fotoAntrean.length < 10) {
              _fotoAntrean.add(f);
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _hapusFotoDariAntrean(int index) {
    setState(() {
      final removed = _fotoAntrean.removeAt(index);
      _gagalUnggahPaths.remove(removed.path);
    });
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTerpilih ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalTerpilih = picked;
        _tanggalController.text = _formatIsoDate(picked);
      });
    }
  }

  // Unggah foto ke Cloudinary paralel dengan pool maks 3 bersamaan
  Future<void> _prosesUnggahDanSimpanBatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoAntrean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal 1 foto dokumentasi!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _sedangMengunggah = true;
      _statusUnggah = 'Mengunggah 0 dari ${_fotoAntrean.length} foto...';
      _gagalUnggahPaths.clear();
    });

    final String albumIdBaru = 'album_${DateTime.now().millisecondsSinceEpoch}';
    final String judulAlbum = _judulController.text.trim();
    final String tanggalIso = _tanggalController.text.trim();
    final String keterangan = _keteranganController.text.trim();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'Admin';

    final List<Map<String, dynamic>> hasilSuksesCloudinary = [];
    int counterSelesai = 0;

    // Fungsi pekerja pengunggahan 1 foto ke Cloudinary
    Future<void> uploadSingleFoto(XFile file, int indexUrutan) async {
      try {
        final uri = Uri.parse('https://api.cloudinary.com/v1_1/${AppConstants.kCloudinaryCloudName}/image/upload');
        final request = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = AppConstants.kCloudinaryUploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        final streamedResp = await request.send();
        final resp = await http.Response.fromStream(streamedResp);

        if (resp.statusCode == 200) {
          final jsonResp = json.decode(resp.body);
          final secureUrl = jsonResp['secure_url'] ?? '';
          final publicId = jsonResp['public_id'] ?? '';

          if (secureUrl.isNotEmpty) {
            hasilSuksesCloudinary.add({
              'urutan': indexUrutan,
              'downloadURL': secureUrl,
              'publicId': publicId,
            });
          } else {
            _gagalUnggahPaths.add(file.path);
          }
        } else {
          _gagalUnggahPaths.add(file.path);
        }
      } catch (e) {
        _gagalUnggahPaths.add(file.path);
      } finally {
        counterSelesai++;
        if (mounted) {
          setState(() {
            _statusUnggah = 'Mengunggah $counterSelesai dari ${_fotoAntrean.length} foto...';
          });
        }
      }
    }

    // Eksekusi pengunggahan paralel dengan pool maks 3 bersamaan
    const int maxConcurrent = 3;
    for (int i = 0; i < _fotoAntrean.length; i += maxConcurrent) {
      final pool = <Future<void>>[];
      for (int j = i; j < i + maxConcurrent && j < _fotoAntrean.length; j++) {
        pool.add(uploadSingleFoto(_fotoAntrean[j], j));
      }
      await Future.wait(pool);
    }

    // Jika ada foto yang gagal diunggah
    if (_gagalUnggahPaths.isNotEmpty) {
      if (mounted) {
        setState(() {
          _sedangMengunggah = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_gagalUnggahPaths.length} foto gagal diunggah ke Cloudinary. Silakan tekan tombol "Coba lagi untuk yang gagal".'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Jika SEMUA foto berhasil diunggah ke Cloudinary, tulis dokumen ke Firestore dengan WriteBatch
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var item in hasilSuksesCloudinary) {
        final docRef = firestore.collection('galeri').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'albumId': albumIdBaru,
          'album': judulAlbum,
          'tanggalAlbum': tanggalIso,
          'urutan': item['urutan'],
          'deskripsi': keterangan,
          'downloadURL': item['downloadURL'],
          'publicId': item['publicId'],
          'uploadedBy': currentUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Album "$judulAlbum" dengan ${_fotoAntrean.length} foto berhasil disimpan!'),
        ),
      );
      Navigator.pop(context); // Kembali ke Halaman Utama Galeri
    } catch (e) {
      if (!mounted) return;
      setState(() => _sedangMengunggah = false);
      final pesanErr = e is FirebaseException && e.code == 'permission-denied'
          ? 'Anda tidak punya izin untuk tindakan ini'
          : 'Gagal menyimpan data album ke Firestore, periksa koneksi internet';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanErr), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Dokumentasi', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 20, color: AppColors.textWhite),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Sub-header & Subtitle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeOrangeBg,
                  borderRadius: AppRadius.r20,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: AppColors.badgeOrangeText),
                    SizedBox(width: 6),
                    Text(
                      'ADMIN / PENGURUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.badgeOrangeText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tambah Dokumentasi Baru',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Unggah foto dan dokumentasi kegiatan untuk arsip galeri Karang Taruna.',
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 20),

              // Area Dropzone & Counter Foto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Foto Dokumentasi', style: AppTextStyles.inputLabel),
                      const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${_fotoAntrean.length} / 10 foto',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _fotoAntrean.length >= 10 ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Box Dropzone Utama
              GestureDetector(
                onTap: _sedangMengunggah ? null : _pilihBanyakFoto,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.r16,
                    border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      const Text('Ketuk untuk pilih foto dokumentasi', style: AppTextStyles.cardTitle),
                      const SizedBox(height: 4),
                      const Text(
                        'Mendukung JPG, PNG (Maks. 10 foto sekaligus, maks 5 MB per foto)',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Barisan Thumbnail Foto Terpilih (jika ada)
              if (_fotoAntrean.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotoAntrean.length,
                    itemBuilder: (context, index) {
                      final file = _fotoAntrean[index];
                      final bool isGagal = _gagalUnggahPaths.contains(file.path);

                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.r12,
                          border: Border.all(
                            color: isGagal ? AppColors.danger : AppColors.cardBorder,
                            width: isGagal ? 2.0 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(file.path),
                              fit: BoxFit.cover,
                            ),
                            // Tombol Silang X untuk menghapus foto dari antrean
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _sedangMengunggah ? null : () => _hapusFotoDariAntrean(index),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.textPrimary.withOpacity(0.7),
                                  child: const Icon(Icons.close, size: 14, color: AppColors.textWhite),
                                ),
                              ),
                            ),
                            if (isGagal)
                              Container(
                                color: AppColors.danger.withOpacity(0.4),
                                child: const Center(
                                  child: Icon(Icons.error_outline, color: AppColors.textWhite, size: 28),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tombol Coba Lagi jika ada pengunggahan gagal
              if (_gagalUnggahPaths.isNotEmpty && !_sedangMengunggah) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    ),
                    onPressed: _prosesUnggahDanSimpanBatch,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('Coba lagi untuk ${_gagalUnggahPaths.length} foto yang gagal'),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Field 1: Nama Kegiatan / Judul Album *
              Row(
                children: [
                  Text('Nama Kegiatan / Judul Album', style: AppTextStyles.inputLabel),
                  const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _judulController,
                enabled: !_sedangMengunggah,
                decoration: _buildInputDecoration(
                  hintText: 'Contoh: Kerja Bakti RT 04 atau Peringatan HUT RI',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama Kegiatan / Judul Album wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field 2: Tanggal Kegiatan *
              Row(
                children: [
                  Text('Tanggal Kegiatan', style: AppTextStyles.inputLabel),
                  const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                enabled: !_sedangMengunggah,
                onTap: _sedangMengunggah ? null : _pilihTanggal,
                decoration: _buildInputDecoration(
                  hintText: 'yyyy-MM-dd',
                  suffixIcon: Icons.calendar_today_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tanggal Kegiatan wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field 3: Keterangan Singkat (Opsional)
              Text('Keterangan Singkat (Opsional)', style: AppTextStyles.inputLabel),
              const SizedBox(height: 6),
              TextFormField(
                controller: _keteranganController,
                enabled: !_sedangMengunggah,
                maxLines: 3,
                decoration: _buildInputDecoration(
                  hintText: 'Tulis catatan singkat mengenai dokumentasi kegiatan ini...',
                ),
              ),
              const SizedBox(height: 24),

              // Status Progres Unggah
              if (_sedangMengunggah) ...[
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(_statusUnggah, style: AppTextStyles.cardSubtitle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Tombol Utama: Simpan Dokumentasi (✓)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    elevation: 0,
                  ),
                  onPressed: _sedangMengunggah ? null : _prosesUnggahDanSimpanBatch,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text('Simpan Dokumentasi', style: AppTextStyles.buttonPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tombol Sekunder: Batal (✕)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                  ),
                  onPressed: _sedangMengunggah ? null : () => Navigator.pop(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppColors.primary, size: 20) : null,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
