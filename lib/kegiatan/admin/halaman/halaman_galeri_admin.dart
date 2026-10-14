import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Model foto galeri (support foto lokal HP atau URL)
class ModelFotoGaleri {
  final String id;
  final String? imagePath;
  final String? imageUrl;
  final String album;

  ModelFotoGaleri({
    required this.id,
    this.imagePath,
    this.imageUrl,
    required this.album,
  });
}

class HalamanGaleriAdmin extends StatefulWidget {
  const HalamanGaleriAdmin({super.key});

  @override
  State<HalamanGaleriAdmin> createState() => _HalamanGaleriAdminState();
}

class _HalamanGaleriAdminState extends State<HalamanGaleriAdmin> {
  String _filterAlbum = 'Semua';
  final ImagePicker _picker = ImagePicker();

  // List penyimpan foto
  late List<ModelFotoGaleri> _daftarFoto;

  @override
  void initState() {
    super.initState();
    // Dimulai dari list kosong agar foto murni dari galeri HP
    _daftarFoto = [];
  }

  // Filter foto berdasarkan album
  List<ModelFotoGaleri> _getFilteredFoto() {
    if (_filterAlbum == 'Semua') {
      return _daftarFoto;
    }
    return _daftarFoto.where((foto) => foto.album == _filterAlbum).toList();
  }

  // Fungsi buka galeri HP dan tambah foto
  Future<void> _pilihFotoDariGaleri() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _daftarFoto.insert(
            0,
            ModelFotoGaleri(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              imagePath: file.path,
              album: _filterAlbum == 'Semua' ? 'Album 1' : _filterAlbum,
            ),
          );
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto dari Galeri HP berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Hapus foto dari list
  void _hapusFoto(int index) {
    setState(() {
      _daftarFoto.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listFoto = _getFilteredFoto();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'Kelola Dokumentasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.more_vert),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2B303A),
      ),
      body: Column(
        children: [
          // Filter Chips Album
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['Semua', 'Album 1', 'Album 2', 'Album 3'].map((album) {
                final isSelected = _filterAlbum == album;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(album),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2B303A),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2B303A) : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF2B303A),
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
            child: listFoto.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada foto di album ini.\nTekan + untuk pilih dari Galeri HP',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: listFoto.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final item = listFoto[index];

                      Widget imageWidget;
                      // Tampilkan foto dari galeri HP jika imagePath tersedia
                      if (item.imagePath != null && item.imagePath!.isNotEmpty) {
                        imageWidget = Image.file(
                          File(item.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
                        imageWidget = Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      } else {
                        imageWidget = Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imageWidget,
                            // Tombol Hapus (X)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: GestureDetector(
                                onTap: () => _hapusFoto(index),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
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
      // Tombol pilih dari galeri
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pilihFotoDariGaleri,
        backgroundColor: const Color(0xFF2B303A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
