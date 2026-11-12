import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_constants.dart';
import '../theme/app_text_styles.dart';
import '../../autentikasi/halaman/halaman_edit_profil.dart';
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

  void _tampilkanModalProfil(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ModalProfilContent(),
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
              _tampilkanModalProfil(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profil',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Profil Saya'),
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

// Modal Sheet Informasi Profil Saya
class _ModalProfilContent extends StatelessWidget {
  const _ModalProfilContent();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.r20,
        ),
        child: const Text('Belum login'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data?.data() ?? {};
          final nama = (data['nama'] ?? data['username'] ?? 'Pengguna').toString();
          final email = (data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '-').toString();
          final rawRole = data['role'] ?? data['jabatan'] ?? 'Anggota';
          final peran = AppConstants.normalisasiPeran(rawRole);
          final whatsapp = (data['whatsapp'] ?? '-').toString();
          final disetujui = data['disetujui'] ?? true;
          final fotoUrl = (data['fotoUrl'] ?? data['foto'] ?? '').toString();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: AppRadius.r20,
                ),
              ),
              const SizedBox(height: 16),

              // Avatar Lingkaran Foto / Inisial
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: ClipOval(
                  child: fotoUrl.isNotEmpty
                      ? Image.network(
                          fotoUrl,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Nama Pengguna
              Text(
                nama,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Badge Peran/Jabatan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.r20,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  peran,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol "Edit Profil" Utama
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Tutup modal sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalamanEditProfil()),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),

              // Card Rincian Informasi User
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.r16,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _barisDetail(Icons.email_outlined, 'Email', email),
                    const Divider(height: 16),
                    _barisDetail(Icons.phone_outlined, 'WhatsApp', whatsapp),
                    const Divider(height: 16),
                    _barisDetail(
                      Icons.verified_user_outlined,
                      'Status Akun',
                      disetujui ? 'Aktif / Disetujui' : 'Menunggu Persetujuan',
                      color: disetujui ? AppColors.badgeGreenText : AppColors.badgeOrangeText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Aksi: Keluar dan Tutup
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Tutup modal profil
                        _konfirmasiKeluar(context);
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _barisDetail(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _konfirmasiKeluar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
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
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await LayananAutentikasi.keluar();
              nav.popUntil((route) => route.isFirst);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}


