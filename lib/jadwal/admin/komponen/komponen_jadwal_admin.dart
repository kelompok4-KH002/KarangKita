import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';

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

// Data Awal Kosong (Murni dari Database Cloud Firestore)
final List<ModelJadwalAdmin> dataJadwalAdminAwal = [];

// Dialog Form Tambah / Edit Jadwal Admin Presisi Sesuai Mockup Figma (`admin_pengurus_edit_jadwal.png`)
class DialogTambahEditJadwalAdmin extends StatefulWidget {
  final ModelJadwalAdmin? jadwalEdit;
  final Function(ModelJadwalAdmin) onSimpan;
  final VoidCallback? onHapus;

  const DialogTambahEditJadwalAdmin({
    super.key,
    this.jadwalEdit,
    required this.onSimpan,
    this.onHapus,
  });

  @override
  State<DialogTambahEditJadwalAdmin> createState() => _DialogTambahEditJadwalAdminState();
}

class _DialogTambahEditJadwalAdminState extends State<DialogTambahEditJadwalAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _jamController;
  late TextEditingController _lokasiController;
  late String _kategoriTerpilih;
  late DateTime _tanggalObj;

  @override
  void initState() {
    super.initState();
    final edit = widget.jadwalEdit;
    _tanggalObj = edit?.tanggal ?? DateTime.now();
    _judulController = TextEditingController(text: edit?.judul ?? '');
    _tanggalController = TextEditingController(
      text: edit != null ? '${_tanggalObj.month}/${_tanggalObj.day}/${_tanggalObj.year}' : '',
    );
    _jamController = TextEditingController(text: edit?.jam ?? '');
    _lokasiController = TextEditingController(text: edit?.lokasi ?? '');
    
    final kat = edit?.kategori ?? 'Rapat';
    _kategoriTerpilih = AppConstants.kDaftarKategoriUtama.contains(kat) ? kat : 'Rapat';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    _lokasiController.dispose();
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
    } catch (_) {}
    return defaultVal;
  }

  // Buka Pop-up Calendar Picker
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

  // Buka Pop-up Time Picker
  void _pilihWaktu() async {
    final wkt = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 30),
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
        _jamController.text = '$jamStr:$menitStr WIB';
      });
    }
  }

  // Dialog Konfirmasi Hapus Spesifik
  void _tampilkanKonfirmasiHapus() {
    final namaAgenda = widget.jadwalEdit?.judul ?? 'agenda ini';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus jadwal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus agenda "$namaAgenda"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
            ),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog konfirmasi
              Navigator.pop(context); // Tutup dialog edit
              if (widget.onHapus != null) widget.onHapus!();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jadwalEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.r20),
      backgroundColor: AppColors.background,
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
                // Header Bar
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Jadwal' : 'Tambah Jadwal Agenda',
                      style: AppTextStyles.formTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Container Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.r16,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Agenda
                      _buildInputLabel('Judul Agenda'),
                      TextFormField(
                        controller: _judulController,
                        decoration: _buildInputDecoration(hintText: 'Nama agenda kegiatan'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Judul agenda wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Tanggal
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

                      // Waktu / Jam
                      _buildInputLabel('Waktu'),
                      TextFormField(
                        controller: _jamController,
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
                          hintText: 'Lokasi agenda',
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Kategori Terpadu
                      _buildInputLabel('Kategori Agenda'),
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
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final tglSimpan = _parseTanggalText(_tanggalController.text, _tanggalObj);
                        final hasil = ModelJadwalAdmin(
                          id: widget.jadwalEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          judul: _judulController.text.trim(),
                          tanggal: tglSimpan,
                          jam: _jamController.text.trim(),
                          lokasi: _lokasiController.text.trim(),
                          kategori: _kategoriTerpilih,
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
                        Text('Simpan', style: AppTextStyles.buttonPrimary),
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
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Red Link: Hapus Jadwal (if editing)
                if (isEdit && widget.onHapus != null)
                  Center(
                    child: GestureDetector(
                      onTap: _tampilkanKonfirmasiHapus,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Hapus Jadwal', style: AppTextStyles.linkDanger),
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
      child: Text(label, style: AppTextStyles.inputLabel),
    );
  }

  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.r10,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
