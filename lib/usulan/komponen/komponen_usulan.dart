import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../peta/komponen/komponen_peta.dart';

// Model Usulan Kegiatan (alur bottom-up: anggota mengusulkan, pengurus memutuskan)
class ModelUsulan {
  final String id;
  final String judul;
  final String kategori;
  final String deskripsi;
  final String lokasi;
  final double? lat;
  final double? lng;
  final DateTime tanggalUsulan;
  final String pengusulUid;
  final String pengusulNama;
  final String status; // 'Menunggu' | 'Disetujui' | 'Ditolak'
  final String catatan; // alasan/catatan dari pengurus
  final String diprosesOleh;
  final List<String> dukungan; // uid anggota yang mendukung
  final DateTime dibuat;

  ModelUsulan({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.deskripsi,
    required this.lokasi,
    required this.tanggalUsulan,
    required this.pengusulUid,
    required this.pengusulNama,
    this.lat,
    this.lng,
    this.status = 'Menunggu',
    this.catatan = '',
    this.diprosesOleh = '',
    this.dukungan = const [],
    DateTime? dibuat,
  }) : dibuat = dibuat ?? DateTime.now();

  bool get punyaKoordinat => lat != null && lng != null;

  factory ModelUsulan.dariDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ModelUsulan(
      id: d['id'] ?? doc.id,
      judul: d['judul'] ?? '',
      kategori: d['kategori'] ?? 'Sosial',
      deskripsi: d['deskripsi'] ?? '',
      lokasi: d['lokasi'] ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      tanggalUsulan: DateTime.tryParse(d['tanggalUsulan'] ?? '') ?? DateTime.now(),
      pengusulUid: d['pengusulUid'] ?? '',
      pengusulNama: d['pengusulNama'] ?? 'Anggota',
      status: d['status'] ?? 'Menunggu',
      catatan: d['catatan'] ?? '',
      diprosesOleh: d['diprosesOleh'] ?? '',
      dukungan: List<String>.from(d['dukungan'] ?? const []),
      dibuat: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> keMap() => {
        'id': id,
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'lat': lat,
        'lng': lng,
        'tanggalUsulan': tanggalUsulan.toIso8601String(),
        'pengusulUid': pengusulUid,
        'pengusulNama': pengusulNama,
        'status': status,
        'catatan': catatan,
        'diprosesOleh': diprosesOleh,
        'dukungan': dukungan,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// Halaman form pengajuan usulan kegiatan. Hasilnya dikembalikan lewat Navigator.pop.
class HalamanFormUsulan extends StatefulWidget {
  final String pengusulUid;
  final String pengusulNama;

  const HalamanFormUsulan({super.key, required this.pengusulUid, required this.pengusulNama});

  @override
  State<HalamanFormUsulan> createState() => _HalamanFormUsulanState();
}

class _HalamanFormUsulanState extends State<HalamanFormUsulan> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController();

  String _kategori = 'Sosial';
  late DateTime _tanggal;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now().add(const Duration(days: 7));
    _tanggalController.text = _format(_tanggal);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pilihTanggal() async {
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    if (tgl != null) {
      setState(() {
        _tanggal = tgl;
        _tanggalController.text = _format(tgl);
      });
    }
  }

  void _kirim() {
    if (!_formKey.currentState!.validate()) return;
    final ref = FirebaseFirestore.instance.collection('usulan').doc();
    Navigator.pop(
      context,
      ModelUsulan(
        id: ref.id,
        judul: _judulController.text.trim(),
        kategori: _kategori,
        deskripsi: _deskripsiController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        lat: _lat,
        lng: _lng,
        tanggalUsulan: _tanggal,
        pengusulUid: widget.pengusulUid,
        pengusulNama: widget.pengusulNama,
        dukungan: [widget.pengusulUid], // pengusul otomatis mendukung usulannya sendiri
      ),
    );
  }

  Widget _label(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(teks, style: AppTextStyles.inputLabel),
            const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  InputDecoration _dekorasi(String hint, {IconData? prefix, IconData? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: prefix != null ? Icon(prefix, color: AppColors.primary, size: 18) : null,
      suffixIcon: suffix != null ? Icon(suffix, color: AppColors.primary, size: 20) : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Usulkan Kegiatan', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.r10),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Usulan akan dibahas pengurus. Jika disetujui, usulan otomatis menjadi kegiatan.',
                        style: TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
                    _label('Judul Usulan'),
                    TextFormField(
                      controller: _judulController,
                      decoration: _dekorasi('Contoh: Turnamen Voli Antar-RT'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Judul usulan wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Kategori'),
                    DropdownButtonFormField<String>(
                      value: _kategori,
                      decoration: _dekorasi('Pilih kategori'),
                      items: AppConstants.kDaftarKategoriUtama
                          .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _kategori = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Usulan Tanggal'),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _pilihTanggal,
                      decoration: _dekorasi('dd/mm/yyyy', suffix: Icons.calendar_today_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Tanggal wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Lokasi'),
                    TextFormField(
                      controller: _lokasiController,
                      decoration: _dekorasi('Contoh: Lapangan RW 05', prefix: Icons.location_on_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    PemilihTitikPeta(
                      lat: _lat,
                      lng: _lng,
                      kataKunciAwal: _lokasiController.text.trim(),
                      onChanged: (hasil) {
                        setState(() {
                          _lat = hasil?.lat;
                          _lng = hasil?.lng;
                          if (hasil?.alamat != null && _lokasiController.text.trim().isEmpty) {
                            _lokasiController.text = hasil!.alamat!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Alasan & Rincian Usulan'),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: _dekorasi('Jelaskan tujuan, manfaat, dan kebutuhan kegiatan...'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Rincian usulan wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    elevation: 0,
                  ),
                  onPressed: _kirim,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Kirim Usulan', style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
