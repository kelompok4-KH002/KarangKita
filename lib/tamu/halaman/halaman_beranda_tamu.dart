import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../autentikasi/halaman/halaman_login.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/event_card.dart';
import '../../kegiatan/admin/halaman/halaman_detail_kegiatan.dart';
import '../../kegiatan/admin/komponen/komponen_kegiatan_admin.dart';

// Beranda Tamu: tampilan hanya-lihat untuk warga, tanpa login.
// Menampilkan kegiatan mendatang & selesai beserta rincian dan peta lokasinya.
class HalamanBerandaTamu extends StatelessWidget {
  const HalamanBerandaTamu({super.key});

  void _keLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLogin()));
  }

  ModelKegiatanAdmin _dariDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ModelKegiatanAdmin(
      id: (data['id'] ?? doc.id).toString(),
      judul: (data['judul'] ?? '').toString(),
      tanggal: DateTime.tryParse((data['tanggal'] ?? '').toString()) ?? DateTime.now(),
      waktu: (data['waktu'] ?? '').toString(),
      lokasi: (data['lokasi'] ?? '').toString(),
      kategori: (data['kategori'] ?? 'Sosial').toString(),
      deskripsi: (data['deskripsi'] ?? '').toString(),
      manualStatus: data['status'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('KarangKita', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: () => _keLogin(context),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Masuk'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('kegiatan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat kegiatan. Periksa koneksi internet atau aturan Firestore.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.statLabel,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Agenda khusus pengurus tidak ditampilkan ke tamu
          final semua = snapshot.data!.docs
              .where((d) => d.data()['targetPeserta'] != 'Pengurus')
              .map(_dariDoc)
              .toList();
          final mendatang = semua.where((k) => k.status == 'Mendatang').toList()
            ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
          final selesai = semua.where((k) => k.status == 'Selesai').toList()
            ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.r12,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Anda melihat sebagai tamu. Masuk untuk mengusulkan kegiatan dan mengelola data.',
                        style: AppTextStyles.cardSubtitle,
                      ),
                    ),
                    TextButton(onPressed: () => _keLogin(context), child: const Text('Masuk')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._bagian(context, 'Kegiatan Mendatang', mendatang, 'Belum ada kegiatan mendatang'),
              const SizedBox(height: 8),
              ..._bagian(context, 'Kegiatan Selesai', selesai, 'Belum ada kegiatan selesai'),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _bagian(BuildContext context, String judul, List<ModelKegiatanAdmin> daftar, String kosong) {
    return [
      Text(judul, style: AppTextStyles.cardTitle),
      const SizedBox(height: 8),
      if (daftar.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(kosong, style: AppTextStyles.statLabel),
        )
      else
        ...daftar.map(
          (k) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EventCard(
              judul: k.judul,
              tanggal: k.tanggal,
              lokasi: k.lokasi,
              kategori: k.kategori,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HalamanDetailKegiatan(kegiatan: k)),
              ),
            ),
          ),
        ),
    ];
  }
}
