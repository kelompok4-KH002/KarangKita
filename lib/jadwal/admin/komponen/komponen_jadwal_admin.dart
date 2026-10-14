import 'package:flutter/material.dart';

// Model Data Jadwal Admin
class ModelJadwalAdmin {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String jam;
  final String lokasi;
  final String kategori;

  ModelJadwalAdmin({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.kategori,
  });
}

// Data awal contoh jadwal admin
final List<ModelJadwalAdmin> dataJadwalAdminAwal = [
  ModelJadwalAdmin(
    id: 'J1',
    judul: 'Rapat Koordinasi Pengurus Karang Taruna',
    tanggal: DateTime.now(),
    jam: '19:30 WIB',
    lokasi: 'Balai Warga RW 05',
    kategori: 'Rapat',
  ),
  ModelJadwalAdmin(
    id: 'J2',
    judul: 'Kerja Bakti Lingkungan',
    tanggal: DateTime.now().add(const Duration(days: 2)),
    jam: '07:30 WIB',
    lokasi: 'Area RT 01 - RT 06',
    kategori: 'Kerja Bakti',
  ),
];

// Kartu Jadwal Admin
class KartuJadwalAdmin extends StatelessWidget {
  final ModelJadwalAdmin jadwal;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  const KartuJadwalAdmin({
    super.key,
    required this.jadwal,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${jadwal.jam} • ${jadwal.lokasi}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: onHapus,
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog Form Tambah / Edit Jadwal Admin
class DialogTambahEditJadwalAdmin extends StatefulWidget {
  final ModelJadwalAdmin? jadwalEdit;
  final Function(ModelJadwalAdmin) onSimpan;

  const DialogTambahEditJadwalAdmin({
    super.key,
    this.jadwalEdit,
    required this.onSimpan,
  });

  @override
  State<DialogTambahEditJadwalAdmin> createState() => _DialogTambahEditJadwalAdminState();
}

class _DialogTambahEditJadwalAdminState extends State<DialogTambahEditJadwalAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _jamController;
  late TextEditingController _lokasiController;
  late String _kategoriTerpilih;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.jadwalEdit?.judul ?? '');
    _jamController = TextEditingController(text: widget.jadwalEdit?.jam ?? '19:30 WIB');
    _lokasiController = TextEditingController(text: widget.jadwalEdit?.lokasi ?? '');
    _kategoriTerpilih = widget.jadwalEdit?.kategori ?? 'Rapat';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _jamController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.jadwalEdit != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal Agenda'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Agenda',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _jamController,
                decoration: const InputDecoration(
                  labelText: 'Jam / Waktu',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Jam wajib diisi' : null,
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
                value: _kategoriTerpilih,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: ['Rapat', 'Kerja Bakti', 'Acara']
                    .map((kat) => DropdownMenuItem(value: kat, child: Text(kat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _kategoriTerpilih = val);
                },
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
              final hasil = ModelJadwalAdmin(
                id: widget.jadwalEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                judul: _judulController.text.trim(),
                tanggal: DateTime.now(),
                jam: _jamController.text.trim(),
                lokasi: _lokasiController.text.trim(),
                kategori: _kategoriTerpilih,
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
