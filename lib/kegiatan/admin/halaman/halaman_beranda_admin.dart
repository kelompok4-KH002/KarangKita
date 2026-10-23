import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/hero_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/event_card.dart';
import 'halaman_kegiatan_admin.dart';
import '../../../jadwal/admin/halaman/halaman_jadwal_admin.dart';
import 'halaman_anggota_admin.dart';
import 'halaman_galeri_admin.dart';

// Container Utama Admin dengan BottomNavigationBar & Navigation Drawer
class HalamanBerandaAdmin extends StatefulWidget {
  final String namaPengguna;
  final String peran;

  const HalamanBerandaAdmin({
    super.key,
    this.namaPengguna = 'Admin KarangKita',
    this.peran = 'Ketua Pengurus',
  });

  @override
  State<HalamanBerandaAdmin> createState() => _HalamanBerandaAdminState();
}

class _HalamanBerandaAdminState extends State<HalamanBerandaAdmin> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _BerandaTabContent(
        namaPengguna: widget.namaPengguna,
        peran: widget.peran,
        onPindahTab: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
      ),
      const HalamanKegiatanAdmin(),
      const HalamanJadwalAdmin(),
      const HalamanAnggotaAdmin(),
      const HalamanGaleriAdmin(),
    ];

    return Scaffold(
      appBar: const AppHeader(title: 'KarangKita'),
      drawer: AppDrawer(
        activeIndex: _currentIndex,
        onSelectTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// Widget Tab 1: Beranda Content Sesuai Mockup Figma (`admin_pengurus_beranda_karangkita.png`)
class _BerandaTabContent extends StatelessWidget {
  final String namaPengguna;
  final String peran;
  final Function(int) onPindahTab;

  const _BerandaTabContent({
    required this.namaPengguna,
    required this.peran,
    required this.onPindahTab,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Card Biru Sapaan Pengguna & Tanggal
          HeroCard(
            namaPengguna: namaPengguna,
            peran: peran,
            tanggal: now,
          ),
          const SizedBox(height: 16),

          // 2. 3 Stat Cards (Kegiatan, Anggota, Foto)
          Row(
            children: const [
              StatCard(
                icon: Icons.event_note_outlined,
                count: '12',
                label: 'Kegiatan',
              ),
              SizedBox(width: 10),
              StatCard(
                icon: Icons.people_outline,
                count: '48',
                label: 'Anggota',
              ),
              SizedBox(width: 10),
              StatCard(
                icon: Icons.photo_camera_outlined,
                count: '96',
                label: 'Foto',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Section "Kegiatan terdekat" with "Lihat semua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kegiatan terdekat',
                style: AppTextStyles.sectionTitle,
              ),
              GestureDetector(
                onTap: () => onPindahTab(1), // Pindah ke Tab Kegiatan
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. List Kegiatan Terdekat dengan Date Badge
          EventCard(
            judul: 'Rapat Kerja Bulanan',
            tanggal: DateTime(now.year, 10, 28),
            lokasi: 'Balai Warga RW 05',
            kategori: 'Rapat',
            onTap: () => onPindahTab(1),
          ),
          EventCard(
            judul: 'Kerja Bakti Lingkungan',
            tanggal: DateTime(now.year, 11, 2),
            lokasi: 'Lapangan Utama',
            kategori: 'Sosial',
            onTap: () => onPindahTab(1),
          ),
          EventCard(
            judul: 'Turnamen Futsal Pemuda',
            tanggal: DateTime(now.year, 11, 10),
            lokasi: 'GOR Kecamatan',
            kategori: 'Olahraga',
            onTap: () => onPindahTab(1),
          ),
        ],
      ),
    );
  }
}
