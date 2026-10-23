import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/date_badge.dart';
import '../komponen/komponen_kegiatan_admin.dart';

// Halaman Kelola Kegiatan Admin Sesuai Mockup Figma (`admin_pengurus_kelola_kegiatan.png`)
class HalamanKegiatanAdmin extends StatefulWidget {
  const HalamanKegiatanAdmin({super.key});

  @override
  State<HalamanKegiatanAdmin> createState() => _HalamanKegiatanAdminState();
}

class _HalamanKegiatanAdminState extends State<HalamanKegiatanAdmin> {
  final TextEditingController _searchController = TextEditingController();
  String _filterKategori = 'Semua';
  late List<ModelKegiatanAdmin> _daftarKegiatan;

  @override
  void initState() {
    super.initState();
    _daftarKegiatan = List.from(dataKegiatanAwal);
    _muatDataDariFirestore();
  }

  // Ambil data kegiatan dari Cloud Firestore jika ada
  void _muatDataDariFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('kegiatan').get();
      if (snap.docs.isNotEmpty) {
        final List<ModelKegiatanAdmin> listDariCloud = [];
        for (var doc in snap.docs) {
          final data = doc.data();
          listDariCloud.add(ModelKegiatanAdmin(
            id: data['id'] ?? doc.id,
            judul: data['judul'] ?? '',
            tanggal: DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now(),
            lokasi: data['lokasi'] ?? '',
            deskripsi: data['deskripsi'] ?? '',
            status: data['status'] ?? 'Mendatang',
          ));
        }
        if (mounted) {
          setState(() {
            _daftarKegiatan = listDariCloud;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ModelKegiatanAdmin> _getFilteredKegiatan() {
    return _daftarKegiatan.where((item) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = item.judul.toLowerCase().contains(query) ||
          item.lokasi.toLowerCase().contains(query);

      bool matchesFilter = true;
      if (_filterKategori == 'Akan datang') {
        matchesFilter = item.status == 'Mendatang';
      } else if (_filterKategori == 'Selesai') {
        matchesFilter = item.status == 'Selesai';
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _tambahKegiatan(ModelKegiatanAdmin kegiatan) async {
    setState(() {
      _daftarKegiatan.insert(0, kegiatan);
    });

    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(kegiatan.id).set({
        'id': kegiatan.id,
        'judul': kegiatan.judul,
        'lokasi': kegiatan.lokasi,
        'deskripsi': kegiatan.deskripsi,
        'status': kegiatan.status,
        'tanggal': kegiatan.tanggal.toIso8601String(),
      });
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kegiatan berhasil ditambahkan')),
    );
  }

  void _editKegiatan(int index, ModelKegiatanAdmin kegiatan) async {
    setState(() {
      _daftarKegiatan[index] = kegiatan;
    });

    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(kegiatan.id).update({
        'judul': kegiatan.judul,
        'lokasi': kegiatan.lokasi,
        'deskripsi': kegiatan.deskripsi,
        'status': kegiatan.status,
        'tanggal': kegiatan.tanggal.toIso8601String(),
      });
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kegiatan berhasil diperbarui')),
    );
  }

  void _hapusKegiatan(int index) async {
    final target = _daftarKegiatan[index];
    setState(() {
      _daftarKegiatan.removeAt(index);
    });

    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(target.id).delete();
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kegiatan berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _getFilteredKegiatan();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari kegiatan...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['Semua', 'Akan datang', 'Selesai'].map((kat) {
                final isSelected = _filterKategori == kat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(kat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _filterKategori = kat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Cards list dengan Date Badge
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada kegiatan ditemukan',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            // Date Badge
                            DateBadge(tanggal: item.tanggal),
                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.judul,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.lokasi,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Edit Icon
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => DialogTambahEditKegiatan(
                                    kegiatanEdit: item,
                                    onSimpan: (newItem) => _editKegiatan(index, newItem),
                                  ),
                                );
                              },
                            ),
                            // Delete Icon X
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                              onPressed: () => _hapusKegiatan(index),
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => DialogTambahEditKegiatan(
              onSimpan: _tambahKegiatan,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
