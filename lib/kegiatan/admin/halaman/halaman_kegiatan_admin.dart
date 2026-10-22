import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../komponen/komponen_kegiatan_admin.dart';

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
    const primaryDarkBlue = Color(0xFF1E3A8A);
    final list = _getFilteredKegiatan();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'Kelola Kegiatan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryDarkBlue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: primaryDarkBlue),
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
                    selectedColor: primaryDarkBlue,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryDarkBlue : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primaryDarkBlue,
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

          // Cards list
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Box
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.event_note_rounded,
                                  color: primaryDarkBlue,
                                  size: 28,
                                ),
                              ),
                            ),
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
                                      color: primaryDarkBlue,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.tanggal.day}/${item.tanggal.month}/${item.tanggal.year} · ${item.lokasi}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: primaryDarkBlue),
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
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: primaryDarkBlue),
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
        backgroundColor: primaryDarkBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
