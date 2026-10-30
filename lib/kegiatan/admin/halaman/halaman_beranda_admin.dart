import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/hero_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/event_card.dart';
import '../komponen/komponen_kegiatan_admin.dart';
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
  String _namaPenggunaReal = '';
  String _peranReal = '';

  @override
  void initState() {
    super.initState();
    _namaPenggunaReal = widget.namaPengguna;
    _peranReal = widget.peran;
    _muatProfilUserRealtime();
  }

  // Muat data profil user yang sedang login murni secara real-time dari Cloud Firestore
  void _muatProfilUserRealtime() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final namaCloud = data['nama'] ?? '';
        final roleCloud = data['role'] ?? data['jabatan'] ?? '';

        if (mounted) {
          setState(() {
            if (namaCloud.toString().trim().isNotEmpty) {
              _namaPenggunaReal = namaCloud.toString().trim();
            }
            if (roleCloud.toString().trim().isNotEmpty) {
              _peranReal = roleCloud.toString().trim();
            }
          });
        }
      }
    } catch (e) {
      // Biarkan mengunakan nilai fallback jika gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _BerandaTabContent(
        namaPengguna: _namaPenggunaReal,
        peran: _peranReal,
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
        namaPengguna: _namaPenggunaReal,
        peran: _peranReal,
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

// Widget Tab 1: Beranda Content (Dinamis Terhubung ke Cloud Firestore)
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
  int _jumlahKegiatan = 0;
  int _jumlahAnggota = 0;
  int _jumlahFoto = 0;
  List<ModelKegiatanAdmin> _kegiatanTerdekat = [];

  @override
  void initState() {
    super.initState();
    _muatDataRealtime();
  }

  // Ambil data statistik dan daftar kegiatan terdekat dari Cloud Firestore
  void _muatDataRealtime() async {
    try {
      final snapKegiatan = await FirebaseFirestore.instance.collection('kegiatan').get();
      final snapAnggota = await FirebaseFirestore.instance.collection('users').get();
      
      // Ambil jumlah foto di koleksi galeri dengan count().get()
      int totalFoto = 0;
      try {
        final countFotoSnap = await FirebaseFirestore.instance.collection('galeri').count().get();
        totalFoto = countFotoSnap.count ?? 0;
      } catch (e) {
        // Jika count() gagal, fallback ke 0
        totalFoto = 0;
      }

      final List<ModelKegiatanAdmin> listKegiatan = [];
      if (snapKegiatan.docs.isNotEmpty) {
        for (var doc in snapKegiatan.docs) {
          final data = doc.data();
          listKegiatan.add(ModelKegiatanAdmin(
            id: data['id'] ?? doc.id,
            judul: data['judul'] ?? '',
            tanggal: DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now(),
            waktu: data['waktu'] ?? '07:30 WIB',
            lokasi: data['lokasi'] ?? '',
            kategori: data['kategori'] ?? 'Sosial',
            deskripsi: data['deskripsi'] ?? '',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _kegiatanTerdekat = listKegiatan;
          _jumlahKegiatan = listKegiatan.length;
          _jumlahAnggota = snapAnggota.docs.isNotEmpty ? snapAnggota.docs.length : 0;
          _jumlahFoto = totalFoto;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kegiatanTerdekat = [];
          _jumlahKegiatan = 0;
          _jumlahAnggota = 0;
          _jumlahFoto = 0;
        });
      }
    }
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

          // 4. List Kegiatan Terdekat Dinamis Dari Database
          _kegiatanTerdekat.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'Belum ada kegiatan terdekat',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: _kegiatanTerdekat.take(3).map((item) {
                    return EventCard(
                      judul: item.judul,
                      tanggal: item.tanggal,
                      lokasi: item.lokasi,
                      kategori: item.kategori,
                      onTap: () => widget.onPindahTab(1),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
