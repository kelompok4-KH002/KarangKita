import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilitas/layanan_cloudinary.dart';
import '../../core/widgets/category_chip.dart';
import '../../notifikasi/layanan/layanan_notifikasi.dart';
import '../model/model_iuran.dart';

// Modul Iuran Sederhana (Manajemen Tagihan & Pembayaran Iuran)
class HalamanIuran extends StatefulWidget {
  final String namaPengguna;
  final String peran;

  const HalamanIuran({
    super.key,
    required this.namaPengguna,
    required this.peran,
  });

  @override
  State<HalamanIuran> createState() => _HalamanIuranState();
}

class _HalamanIuranState extends State<HalamanIuran> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isBendaharaAtauKetua =>
      widget.peran == 'Bendahara' ||
      widget.peran == 'Ketua' ||
      widget.peran == 'Admin' ||
      AppConstants.bolehKelolaKeanggotaan(widget.peran);

  CollectionReference<Map<String, dynamic>> get _colIuran =>
      FirebaseFirestore.instance.collection('iuran');

  CollectionReference<Map<String, dynamic>> get _colPembayaran =>
      FirebaseFirestore.instance.collection('pembayaran');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isBendaharaAtauKetua ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String teks, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), backgroundColor: error ? AppColors.danger : null),
    );
  }

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

  String _formatTanggal(DateTime date) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final bln = date.month >= 1 && date.month <= 12 ? bulan[date.month] : '${date.month}';
    return '${date.day} $bln ${date.year}';
  }

  // ---- Form Buat Tagihan Iuran Baru (Bendahara / Ketua) ----

  Future<void> _tampilkanFormBuatTagihan() async {
    final formKey = GlobalKey<FormState>();
    final judulCtrl = TextEditingController();
    final nominalCtrl = TextEditingController();
    DateTime jatuhTempo = DateTime.now().add(const Duration(days: 14));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buat Tagihan Iuran Baru', style: AppTextStyles.formTitle),
                  const SizedBox(height: 16),
                  Text('Judul Tagihan', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: judulCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Iuran Bulanan November 2026',
                      border: OutlineInputBorder(borderRadius: AppRadius.r10),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  Text('Nominal (Rp)', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nominalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 15000',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(borderRadius: AppRadius.r10),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Nominal wajib diisi';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Masukkan nominal angka yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Jatuh Tempo', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: jatuhTempo,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => jatuhTempo = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: AppRadius.r10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(_formatTanggal(jatuhTempo), style: AppTextStyles.cardTitle),
                        ],
                      ),
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
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context);

                        try {
                          final docRef = _colIuran.doc();
                          final nominal = int.parse(nominalCtrl.text.trim());
                          final tagihanBaru = ModelIuran(
                            id: docRef.id,
                            judul: judulCtrl.text.trim(),
                            nominal: nominal,
                            jatuhTempo: jatuhTempo,
                            dibuatOleh: widget.namaPengguna,
                          );

                          await docRef.set(tagihanBaru.keMap());

                          // Kirim notifikasi tagihan baru
                          await LayananNotifikasi.kirim(
                            penerima: [LayananNotifikasi.kePengurus, LayananNotifikasi.kePeran('Anggota')],
                            judul: 'Tagihan iuran baru',
                            isi: 'Tagihan "${tagihanBaru.judul}" sebesar ${_formatRupiah(nominal)} telah dibuat.',
                            tipe: 'iuran',
                          );

                          _snack('Tagihan iuran berhasil dibuat');
                        } catch (e) {
                          _snack('Gagal membuat tagihan iuran: $e', error: true);
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Simpan Tagihan', style: AppTextStyles.buttonPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Form Pembayaran Iuran (Anggota) ----

  Future<void> _tampilkanFormBayar(ModelIuran iuran) async {
    String metode = 'Transfer';
    XFile? fileFoto;
    final catatanCtrl = TextEditingController();
    bool mengunggah = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konfirmasi Bayar: ${iuran.judul}', style: AppTextStyles.formTitle),
                const SizedBox(height: 4),
                Text('Nominal: ${_formatRupiah(iuran.nominal)}', style: AppTextStyles.cardSubtitle),
                const SizedBox(height: 16),
                Text('Metode Pembayaran', style: AppTextStyles.inputLabel),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Transfer')),
                        selected: metode == 'Transfer',
                        onSelected: mengunggah ? null : (_) => setModalState(() => metode = 'Transfer'),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: metode == 'Transfer' ? AppColors.textWhite : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Tunai')),
                        selected: metode == 'Tunai',
                        onSelected: mengunggah ? null : (_) => setModalState(() => metode = 'Tunai'),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: metode == 'Tunai' ? AppColors.textWhite : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (metode == 'Transfer') ...[
                  Text('Bukti Transfer (JPG/PNG, Maks 5 MB)', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: mengunggah
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                            if (img != null) {
                              setModalState(() => fileFoto = img);
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: AppRadius.r10,
                      ),
                      child: fileFoto != null
                          ? Center(
                              child: Text(
                                'Terpilih: ${fileFoto!.name}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 32, color: AppColors.primary),
                                SizedBox(height: 6),
                                Text('Ketuk untuk unggah foto bukti transfer', style: AppTextStyles.cardSubtitle),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Text('Catatan / Keterangan (Opsional)', style: AppTextStyles.inputLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: catatanCtrl,
                  enabled: !mengunggah,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sudah mentransfer via DANA / Bayar via Mas Bendahara',
                    border: OutlineInputBorder(borderRadius: AppRadius.r10),
                  ),
                ),
                const SizedBox(height: 20),
                if (mengunggah)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                      ),
                      onPressed: () async {
                        if (metode == 'Transfer' && fileFoto == null) {
                          _snack('Silakan pilih foto bukti transfer terlebih dahulu!', error: true);
                          return;
                        }

                        setModalState(() => mengunggah = true);

                        String buktiUrl = '';
                        if (metode == 'Transfer' && fileFoto != null) {
                          final res = await LayananCloudinary.unggahGambar(fileFoto!);
                          if (res != null) {
                            buktiUrl = res['secure_url'] ?? '';
                          } else {
                            setModalState(() => mengunggah = false);
                            _snack('Gagal mengunggah foto bukti ke Cloudinary', error: true);
                            return;
                          }
                        }

                        try {
                          final idPembayaran = 'bayar_${iuran.id}_$_uid';
                          final bayar = ModelPembayaran(
                            id: idPembayaran,
                            iuranId: iuran.id,
                            uidAnggota: _uid,
                            namaAnggota: widget.namaPengguna,
                            metode: metode,
                            buktiUrl: buktiUrl,
                            status: 'Menunggu',
                            catatan: catatanCtrl.text.trim(),
                          );

                          await _colPembayaran.doc(idPembayaran).set(bayar.keMap());

                          // Notifikasi ke Bendahara
                          await LayananNotifikasi.kirim(
                            penerima: [LayananNotifikasi.kePeran('Bendahara')],
                            judul: 'Pembayaran iuran baru',
                            isi: '${widget.namaPengguna} mengajukan konfirmasi pembayaran "${iuran.judul}".',
                            tipe: 'iuran',
                          );

                          if (mounted) Navigator.pop(context);
                          _snack('Konfirmasi pembayaran dikirim ke Bendahara');
                        } catch (e) {
                          setModalState(() => mengunggah = false);
                          _snack('Gagal menyimpan konfirmasi pembayaran: $e', error: true);
                        }
                      },
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Kirim Pembayaran', style: AppTextStyles.buttonPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Verifikasi Pembayaran (Bendahara / Ketua) ----

  Future<void> _verifikasiPembayaran(ModelPembayaran p, String status) async {
    String catatanTolak = '';
    if (status == 'Ditolak') {
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final res = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
          title: const Text('Tolak Pembayaran?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan penolakan',
                border: OutlineInputBorder(borderRadius: AppRadius.r10),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Alasan wajib diisi' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: AppColors.textWhite),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, ctrl.text.trim());
                }
              },
              child: const Text('Tolak'),
            ),
          ],
        ),
      );

      if (res == null) return;
      catatanTolak = res;
    }

    try {
      await _colPembayaran.doc(p.id).update({
        'status': status,
        if (catatanTolak.isNotEmpty) 'catatan': catatanTolak,
      });

      // Notifikasi ke Anggota pengaju
      await LayananNotifikasi.kirim(
        penerima: [LayananNotifikasi.keUid(p.uidAnggota)],
        judul: status == 'Lunas' ? 'Pembayaran iuran dikonfirmasi' : 'Pembayaran iuran ditolak',
        isi: status == 'Lunas'
            ? 'Pembayaran iuran Anda (${p.metode}) telah diverifikasi Lunas.'
            : 'Pembayaran iuran Anda ditolak. Alasan: $catatanTolak',
        tipe: 'iuran',
      );

      _snack(status == 'Lunas' ? 'Pembayaran diverifikasi Lunas' : 'Pembayaran ditolak');
    } catch (e) {
      _snack('Gagal memproses verifikasi: $e', error: true);
    }
  }

  // ---- Detail Bukti Transfer (Modal Preview Foto) ----

  void _lihatBuktiFoto(String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- UI Tampilan ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iuran Taruna', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Daftar Tagihan'),
            if (_isBendaharaAtauKetua) const Tab(text: 'Verifikasi Bayar'),
            const Tab(text: 'Riwayat Saya'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabDaftarTagihan(),
          if (_isBendaharaAtauKetua) _buildTabVerifikasiBendahara(),
          _buildTabRiwayatSaya(),
        ],
      ),
      floatingActionButton: _isBendaharaAtauKetua
          ? FloatingActionButton.extended(
              onPressed: _tampilkanFormBuatTagihan,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              icon: const Icon(Icons.add),
              label: const Text('Buat Tagihan'),
            )
          : null,
    );
  }

  // Tab 1: Daftar Tagihan Iuran
  Widget _buildTabDaftarTagihan() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _colIuran.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapIuran) {
        if (!snapIuran.hasData) return const Center(child: CircularProgressIndicator());

        final daftarIuran = snapIuran.data!.docs.map(ModelIuran.dariDoc).toList();
        if (daftarIuran.isEmpty) {
          return const Center(child: Text('Belum ada tagihan iuran', style: AppTextStyles.statLabel));
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _colPembayaran.snapshots(),
          builder: (context, snapBayar) {
            final mapBayarSaya = <String, ModelPembayaran>{};
            final mapLunasCount = <String, int>{};
            final mapLunasTotal = <String, int>{};

            if (snapBayar.hasData) {
              for (var doc in snapBayar.data!.docs) {
                final p = ModelPembayaran.dariDoc(doc);
                if (p.uidAnggota == _uid) {
                  mapBayarSaya[p.iuranId] = p;
                }
                if (p.status == 'Lunas') {
                  mapLunasCount[p.iuranId] = (mapLunasCount[p.iuranId] ?? 0) + 1;
                }
              }
            }

            // Hitung ringkasan total terkumpul (jika Bendahara)
            int grandTotalTerkumpul = 0;
            if (snapBayar.hasData) {
              for (var doc in snapBayar.data!.docs) {
                final p = ModelPembayaran.dariDoc(doc);
                if (p.status == 'Lunas') {
                  // cari iuran nominal
                  final iuranMatch = daftarIuran.firstWhere(
                    (i) => i.id == p.iuranId,
                    orElse: () => ModelIuran(id: '', judul: '', nominal: 0, jatuhTempo: DateTime.now(), dibuatOleh: ''),
                  );
                  grandTotalTerkumpul += iuranMatch.nominal;
                }
              }
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isBendaharaAtauKetua) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.r16,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.account_balance_wallet, color: AppColors.textWhite),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Dana Terkumpul', style: AppTextStyles.cardSubtitle),
                            const SizedBox(height: 2),
                            Text(
                              _formatRupiah(grandTotalTerkumpul),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...daftarIuran.map((iuran) {
                  final bayarSaya = mapBayarSaya[iuran.id];
                  final statusSaya = bayarSaya?.status ?? 'Belum Bayar';
                  final lunasCount = mapLunasCount[iuran.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.r16,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryChip(kategori: statusSaya),
                            const Spacer(),
                            Text(
                              _formatRupiah(iuran.nominal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(iuran.judul, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Jatuh Tempo: ${_formatTanggal(iuran.jatuhTempo)} • Dibuat oleh ${iuran.dibuatOleh}',
                          style: AppTextStyles.cardSubtitle,
                        ),
                        if (_isBendaharaAtauKetua) ...[
                          const SizedBox(height: 6),
                          Text('$lunasCount anggota telah melunasi', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (bayarSaya != null && bayarSaya.catatan.isNotEmpty)
                              Expanded(
                                child: Text(
                                  'Catatan: ${bayarSaya.catatan}',
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                ),
                              ),
                            if (statusSaya == 'Belum Bayar' || statusSaya == 'Ditolak')
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textWhite,
                                  shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                                ),
                                onPressed: () => _tampilkanFormBayar(iuran),
                                icon: const Icon(Icons.payment, size: 16),
                                label: Text(statusSaya == 'Ditolak' ? 'Bayar Ulang' : 'Bayar Sekarang'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // Tab 2: Verifikasi Pembayaran (Bendahara / Ketua)
  Widget _buildTabVerifikasiBendahara() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _colPembayaran.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapBayar) {
        if (!snapBayar.hasData) return const Center(child: CircularProgressIndicator());

        final daftarBayar = snapBayar.data!.docs.map(ModelPembayaran.dariDoc).toList();
        final menunggu = daftarBayar.where((p) => p.status == 'Menunggu').toList();

        if (menunggu.isEmpty) {
          return const Center(child: Text('Tidak ada pembayaran yang menunggu verifikasi', style: AppTextStyles.statLabel));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: menunggu.length,
          itemBuilder: (context, i) {
            final p = menunggu[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.r16,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryChip(kategori: p.metode),
                      const SizedBox(width: 6),
                      CategoryChip(kategori: p.status),
                      const Spacer(),
                      Text(_formatTanggal(p.dibuat), style: AppTextStyles.cardSubtitle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(p.namaAnggota, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  if (p.catatan.isNotEmpty) Text('Keterangan: ${p.catatan}', style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 10),
                  if (p.metode == 'Transfer' && p.buktiUrl.isNotEmpty) ...[
                    OutlinedButton.icon(
                      onPressed: () => _lihatBuktiFoto(p.buktiUrl),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Lihat Bukti Transfer'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        onPressed: () => _verifikasiPembayaran(p, 'Ditolak'),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Tolak'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.badgeGreenText,
                          foregroundColor: AppColors.textWhite,
                        ),
                        onPressed: () => _verifikasiPembayaran(p, 'Lunas'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('ACC Lunas'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Tab 3: Riwayat Saya
  Widget _buildTabRiwayatSaya() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _colPembayaran.where('uidAnggota', isEqualTo: _uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final me = snap.data!.docs.map(ModelPembayaran.dariDoc).toList()
          ..sort((a, b) => b.dibuat.compareTo(a.dibuat));

        if (me.isEmpty) {
          return const Center(child: Text('Belum ada riwayat konfirmasi pembayaran', style: AppTextStyles.statLabel));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: me.length,
          itemBuilder: (context, i) {
            final p = me[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.r12,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: p.status == 'Lunas'
                        ? AppColors.badgeGreenBg
                        : p.status == 'Ditolak'
                            ? AppColors.dangerBg
                            : AppColors.badgeOrangeBg,
                    child: Icon(
                      p.status == 'Lunas'
                          ? Icons.check_circle_outline
                          : p.status == 'Ditolak'
                              ? Icons.cancel_outlined
                              : Icons.hourglass_empty,
                      color: p.status == 'Lunas'
                          ? AppColors.badgeGreenText
                          : p.status == 'Ditolak'
                              ? AppColors.danger
                              : AppColors.badgeOrangeText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pembayaran ${p.metode}', style: AppTextStyles.cardTitle),
                        const SizedBox(height: 2),
                        Text(_formatTanggal(p.dibuat), style: AppTextStyles.cardSubtitle),
                        if (p.catatan.isNotEmpty)
                          Text('Catatan: ${p.catatan}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  CategoryChip(kategori: p.status),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
