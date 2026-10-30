import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../autentikasi/layanan/pengalihan_role.dart';
import '../../notifikasi/komponen/ikon_notifikasi.dart';

// AppHeader Seragam (Hamburger Kiri, Title KarangKita, Profile Kanan dengan Popup & Confirm Logout)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppHeader({
    super.key,
    this.title = 'KarangKita',
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  void _tampilkanDialogKonfirmasiLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop(); // Tutup dialog
              await LayananAutentikasi.keluar();
              nav.popUntil((route) => route.isFirst);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        tooltip: 'Buka Menu',
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Text(
        title,
        style: AppTextStyles.headerTitle,
      ),
      centerTitle: true,
      actions: [
        const IkonNotifikasi(),
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
          ),
          onSelected: (value) {
            if (value == 'keluar') {
              _tampilkanDialogKonfirmasiLogout(context);
            } else if (value == 'profil') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman Profil Pengguna')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profil',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Profil'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'keluar',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text('Keluar', style: TextStyle(color: AppColors.danger)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      elevation: 0,
      backgroundColor: Colors.transparent,
    );
  }
}
