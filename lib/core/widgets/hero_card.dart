import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Hero Card Biru Sapaan Pengguna Sesuai Mockup Figma
class HeroCard extends StatelessWidget {
  final String namaPengguna;
  final String peran;
  final DateTime tanggal;

  const HeroCard({
    super.key,
    required this.namaPengguna,
    required this.peran,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const List<String> namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final stringHari = namaHari[(tanggal.weekday - 1) % 7];
    final stringTanggal = '$stringHari, ${tanggal.day} ${namaBulan[tanggal.month]} ${tanggal.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPill.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF60A5FA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Karang Taruna Digital',
                        style: AppTextStyles.heroPill,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Greeting
                Text(
                  'Halo, $peran!',
                  style: AppTextStyles.heroGreeting,
                ),
                const SizedBox(height: 4),

                // Date
                Text(
                  stringTanggal,
                  style: AppTextStyles.heroDate,
                ),
              ],
            ),
          ),

          // Right Profile Avatar Circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
