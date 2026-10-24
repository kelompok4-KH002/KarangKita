import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/date_badge.dart';
import '../komponen/komponen_jadwal_admin.dart';

// Halaman Kelola Jadwal Admin Sesuai Mockup Figma (`admin_pengurus_kelola_jadwal.png`)
class HalamanJadwalAdmin extends StatefulWidget {
  const HalamanJadwalAdmin({super.key});

  @override
  State<HalamanJadwalAdmin> createState() => _HalamanJadwalAdminState();
}

class _HalamanJadwalAdminState extends State<HalamanJadwalAdmin> {
  DateTime _tanggalTerpilih = DateTime.now();
  late List<ModelJadwalAdmin> _daftarJadwal;

  @override
  void initState() {
    super.initState();
    _daftarJadwal = List.from(dataJadwalAdminAwal);
    _muatJadwalDariFirestore();
  }

  void _muatJadwalDariFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('jadwal').get();
      if (snap.docs.isNotEmpty) {
        final List<ModelJadwalAdmin> listDariCloud = [];
        for (var doc in snap.docs) {
          final data = doc.data();
          listDariCloud.add(ModelJadwalAdmin(
            id: data['id'] ?? doc.id,
            judul: data['judul'] ?? '',
            tanggal: DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now(),
            jam: data['jam'] ?? '19:30 WIB',
            lokasi: data['lokasi'] ?? '',
            kategori: data['kategori'] ?? 'Rapat',
          ));
        }
        if (mounted) {
          setState(() {
            _daftarJadwal = listDariCloud;
          });
        }
      }
    } catch (_) {}
  }

  void _tambahJadwal(ModelJadwalAdmin jadwal) async {
    setState(() {
      _daftarJadwal.insert(0, jadwal);
    });

    try {
      await FirebaseFirestore.instance.collection('jadwal').doc(jadwal.id).set({
        'id': jadwal.id,
        'judul': jadwal.judul,
        'jam': jadwal.jam,
        'lokasi': jadwal.lokasi,
        'kategori': jadwal.kategori,
        'tanggal': jadwal.tanggal.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
    );
  }

  void _editJadwal(int index, ModelJadwalAdmin jadwal) async {
    setState(() {
      _daftarJadwal[index] = jadwal;
    });

    try {
      await FirebaseFirestore.instance.collection('jadwal').doc(jadwal.id).set({
        'id': jadwal.id,
        'judul': jadwal.judul,
        'jam': jadwal.jam,
        'lokasi': jadwal.lokasi,
        'kategori': jadwal.kategori,
        'tanggal': jadwal.tanggal.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil diperbarui')),
    );
  }

  void _hapusJadwal(int index) async {
    final target = _daftarJadwal[index];
    setState(() {
      _daftarJadwal.removeAt(index);
    });

    try {
      await FirebaseFirestore.instance.collection('jadwal').doc(target.id).delete();
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const List<String> namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final int jumlahHari = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month + 1, 0).day;
    final int hariMulaiIndex = (DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month, 1).weekday - 1) % 7;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bulan & Tahun Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _tanggalTerpilih = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month - 1, 1);
                    });
                  },
                ),
                Text(
                  '${namaBulan[_tanggalTerpilih.month]} ${_tanggalTerpilih.year}',
                  style: AppTextStyles.cardTitle,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                  onPressed: () {
                    setState(() {
                      _tanggalTerpilih = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Baris nama hari
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: namaHari.map((hari) {
                return Expanded(
                  child: Center(
                    child: Text(
                      hari,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Grid Tanggal
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 35,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final int nomorHari = index - hariMulaiIndex + 1;
                if (nomorHari < 1 || nomorHari > jumlahHari) {
                  return const SizedBox.shrink();
                }

                final bool isTerpilih = nomorHari == _tanggalTerpilih.day;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _tanggalTerpilih = DateTime(
                        _tanggalTerpilih.year,
                        _tanggalTerpilih.month,
                        nomorHari,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTerpilih ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$nomorHari',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isTerpilih ? FontWeight.bold : FontWeight.normal,
                            color: isTerpilih ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (nomorHari % 7 == 3 || nomorHari == 10 || nomorHari == 17 || nomorHari == 24 || nomorHari == 31)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isTerpilih ? Colors.white : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Tanggal terpilih & agenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal terpilih (${_tanggalTerpilih.day}/${_tanggalTerpilih.month}/${_tanggalTerpilih.year})',
                  style: AppTextStyles.cardTitle,
                ),
                Text(
                  'Agenda',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kartu Agenda Sesuai Mockup Figma
            _daftarJadwal.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Belum ada agenda', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _daftarJadwal.length,
                    itemBuilder: (context, index) {
                      final item = _daftarJadwal[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            DateBadge(tanggal: item.tanggal),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.judul,
                                    style: AppTextStyles.cardTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.jam} · ${item.lokasi}',
                                    style: AppTextStyles.cardSubtitle,
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => DialogTambahEditJadwalAdmin(
                                    jadwalEdit: item,
                                    onSimpan: (newItem) => _editJadwal(index, newItem),
                                    onHapus: () => _hapusJadwal(index),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                              onPressed: () => _hapusJadwal(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),

            // Big button "Tambah jadwal"
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => DialogTambahEditJadwalAdmin(onSimpan: _tambahJadwal),
                  );
                },
                child: const Text('Tambah jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
