import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../autentikasi/halaman/halaman_login.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/event_card.dart';
import '../../kegiatan/admin/halaman/halaman_detail_kegiatan.dart';
import '../../kegiatan/admin/komponen/komponen_kegiatan_admin.dart';
import '../../kegiatan/anggota/halaman/galeri_pages.dart';
import '../../kegiatan/anggota/layanan/kegiatan_service.dart';
import '../../patungan/layanan/layanan_patungan.dart';
import '../../patungan/model/model_patungan.dart';

// Beranda Tamu: tampilan hanya-lihat untuk warga, tanpa login.
// Menampilkan kegiatan mendatang & selesai beserta rincian dan peta lokasinya.
class HalamanBerandaTamu extends StatelessWidget {
  const HalamanBerandaTamu({super.key});

  void _keLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLogin()));
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

  void _salinRekening(BuildContext context, String nomor) {
    Clipboard.setData(ClipboardData(text: nomor));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor disalin')),
    );
  }

  String _formatNoWa(String input) {
    String clean = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    return clean;
  }

  void _hubungiBendahara(BuildContext context, String kontakWa) async {
    final noWa = _formatNoWa(kontakWa);
    final uri = Uri.parse('https://wa.me/$noWa');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka WhatsApp')),
        );
      }
    }
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
              _buildBagianPatunganTamu(context),
              ..._bagian(context, 'Kegiatan Mendatang', mendatang, 'Belum ada kegiatan mendatang'),
              const SizedBox(height: 8),
              ..._bagian(context, 'Kegiatan Selesai', selesai, 'Belum ada kegiatan selesai'),
              _buildBagianGaleriTamu(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBagianGaleriTamu(BuildContext context) {
    return FutureBuilder<List<AlbumGaleri>>(
      future: KegiatanService.albumFuture(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final albums = snapshot.data ?? [];
        if (albums.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Dokumentasi Kegiatan', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                itemBuilder: (context, i) {
                  final album = albums[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AlbumPage(album: album)),
                    ),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: SizedBox(
                              height: 90,
                              width: double.infinity,
                              child: album.sampul != null
                                  ? Image.network(album.sampul!, fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.primaryLight,
                                      child: const Icon(Icons.collections, color: AppColors.primary, size: 28),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  album.judul,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${album.fotos.length} Foto',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildBagianPatunganTamu(BuildContext context) {
    return StreamBuilder<List<ModelPatungan>>(
      stream: LayananPatungan.streamAktif(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final daftarAktif = snapshot.data ?? [];
        if (daftarAktif.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Patungan', style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            ...daftarAktif.map((item) => _buildKartuPatunganTamu(context, item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildKartuPatunganTamu(BuildContext context, ModelPatungan item) {
    final bool hasTarget = item.targetDana > 0;
    final double persen = hasTarget ? (item.terkumpul / item.targetDana).clamp(0.0, 1.0) : 0.0;
    final bool hasWa = item.kontakWa != null && item.kontakWa!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Row(
            children: [
              CategoryChip(kategori: item.metode),
              const Spacer(),
              const Icon(Icons.volunteer_activism_outlined, size: 20, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.judul, style: AppTextStyles.cardTitle),
          const SizedBox(height: 2),
          const Text(
            'Seikhlasnya, berapa pun sangat berarti',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.primary),
          ),
          if (item.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.deskripsi, style: AppTextStyles.cardSubtitle),
          ],
          const SizedBox(height: 12),

          // Detail Pembayaran
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'No. Rek/HP: ${item.nomorRekening}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      InkWell(
                        onTap: () => _salinRekening(context, item.nomorRekening),
                        borderRadius: AppRadius.r8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.r8,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 12, color: AppColors.textWhite),
                              SizedBox(width: 4),
                              Text('Salin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (item.atasNama.isNotEmpty)
                  Text('A.n: ${item.atasNama}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Target & Progress
          if (hasTarget) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terkumpul ${_formatRupiah(item.terkumpul)} dari ${_formatRupiah(item.targetDana)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.badgeGreenText),
                ),
                Text(
                  '${(persen * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.r10,
              child: LinearProgressIndicator(
                value: persen,
                minHeight: 6,
                backgroundColor: AppColors.primaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (item.batasWaktu != null && item.batasWaktu!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Batas Waktu: ${item.batasWaktu}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Tombol Hubungi Bendahara via WhatsApp
          if (hasWa)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.badgeGreenText,
                  side: const BorderSide(color: AppColors.badgeGreenText),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => _hubungiBendahara(context, item.kontakWa!),
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('Hubungi Bendahara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
        ],
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

