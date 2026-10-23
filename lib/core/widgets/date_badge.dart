import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Date Badge (Box Bulan + Tanggal) Sesuai Mockup Figma
class DateBadge extends StatelessWidget {
  final DateTime tanggal;

  const DateBadge({
    super.key,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> singkatanBulan = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
    ];

    final bulan = singkatanBulan[tanggal.month];
    final hari = tanggal.day < 10 ? '0${tanggal.day}' : '${tanggal.day}';

    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              bulan,
              style: AppTextStyles.dateBadgeMonth,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hari,
            style: AppTextStyles.dateBadgeDay,
          ),
        ],
      ),
    );
  }
}
