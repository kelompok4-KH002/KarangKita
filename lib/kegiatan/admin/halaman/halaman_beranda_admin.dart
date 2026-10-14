import 'package:flutter/material.dart';
import 'halaman_kegiatan_admin.dart';
import '../../../jadwal/admin/halaman/halaman_jadwal_admin.dart';
import 'halaman_anggota_admin.dart';
import 'halaman_galeri_admin.dart';
import '../../../autentikasi/halaman/halaman_login.dart';

// Container utama admin dengan BottomNavigationBar 5 Tab
class HalamanBerandaAdmin extends StatefulWidget {
  const HalamanBerandaAdmin({super.key});

  @override
  State<HalamanBerandaAdmin> createState() => _HalamanBerandaAdminState();
}

class _HalamanBerandaAdminState extends State<HalamanBerandaAdmin> {
  // Index tab aktif
  int _currentIndex = 0;

  // Daftar halaman untuk masing-masing tab
  final List<Widget> _pages = const [
    _BerandaTabContent(),
    HalamanKegiatanAdmin(),
    HalamanJadwalAdmin(),
    HalamanAnggotaAdmin(),
    HalamanGaleriAdmin(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      // Bottom Navigation Bar 5 Tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2B303A),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Kegiatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Jadwal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Anggota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Galeri',
          ),
        ],
      ),
    );
  }
}

// Content untuk Tab 1 (Beranda Admin)
class _BerandaTabContent extends StatelessWidget {
  const _BerandaTabContent();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const List<String> namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final parentState = context.findAncestorStateOfType<_HalamanBerandaAdminState>();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'KarangKita',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout Admin',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HalamanLogin()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2B303A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sapaan pengguna & Tanggal hari ini
            const Text(
              'Sapaan pengguna',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B303A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tanggal hari ini (${now.day} ${namaBulan[now.month]} ${now.year})',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // 3 Stat Cards (Kegiatan / Anggota / Foto)
            Row(
              children: [
                _buildStatCard('03', 'Kegiatan'),
                const SizedBox(width: 10),
                _buildStatCard('12', 'Anggota'),
                const SizedBox(width: 10),
                _buildStatCard('08', 'Foto'),
              ],
            ),
            const SizedBox(height: 20),

            // 4 Quick Access Icons (Pindah Tab Langsung)
            Row(
              mainAxisAlignment: Main.spaceAround,
              children: [
                _buildQuickIcon(Icons.event_note, 'Kegiatan', () {
                  parentState?.setState(() => parentState._currentIndex = 1);
                }),
                _buildQuickIcon(Icons.calendar_month, 'Jadwal', () {
                  parentState?.setState(() => parentState._currentIndex = 2);
                }),
                _buildQuickIcon(Icons.people, 'Anggota', () {
                  parentState?.setState(() => parentState._currentIndex = 3);
                }),
                _buildQuickIcon(Icons.folder_outlined, 'Dokumen', () {
                  parentState?.setState(() => parentState._currentIndex = 4);
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Section Kegiatan terdekat
            Row(
              mainAxisAlignment: Main.spaceEvenly,
              children: [
                const Expanded(
                  child: Text(
                    'Kegiatan terdekat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B303A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    parentState?.setState(() => parentState._currentIndex = 1);
                  },
                  child: Text(
                    'Lihat semua',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Cards Kegiatan Terdekat
            _buildKegiatanItemCard(
              'Rapat Bulanan Pengurus',
              '18 Oktober 2026 · Balai Warga RW 05',
            ),
            _buildKegiatanItemCard(
              'Kerja Bakti Cat Gapura & Bersih Desa',
              '25 Oktober 2026 · RT 02 & RT 03',
            ),
            _buildKegiatanItemCard(
              'Turnamen Futsal Pemuda',
              '1 November 2026 · Lapangan Champion',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B303A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2B303A), size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2B303A),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildKegiatanItemCard(String judul, String info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey.shade500,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2B303A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
