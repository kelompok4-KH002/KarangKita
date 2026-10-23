import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'date_badge.dart';

// Event Card Kegiatan Terdekat Sesuai Mockup Figma
class EventCard extends StatelessWidget {
  final String judul;
  final DateTime tanggal;
  final String lokasi;
  final String kategori;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.judul,
    required this.tanggal,
    required this.lokasi,
    this.kategori = 'Rapat',
    this.onTap,
  });

  Color _warnaKategoriBg(String kat) {
    switch (kat) {
      case 'Sosial':
        return AppColors.badgeGreenBg;
      case 'Olahraga':
        return AppColors.badgeOrangeBg;
      default:
        return AppColors.badgeBlueBg;
    }
  }

  Color _warnaKategoriText(String kat) {
    switch (kat) {
      case 'Sosial':
        return AppColors.badgeGreenText;
      case 'Olahraga':
        return AppColors.badgeOrangeText;
      default:
        return AppColors.badgeBlueText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Left Date Badge
              DateBadge(tanggal: tanggal),
              const SizedBox(width: 14),

              // Right Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori Chip Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _warnaKategoriBg(kategori),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kategori,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _warnaKategoriText(kategori),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Judul
                    Text(
                      judul,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Lokasi
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
                            lokasi,
                            style: AppTextStyles.cardSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
