import 'package:flutter/material.dart';

// Model Data Kegiatan Admin
class ModelKegiatanAdmin {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String lokasi;
  final String deskripsi;
  final String status;

  ModelKegiatanAdmin({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.lokasi,
    required this.deskripsi,
    required this.status,
  });
}

// Data awal contoh untuk Admin Kegiatan
final List<ModelKegiatanAdmin> dataKegiatanAwal = [
  ModelKegiatanAdmin(
    id: 'K1',
    judul: 'Kerja Bakti Akbar Menyambut HUT RI',
    tanggal: DateTime.now().add(const Duration(days: 2)),
    lokasi: 'Seluruh Wilayah RW 05',
    deskripsi: 'Pembersihan selokan, pemasangan bendera, dan pengecatan gapura.',
    status: 'Mendatang',
  ),
  ModelKegiatanAdmin(
    id: 'K2',
    judul: 'Lomba Olahraga & Ketangkasan Pemuda',
    tanggal: DateTime.now().add(const Duration(days: 5)),
    lokasi: 'Lapangan Serbaguna RT 03',
    deskripsi: 'Pertandingan catur, bulutangkis, dan futsal antar RT.',
    status: 'Mendatang',
  ),
  ModelKegiatanAdmin(
    id: 'K3',
    judul: 'Penyuluhan Kesehatan & Donor Darah',
    tanggal: DateTime.now().subtract(const Duration(days: 3)),
    lokasi: 'Balai Warga RW 05',
    deskripsi: 'Kerjasama dengan Puskesmas kecamatan setempat.',
    status: 'Selesai',
  ),
];

// Kartu Item Kegiatan di Halaman Admin
class KartuKegiatanAdmin extends StatelessWidget {
  final ModelKegiatanAdmin kegiatan;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const KartuKegiatanAdmin({
    super.key,
    required this.kegiatan,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelesai = kegiatan.status == 'Selesai';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelesai ? Colors.grey.shade200 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kegiatan.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelesai ? Colors.grey.shade700 : Colors.blueAccent,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit Kegiatan',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: onHapus,
                      tooltip: 'Hapus Kegiatan',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              kegiatan.judul,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${kegiatan.tanggal.day}/${kegiatan.tanggal.month}/${kegiatan.tanggal.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    kegiatan.lokasi,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              kegiatan.deskripsi,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog Form Tambah / Edit Kegiatan
class DialogTambahEditKegiatan extends StatefulWidget {
  final ModelKegiatanAdmin? kegiatanEdit;
  final Function(ModelKegiatanAdmin) onSimpan;

  const DialogTambahEditKegiatan({
    super.key,
    this.kegiatanEdit,
    required this.onSimpan,
  });

  @override
  State<DialogTambahEditKegiatan> createState() => _DialogTambahEditKegiatanState();
}

class _DialogTambahEditKegiatanState extends State<DialogTambahEditKegiatan> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _lokasiController;
  late TextEditingController _deskripsiController;
  late DateTime _tanggalTerpilih;
  late String _statusTerpilih;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.kegiatanEdit?.judul ?? '');
    _lokasiController = TextEditingController(text: widget.kegiatanEdit?.lokasi ?? '');
    _deskripsiController = TextEditingController(text: widget.kegiatanEdit?.deskripsi ?? '');
    _tanggalTerpilih = widget.kegiatanEdit?.tanggal ?? DateTime.now();
    _statusTerpilih = widget.kegiatanEdit?.status ?? 'Mendatang';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.kegiatanEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan Baru'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Kegiatan',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Lokasi wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _statusTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Status Kegiatan',
                  border: OutlineInputBorder(),
                ),
                items: ['Mendatang', 'Selesai']
                    .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _statusTerpilih = val);
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final hasil = ModelKegiatanAdmin(
                id: widget.kegiatanEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                judul: _judulController.text.trim(),
                tanggal: _tanggalTerpilih,
                lokasi: _lokasiController.text.trim(),
                deskripsi: _deskripsiController.text.trim(),
                status: _statusTerpilih,
              );
              widget.onSimpan(hasil);
              Navigator.pop(context);
            }
          },
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
