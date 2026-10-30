import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/category_chip.dart';
import '../../notifikasi/layanan/layanan_notifikasi.dart';
import '../../peta/komponen/komponen_peta.dart';
import '../komponen/komponen_usulan.dart';

// Halaman Usulan Kegiatan (bottom-up).
// Semua anggota dapat mengusulkan & mendukung; jajaran pengurus menyetujui atau menolak.
class HalamanUsulan extends StatefulWidget {
  final String namaPengguna;
  final String peran;

  const HalamanUsulan({super.key, required this.namaPengguna, required this.peran});

  @override
  State<HalamanUsulan> createState() => _HalamanUsulanState();
}

class _HalamanUsulanState extends State<HalamanUsulan> {
  static const List<String> _filter = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  static const List<String> _bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _filterTerpilih = 'Semua';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _bisaMenilai => AppConstants.isPengurus(widget.peran);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('usulan');

  String _pesanError(Object e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'Anda tidak punya izin untuk tindakan ini';
    }
    return 'Gagal memproses, periksa koneksi internet';
  }

  void _snack(String teks, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks), backgroundColor: error ? AppColors.danger : null),
    );
  }

  String _tgl(DateTime d) => '${d.day} ${_bulan[d.month]} ${d.year}';

  // ---- Aksi ----

  Future<void> _ajukanUsulan() async {
    final hasil = await Navigator.push<ModelUsulan>(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanFormUsulan(pengusulUid: _uid, pengusulNama: widget.namaPengguna),
      ),
    );
    if (hasil == null) return;

    try {
      await _col.doc(hasil.id).set(hasil.keMap());
      await LayananNotifikasi.kirim(
        penerima: [LayananNotifikasi.kePengurus],
        judul: 'Usulan kegiatan baru',
        isi: '${widget.namaPengguna} mengusulkan "${hasil.judul}".',
        tipe: 'usulan',
      );
      _snack('Usulan berhasil dikirim ke pengurus');
    } catch (e) {
      _snack(_pesanError(e), error: true);
    }
  }

  Future<void> _toggleDukungan(ModelUsulan u) async {
    final sudah = u.dukungan.contains(_uid);
    try {
      await _col.doc(u.id).update({
        'dukungan': sudah ? FieldValue.arrayRemove([_uid]) : FieldValue.arrayUnion([_uid]),
      });
    } catch (e) {
      _snack(_pesanError(e), error: true);
    }
  }

  // Dialog catatan. Saat menolak, catatan wajib diisi.
  Future<String?> _mintaCatatan({required String judul, required bool wajib, required String tombol, Color? warna}) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: wajib ? 'Tuliskan alasan penolakan' : 'Catatan untuk pengusul (opsional)',
              border: OutlineInputBorder(borderRadius: AppRadius.r10),
            ),
            validator: (v) => wajib && (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: warna ?? AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(tombol),
          ),
        ],
      ),
    );
  }

  Future<void> _setujui(ModelUsulan u) async {
    final catatan = await _mintaCatatan(
      judul: 'Setujui usulan?',
      wajib: false,
      tombol: 'Setujui',
      warna: AppColors.badgeGreenText,
    );
    if (catatan == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final idKegiatan = 'usulan_${u.id}';
      final batch = db.batch();

      // Usulan yang disetujui langsung menjadi kegiatan (skema sama dengan halaman Kegiatan)
      batch.set(
        db.collection('kegiatan').doc(idKegiatan),
        {
          'id': idKegiatan,
          'judul': u.judul,
          'waktu': '07:30 WIB',
          'lokasi': u.lokasi,
          'kategori': u.kategori,
          'deskripsi': u.deskripsi,
          'status': 'Mendatang',
          'tanggal': u.tanggalUsulan.toIso8601String(),
          'lat': u.lat,
          'lng': u.lng,
          'usulanId': u.id,
          'diusulkanOleh': u.pengusulNama,
        },
        SetOptions(merge: true),
      );
      batch.update(_col.doc(u.id), {
        'status': 'Disetujui',
        'catatan': catatan,
        'diprosesOleh': widget.namaPengguna,
        'kegiatanId': idKegiatan,
      });
      await batch.commit();

      await LayananNotifikasi.kirim(
        penerima: [LayananNotifikasi.keUid(u.pengusulUid)],
        judul: 'Usulan Anda disetujui',
        isi: '"${u.judul}" disetujui oleh ${widget.namaPengguna} dan masuk ke daftar kegiatan.',
        tipe: 'usulan',
      );
      _snack('Usulan disetujui dan ditambahkan ke daftar kegiatan');
    } catch (e) {
      _snack(_pesanError(e), error: true);
    }
  }

  Future<void> _tolak(ModelUsulan u) async {
    final alasan = await _mintaCatatan(
      judul: 'Tolak usulan?',
      wajib: true,
      tombol: 'Tolak',
      warna: AppColors.danger,
    );
    if (alasan == null) return;

    try {
      await _col.doc(u.id).update({
        'status': 'Ditolak',
        'catatan': alasan,
        'diprosesOleh': widget.namaPengguna,
      });
      await LayananNotifikasi.kirim(
        penerima: [LayananNotifikasi.keUid(u.pengusulUid)],
        judul: 'Usulan Anda ditolak',
        isi: '"${u.judul}" ditolak. Alasan: $alasan',
        tipe: 'usulan',
      );
      _snack('Usulan ditolak');
    } catch (e) {
      _snack(_pesanError(e), error: true);
    }
  }

  Future<void> _hapus(ModelUsulan u) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Batalkan usulan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Usulan "${u.judul}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.textWhite,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await _col.doc(u.id).delete();
      _snack('Usulan dihapus');
    } catch (e) {
      _snack(_pesanError(e), error: true);
    }
  }

  void _lihatDetail(ModelUsulan u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryChip(kategori: u.status),
                  const SizedBox(width: 6),
                  CategoryChip(kategori: u.kategori),
                ],
              ),
              const SizedBox(height: 12),
              Text(u.judul, style: AppTextStyles.formTitle),
              const SizedBox(height: 4),
              Text('Diusulkan oleh ${u.pengusulNama}', style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 14),
              _barisInfo(Icons.event_outlined, 'Usulan tanggal ${_tgl(u.tanggalUsulan)}'),
              _barisInfo(Icons.location_on_outlined, u.lokasi),
              _barisInfo(Icons.thumb_up_alt_outlined, '${u.dukungan.length} dukungan'),
              const SizedBox(height: 8),
              const Text('Rincian', style: AppTextStyles.inputLabel),
              const SizedBox(height: 4),
              Text(u.deskripsi, style: AppTextStyles.cardSubtitle),
              if (u.catatan.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: u.status == 'Ditolak' ? AppColors.dangerBg : AppColors.badgeGreenBg,
                    borderRadius: AppRadius.r10,
                  ),
                  child: Text(
                    'Catatan ${u.diprosesOleh.isEmpty ? 'pengurus' : u.diprosesOleh}: ${u.catatan}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
              if (u.punyaKoordinat) ...[
                const SizedBox(height: 16),
                const Text('Lokasi di Peta', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                PetaPratinjau(lat: u.lat!, lng: u.lng!, tinggi: 200),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisInfo(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(ikon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: AppTextStyles.cardTitle)),
        ],
      ),
    );
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: _filter.map((f) {
                final aktif = f == _filterTerpilih;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: aktif,
                    onSelected: (_) => setState(() => _filterTerpilih = f),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: aktif ? AppColors.textWhite : AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surface,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        snapshot.error is FirebaseException &&
                                (snapshot.error as FirebaseException).code == 'permission-denied'
                            ? 'Anda tidak punya izin untuk membaca usulan'
                            : 'Gagal memuat usulan, periksa koneksi internet',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.statLabel,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final semua = snapshot.data!.docs.map(ModelUsulan.dariDoc).toList()
                  ..sort((a, b) => b.dibuat.compareTo(a.dibuat));
                final daftar = _filterTerpilih == 'Semua'
                    ? semua
                    : semua.where((u) => u.status == _filterTerpilih).toList();

                if (daftar.isEmpty) {
                  return Center(
                    child: Text(
                      semua.isEmpty ? 'Belum ada usulan kegiatan' : 'Tidak ada usulan berstatus $_filterTerpilih',
                      style: AppTextStyles.statLabel,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) => _kartuUsulan(daftar[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajukanUsulan,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('Usulkan'),
      ),
    );
  }

  Widget _kartuUsulan(ModelUsulan u) {
    final menunggu = u.status == 'Menunggu';
    final sudahDukung = u.dukungan.contains(_uid);
    final milikSaya = u.pengusulUid == _uid;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _lihatDetail(u),
      child: Container(
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
                CategoryChip(kategori: u.status),
                const SizedBox(width: 6),
                CategoryChip(kategori: u.kategori),
                const Spacer(),
                if (u.punyaKoordinat) const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(u.judul, style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text(
              '${u.pengusulNama} • ${_tgl(u.tanggalUsulan)} • ${u.lokasi}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardSubtitle,
            ),
            const SizedBox(height: 6),
            Text(u.deskripsi, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.cardSubtitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Dukungan anggota
                InkWell(
                  onTap: menunggu ? () => _toggleDukungan(u) : null,
                  borderRadius: AppRadius.r8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: sudahDukung ? AppColors.primary : AppColors.primaryLight,
                      borderRadius: AppRadius.r8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sudahDukung ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                          size: 15,
                          color: sudahDukung ? AppColors.textWhite : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${u.dukungan.length} dukung',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sudahDukung ? AppColors.textWhite : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (menunggu && milikSaya)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => _hapus(u),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Batalkan'),
                  ),
                if (menunggu && _bisaMenilai) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () => _tolak(u),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Tolak'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.badgeGreenText,
                      foregroundColor: AppColors.textWhite,
                      elevation: 0,
                    ),
                    onPressed: () => _setujui(u),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Setujui'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
