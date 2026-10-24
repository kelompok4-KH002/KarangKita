import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/date_badge.dart';
import '../komponen/komponen_kegiatan_admin.dart';

// Halaman Kelola Kegiatan Admin High-Fidelity Sesuai Mockup Figma (`admin_pengurus_kelola_kegiatan.png`)
class HalamanKegiatanAdmin extends StatefulWidget {
  const HalamanKegiatanAdmin({super.key});

  @override
  State<HalamanKegiatanAdmin> createState() => _HalamanKegiatanAdminState();
}

class _HalamanKegiatanAdminState extends State<HalamanKegiatanAdmin> {
  late List<ModelKegiatanAdmin> _daftarKegiatan;

  @override
  void initState() {
    super.initState();
    _daftarKegiatan = [];
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
            waktu: data['waktu'] ?? '07:30 WIB',
            lokasi: data['lokasi'] ?? '',
            kategori: data['kategori'] ?? 'Sosial',
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

  void _tambahKegiatan(ModelKegiatanAdmin kegiatan) async {
    setState(() {
      _daftarKegiatan.insert(0, kegiatan);
    });

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
              dotColor: Colors.blueAccent,
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
                        onEdit: () => _bukaDialogEdit(item, origIndex),
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
              dotColor: Colors.green,
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
                        onEdit: () => _bukaDialogEdit(item, origIndex),
                        onHapus: () => _hapusKegiatan(origIndex),
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
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

  void _bukaDialogEdit(ModelKegiatanAdmin item, int origIndex) {
    showDialog(
      context: context,
      builder: (context) => DialogTambahEditKegiatan(
        kegiatanEdit: item,
        onSimpan: (newItem) => _editKegiatan(origIndex, newItem),
        onHapus: () => _hapusKegiatan(origIndex),
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const Spacer(),
        Text(
          tag,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(6),
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
                  borderRadius: BorderRadius.circular(6),
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
              Text(
                '• ${item.lokasi}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                  color: const Color(0xFFEEF2FF),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.tanggal.day} ${_getNamaBulan(item.tanggal.month)} ${item.tanggal.year} • ${item.lokasi}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
              // Light Red Box Delete Button
              InkWell(
                onTap: onHapus,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                ),
              ),
              const SizedBox(width: 8),

              // Light Blue Edit Button
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
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
        child: Text(msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ),
    );
  }

  static String _getNamaBulan(int m) {
    const List<String> b = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return b[m];
  }
}
