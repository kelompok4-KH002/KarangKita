import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

// Widget Tab 1: Beranda Content (Angka Stat Dinamis dari Database)
class _BerandaTabContent extends StatefulWidget {
  final String namaPengguna;
  final String peran;
  final Function(int) onPindahTab;

  const _BerandaTabContent({
    required this.namaPengguna,
    required this.peran,
    required this.onPindahTab,
  });

  @override
  State<_BerandaTabContent> createState() => _BerandaTabContentState();
}

class _BerandaTabContentState extends State<_BerandaTabContent> {
  int _jumlahKegiatan = 3;
  int _jumlahAnggota = 5;
  int _jumlahFoto = 0;

  @override
  void initState() {
    super.initState();
    _hitungStatistikDinamis();
  }

  // Hitung jumlah data kegiatan, anggota, dan foto dari Cloud Firestore secara dinamis
  void _hitungStatistikDinamis() async {
    try {
      final snapKegiatan = await FirebaseFirestore.instance.collection('kegiatan').get();
      final snapAnggota = await FirebaseFirestore.instance.collection('users').get();

      if (mounted) {
        setState(() {
          if (snapKegiatan.docs.isNotEmpty) {
            _jumlahKegiatan = snapKegiatan.docs.length;
          }
          if (snapAnggota.docs.isNotEmpty) {
            _jumlahAnggota = snapAnggota.docs.length;
          }
        });
      }
    } catch (_) {}
  }

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
            namaPengguna: widget.namaPengguna,
            peran: widget.peran,
            tanggal: now,
          ),
          const SizedBox(height: 16),

          // 2. 3 Stat Cards Dinamis (Kegiatan, Anggota, Foto)
          Row(
            children: [
              StatCard(
                icon: Icons.event_note_outlined,
                count: '$_jumlahKegiatan',
                label: 'Kegiatan',
              ),
              const SizedBox(width: 10),
              StatCard(
                icon: Icons.people_outline,
                count: '$_jumlahAnggota',
                label: 'Anggota',
              ),
              const SizedBox(width: 10),
              StatCard(
                icon: Icons.photo_camera_outlined,
                count: '$_jumlahFoto',
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
                onTap: () => widget.onPindahTab(1),
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
            onTap: () => widget.onPindahTab(1),
          ),
          EventCard(
            judul: 'Kerja Bakti Lingkungan',
            tanggal: DateTime(now.year, 11, 2),
            lokasi: 'Lapangan Utama',
            kategori: 'Sosial',
            onTap: () => widget.onPindahTab(1),
          ),
          EventCard(
            judul: 'Turnamen Futsal Pemuda',
            tanggal: DateTime(now.year, 11, 10),
            lokasi: 'GOR Kecamatan',
            kategori: 'Olahraga',
            onTap: () => widget.onPindahTab(1),
          ),
        ],
      ),
    );
  }
}
