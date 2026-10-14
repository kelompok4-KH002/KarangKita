import 'package:flutter/material.dart';

class ModelJadwal {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String jam;
  final String lokasi;
  final String kategori;
  final String deskripsi;

  ModelJadwal({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.kategori,
    required this.deskripsi,
  });
}

// Widget kalender bulanan
class WidgetKalenderSimple extends StatelessWidget {
  final DateTime tanggalTerpilih;
  final ValueChanged<DateTime> onTanggalDipilih;

  const WidgetKalenderSimple({
    super.key,
    required this.tanggalTerpilih,
    required this.onTanggalDipilih,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime awalBulan = DateTime(tanggalTerpilih.year, tanggalTerpilih.month, 1);
    final int jumlahHari = DateTime(tanggalTerpilih.year, tanggalTerpilih.month + 1, 0).day;
    final int hariMulaiIndex = awalBulan.weekday % 7;

    const List<String> namaHari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const List<String> namaBulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header bulan & navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${namaBulan[tanggalTerpilih.month]} ${tanggalTerpilih.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        onTanggalDipilih(
                          DateTime(tanggalTerpilih.year, tanggalTerpilih.month - 1, 1),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        onTanggalDipilih(
                          DateTime(tanggalTerpilih.year, tanggalTerpilih.month + 1, 1),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),

            // Baris nama hari
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: namaHari.map((hari) {
                return Expanded(
                  child: Center(
                    child: Text(
                      hari,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Grid angka tanggal
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 35,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final int nomorHari = index - hariMulaiIndex + 1;

                if (nomorHari < 1 || nomorHari > jumlahHari) {
                  return const SizedBox.shrink();
                }

                final DateTime tglIndex = DateTime(
                  tanggalTerpilih.year,
                  tanggalTerpilih.month,
                  nomorHari,
                );

                final bool isTerpilih =
                    tanggalTerpilih.year == tglIndex.year &&
                    tanggalTerpilih.month == tglIndex.month &&
                    tanggalTerpilih.day == tglIndex.day;

                final DateTime hariIni = DateTime.now();
                final bool isHariIni =
                    hariIni.year == tglIndex.year &&
                    hariIni.month == tglIndex.month &&
                    hariIni.day == tglIndex.day;

                return InkWell(
                  onTap: () => onTanggalDipilih(tglIndex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTerpilih
                          ? Colors.blueAccent
                          : (isHariIni ? Colors.blue.shade50 : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isHariIni && !isTerpilih
                          ? Border.all(color: Colors.blueAccent, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$nomorHari',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isTerpilih || isHariIni ? FontWeight.bold : FontWeight.normal,
                          color: isTerpilih
                              ? Colors.white
                              : (isHariIni ? Colors.blueAccent : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Chip filter kategori
class WidgetFilterKategori extends StatelessWidget {
  final List<String> daftarKategori;
  final String kategoriTerpilih;
  final ValueChanged<String> onKategoriDipilih;

  const WidgetFilterKategori({
    super.key,
    required this.daftarKategori,
    required this.kategoriTerpilih,
    required this.onKategoriDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: daftarKategori.map((kategori) {
          final bool isSelected = kategoriTerpilih == kategori;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(kategori),
              selected: isSelected,
              selectedColor: Colors.blueAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onKategoriDipilih(kategori),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Kartu agenda item
class KartuAgenda extends StatelessWidget {
  final ModelJadwal jadwal;
  final VoidCallback onTap;

  const KartuAgenda({
    super.key,
    required this.jadwal,
    required this.onTap,
  });

  Color _warnaKategori(String kategori) {
    switch (kategori) {
      case 'Rapat':
        return Colors.orange;
      case 'Kerja Bakti':
        return Colors.green;
      case 'Acara':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color warnaTag = _warnaKategori(jadwal.kategori);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: warnaTag.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      jadwal.kategori,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: warnaTag,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        jadwal.jam,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                jadwal.judul,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      jadwal.lokasi,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog detail agenda saat diklik
class DialogDetailJadwal extends StatelessWidget {
  final ModelJadwal jadwal;

  const DialogDetailJadwal({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(jadwal.judul),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(jadwal.kategori),
            backgroundColor: Colors.blue.shade50,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 15, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text('${jadwal.tanggal.day}/${jadwal.tanggal.month}/${jadwal.tanggal.year}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 15, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text(jadwal.jam),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 15, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(jadwal.lokasi)),
            ],
          ),
          const Divider(height: 20),
          const Text(
            'Deskripsi:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(jadwal.deskripsi),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
