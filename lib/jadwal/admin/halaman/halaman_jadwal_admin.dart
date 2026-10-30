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
  bool _sedangMemuat = true;
  bool _adaErrorMemuat = false;
  String _pesanErrorMemuat = '';

  @override
  void initState() {
    super.initState();
    _daftarJadwal = [];
    _muatJadwalDariFirestore();
  }

  String _getPesanError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Anda tidak punya izin untuk tindakan ini';
    }
    return 'Gagal menyimpan, periksa koneksi internet';
  }

  String _getPesanErrorHapus(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Anda tidak punya izin untuk tindakan ini';
    }
    return 'Gagal menghapus jadwal, periksa koneksi internet';
  }

  // Membaca murni dari koleksi 'kegiatan' (Satu sumber terpadu)
  void _muatJadwalDariFirestore() async {
    setState(() {
      _sedangMemuat = true;
      _adaErrorMemuat = false;
    });

    try {
      final snap = await FirebaseFirestore.instance.collection('kegiatan').get();
      final List<ModelJadwalAdmin> listDariCloud = [];
      for (var doc in snap.docs) {
        final data = doc.data();
        final rawWaktu = data['waktu'] ?? data['jam'] ?? '19:30 WIB';
        final wktMulai = data['waktuMulai'] ?? (rawWaktu.contains('-') ? rawWaktu.split('-')[0].trim() : rawWaktu);
        final wktSelesai = data['waktuSelesai'] ?? (rawWaktu.contains('-') ? rawWaktu.split('-')[1].trim() : '21:00 WIB');

        listDariCloud.add(ModelJadwalAdmin(
          id: data['id'] ?? doc.id,
          judul: data['judul'] ?? '',
          targetPeserta: data['targetPeserta'] ?? 'Pengurus',
          tanggal: DateTime.tryParse(data['tanggal'] ?? '') ?? DateTime.now(),
          waktuMulai: wktMulai,
          waktuSelesai: wktSelesai,
          lokasi: data['lokasi'] ?? '',
          catatan: data['catatan'] ?? data['deskripsi'] ?? '',
          kategori: data['kategori'] ?? 'Rapat',
        ));
      }
      if (mounted) {
        setState(() {
          _daftarJadwal = listDariCloud;
          _sedangMemuat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sedangMemuat = false;
          _adaErrorMemuat = true;
          _pesanErrorMemuat = e is FirebaseException && e.code == 'permission-denied'
              ? 'Anda tidak punya izin untuk membaca data ini'
              : 'Gagal memuat data, periksa koneksi internet';
        });
      }
    }
  }

  void _tambahJadwal(ModelJadwalAdmin jadwal) async {
    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(jadwal.id).set({
        'id': jadwal.id,
        'judul': jadwal.judul,
        'targetPeserta': jadwal.targetPeserta,
        'waktu': '${jadwal.waktuMulai} - ${jadwal.waktuSelesai}',
        'waktuMulai': jadwal.waktuMulai,
        'waktuSelesai': jadwal.waktuSelesai,
        'lokasi': jadwal.lokasi,
        'catatan': jadwal.catatan,
        'deskripsi': jadwal.catatan,
        'kategori': jadwal.kategori,
        'tanggal': jadwal.tanggal.toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _daftarJadwal.insert(0, jadwal);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanError(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _editJadwal(int index, ModelJadwalAdmin jadwal) async {
    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(jadwal.id).set({
        'id': jadwal.id,
        'judul': jadwal.judul,
        'targetPeserta': jadwal.targetPeserta,
        'waktu': '${jadwal.waktuMulai} - ${jadwal.waktuSelesai}',
        'waktuMulai': jadwal.waktuMulai,
        'waktuSelesai': jadwal.waktuSelesai,
        'lokasi': jadwal.lokasi,
        'catatan': jadwal.catatan,
        'deskripsi': jadwal.catatan,
        'kategori': jadwal.kategori,
        'tanggal': jadwal.tanggal.toIso8601String(),
      }, SetOptions(merge: true));

      setState(() {
        _daftarJadwal[index] = jadwal;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanError(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _hapusJadwal(int index) async {
    final target = _daftarJadwal[index];

    try {
      await FirebaseFirestore.instance.collection('kegiatan').doc(target.id).delete();

      setState(() {
        _daftarJadwal.removeAt(index);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getPesanErrorHapus(e)), backgroundColor: AppColors.danger),
      );
    }
  }

  void _bukaHalamanFormJadwal({ModelJadwalAdmin? jadwalEdit, int? origIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HalamanFormJadwalAdmin(
          jadwalEdit: jadwalEdit,
          onSimpan: (newItem) {
            if (jadwalEdit != null && origIndex != null) {
              _editJadwal(origIndex, newItem);
            } else {
              _tambahJadwal(newItem);
            }
          },
          onHapus: origIndex != null ? () => _hapusJadwal(origIndex) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sedangMemuat) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_adaErrorMemuat) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pesanErrorMemuat, style: AppTextStyles.statLabel),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.textWhite),
                onPressed: _muatJadwalDariFirestore,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    const List<String> namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const List<String> namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final int jumlahHari = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month + 1, 0).day;
    final int hariMulaiIndex = (DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month, 1).weekday - 1) % 7;

    // Filter agenda khusus tanggal yang sedang dipilih
    final agendaTersaring = _daftarJadwal.where((j) {
      return j.tanggal.year == _tanggalTerpilih.year &&
          j.tanggal.month == _tanggalTerpilih.month &&
          j.tanggal.day == _tanggalTerpilih.day;
    }).toList();

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
                      style: AppTextStyles.statLabel,
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

                final DateTime tglIndex = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month, nomorHari);
                final bool isTerpilih = nomorHari == _tanggalTerpilih.day;

                // Hitung titik penanda agenda secara dinamis dari data asli
                final bool adaAgenda = _daftarJadwal.any((j) =>
                    j.tanggal.year == tglIndex.year &&
                    j.tanggal.month == tglIndex.month &&
                    j.tanggal.day == tglIndex.day);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _tanggalTerpilih = tglIndex;
                    });
                  },
                  borderRadius: AppRadius.r12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTerpilih ? AppColors.primary : Colors.transparent,
                      borderRadius: AppRadius.r12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$nomorHari',
                          style: isTerpilih ? AppTextStyles.calendarDaySelected : AppTextStyles.calendarDay,
                        ),
                        if (adaAgenda)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isTerpilih ? AppColors.textWhite : AppColors.primary,
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
                const Text(
                  'Agenda',
                  style: AppTextStyles.statLabel,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kartu Agenda Filtered Sesuai Tanggal Terpilih
            agendaTersaring.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Belum ada agenda di tanggal ini', style: AppTextStyles.statLabel),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: agendaTersaring.length,
                    itemBuilder: (context, index) {
                      final item = agendaTersaring[index];
                      final origIndex = _daftarJadwal.indexOf(item);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.r16,
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: AppRadius.r6,
                                        ),
                                        child: Text(
                                          item.targetPeserta.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
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
                              onPressed: () => _bukaHalamanFormJadwal(
                                jadwalEdit: item,
                                origIndex: origIndex,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                              onPressed: () => _hapusJadwal(origIndex),
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
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.r12,
                  ),
                ),
                onPressed: () => _bukaHalamanFormJadwal(),
                child: const Text('Tambah jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
