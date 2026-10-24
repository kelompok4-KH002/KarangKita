import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';

class ModelAnggotaAdmin {
  final String id;
  final String nama;
  final String jabatan;
  final bool disetujui;

  ModelAnggotaAdmin({
    required this.id,
    required this.nama,
    required this.jabatan,
    this.disetujui = true,
  });
}

// Halaman Kelola Anggota Admin Sesuai Mockup Figma (`admin_pengurus_kelola_anggota.png`)
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
    _daftarAnggota = [];
    _muatUserFirestore();
  }

  void _muatUserFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      if (snap.docs.isNotEmpty) {
        final List<ModelAnggotaAdmin> cloudList = [];
        for (var doc in snap.docs) {
          final data = doc.data();
          cloudList.add(ModelAnggotaAdmin(
            id: doc.id,
            nama: data['nama'] ?? data['username'] ?? 'Pengguna',
            jabatan: '${data['role'] ?? 'Anggota'} ${data['disetujui'] == false ? '(Pending ACC)' : ''}',
            disetujui: data['disetujui'] ?? true,
          ));
        }
        if (mounted) {
          setState(() {
            _daftarAnggota.addAll(cloudList);
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

  List<ModelAnggotaAdmin> _getFiltered() {
    final query = _searchController.text.toLowerCase();
    return _daftarAnggota.where((item) {
      return item.nama.toLowerCase().contains(query) ||
          item.jabatan.toLowerCase().contains(query);
    }).toList();
  }

  void _setujuiPersetujuanPengurus(String uid, String nama) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'disetujui': true,
      });
    } catch (_) {}

    setState(() {
      final idx = _daftarAnggota.indexWhere((item) => item.id == uid);
      if (idx != -1) {
        _daftarAnggota[idx] = ModelAnggotaAdmin(
          id: uid,
          nama: nama,
          jabatan: 'Pengurus (Disetujui)',
          disetujui: true,
        );
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun Pengurus $nama berhasil di-ACC/Disetujui!')),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: item.disetujui ? AppColors.primaryLight : Colors.orange.shade100,
                              child: Text(
                                item.nama.isNotEmpty ? item.nama[0] : 'A',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.disetujui ? AppColors.primary : Colors.orange.shade900,
                                ),
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: item.disetujui ? AppColors.textSecondary : Colors.orange.shade800,
                                      fontWeight: item.disetujui ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (!item.disetujui)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _setujuiPersetujuanPengurus(item.id, item.nama),
                                child: const Text('Setujui (ACC)', style: TextStyle(fontSize: 11)),
                              )
                            else ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                onPressed: () => _tambahAtauEditAnggota(item, index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                                onPressed: () => _hapusAnggota(index),
                              ),
                            ],
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
