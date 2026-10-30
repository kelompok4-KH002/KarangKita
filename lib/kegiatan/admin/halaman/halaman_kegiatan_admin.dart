import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../komponen/komponen_kegiatan_admin.dart';

// Halaman Kelola Kegiatan Admin High-Fidelity Sesuai Mockup Figma (`admin_pengurus_kelola_kegiatan.png`)
class HalamanKegiatanAdmin extends StatefulWidget {
  const HalamanKegiatanAdmin({super.key});

  @override
  State<HalamanKegiatanAdmin> createState() => _HalamanKegiatanAdminState();
}

class _HalamanKegiatanAdminState extends State<HalamanKegiatanAdmin> {
  late List<ModelKegiatanAdmin> _daftarKegiatan;
  bool _sedangMemuat = true;
  bool _adaErrorMemuat = false;
  String _pesanErrorMemuat = '';

  @override
  void initState() {
    super.initState();
    _daftarKegiatan = [];
    _muatDataDariFirestore();
  }

  String _getPesanError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Anda tidak punya izin untuk tindakan ini';
    }
    return 'Gagal menyimpan, periksa koneksi internet';
  }

  String _getPesanErrorHapus(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Anda tidak punya izin untuk tindakan ini';
    }
    return 'Gagal menghapus kegiatan, periksa koneksi internet';
  }

  void _muatDataDariFirestore() async {
    setState(() {
      _sedangMemuat = true;
      _adaErrorMemuat = false;
    });

    try {
      final snap = await FirebaseFirestore.instance.collection('kegiatan').get();
      final List<ModelKegiatanAdmin> listDariCloud = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        listDariCloud.add(ModelKegiatanAdmin(
          id: data['id'] ?? doc.id,
          judul: data['judul'] ?? '',
          tanggal: DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now(),
          waktu: data['waktu'] ?? '07:30 WIB',
          lokasi: data['lokasi'] ?? '',
          kategori: data['kategori'] ?? 'Sosial',
          deskripsi: data['deskripsi'] ?? '',
          manualStatus: data['status'],
        ));
      }
      if (mounted) {
        setState(() {
          _daftarKegiatan = listDariCloud;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
          _adaErrorMemuat = true;
          _pesanErrorMemuat = e is FirebaseException && e.code == 'permission-denied'
              ? 'Anda tidak punya izin untuk membaca data ini'
              : 'Gagal memuat data, periksa koneksi internet';
        });
      }
    }
  }

  void _tambahKegiatan(ModelKegiatanAdmin kegiatan) async {
    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(kegiatan.id).set({
        'id': kegiatan.id,
        'judul': kegiatan.judul,
        'waktu': kegiatan.waktu,
        'lokasi': kegiatan.lokasi,
        'kategori': kegiatan.kategori,
        'deskripsi': kegiatan.deskripsi,
        'status': kegiatan.status,
        'tanggal': kegiatan.tanggal.toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _daftarKegiatan.insert(0, kegiatan);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanError(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _editKegiatan(int index, ModelKegiatanAdmin kegiatan) async {
    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(kegiatan.id).set({
        'id': kegiatan.id,
        'judul': kegiatan.judul,
        'waktu': kegiatan.waktu,
        'lokasi': kegiatan.lokasi,
        'kategori': kegiatan.kategori,
        'deskripsi': kegiatan.deskripsi,
        'status': kegiatan.status,
        'tanggal': kegiatan.tanggal.toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _daftarKegiatan[index] = kegiatan;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanError(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _hapusKegiatan(int index) async {
    final target = _daftarKegiatan[index];

    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(target.id).delete();

      setState(() {
        _daftarKegiatan.removeAt(index);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanErrorHapus(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _bukaHalamanFormKegiatan({ModelKegiatanAdmin? kegiatanEdit, int? origIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanFormKegiatanAdmin(
          kegiatanEdit: kegiatanEdit,
          onSimpan: (newItem) {
            if (kegiatanEdit != null && origIndex != null) {
              _editKegiatan(origIndex, newItem);
            } else {
              _tambahKegiatan(newItem);
            }
          },
          onHapus: origIndex != null ? () => _hapusKegiatan(origIndex) : null,
        ),
      ),
    );
  }

  IconData _getKategoriIcon(String kategori) {
    switch (kategori) {
      case 'Olahraga':
        return Icons.emoji_events_outlined;
      case 'Rapat':
        return Icons.groups_outlined;
      case 'Edukasi':
        return Icons.school_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                onPressed: _muatDataDariFirestore,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // Status 'Mendatang' vs 'Selesai' dihitung secara dinamis via getter kegiatan.status
    final listMendatang = _daftarKegiatan.where((k) => k.status == 'Mendatang').toList();
    final listSelesai = _daftarKegiatan.where((k) => k.status == 'Selesai').toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Seksi Kegiatan Mendatang
            _buildSectionHeader(
              title: 'Kegiatan Mendatang',
              count: listMendatang.length,
              tag: 'Agenda Aktif',
              dotColor: AppColors.primary,
            ),
            const SizedBox(height: 12),

            listMendatang.isEmpty
                ? _buildEmptyState('Belum ada kegiatan mendatang')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listMendatang.length,
                    itemBuilder: (context, index) {
                      final item = listMendatang[index];
                      final origIndex = _daftarKegiatan.indexOf(item);
                      return _buildKegiatanCard(
                        item: item,
                        onEdit: () => _bukaHalamanFormKegiatan(
                          kegiatanEdit: item,
                          origIndex: origIndex,
                        ),
                        onHapus: () => _hapusKegiatan(origIndex),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // 2. Seksi Kegiatan Selesai
            _buildSectionHeader(
              title: 'Kegiatan Selesai',
              count: listSelesai.length,
              tag: 'Arsip',
              dotColor: AppColors.badgeGreenText,
            ),
            const SizedBox(height: 12),

            listSelesai.isEmpty
                ? _buildEmptyState('Belum ada kegiatan yang selesai')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listSelesai.length,
                    itemBuilder: (context, index) {
                      final item = listSelesai[index];
                      final origIndex = _daftarKegiatan.indexOf(item);
                      return _buildKegiatanCard(
                        item: item,
                        onEdit: () => _bukaHalamanFormKegiatan(
                          kegiatanEdit: item,
                          origIndex: origIndex,
                        ),
                        onHapus: () => _hapusKegiatan(origIndex),
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaHalamanFormKegiatan(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        child: const Icon(Icons.add),
      ),
    );
  }

  static Widget _buildSectionHeader({
    required String title,
    required int count,
    required String tag,
    required Color dotColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: AppRadius.r12,
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const Spacer(),
        Text(
          tag,
          style: AppTextStyles.cardSubtitle,
        ),
      ],
    );
  }

  Widget _buildKegiatanCard({
    required ModelKegiatanAdmin item,
    required VoidCallback onEdit,
    required VoidCallback onHapus,
  }) {
    final bool isSelesai = item.status == 'Selesai';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tags Row
          Row(
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelesai ? AppColors.badgeGreenBg : AppColors.badgeBlueBg,
                  borderRadius: AppRadius.r6,
                ),
                child: Text(
                  isSelesai ? 'Selesai' : 'Mendatang',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelesai ? AppColors.badgeGreenText : AppColors.badgeBlueText,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Kategori Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.badgeGreenBg,
                  borderRadius: AppRadius.r6,
                ),
                child: Text(
                  item.kategori,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.badgeGreenText,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Subtext Location
              Expanded(
                child: Text(
                  '• ${item.lokasi}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardSubtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content Row: Category Circle Icon + Title & Date/Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getKategoriIcon(item.kategori),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.tanggal.day} ${_getNamaBulan(item.tanggal.month)} ${item.tanggal.year} • ${item.lokasi}',
                      style: AppTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Delete Button
              InkWell(
                onTap: onHapus,
                borderRadius: AppRadius.r8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: AppRadius.r8,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                ),
              ),
              const SizedBox(width: 8),

              // Edit Button
              InkWell(
                onTap: onEdit,
                borderRadius: AppRadius.r8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.r8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        isSelesai ? 'Edit Laporan/Kegiatan' : 'Edit Kegiatan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(msg, style: AppTextStyles.statLabel),
      ),
    );
  }

  static String _getNamaBulan(int m) {
    const List<String> b = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return b[m];
  }
}
