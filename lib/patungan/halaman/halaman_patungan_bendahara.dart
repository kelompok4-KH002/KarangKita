import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/category_chip.dart';
import '../layanan/layanan_patungan.dart';
import '../model/model_patungan.dart';

// Halaman Kelola Patungan (Bendahara Eksekusi & Ketua Monitoring)
class HalamanPatunganBendahara extends StatefulWidget {
  final String peran;

  const HalamanPatunganBendahara({
    super.key,
    this.peran = 'Bendahara',
  });

  @override
  State<HalamanPatunganBendahara> createState() => _HalamanPatunganBendaharaState();
}

class _HalamanPatunganBendaharaState extends State<HalamanPatunganBendahara> {
  bool get _isBendahara => AppConstants.normalisasiPeran(widget.peran) == 'Bendahara';
  String _formatRupiah(int nominal) {
    final str = nominal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  void _bukaModalForm([ModelPatungan? editItem]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DialogFormPatungan(editItem: editItem),
    );
  }

  void _konfirmasiHapus(ModelPatungan item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus Patungan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus patungan "${item.judul}"? Tindakan ini tidak dapat dibatalkan.'),
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                await LayananPatungan.hapus(item.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Patungan "${item.judul}" berhasil dihapus.')),
                );
              } catch (e) {
                if (!mounted) return;
                final msg = e is FirebaseException && e.code == 'permission-denied'
                    ? 'Anda tidak punya izin untuk menghapus patungan ini'
                    : 'Gagal menghapus patungan, periksa koneksi internet';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _toggleStatusAktif(ModelPatungan item) async {
    final statusBaru = !item.aktif;
    try {
      await LayananPatungan.ubahStatusAktif(item.id, statusBaru);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusBaru
              ? 'Patungan "${item.judul}" diaktifkan.'
              : 'Patungan "${item.judul}" dinonaktifkan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is FirebaseException && e.code == 'permission-denied'
          ? 'Anda tidak punya izin untuk mengubah status patungan'
          : 'Gagal mengubah status patungan, periksa koneksi internet';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Kelola Patungan'),
      body: StreamBuilder<List<ModelPatungan>>(
        stream: LayananPatungan.streamSemua(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final e = snapshot.error;
            final pesanError = e is FirebaseException && e.code == 'permission-denied'
                ? 'Anda tidak punya izin untuk membaca data patungan'
                : 'Gagal memuat data patungan. Periksa koneksi internet Anda.';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text(pesanError, style: AppTextStyles.statLabel, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final daftar = snapshot.data ?? [];

          if (daftar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volunteer_activism_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text('Belum ada patungan', style: AppTextStyles.formTitle),
                    const SizedBox(height: 6),
                    const Text(
                      'Tekan tombol + di bawah untuk membuat penggalangan dana patungan baru.',
                      style: AppTextStyles.cardSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: daftar.length,
            itemBuilder: (context, i) => _buildKartuPatungan(daftar[i]),
          );
        },
      ),
      floatingActionButton: _isBendahara
          ? FloatingActionButton(
              onPressed: () => _bukaModalForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildKartuPatungan(ModelPatungan item) {
    final bool hasTarget = item.targetDana > 0;
    final double persen = hasTarget ? (item.terkumpul / item.targetDana).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Status Chip & Actions
          Row(
            children: [
              CategoryChip(kategori: item.metode),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.aktif ? AppColors.badgeGreenBg : AppColors.cardBorder,
                  borderRadius: AppRadius.r20,
                ),
                child: Text(
                  item.aktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.aktif ? AppColors.badgeGreenText : AppColors.textMuted,
                  ),
                ),
              ),
              const Spacer(),
              // Toggle Active Switch (Khusus Bendahara)
              if (_isBendahara)
                Switch(
                  value: item.aktif,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => _toggleStatusAktif(item),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Judul
          Text(item.judul, style: AppTextStyles.cardTitle),
          if (item.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.deskripsi, style: AppTextStyles.cardSubtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),

          // Rincian Pembayaran
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.r10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.namaPenyedia.isNotEmpty)
                  Text('Penyedia: ${item.namaPenyedia}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (item.nomorRekening.isNotEmpty)
                  Text('No. Rek/HP: ${item.nomorRekening}', style: const TextStyle(fontSize: 12)),
                if (item.atasNama.isNotEmpty)
                  Text('A.n: ${item.atasNama}', style: const TextStyle(fontSize: 12)),
                if (item.kontakWa != null && item.kontakWa!.isNotEmpty)
                  Text('WA Kontak: ${item.kontakWa}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Informasi Terkumpul & Target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terkumpul:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    _formatRupiah(item.terkumpul),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.badgeGreenText),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Target:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(
                    hasTarget ? _formatRupiah(item.targetDana) : 'Tanpa Target',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),

          // Progress Bar (jika ada target)
          if (hasTarget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: AppRadius.r10,
              child: LinearProgressIndicator(
                value: persen,
                minHeight: 6,
                backgroundColor: AppColors.primaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],

          if (item.batasWaktu != null && item.batasWaktu!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Batas Waktu: ${item.batasWaktu}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Action Buttons: Edit & Hapus (Khusus Bendahara)
          if (_isBendahara)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _bukaModalForm(item),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () => _konfirmasiHapus(item),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus'),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.r8,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text(
                    'Mode Monitoring Ketua',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Dialog Form Tambah / Edit Patungan
class _DialogFormPatungan extends StatefulWidget {
  final ModelPatungan? editItem;

  const _DialogFormPatungan({this.editItem});

  @override
  State<_DialogFormPatungan> createState() => _DialogFormPatunganState();
}

class _DialogFormPatunganState extends State<_DialogFormPatungan> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late TextEditingController _namaPenyediaController;
  late TextEditingController _nomorRekeningController;
  late TextEditingController _atasNamaController;
  late TextEditingController _kontakWaController;
  late TextEditingController _targetDanaController;
  late TextEditingController _terkumpulController;
  late TextEditingController _batasWaktuController;

  String _metodeTerpilih = 'Transfer Bank';
  bool _prosesSimpan = false;

  final List<String> _opsiMetode = ['Transfer Bank', 'E-Wallet', 'Tunai ke Bendahara'];

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _judulController = TextEditingController(text: item?.judul ?? '');
    _deskripsiController = TextEditingController(text: item?.deskripsi ?? '');
    _namaPenyediaController = TextEditingController(text: item?.namaPenyedia ?? '');
    _nomorRekeningController = TextEditingController(text: item?.nomorRekening ?? '');
    _atasNamaController = TextEditingController(text: item?.atasNama ?? '');
    _kontakWaController = TextEditingController(text: item?.kontakWa ?? '');
    _targetDanaController = TextEditingController(text: item != null ? item.targetDana.toString() : '0');
    _terkumpulController = TextEditingController(text: item != null ? item.terkumpul.toString() : '0');
    _batasWaktuController = TextEditingController(text: item?.batasWaktu ?? '');

    if (item != null && _opsiMetode.contains(item.metode)) {
      _metodeTerpilih = item.metode;
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _namaPenyediaController.dispose();
    _nomorRekeningController.dispose();
    _atasNamaController.dispose();
    _kontakWaController.dispose();
    _targetDanaController.dispose();
    _terkumpulController.dispose();
    _batasWaktuController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalBatasWaktu() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _batasWaktuController.text = '${picked.day}-${picked.month}-${picked.year}';
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _prosesSimpan = true);

    try {
      final isEdit = widget.editItem != null;
      final target = int.tryParse(_targetDanaController.text.trim()) ?? 0;
      final terkumpul = int.tryParse(_terkumpulController.text.trim()) ?? 0;

      final patungan = ModelPatungan(
        id: widget.editItem?.id ?? '',
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        metode: _metodeTerpilih,
        namaPenyedia: _namaPenyediaController.text.trim(),
        nomorRekening: _nomorRekeningController.text.trim(),
        atasNama: _atasNamaController.text.trim(),
        kontakWa: _kontakWaController.text.trim().isNotEmpty ? _kontakWaController.text.trim() : null,
        targetDana: target,
        terkumpul: terkumpul,
        batasWaktu: _batasWaktuController.text.trim().isNotEmpty ? _batasWaktuController.text.trim() : null,
        aktif: widget.editItem?.aktif ?? true,
        createdAt: widget.editItem?.createdAt ?? DateTime.now(),
      );

      if (isEdit) {
        await LayananPatungan.ubah(patungan);
      } else {
        await LayananPatungan.tambah(patungan);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Data patungan berhasil diperbarui.' : 'Patungan baru berhasil dibuat.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _prosesSimpan = false);
      final msg = e is FirebaseException && e.code == 'permission-denied'
          ? 'Anda tidak punya izin untuk menyimpan data patungan'
          : 'Gagal menyimpan data patungan, periksa koneksi internet';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editItem != null;
    final butuhNomorRekening = _metodeTerpilih != 'Tunai ke Bendahara';

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
                      isEdit ? 'Edit Data Patungan' : 'Buat Patungan Baru',
                      style: AppTextStyles.formTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Form
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
                      // Judul Patungan
                      _buildLabel('Judul Patungan'),
                      TextFormField(
                        controller: _judulController,
                        decoration: _inputDec('Mis: Patungan Acara 17-an / Duka Cita', Icons.volunteer_activism_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Judul patungan wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Deskripsi
                      _buildLabel('Deskripsi Singkat', trailing: 'Opsional'),
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 2,
                        decoration: _inputDec('Keterangan tujuan patungan', Icons.description_outlined),
                      ),
                      const SizedBox(height: 14),

                      // Metode Pembayaran
                      _buildLabel('Metode Pembayaran'),
                      DropdownButtonFormField<String>(
                        value: _metodeTerpilih,
                        decoration: _inputDec('Pilih Metode Pembayaran'),
                        items: _opsiMetode
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _metodeTerpilih = val);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Metode pembayaran wajib dipilih';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nama Penyedia (BCA, DANA, dll)
                      _buildLabel('Nama Bank / Penyedia E-Wallet', trailing: butuhNomorRekening ? null : 'Opsional'),
                      TextFormField(
                        controller: _namaPenyediaController,
                        decoration: _inputDec(
                          butuhNomorRekening ? 'Contoh: BCA / DANA / Mandiri' : 'Misal: Kas Bendahara RT',
                          Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nomor Rekening / HP
                      if (butuhNomorRekening) ...[
                        _buildLabel('Nomor Rekening / No. HP'),
                        TextFormField(
                          controller: _nomorRekeningController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('Nomor rekening atau HP penerima', Icons.numbers_outlined),
                          validator: (v) {
                            if (butuhNomorRekening && (v == null || v.trim().isEmpty)) {
                              return 'Nomor rekening/HP wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Atas Nama
                      _buildLabel('Atas Nama (Pemilik Rekening)'),
                      TextFormField(
                        controller: _atasNamaController,
                        decoration: _inputDec('Nama lengkap pemilik rekening', Icons.badge_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Atas nama wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Kontak WA opsional
                      _buildLabel('Nomor WhatsApp Kontak', trailing: 'Opsional'),
                      TextFormField(
                        controller: _kontakWaController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDec('081234567890 (Konfirmasi)', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 14),

                      // Target Dana
                      _buildLabel('Target Dana (Rp)', trailing: '0 = Tanpa Target'),
                      TextFormField(
                        controller: _targetDanaController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDec('Contoh: 1000000', Icons.monetization_on_outlined),
                      ),
                      const SizedBox(height: 14),

                      // Jumlah Terkumpul (Diisi Manual)
                      _buildLabel('Jumlah Terkumpul Saat Ini (Rp)', trailing: 'Diisi Manual'),
                      TextFormField(
                        controller: _terkumpulController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDec('Jumlah dana terkumpul sejauh ini', Icons.savings_outlined),
                      ),
                      const SizedBox(height: 14),

                      // Batas Waktu opsional
                      _buildLabel('Batas Waktu Patungan', trailing: 'Opsional'),
                      TextFormField(
                        controller: _batasWaktuController,
                        readOnly: true,
                        onTap: _pilihTanggalBatasWaktu,
                        decoration: _inputDec('Pilih tanggal batas waktu', Icons.calendar_today_outlined).copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _batasWaktuController.clear()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                    onPressed: _prosesSimpan ? null : _simpan,
                    child: _prosesSimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2),
                          )
                        : const Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.inputLabel),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hintText, [IconData? prefixIcon]) {
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
