import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';

// Model Data Kegiatan Admin
class ModelKegiatanAdmin {
  final String id;
  final String judul;
  final DateTime tanggal;
  final String waktu;
  final String lokasi;
  final String kategori;
  final String deskripsi;
  final String? manualStatus; // 'Mendatang' atau 'Selesai'

  ModelKegiatanAdmin({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.waktu,
    required this.lokasi,
    required this.kategori,
    required this.deskripsi,
    this.manualStatus,
  });

  // Status 'Mendatang' vs 'Selesai' (Mendahulukan manualStatus, fallback ke kalkulasi tanggal relatif)
  String get status {
    if (manualStatus != null && manualStatus!.isNotEmpty) {
      return manualStatus!;
    }
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tglStart = DateTime(tanggal.year, tanggal.month, tanggal.day);
    if (tglStart.isAfter(todayStart) || tglStart.isAtSameMomentAs(todayStart)) {
      return 'Mendatang';
    }
    return 'Selesai';
  }
}

// Data Awal Kosong (Murni dari Cloud Firestore Database)
final List<ModelKegiatanAdmin> dataKegiatanAwal = [];

// Halaman Penuh Form Tambah / Edit Kegiatan Presisi Sesuai Mockup (`admin_pengurus_edit_kegiatan.png`)
class HalamanFormKegiatanAdmin extends StatefulWidget {
  final ModelKegiatanAdmin? kegiatanEdit;
  final Function(ModelKegiatanAdmin) onSimpan;
  final VoidCallback? onHapus;

  const HalamanFormKegiatanAdmin({
    super.key,
    this.kegiatanEdit,
    required this.onSimpan,
    this.onHapus,
  });

  @override
  State<HalamanFormKegiatanAdmin> createState() => _HalamanFormKegiatanAdminState();
}

class _HalamanFormKegiatanAdminState extends State<HalamanFormKegiatanAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _waktuController;
  late TextEditingController _lokasiController;
  late TextEditingController _deskripsiController;

  late String _kategoriTerpilih;
  late String _statusTerpilih;
  late DateTime _tanggalObj;

  @override
  void initState() {
    super.initState();
    final edit = widget.kegiatanEdit;
    _tanggalObj = edit?.tanggal ?? DateTime.now();

    _judulController = TextEditingController(text: edit?.judul ?? '');
    _tanggalController = TextEditingController(text: _formatTanggalDisplay(_tanggalObj));
    _waktuController = TextEditingController(text: edit?.waktu ?? '07:30 WIB');
    _lokasiController = TextEditingController(text: edit?.lokasi ?? '');
    _deskripsiController = TextEditingController(text: edit?.deskripsi ?? '');

    final kat = edit?.kategori ?? 'Sosial';
    _kategoriTerpilih = AppConstants.kDaftarKategoriUtama.contains(kat) ? kat : 'Sosial';
    _statusTerpilih = edit?.status ?? 'Mendatang';
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

  String _formatTanggalDisplay(DateTime date) {
    final mStr = date.month.toString().padLeft(2, '0');
    final dStr = date.day.toString().padLeft(2, '0');
    return '$mStr/$dStr/${date.year}';
  }

  Future<void> _pilihTanggal() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggalObj,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
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
        _tanggalController.text = _formatTanggalDisplay(tgl);
      });
    }
  }

  Future<void> _pilihWaktu() async {
    final wkt = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
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

  void _tampilkanKonfirmasiHapus() {
    final namaKegiatan = widget.kegiatanEdit?.judul ?? 'kegiatan ini';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus kegiatan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus kegiatan "$namaKegiatan"? Tindakan ini tidak dapat dibatalkan.'),
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
              Navigator.pop(context); // Kembali dari halaman form
              if (widget.onHapus != null) widget.onHapus!();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _simpanForm() {
    if (_formKey.currentState!.validate()) {
      final hasil = ModelKegiatanAdmin(
        id: widget.kegiatanEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        judul: _judulController.text.trim(),
        tanggal: _tanggalObj,
        waktu: _waktuController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        kategori: _kategoriTerpilih,
        deskripsi: _deskripsiController.text.trim(),
        manualStatus: _statusTerpilih,
      );
      widget.onSimpan(hasil);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.kegiatanEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kegiatan' : 'Tambah Kegiatan Baru', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 20, color: AppColors.textWhite),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Container
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
                    // Field 1: Nama Kegiatan *
                    Row(
                      children: [
                        Text('Nama Kegiatan', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulController,
                      decoration: _buildInputDecoration(hintText: 'Contoh: Kerja Bakti Lingkungan RW 05'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama kegiatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Kategori Kegiatan *
                    Row(
                      children: [
                        Text('Kategori Kegiatan', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 16),

                    // Field 3: Tanggal *
                    Row(
                      children: [
                        Text('Tanggal', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _pilihTanggal,
                      decoration: _buildInputDecoration(
                        hintText: 'mm/dd/yyyy',
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Tanggal wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 4: Waktu *
                    Row(
                      children: [
                        Text('Waktu', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _waktuController,
                      readOnly: true,
                      onTap: _pilihWaktu,
                      decoration: _buildInputDecoration(
                        hintText: '07:30 WIB',
                        suffixIcon: Icons.access_time_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Waktu wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 5: Lokasi *
                    Row(
                      children: [
                        Text('Lokasi', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: _buildInputDecoration(
                        hintText: 'Area Lingkungan RW 05 (RT 01 - 04)',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 6: Deskripsi *
                    Row(
                      children: [
                        Text('Deskripsi', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: _buildInputDecoration(
                        hintText: 'Tuliskan rincian, agenda, perlengkapan yang perlu dibawa...',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 7: Status Kegiatan * (Segmented Toggle Pills)
                    Row(
                      children: [
                        Text('Status Kegiatan', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _statusTerpilih = 'Mendatang'),
                            borderRadius: AppRadius.r12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _statusTerpilih == 'Mendatang' ? AppColors.surface : AppColors.background,
                                borderRadius: AppRadius.r12,
                                border: Border.all(
                                  color: _statusTerpilih == 'Mendatang' ? AppColors.primary : AppColors.cardBorder,
                                  width: _statusTerpilih == 'Mendatang' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.badgeOrangeText,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mendatang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _statusTerpilih == 'Mendatang' ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _statusTerpilih = 'Selesai'),
                            borderRadius: AppRadius.r12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _statusTerpilih == 'Selesai' ? AppColors.surface : AppColors.background,
                                borderRadius: AppRadius.r12,
                                border: Border.all(
                                  color: _statusTerpilih == 'Selesai' ? AppColors.primary : AppColors.cardBorder,
                                  width: _statusTerpilih == 'Selesai' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.badgeGreenText,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selesai',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _statusTerpilih == 'Selesai' ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Button Primary: Simpan (💾)
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
                  onPressed: _simpanForm,
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

              // Red Link: Hapus Kegiatan (if editing)
              if (isEdit && widget.onHapus != null)
                Center(
                  child: GestureDetector(
                    onTap: _tampilkanKonfirmasiHapus,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                        SizedBox(width: 6),
                        Text('Hapus Kegiatan', style: AppTextStyles.linkDanger),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: AppColors.primary, size: 20) : null,
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

// Wrapper Dialog Legacy untuk Kompatibilitas
class DialogTambahEditKegiatan extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return HalamanFormKegiatanAdmin(
      kegiatanEdit: kegiatanEdit,
      onSimpan: onSimpan,
      onHapus: onHapus,
    );
  }
}
