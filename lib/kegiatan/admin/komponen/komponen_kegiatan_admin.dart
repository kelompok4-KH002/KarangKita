import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// Model Data Kegiatan Admin
class ModelKegiatanAdmin {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String waktu;
  final String lokasi;
  final String kategori;
  final String deskripsi;
  final String status; // Mendatang / Selesai

  ModelKegiatanAdmin({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.waktu,
    required this.lokasi,
    required this.kategori,
    required this.deskripsi,
    required this.status,
  });
}

// Data Awal Contoh Sesuai Mockup Figma (`admin_pengurus_kelola_kegiatan.png`)
final List<ModelKegiatanAdmin> dataKegiatanAwal = [
  ModelKegiatanAdmin(
    id: 'K1',
    judul: 'Kerja Bakti Lingkungan RW 05',
    tanggal: DateTime(2024, 11, 15),
    waktu: '07:30 WIB',
    lokasi: 'Area RT 01 - 04',
    kategori: 'Sosial',
    deskripsi: 'Kerja bakti pembersihan saluran air, pemangkasan dahan pohon, dan pengelolaan sampah warga menjelang musim hujan.',
    status: 'Mendatang',
  ),
  ModelKegiatanAdmin(
    id: 'K2',
    judul: 'Turnamen Voli Antar Pemuda',
    tanggal: DateTime(2024, 11, 20),
    waktu: '16:00 WIB',
    lokasi: 'Lapangan Utama',
    kategori: 'Olahraga',
    deskripsi: 'Turnamen voli mempererat silaturahmi pemuda karang taruna antar RT.',
    status: 'Mendatang',
  ),
  ModelKegiatanAdmin(
    id: 'K3',
    judul: 'Rapat Pleno Kepengurusan',
    tanggal: DateTime(2024, 10, 28),
    waktu: '19:30 WIB',
    lokasi: 'Balai Warga Lt. 2',
    kategori: 'Rapat',
    deskripsi: 'Evaluasi program kerja triwulan dan perencanaan kegiatan akhir tahun.',
    status: 'Selesai',
  ),
  ModelKegiatanAdmin(
    id: 'K4',
    judul: 'Pelatihan Desain Grafis',
    tanggal: DateTime(2024, 10, 10),
    waktu: '13:00 WIB',
    lokasi: 'Sekretariat Karang Taruna',
    kategori: 'Edukasi',
    deskripsi: 'Workshop peningkatkan skill publikasi & media sosial pemuda desa.',
    status: 'Selesai',
  ),
];

// Dialog Form Tambah / Edit Kegiatan Presisi Sesuai Mockup Figma (`admin_pengurus_edit_kegiatan.png`)
class DialogTambahEditKegiatan extends StatefulWidget {
  final ModelKegiatanAdmin? kegiatanEdit;
  final Function(ModelKegiatanAdmin) onSimpan;
  final VoidCallback? onHapus;

  const DialogTambahEditKegiatan({
    super.key,
    this.kegiatanEdit,
    required this.onSimpan,
    this.onHapus,
  });

  @override
  State<DialogTambahEditKegiatan> createState() => _DialogTambahEditKegiatanState();
}

class _DialogTambahEditKegiatanState extends State<DialogTambahEditKegiatan> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _waktuController;
  late TextEditingController _lokasiController;
  late TextEditingController _deskripsiController;
  late String _statusTerpilih;
  late String _kategoriTerpilih;

  @override
  void initState() {
    super.initState();
    final edit = widget.kegiatanEdit;
    _judulController = TextEditingController(text: edit?.judul ?? '');
    _tanggalController = TextEditingController(
      text: edit != null ? '${edit.tanggal.month}/${edit.tanggal.day}/${edit.tanggal.year}' : '11/15/2024',
    );
    _waktuController = TextEditingController(text: edit?.waktu ?? '07:30 WIB');
    _lokasiController = TextEditingController(text: edit?.lokasi ?? 'Area Lingkungan RW 05 (RT 01 - 04)');
    _deskripsiController = TextEditingController(
      text: edit?.deskripsi ?? 'Kerja bakti pembersihan saluran air, pemangkasan dahan pohon, dan pengelolaan sampah warga menjelang musim hujan.',
    );
    _statusTerpilih = edit?.status ?? 'Mendatang';
    _kategoriTerpilih = edit?.kategori ?? 'Sosial';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _waktuController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.kegiatanEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF8FAFC),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan Baru',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Kegiatan
                      _buildInputLabel('Nama Kegiatan'),
                      TextFormField(
                        controller: _judulController,
                        decoration: _buildInputDecoration(hintText: 'Nama kegiatan Anda'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nama kegiatan wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Tanggal
                      _buildInputLabel('Tanggal'),
                      TextFormField(
                        controller: _tanggalController,
                        decoration: _buildInputDecoration(hintText: 'MM/DD/YYYY'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Tanggal wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Waktu
                      _buildInputLabel('Waktu'),
                      TextFormField(
                        controller: _waktuController,
                        decoration: _buildInputDecoration(hintText: '07:30 WIB'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Waktu wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Lokasi
                      _buildInputLabel('Lokasi'),
                      TextFormField(
                        controller: _lokasiController,
                        decoration: _buildInputDecoration(
                          hintText: 'Lokasi kegiatan',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Deskripsi
                      _buildInputLabel('Deskripsi'),
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(hintText: 'Tuliskan deskripsi kegiatan...'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Status Kegiatan Segmented Pill
                      _buildInputLabel('Status Kegiatan'),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _statusTerpilih = 'Mendatang'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _statusTerpilih == 'Mendatang' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _statusTerpilih == 'Mendatang'
                                        ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Mendatang',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _statusTerpilih = 'Selesai'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _statusTerpilih == 'Selesai' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: _statusTerpilih == 'Selesai'
                                        ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Selesai',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Button Primary: Simpan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final hasil = ModelKegiatanAdmin(
                          id: widget.kegiatanEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          judul: _judulController.text.trim(),
                          tanggal: DateTime.now(),
                          waktu: _waktuController.text.trim(),
                          lokasi: _lokasiController.text.trim(),
                          kategori: _kategoriTerpilih,
                          deskripsi: _deskripsiController.text.trim(),
                          status: _statusTerpilih,
                        );
                        widget.onSimpan(hasil);
                        Navigator.pop(context);
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Button Outlined: Batal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Red Link: Hapus Kegiatan (if editing)
                if (isEdit && widget.onHapus != null)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onHapus!();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text(
                            'Hapus Kegiatan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  static InputDecoration _buildInputDecoration({required String hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
