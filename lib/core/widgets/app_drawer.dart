import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../autentikasi/halaman/halaman_login.dart';

// Navigation Drawer Interaktif Sesuai Usability & Mockup
class AppDrawer extends StatelessWidget {
  final int activeIndex;
  final Function(int) onSelectTab;

  const AppDrawer({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
  });

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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HalamanLogin()),
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          // 1. Header Profil User
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 36, color: AppColors.primary),
            ),
            accountName: const Text(
              'Admin KarangKita',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: const Text(
              'Ketua / Pengurus Utama',
              style: TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
            ),
          ),

          // 2. Menu Utama (Beranda, Kegiatan, Jadwal, Anggota, Galeri)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.home_filled,
                  label: 'Beranda',
                  index: 0,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.event_note_outlined,
                  label: 'Kegiatan',
                  index: 1,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  label: 'Jadwal',
                  index: 2,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.people_outline,
                  label: 'Anggota',
                  index: 3,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.photo_library_outlined,
                  label: 'Galeri',
                  index: 4,
                ),

                const Divider(height: 24, thickness: 1, color: AppColors.cardBorder),

                // 3. Menu Bantuan & Pengaturan
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.textSecondary),
                  title: const Text('Bantuan & FAQ', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Halaman Bantuan & FAQ')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  title: const Text('Pengaturan', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Halaman Pengaturan')),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),

          // 4. Tombol Keluar (Paling Bawah)
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              _tampilkanDialogKonfirmasiLogout(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = activeIndex == index;

    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primaryLight,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Tutup drawer
        onSelectTab(index);
      },
    );
  }
}
