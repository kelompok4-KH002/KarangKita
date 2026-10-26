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

// Model Data Dokumentasi Foto Galeri
class ModelFotoGaleri {
  final String id;
  final String judul;
  final String album;
  final String deskripsi;
  final String downloadUrl;
  final String publicId;
  final String uploadedBy;
  final DateTime createdAt;

  ModelFotoGaleri({
    required this.id,
    required this.judul,
    required this.album,
    required this.deskripsi,
    required this.downloadUrl,
    required this.publicId,
    required this.uploadedBy,
    required this.createdAt,
  });
}

// Halaman Kelola Dokumentasi Galeri Admin High-Fidelity (`admin_pengurus_kelola_dokumentasi.png`)
class HalamanGaleriAdmin extends StatefulWidget {
  const HalamanGaleriAdmin({super.key});

  @override
  State<HalamanGaleriAdmin> createState() => _HalamanGaleriAdminState();
}

class _HalamanGaleriAdminState extends State<HalamanGaleriAdmin> {
  String _filterAlbum = 'Semua';
  late List<ModelFotoGaleri> _daftarFoto;
  bool _sedangMemuat = true;
  bool _adaErrorMemuat = false;
  String _pesanErrorMemuat = '';

  @override
  void initState() {
    super.initState();
    _daftarFoto = [];
    _muatGaleriDariFirestore();
  }

  // Muat foto dari Cloud Firestore (Maksimal 60 foto terbaru)
  void _muatGaleriDariFirestore() async {
    setState(() {
      _sedangMemuat = true;
      _adaErrorMemuat = false;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('galeri')
          .orderBy('createdAt', descending: true)
          .limit(60)
          .get();

      final List<ModelFotoGaleri> listCloud = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final tglRaw = data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();

        listCloud.add(ModelFotoGaleri(
          id: doc.id,
          judul: data['judul'] ?? 'Foto Dokumentasi',
          album: data['album'] ?? 'Umum',
          deskripsi: data['deskripsi'] ?? '',
          downloadUrl: data['downloadURL'] ?? data['imageUrl'] ?? '',
          publicId: data['publicId'] ?? '',
          uploadedBy: data['uploadedBy'] ?? '',
          createdAt: tglRaw,
        ));
      }

      if (mounted) {
        setState(() {
          _daftarFoto = listCloud;
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

  // Dapatkan daftar album unik secara dinamis dari data asli
  List<String> _getDaftarAlbumDinamis() {
    final Set<String> albumSet = {'Semua'};
    for (var f in _daftarFoto) {
      if (f.album.trim().isNotEmpty) {
        albumSet.add(f.album.trim());
      }
    }
    return albumSet.toList();
  }

  // Filter list foto berdasarkan album
  List<ModelFotoGaleri> _getFilteredFoto() {
    if (_filterAlbum == 'Semua') {
      return _daftarFoto;
    }
    return _daftarFoto.where((foto) => foto.album == _filterAlbum).toList();
  }

  // Sisipkan transformasi URL Cloudinary untuk hemat kuota & loading super cepat
  String _getThumbnailUrl(String originalUrl) {
    if (originalUrl.contains('/upload/')) {
      return originalUrl.replaceFirst('/upload/', '/upload/w_400,q_auto,f_auto/');
    }
    return originalUrl;
  }

  // Hapus foto: Hapus dokumen Firestore DULU, lalu tampilkan SnackBar
  void _hapusFoto(ModelFotoGaleri item) {
    final tglStr = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus foto ini?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus foto "${item.judul}" dari album "${item.album}" (Diunggah: $tglStr)? Tindakan ini tidak dapat dibatalkan.',
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

              try {
                // 1. Hapus dokumen Firestore DULU
                await FirebaseFirestore.instance.collection('galeri').doc(item.id).delete();

                // 2. Jika Firestore BERHASIL, perbarui list di layar
                setState(() {
                  _daftarFoto.removeWhere((f) => f.id == item.id);
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Foto "${item.judul}" berhasil dihapus dari galeri (berkas Cloudinary tetap tersimpan).'),
                  ),
                );
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

  void _bukaModalTambahFoto() {
    showDialog(
      context: context,
      builder: (context) => DialogTambahDokumentasi(
        daftarAlbumExisting: _getDaftarAlbumDinamis().where((a) => a != 'Semua').toList(),
        onSimpanSukses: (newFoto) {
          setState(() {
            _daftarFoto.insert(0, newFoto);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto dokumentasi berhasil diunggah!')),
          );
        },
      ),
    );
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite),
                onPressed: _muatGaleriDariFirestore,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final daftarAlbum = _getDaftarAlbumDinamis();
    final listFotoFiltered = _getFilteredFoto();

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips Album Dinamis
          if (daftarAlbum.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: daftarAlbum.map((album) {
                  final isSelected = _filterAlbum == album;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(album),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.textWhite : AppColors.primary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _filterAlbum = album;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Grid Foto 3 Kolom
          Expanded(
            child: listFotoFiltered.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada foto di album ini',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.statLabel,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: listFotoFiltered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final item = listFotoFiltered[index];
                      final thumbUrl = _getThumbnailUrl(item.downloadUrl);

                      return Container(
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
                              width: double.infinity,
                              height: double.infinity,
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
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.cardBorder,
                                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                              ),
                            ),
                            // Tombol Hapus (X)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => _hapusFoto(item),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.textPrimary.withOpacity(0.6),
                                  child: const Icon(Icons.close, size: 14, color: AppColors.textWhite),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _bukaModalTambahFoto,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}

// Modal Dialog Form Tambah Dokumentasi Sesuai Mockup Figma (`admin_pengurus_tambah_dokumentasi.png`)
class DialogTambahDokumentasi extends StatefulWidget {
  final List<String> daftarAlbumExisting;
  final Function(ModelFotoGaleri) onSimpanSukses;

  const DialogTambahDokumentasi({
    super.key,
    required this.daftarAlbumExisting,
    required this.onSimpanSukses,
  });

  @override
  State<DialogTambahDokumentasi> createState() => _DialogTambahDokumentasiState();
}

class _DialogTambahDokumentasiState extends State<DialogTambahDokumentasi> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late TextEditingController _albumBaruController;
  late String _albumTerpilih;
  bool _isAlbumBaru = false;

  XFile? _fotoTerpilih;
  bool _sedangMengunggah = false;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController();
    _deskripsiController = TextEditingController();
    _albumBaruController = TextEditingController();

    if (widget.daftarAlbumExisting.isNotEmpty) {
      _albumTerpilih = widget.daftarAlbumExisting.first;
    } else {
      _albumTerpilih = 'Kegiatan';
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _albumBaruController.dispose();
    super.dispose();
  }

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file != null) {
        // Validasi ukuran file terkompresi <= 5 MB
        final int fileBytes = await file.length();
        if (fileBytes > 5 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran foto melebihi batas maksimal 5 MB!'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }

        setState(() {
          _fotoTerpilih = file;
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

  Future<void> _prosesUnggahDanSimpan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih foto berkas terlebih dahulu!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _sedangMengunggah = true);

    final String albumFinal = _isAlbumBaru
        ? _albumBaruController.text.trim()
        : _albumTerpilih;

    try {
      // 1. Unggah berkas ke Cloudinary via HTTP POST Unsigned Upload
      if (AppConstants.kCloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
          AppConstants.kCloudinaryUploadPreset == 'YOUR_UPLOAD_PRESET') {
        throw Exception('Cloud Name atau Upload Preset belum terkonfigurasi.');
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/${AppConstants.kCloudinaryCloudName}/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = AppConstants.kCloudinaryUploadPreset
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            _fotoTerpilih!.path,
            contentType: null, // Cloudinary otomatis mendeteksi image/jpeg
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Gagal mengunggah foto ke Cloudinary. Periksa koneksi internet Anda.');
      }

      final jsonResp = json.decode(response.body);
      final String secureUrl = jsonResp['secure_url'] ?? '';
      final String publicId = jsonResp['public_id'] ?? '';

      if (secureUrl.isEmpty) {
        throw Exception('Gagal mendapatkan URL gambar dari Cloudinary.');
      }

      // 2. Simpan metadata dokumen ke Cloud Firestore
      final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'Admin';
      final newDocRef = FirebaseFirestore.instance.collection('galeri').doc();

      try {
        await newDocRef.set({
          'id': newDocRef.id,
          'judul': _judulController.text.trim(),
          'album': albumFinal,
          'deskripsi': _deskripsiController.text.trim(),
          'downloadURL': secureUrl,
          'publicId': publicId,
          'uploadedBy': currentUid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final newFoto = ModelFotoGaleri(
          id: newDocRef.id,
          judul: _judulController.text.trim(),
          album: albumFinal,
          deskripsi: _deskripsiController.text.trim(),
          downloadUrl: secureUrl,
          publicId: publicId,
          uploadedBy: currentUid,
          createdAt: DateTime.now(),
        );

        widget.onSimpanSukses(newFoto);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        // Jika simpan Firestore gagal setelah Cloudinary berhasil
        if (!mounted) return;
        final pesanErr = e is FirebaseException && e.code == 'permission-denied'
            ? 'Anda tidak punya izin untuk tindakan ini'
            : 'Gagal menyimpan data foto ke Firestore. Berkas Cloudinary telah terunggah.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanErr), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    if (mounted) setState(() => _sedangMengunggah = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.r20),
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tambah Dokumentasi Baru',
                      style: AppTextStyles.formTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Container Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.r16,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Dokumentasi
                      _buildInputLabel('Judul Dokumentasi'),
                      TextFormField(
                        controller: _judulController,
                        decoration: _buildInputDecoration(hintText: 'Nama/Judul dokumentasi foto'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Judul dokumentasi wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Album
                      _buildInputLabel('Album Dokumentasi'),
                      Row(
                        children: [
                          Expanded(
                            child: _isAlbumBaru
                                ? TextFormField(
                                    controller: _albumBaruController,
                                    decoration: _buildInputDecoration(hintText: 'Ketik nama album baru'),
                                    validator: (val) => _isAlbumBaru && (val == null || val.trim().isEmpty)
                                        ? 'Nama album baru wajib diisi'
                                        : null,
                                  )
                                : DropdownButtonFormField<String>(
                                    value: _albumTerpilih,
                                    decoration: _buildInputDecoration(hintText: 'Pilih Album'),
                                    items: [
                                      ...widget.daftarAlbumExisting,
                                      'Kegiatan',
                                      'Sosial',
                                      'Olahraga'
                                    ]
                                        .toSet()
                                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _albumTerpilih = val);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isAlbumBaru ? Icons.list_alt : Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            tooltip: _isAlbumBaru ? 'Pilih Album Existing' : 'Buat Album Baru',
                            onPressed: () {
                              setState(() {
                                _isAlbumBaru = !_isAlbumBaru;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Box File Picker
                      _buildInputLabel('Berkas Unggahan Foto'),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library, color: AppColors.primary),
                                    title: const Text('Pilih dari Galeri HP'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pilihFoto(ImageSource.gallery);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                                    title: const Text('Ambil Foto Kamera'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pilihFoto(ImageSource.camera);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppRadius.r12,
                            border: Border.all(
                              color: _fotoTerpilih == null ? AppColors.cardBorder : AppColors.primary,
                              width: _fotoTerpilih == null ? 1.0 : 1.5,
                            ),
                          ),
                          child: _fotoTerpilih != null
                              ? ClipRRect(
                                  borderRadius: AppRadius.r12,
                                  child: Image.file(
                                    File(_fotoTerpilih!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.primary),
                                    SizedBox(height: 6),
                                    Text('Klik untuk memilih foto (Maks 5 MB)', style: AppTextStyles.inputHint),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Deskripsi Multiline
                      _buildInputLabel('Deskripsi Dokumentasi'),
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: _buildInputDecoration(hintText: 'Deskripsi singkat foto kegiatan...'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Button Primary: Simpan
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
                    onPressed: _sedangMengunggah ? null : _prosesUnggahDanSimpan,
                    child: _sedangMengunggah
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Simpan & Unggah', style: AppTextStyles.buttonPrimary),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Button Outlined: Batal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(label, style: AppTextStyles.inputLabel),
    );
  }

  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      filled: true,
      fillColor: AppColors.background,
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
