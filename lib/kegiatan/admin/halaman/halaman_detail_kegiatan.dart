import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../peta/komponen/komponen_peta.dart';
import '../../anggota/halaman/galeri_pages.dart';
import '../../anggota/layanan/kegiatan_service.dart';
import '../komponen/komponen_kegiatan_admin.dart';

// Halaman rincian kegiatan lengkap dengan peta lokasi
class HalamanDetailKegiatan extends StatelessWidget {
  final ModelKegiatanAdmin kegiatan;

  const HalamanDetailKegiatan({super.key, required this.kegiatan});

  static const List<String> _bulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final tgl = kegiatan.tanggal;
    final isSelesai = kegiatan.status == 'Selesai';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rincian Kegiatan', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelesai ? AppColors.badgeGreenBg : AppColors.badgeBlueBg,
                      borderRadius: AppRadius.r6,
                    ),
                    child: Text(
                      isSelesai ? 'Selesai' : 'Mendatang',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelesai ? AppColors.badgeGreenText : AppColors.badgeBlueText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CategoryChip(kategori: kegiatan.kategori),
                ],
              ),
              const SizedBox(height: 12),
              Text(kegiatan.judul, style: AppTextStyles.formTitle),
              const SizedBox(height: 14),
              _baris(Icons.event_outlined, '${tgl.day} ${_bulan[tgl.month]} ${tgl.year}'),
              _baris(Icons.access_time_outlined, kegiatan.waktu),
              _baris(Icons.location_on_outlined, kegiatan.lokasi),
              const SizedBox(height: 8),
              const Text('Deskripsi', style: AppTextStyles.inputLabel),
              const SizedBox(height: 4),
              Text(kegiatan.deskripsi.isEmpty ? '-' : kegiatan.deskripsi, style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 18),
              const Text('Lokasi di Peta', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              if (kegiatan.punyaKoordinat)
                PetaPratinjau(lat: kegiatan.lat!, lng: kegiatan.lng!, tinggi: 220)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadius.r10,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text(
                    'Titik peta belum ditandai untuk kegiatan ini. Pengurus dapat menambahkannya lewat Edit Kegiatan.',
                    style: AppTextStyles.cardSubtitle,
                  ),
                ),
              const SizedBox(height: 18),
              _buildSeksiFotoDokumentasi(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeksiFotoDokumentasi(BuildContext context) {
    return StreamBuilder<List<AlbumGaleri>>(
      stream: KegiatanService.albumStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final albums = snapshot.data ?? [];
        final String judulLower = kegiatan.judul.trim().toLowerCase();

        // Cari album yang judul/albumId-nya mirip atau persis dengan kegiatan ini
        final List<GaleriFoto> fotosCocok = [];
        for (final album in albums) {
          final aJudul = album.judul.trim().toLowerCase();
          final aId = album.albumId.trim().toLowerCase();
          if (aJudul.contains(judulLower) || judulLower.contains(aJudul) || aId == kegiatan.id) {
            fotosCocok.addAll(album.fotos);
          }
        }

        // Pencocokan ketat: HANYA gunakan foto dari album yang benar-benar cocok dengan kegiatan ini
        final List<GaleriFoto> fotoTampil = fotosCocok;

        if (fotoTampil.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foto Dokumentasi Kegiatan', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.r10,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  'Belum ada foto dokumentasi yang diunggah untuk kegiatan ini.',
                  style: AppTextStyles.cardSubtitle,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Foto Dokumentasi Kegiatan', style: AppTextStyles.inputLabel),
                const Spacer(),
                Text('${fotoTampil.length} Foto', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fotoTampil.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, i) {
                final foto = fotoTampil[i];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FotoViewerPage(fotos: fotoTampil, index: i),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.r8,
                    child: Image.network(
                      foto.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _baris(IconData ikon, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: AppTextStyles.cardTitle)),
        ],
      ),
    );
  }
}
