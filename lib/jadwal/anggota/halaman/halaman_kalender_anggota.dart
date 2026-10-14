import 'package:flutter/material.dart';
import '../komponen/komponen_kalender_anggota.dart';

class HalamanKalenderAnggota extends StatefulWidget {
  final List<ModelJadwal>? daftarJadwal;

  const HalamanKalenderAnggota({super.key, this.daftarJadwal});

  @override
  State<HalamanKalenderAnggota> createState() => _HalamanKalenderAnggotaState();
}

class _HalamanKalenderAnggotaState extends State<HalamanKalenderAnggota> {
  DateTime _tanggalTerpilih = DateTime.now();
  String _kategoriTerpilih = 'Semua';

  final List<String> _daftarKategori = ['Semua', 'Rapat', 'Kerja Bakti', 'Acara'];
  late List<ModelJadwal> _semuaJadwal;

  @override
  void initState() {
    super.initState();
    _semuaJadwal = widget.daftarJadwal ?? [];
  }

  // Filter jadwal berdasarkan tanggal & kategori
  List<ModelJadwal> _jadwalTersaring() {
    return _semuaJadwal.where((jadwal) {
      final bool samaTanggal =
          jadwal.tanggal.year == _tanggalTerpilih.year &&
          jadwal.tanggal.month == _tanggalTerpilih.month &&
          jadwal.tanggal.day == _tanggalTerpilih.day;

      final bool samaKategori =
          _kategoriTerpilih == 'Semua' || jadwal.kategori == _kategoriTerpilih;

      return samaTanggal && samaKategori;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<ModelJadwal> jadwalList = _jadwalTersaring();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal & Kalender'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kalender bulanan
              WidgetKalenderSimple(
                tanggalTerpilih: _tanggalTerpilih,
                onTanggalDipilih: (tanggal) {
                  setState(() {
                    _tanggalTerpilih = tanggal;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Filter kategori
              const Text(
                'Kategori Kegiatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              WidgetFilterKategori(
                daftarKategori: _daftarKategori,
                kategoriTerpilih: _kategoriTerpilih,
                onKategoriDipilih: (kategori) {
                  setState(() {
                    _kategoriTerpilih = kategori;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Header tanggal terpilih
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda ${_tanggalTerpilih.day}/${_tanggalTerpilih.month}/${_tanggalTerpilih.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  Text(
                    '${jadwalList.length} Kegiatan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Daftar agenda
              jadwalList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada agenda pada tanggal ini',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jadwalList.length,
                      itemBuilder: (context, index) {
                        final item = jadwalList[index];
                        return KartuAgenda(
                          jadwal: item,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => DialogDetailJadwal(jadwal: item),
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
