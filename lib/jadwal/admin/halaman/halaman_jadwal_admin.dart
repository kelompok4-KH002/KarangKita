import 'package:flutter/material.dart';
import '../komponen/komponen_jadwal_admin.dart';

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
  }

  void _tambahJadwal(ModelJadwalAdmin jadwal) {
    setState(() {
      _daftarJadwal.insert(0, jadwal);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
    );
  }

  void _editJadwal(int index, ModelJadwalAdmin jadwal) {
    setState(() {
      _daftarJadwal[index] = jadwal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil diperbarui')),
    );
  }

  void _hapusJadwal(int index) {
    setState(() {
      _daftarJadwal.removeAt(index);
    });
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
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text(
          'Kelola Jadwal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => DialogTambahEditJadwalAdmin(onSimpan: _tambahJadwal),
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
            // Header Bulan & Tahun Navigasi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _tanggalTerpilih = DateTime(_tanggalTerpilih.year, _tanggalTerpilih.month - 1, 1);
                    });
                  },
                ),
                Text(
                  '${namaBulan[_tanggalTerpilih.month]} ${_tanggalTerpilih.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B303A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
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
                      color: isTerpilih ? const Color(0xFF2B303A) : Colors.transparent,
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
                            color: isTerpilih ? Colors.white : const Color(0xFF2B303A),
                          ),
                        ),
                        if (nomorHari % 7 == 3 || nomorHari == 10 || nomorHari == 17 || nomorHari == 24 || nomorHari == 31)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isTerpilih ? Colors.white : const Color(0xFF2B303A),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Agenda',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kartu Agenda
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.event, color: Color(0xFF2B303A)),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.judul,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.jam} · ${item.lokasi}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2B303A)),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => DialogTambahEditJadwalAdmin(
                                    jadwalEdit: item,
                                    onSimpan: (newItem) => _editJadwal(index, newItem),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF2B303A)),
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
                  backgroundColor: const Color(0xFF2B303A),
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
