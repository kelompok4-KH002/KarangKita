import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../peta/komponen/komponen_peta.dart';
import '../komponen/komponen_kegiatan_admin.dart';

// Halaman rincian kegiatan lengkap dengan peta lokasi
class HalamanDetailKegiatan extends StatelessWidget {
  final ModelKegiatanAdmin kegiatan;

  const HalamanDetailKegiatan({super.key, required this.kegiatan});

  static const List<String> _bulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final tgl = kegiatan.tanggal;
    final isSelesai = kegiatan.status == 'Selesai';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rincian Kegiatan', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.r16,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  CategoryChip(kategori: kegiatan.kategori),
                ],
              ),
              const SizedBox(height: 12),
              Text(kegiatan.judul, style: AppTextStyles.formTitle),
              const SizedBox(height: 14),
              _baris(Icons.event_outlined, '${tgl.day} ${_bulan[tgl.month]} ${tgl.year}'),
              _baris(Icons.access_time_outlined, kegiatan.waktu),
              _baris(Icons.location_on_outlined, kegiatan.lokasi),
              const SizedBox(height: 8),
              const Text('Deskripsi', style: AppTextStyles.inputLabel),
              const SizedBox(height: 4),
              Text(kegiatan.deskripsi.isEmpty ? '-' : kegiatan.deskripsi, style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 18),
              const Text('Lokasi di Peta', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              if (kegiatan.punyaKoordinat)
                PetaPratinjau(lat: kegiatan.lat!, lng: kegiatan.lng!, tinggi: 220)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.r10,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text(
                    'Titik peta belum ditandai untuk kegiatan ini. Pengurus dapat menambahkannya lewat Edit Kegiatan.',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: AppTextStyles.cardTitle)),
        ],
      ),
    );
  }
}
