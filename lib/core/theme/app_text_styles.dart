import 'package:flutter/material.dart';
import 'app_colors.dart';

// Design Tokens Gaya Teks Terpusat KarangKita (Mockup Figma)
class AppTextStyles {
  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heroGreeting = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle heroDate = TextStyle(
    fontSize: 13,
    color: Color(0xFF93C5FD),
  );

  static const TextStyle heroPill = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle statCount = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle dateBadgeMonth = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
  );

  static const TextStyle dateBadgeDay = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle calendarDay = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle calendarDaySelected = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle formTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle linkDanger = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.danger,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputHint = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
  );
}
