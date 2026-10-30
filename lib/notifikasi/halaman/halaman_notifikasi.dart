import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../layanan/layanan_notifikasi.dart';

// Halaman daftar notifikasi pengguna (keanggotaan & usulan kegiatan)
class HalamanNotifikasi extends StatelessWidget {
  final String uid;
  final String peran;

  const HalamanNotifikasi({super.key, required this.uid, required this.peran});

  static const List<String> _bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String _formatWaktu(DateTime t) {
    final selisih = DateTime.now().difference(t);
    if (selisih.inMinutes < 1) return 'Baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    final jam = t.hour.toString().padLeft(2, '0');
    final menit = t.minute.toString().padLeft(2, '0');
    return '${t.day} ${_bulan[t.month]} ${t.year}, $jam:$menit';
  }

  static IconData _ikon(String tipe) {
    switch (tipe) {
      case 'anggota':
        return Icons.person_add_alt_1_outlined;
      case 'jabatan':
        return Icons.badge_outlined;
      case 'usulan':
        return Icons.lightbulb_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ModelNotifikasi>>(
      stream: LayananNotifikasi.alirkan(uid, peran),
      builder: (context, snapshot) {
        final daftar = snapshot.data ?? const <ModelNotifikasi>[];
        final adaBelumDibaca = daftar.any((n) => !n.dibaca);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Notifikasi', style: AppTextStyles.headerTitle),
            centerTitle: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0.5,
            actions: [
              if (adaBelumDibaca)
                TextButton(
                  onPressed: () => LayananNotifikasi.tandaiSemuaDibaca(daftar, uid),
                  child: const Text('Tandai semua'),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat notifikasi. Periksa koneksi internet atau izin akses.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.statLabel,
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (daftar.isEmpty) {
                return const Center(
                  child: Text('Belum ada notifikasi', style: AppTextStyles.statLabel),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daftar.length,
                itemBuilder: (context, index) => _buildItem(daftar[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(ModelNotifikasi n) {
    return GestureDetector(
      onTap: () {
        if (!n.dibaca) LayananNotifikasi.tandaiDibaca(n.id, uid);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.dibaca ? AppColors.surface : AppColors.primaryLight,
          borderRadius: AppRadius.r12,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Icon(_ikon(n.tipe), size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.judul,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontWeight: n.dibaca ? FontWeight.w600 : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(n.isi, style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 6),
                  Text(
                    _formatWaktu(n.waktu),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!n.dibaca)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
