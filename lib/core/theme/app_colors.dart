import 'package:flutter/material.dart';

// Design Tokens Warna Terpusat KarangKita (Mockup Figma)
class AppColors {
  static const Color primary = Color(0xFF1E3A8A); // Biru Tua Utama Figma
  static const Color primaryDark = Color(0xFF1A365D);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color accentPill = Color(0xFF2563EB);
  
  static const Color background = Color(0xFFF8FAFC); // Latar Belakang Terang
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x05000000);
  
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;
  
  // Chip Colors per Kategori & Peran
  static const Color badgeBlueBg = Color(0xFFDBEAFE);
  static const Color badgeBlueText = Color(0xFF1D4ED8);
  
  static const Color badgeGreenBg = Color(0xFFDCFCE7);
  static const Color badgeGreenText = Color(0xFF15803D);

  static const Color badgeOrangeBg = Color(0xFFFFEDD5);
  static const Color badgeOrangeText = Color(0xFFC2410C);

  static const Color badgePurpleBg = Color(0xFFF3E8FF);
  static const Color badgePurpleText = Color(0xFF7E22CE);

  static const Color badgeTealBg = Color(0xFFCCFBF1);
  static const Color badgeTealText = Color(0xFF0F766E);

  static const Color badgeIndigoBg = Color(0xFFE0E7FF);
  static const Color badgeIndigoText = Color(0xFF4338CA);

  static const Color badgeNeutralBg = Color(0xFFF1F5F9);
  static const Color badgeNeutralText = Color(0xFF475569);
  
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
}

// Design Tokens Border Radius Terpusat
class AppRadius {
  static const BorderRadius r8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius r10 = BorderRadius.all(Radius.circular(10));
  static const BorderRadius r12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius r16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius r20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius r30 = BorderRadius.all(Radius.circular(30));
}
