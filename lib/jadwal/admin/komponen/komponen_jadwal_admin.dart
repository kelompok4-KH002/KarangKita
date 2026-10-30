import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';

// Model Data Jadwal Admin Terpadu Sesuai Mockup
class ModelJadwalAdmin {
  final String id;
  final String judul;
  final String targetPeserta; // 'Pengurus' atau 'Umum / Warga'
  final DateTime tanggal;
  final String waktuMulai;
  final String waktuSelesai;
  final String lokasi;
  final String catatan;
  final String kategori;

  ModelJadwalAdmin({
    required this.id,
    required this.judul,
    this.targetPeserta = 'Pengurus',
    required this.tanggal,
    this.waktuMulai = '19:30 WIB',
    this.waktuSelesai = '21:00 WIB',
    required this.lokasi,
    this.catatan = '',
    this.kategori = 'Rapat',
  });

  String get jam => waktuSelesai.isNotEmpty && waktuSelesai != waktuMulai
      ? '$waktuMulai - $waktuSelesai'
      : waktuMulai;
}

// Data Awal Kosong (Murni dari Database Cloud Firestore)
final List<ModelJadwalAdmin> dataJadwalAdminAwal = [];

// Halaman Penuh Form Tambah / Edit Jadwal Admin Presisi Sesuai Mockup (`admin_pengurus_edit_jadwal.png` & `admin_pengurus_tambah_jadwal.png`)
class HalamanFormJadwalAdmin extends StatefulWidget {
  final ModelJadwalAdmin? jadwalEdit;
  final Function(ModelJadwalAdmin) onSimpan;
  final VoidCallback? onHapus;

  const HalamanFormJadwalAdmin({
    super.key,
    this.jadwalEdit,
    required this.onSimpan,
    this.onHapus,
  });

  @override
  State<HalamanFormJadwalAdmin> createState() => _HalamanFormJadwalAdminState();
}

class _HalamanFormJadwalAdminState extends State<HalamanFormJadwalAdmin> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _tanggalController;
  late TextEditingController _waktuMulaiController;
  late TextEditingController _waktuSelesaiController;
  late TextEditingController _lokasiController;
  late TextEditingController _catatanController;

  late String _targetPeserta;
  late DateTime _tanggalObj;

  @override
  void initState() {
    super.initState();
    final edit = widget.jadwalEdit;
    _tanggalObj = edit?.tanggal ?? DateTime.now();

    _judulController = TextEditingController(text: edit?.judul ?? '');
    _tanggalController = TextEditingController(text: _formatTanggalIndonesiaDisplay(_tanggalObj));
    _waktuMulaiController = TextEditingController(text: edit?.waktuMulai ?? '19:30 WIB');
    _waktuSelesaiController = TextEditingController(text: edit?.waktuSelesai ?? '21:00 WIB');
    _lokasiController = TextEditingController(text: edit?.lokasi ?? '');
    _catatanController = TextEditingController(text: edit?.catatan ?? '');

    _targetPeserta = edit?.targetPeserta ?? 'Pengurus';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _tanggalController.dispose();
    _waktuMulaiController.dispose();
    _waktuSelesaiController.dispose();
    _lokasiController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String _formatTanggalIndonesiaDisplay(DateTime date) {
    const namaBulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final bln = date.month >= 1 && date.month <= 12 ? namaBulan[date.month] : '${date.month}';
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr $bln ${date.year}';
  }

  // Buka Pop-up Calendar Picker
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
        _tanggalController.text = _formatTanggalIndonesiaDisplay(tgl);
      });
    }
  }

  // Buka Pop-up Time Picker
  Future<void> _pilihWaktu(TextEditingController controller) async {
    final wkt = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 30),
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
        controller.text = '$jamStr:$menitStr WIB';
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
      final hasil = ModelJadwalAdmin(
        id: widget.jadwalEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        judul: _judulController.text.trim(),
        targetPeserta: _targetPeserta,
        tanggal: _tanggalObj,
        waktuMulai: _waktuMulaiController.text.trim(),
        waktuSelesai: _waktuSelesaiController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        catatan: _catatanController.text.trim(),
        kategori: 'Rapat',
      );
      widget.onSimpan(hasil);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jadwalEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal', style: AppTextStyles.headerTitle),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Sub-header (Khusus mode Tambah Baru)
              if (!isEdit) ...[
                Text(
                  'FORMULIR PENGURUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Buat Agenda Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: AppRadius.r12,
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Agenda yang ditambahkan akan otomatis tersinkronisasi ke kalender kegiatan pengurus dan warga terpilih.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Card Container Form Fields
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
                    // Field 1: Nama Agenda *
                    Row(
                      children: [
                        Text('Nama Agenda', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _judulController,
                      decoration: _buildInputDecoration(hintText: 'Contoh: Rapat Pleno Bulanan Pengurus'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama agenda wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Target Peserta * (Segmented Toggle Pills)
                    Row(
                      children: [
                        Text('Target Peserta', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _targetPeserta = 'Pengurus'),
                            borderRadius: AppRadius.r12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _targetPeserta == 'Pengurus' ? AppColors.primary : AppColors.background,
                                borderRadius: AppRadius.r12,
                                border: Border.all(
                                  color: _targetPeserta == 'Pengurus' ? AppColors.primary : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 18,
                                    color: _targetPeserta == 'Pengurus' ? AppColors.textWhite : AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pengurus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _targetPeserta == 'Pengurus' ? AppColors.textWhite : AppColors.textPrimary,
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
                            onTap: () => setState(() => _targetPeserta = 'Umum / Warga'),
                            borderRadius: AppRadius.r12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _targetPeserta == 'Umum / Warga' ? AppColors.primary : AppColors.background,
                                borderRadius: AppRadius.r12,
                                border: Border.all(
                                  color: _targetPeserta == 'Umum / Warga' ? AppColors.primary : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 18,
                                    color: _targetPeserta == 'Umum / Warga' ? AppColors.textWhite : AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Umum / Warga',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _targetPeserta == 'Umum / Warga' ? AppColors.textWhite : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Tanggal Pelaksanaan *
                    Row(
                      children: [
                        Text('Tanggal Pelaksanaan', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _pilihTanggal,
                      decoration: _buildInputDecoration(
                        hintText: 'Pilih tanggal pelaksanaan',
                        prefixIcon: Icons.calendar_today_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Tanggal wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 4: Waktu Mulai & Waktu Selesai (2 Kolom Berdampingan)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Waktu Mulai', style: AppTextStyles.inputLabel),
                                  const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _waktuMulaiController,
                                readOnly: true,
                                onTap: () => _pilihWaktu(_waktuMulaiController),
                                decoration: _buildInputDecoration(
                                  hintText: '19:30 WIB',
                                  prefixIcon: Icons.access_time_outlined,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Waktu mulai wajib dipilih' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Waktu Selesai', style: AppTextStyles.inputLabel),
                                  const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _waktuSelesaiController,
                                readOnly: true,
                                onTap: () => _pilihWaktu(_waktuSelesaiController),
                                decoration: _buildInputDecoration(
                                  hintText: '21:00 WIB',
                                  prefixIcon: Icons.hourglass_empty_outlined,
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Waktu selesai wajib dipilih' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field 5: Lokasi Tempat *
                    Row(
                      children: [
                        Text('Lokasi Tempat', style: AppTextStyles.inputLabel),
                        const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: _buildInputDecoration(
                        hintText: 'Balai Warga RW 05 / Ruang Rapat',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi tempat wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Field 6: Catatan / Agenda Rapat (Opsional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Catatan / Agenda Rapat', style: AppTextStyles.inputLabel),
                        const Text('Opsional', style: AppTextStyles.cardSubtitle),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 3,
                      decoration: _buildInputDecoration(
                        hintText: 'Ringkasan poin pembahasan, perlengkapan yang perlu dibawa, dll...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Button Primary: Simpan (✓)
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
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 8),
                      Text('Simpan', style: AppTextStyles.buttonPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Button Outlined: Batal (✕)
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Link Merah: Hapus Jadwal (saat mode Edit)
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
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primary, size: 18) : null,
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
class DialogTambahEditJadwalAdmin extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return HalamanFormJadwalAdmin(
      jadwalEdit: jadwalEdit,
      onSimpan: onSimpan,
      onHapus: onHapus,
    );
  }
}
