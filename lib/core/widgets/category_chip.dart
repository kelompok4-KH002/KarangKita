import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Widget CategoryChip / PeranBadge Terpadu Sesuai Design Token
class CategoryChip extends StatelessWidget {
  final String kategori;

  const CategoryChip({
    super.key,
    required this.kategori,
  });

  Color get _bgColor {
    switch (kategori) {
      case 'Rapat':
      case 'Pengurus':
        return AppColors.badgeBlueBg;

      case 'Sosial':
      case 'Anggota':
        return AppColors.badgeGreenBg;

      case 'Olahraga':
      case 'Menunggu persetujuan':
        return AppColors.badgeOrangeBg;

      case 'Edukasi':
        return AppColors.badgePurpleBg;

      case 'Kerja Bakti':
      case 'Warga':
        return AppColors.badgeTealBg;

      case 'Acara':
      case 'Ketua':
        return AppColors.badgeIndigoBg;

      default:
        return AppColors.badgeNeutralBg; // Fallback netral jika tidak terdaftar
    }
  }

  Color get _textColor {
    switch (kategori) {
      case 'Rapat':
      case 'Pengurus':
        return AppColors.badgeBlueText;

      case 'Sosial':
      case 'Anggota':
        return AppColors.badgeGreenText;

      case 'Olahraga':
      case 'Menunggu persetujuan':
        return AppColors.badgeOrangeText;

      case 'Edukasi':
        return AppColors.badgePurpleText;

      case 'Kerja Bakti':
      case 'Warga':
        return AppColors.badgeTealText;

      case 'Acara':
      case 'Ketua':
        return AppColors.badgeIndigoText;

      default:
        return AppColors.badgeNeutralText; // Fallback netral jika tidak terdaftar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kategori,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
    );
  }
}
