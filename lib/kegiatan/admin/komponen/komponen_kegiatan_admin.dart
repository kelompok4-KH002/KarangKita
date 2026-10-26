import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';

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

// Data Awal Kosong (Murni dari Cloud Firestore Database)
final List<ModelKegiatanAdmin> dataKegiatanAwal = [];

// Dialog Form Tambah / Edit Kegiatan dengan Pilihan Kategori Interaktif
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
  late DateTime _tanggalObj;

  @override
  void initState() {
    super.initState();
    final edit = widget.kegiatanEdit;
    _tanggalObj = edit?.tanggal ?? DateTime.now();
    _judulController = TextEditingController(text: edit?.judul ?? '');
    _tanggalController = TextEditingController(
      text: edit != null ? '${_tanggalObj.month}/${_tanggalObj.day}/${_tanggalObj.year}' : '',
    );
    _waktuController = TextEditingController(text: edit?.waktu ?? '');
    _lokasiController = TextEditingController(text: edit?.lokasi ?? '');
    _deskripsiController = TextEditingController(text: edit?.deskripsi ?? '');
    _statusTerpilih = edit?.status ?? 'Mendatang';
    
    final kat = edit?.kategori ?? 'Olahraga';
    _kategoriTerpilih = AppConstants.kDaftarKategoriUtama.contains(kat) ? kat : 'Olahraga';
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

  DateTime _parseTanggalText(String text, DateTime defaultVal) {
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        final m = int.parse(parts[0]);
        final d = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (e) {
      // Biarkan mengembalikan defaultVal jika gagal di-parse
    }
    return defaultVal;
  }

  // Buka kalender interaktif untuk memilih tanggal
  void _pilihTanggal() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggalObj,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (tgl != null) {
      setState(() {
        _tanggalObj = tgl;
        _tanggalController.text = '${tgl.month}/${tgl.day}/${tgl.year}';
      });
    }
  }

  // Buka time picker interaktif untuk memilih jam
  void _pilihWaktu() async {
    final wkt = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (wkt != null) {
      if (!mounted) return;
      final jamStr = wkt.hour.toString().padLeft(2, '0');
      final menitStr = wkt.minute.toString().padLeft(2, '0');
      setState(() {
        _waktuController.text = '$jamStr:$menitStr WIB';
      });
    }
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

                      // Kategori Kegiatan Terpadu
                      _buildInputLabel('Kategori Kegiatan'),
                      DropdownButtonFormField<String>(
                        value: _kategoriTerpilih,
                        decoration: _buildInputDecoration(hintText: 'Pilih Kategori'),
                        items: AppConstants.kDaftarKategoriUtama
                            .map((kat) => DropdownMenuItem(value: kat, child: Text(kat)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _kategoriTerpilih = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Tanggal (Pop-up Calendar Picker Interaktif)
                      _buildInputLabel('Tanggal'),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _pilihTanggal,
                        decoration: _buildInputDecoration(
                          hintText: 'Pilih tanggal di kalender',
                          suffixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 20),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Tanggal wajib dipilih' : null,
                      ),
                      const SizedBox(height: 14),

                      // Waktu (Pop-up Time Picker Interaktif)
                      _buildInputLabel('Waktu'),
                      TextFormField(
                        controller: _waktuController,
                        readOnly: true,
                        onTap: _pilihWaktu,
                        decoration: _buildInputDecoration(
                          hintText: 'Pilih jam kegiatan',
                          suffixIcon: const Icon(Icons.access_time_outlined, color: AppColors.primary, size: 20),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Waktu wajib dipilih' : null,
                      ),
                      const SizedBox(height: 14),

                      // Lokasi
                      _buildInputLabel('Lokasi'),
                      TextFormField(
                        controller: _lokasiController,
                        decoration: _buildInputDecoration(
                          hintText: 'Area Lingkungan RW 05 (RT 01 - 04)',
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
                        final tglSimpan = _parseTanggalText(_tanggalController.text, _tanggalObj);
                        final hasil = ModelKegiatanAdmin(
                          id: widget.kegiatanEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          judul: _judulController.text.trim(),
                          tanggal: tglSimpan,
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

  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      suffixIcon: suffixIcon,
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
