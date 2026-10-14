import 'package:flutter/material.dart';

class ModelAnggotaAdmin {
  final String id;
  final String nama;
  final String jabatan;

  ModelAnggotaAdmin({
    required this.id,
    required this.nama,
    required this.jabatan,
  });
}

class HalamanAnggotaAdmin extends StatefulWidget {
  const HalamanAnggotaAdmin({super.key});

  @override
  State<HalamanAnggotaAdmin> createState() => _HalamanAnggotaAdminState();
}

class _HalamanAnggotaAdminState extends State<HalamanAnggotaAdmin> {
  final TextEditingController _searchController = TextEditingController();
  late List<ModelAnggotaAdmin> _daftarAnggota;

  @override
  void initState() {
    super.initState();
    _daftarAnggota = [
      ModelAnggotaAdmin(id: 'A1', nama: 'Nadhif Shidqi', jabatan: 'Ketua Karang Taruna'),
      ModelAnggotaAdmin(id: 'A2', nama: 'Kireyna Putri', jabatan: 'Wakil Ketua'),
      ModelAnggotaAdmin(id: 'A3', nama: 'Lucas Amadeus', jabatan: 'Sekretaris'),
      ModelAnggotaAdmin(id: 'A4', nama: 'Elizabeth Wong', jabatan: 'Bendahara'),
      ModelAnggotaAdmin(id: 'A5', nama: 'Amizola Saputra', jabatan: 'Seksi Humas & Acara'),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ModelAnggotaAdmin> _getFiltered() {
    final query = _searchController.text.toLowerCase();
    return _daftarAnggota.where((item) {
      return item.nama.toLowerCase().contains(query) ||
          item.jabatan.toLowerCase().contains(query);
    }).toList();
  }

  void _tambahAtauEditAnggota([ModelAnggotaAdmin? editItem, int? index]) {
    final namaCtrl = TextEditingController(text: editItem?.nama ?? '');
    final jabatanCtrl = TextEditingController(text: editItem?.jabatan ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(editItem == null ? 'Tambah Anggota Baru' : 'Edit Data Anggota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Anggota', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jabatanCtrl,
              decoration: const InputDecoration(labelText: 'Jabatan / Peran', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B303A), foregroundColor: Colors.white),
            onPressed: () {
              if (namaCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (editItem != null && index != null) {
                    _daftarAnggota[index] = ModelAnggotaAdmin(
                      id: editItem.id,
                      nama: namaCtrl.text.trim(),
                      jabatan: jabatanCtrl.text.trim(),
                    );
                  } else {
                    _daftarAnggota.add(ModelAnggotaAdmin(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      nama: namaCtrl.text.trim(),
                      jabatan: jabatanCtrl.text.trim(),
                    ));
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _hapusAnggota(int index) {
    setState(() {
      _daftarAnggota.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anggota berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _getFiltered();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'Kelola Anggota',
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
        foregroundColor: const Color(0xFF2B303A),
      ),
      body: Column(
        children: [
          // Search Bar
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
                  borderSide: const BorderSide(color: Color(0xFF2B303A)),
                ),
              ),
            ),
          ),

          // List Items
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Anggota tidak ditemukan', style: TextStyle(color: Colors.grey.shade600)))
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
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFE5E7EB),
                              child: Text(
                                item.nama.isNotEmpty ? item.nama[0] : 'A',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B303A)),
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nama,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.jabatan,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2B303A)),
                              onPressed: () => _tambahAtauEditAnggota(item, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2B303A)),
                              onPressed: () => _hapusAnggota(index),
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
        onPressed: () => _tambahAtauEditAnggota(),
        backgroundColor: const Color(0xFF2B303A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
