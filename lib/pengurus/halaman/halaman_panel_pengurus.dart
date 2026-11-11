import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/category_chip.dart';
import '../../iuran/halaman/halaman_iuran.dart';
import '../../iuran/model/model_iuran.dart';
import '../../kegiatan/admin/halaman/halaman_anggota_admin.dart';
import '../../usulan/halaman/halaman_usulan.dart';

// Halaman Panel Pengurus Gabungan (Ketua, Sekretaris, Bendahara)
class HalamanPanelPengurus extends StatelessWidget {
  final String namaPengguna;
  final String peran;

  const HalamanPanelPengurus({
    super.key,
    required this.namaPengguna,
    required this.peran,
  });

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

  @override
  Widget build(BuildContext context) {
    final bool isPengurusInti = AppConstants.isPengurusInti(peran);

    return Scaffold(
      appBar: const AppHeader(title: 'Panel Pengurus'),
      body: !isPengurusInti
          ? _buildAksesDitolak()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildKontenPengurus(context),
                ],
              ),
            ),
    );
  }

  // Tampilan jika pengguna bukan Pengurus Inti
  Widget _buildAksesDitolak() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Khusus pengurus inti',
              style: AppTextStyles.formTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini hanya dapat diakses oleh Ketua, Sekretaris, dan Bendahara.',
              style: AppTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Kartu Header Profil & Jabatan Pengurus
  Widget _buildHeaderCard() {
    final String peranNormalized = AppConstants.normalisasiPeran(peran);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.r16,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.admin_panel_settings,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaPengguna,
                  style: AppTextStyles.heroGreeting.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Jabatan: ',
                      style: AppTextStyles.heroDate,
                    ),
                    CategoryChip(kategori: peranNormalized),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bagian-bagian Panel Pengurus Berdasarkan Peran
  Widget _buildKontenPengurus(BuildContext context) {
    final String peranNorm = AppConstants.normalisasiPeran(peran);
    final bool isKetuaOrAdmin =
        peranNorm == 'Ketua' || peranNorm == 'Admin' || AppConstants.bolehKelolaKeanggotaan(peran);
    final bool isSekretaris = peranNorm == 'Sekretaris';
    final bool isBendahara = peranNorm == 'Bendahara';

    final bool showUsulan = isSekretaris || isKetuaOrAdmin;
    final bool showKeuangan = isBendahara || isKetuaOrAdmin;
    final bool showKeanggotaan = isKetuaOrAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showUsulan) ...[
          _buildBagianUsulan(context, isSekretaris: isSekretaris),
          const SizedBox(height: 16),
        ],
        if (showKeuangan) ...[
          _buildBagianKeuangan(context),
          const SizedBox(height: 16),
        ],
        if (showKeanggotaan) ...[
          _buildBagianKeanggotaan(context),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // Bagian a: Usulan Kegiatan (Sekretaris & Ketua)
  Widget _buildBagianUsulan(BuildContext context, {required bool isSekretaris}) {
    final statusDisasar = isSekretaris ? 'Menunggu' : 'Diteruskan';
    final labelRingkasan = isSekretaris
        ? 'Usulan Menunggu Tinjauan'
        : 'Usulan Menunggu ACC Ketua';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Usulan Kegiatan', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('usulan').snapshots(),
            builder: (context, snapshot) {
              String countText = '-';
              if (snapshot.hasError) {
                countText = '-';
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                countText = '...';
              } else if (snapshot.hasData) {
                final count = snapshot.data!.docs
                    .where((doc) => (doc.data()['status'] ?? '') == statusDisasar)
                    .length;
                countText = '$count';
              }

              return Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.r12,
                ),
                child: Row(
                  children: [
                    Text(countText, style: AppTextStyles.statCount),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(labelRingkasan, style: AppTextStyles.statLabel),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: const AppHeader(title: 'Usulan Kegiatan'),
                      body: HalamanUsulan(
                        namaPengguna: namaPengguna,
                        peran: peran,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Buka Usulan', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // Bagian b: Keuangan & Iuran (Bendahara & Ketua)
  Widget _buildBagianKeuangan(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Keuangan & Iuran', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('iuran').snapshots(),
            builder: (context, snapIuran) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('pembayaran').snapshots(),
                builder: (context, snapBayar) {
                  String countMenunggu = '-';
                  String totalTerkumpulText = 'Rp -';

                  if (!snapIuran.hasError &&
                      !snapBayar.hasError &&
                      snapIuran.hasData &&
                      snapBayar.hasData) {
                    final listIuran = snapIuran.data!.docs.map(ModelIuran.dariDoc).toList();
                    final listBayar = snapBayar.data!.docs.map(ModelPembayaran.dariDoc).toList();

                    final int pendingCount =
                        listBayar.where((p) => p.status == 'Menunggu').length;
                    countMenunggu = '$pendingCount';

                    int total = 0;
                    for (final p in listBayar) {
                      if (p.status == 'Lunas') {
                        final iuranMatch = listIuran.firstWhere(
                          (i) => i.id == p.iuranId,
                          orElse: () => ModelIuran(
                            id: '',
                            judul: '',
                            nominal: 0,
                            jatuhTempo: DateTime.now(),
                            dibuatOleh: '',
                          ),
                        );
                        total += iuranMatch.nominal;
                      }
                    }
                    totalTerkumpulText = _formatRupiah(total);
                  } else if (snapIuran.connectionState == ConnectionState.waiting ||
                      snapBayar.connectionState == ConnectionState.waiting) {
                    countMenunggu = '...';
                    totalTerkumpulText = '...';
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: AppRadius.r12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(countMenunggu, style: AppTextStyles.statCount),
                              const SizedBox(height: 2),
                              const Text('Menunggu Verifikasi', style: AppTextStyles.statLabel),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.badgeGreenBg,
                            borderRadius: AppRadius.r12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalTerkumpulText,
                                style: AppTextStyles.statCount.copyWith(
                                  fontSize: 16,
                                  color: AppColors.badgeGreenText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text('Total Dana Terkumpul', style: AppTextStyles.statLabel),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HalamanIuran(
                      namaPengguna: namaPengguna,
                      peran: peran,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Buka Iuran', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // Bagian c: Keanggotaan & Struktur (Ketua saja)
  Widget _buildBagianKeanggotaan(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_outline, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Keanggotaan & Struktur', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              String pendingText = '-';
              String ketuaNama = '-';
              String sekretarisNama = '-';
              String bendaharaNama = '-';

              if (!snapshot.hasError && snapshot.hasData) {
                int pendingCount = 0;
                ketuaNama = 'Belum Ada';
                sekretarisNama = 'Belum Ada';
                bendaharaNama = 'Belum Ada';

                for (final doc in snapshot.data!.docs) {
                  final data = doc.data();
                  final bool disetujui = data['disetujui'] ?? true;
                  final String roleNorm = AppConstants.normalisasiPeran(data['role'] ?? data['jabatan']);
                  final String nama = (data['nama'] ?? data['username'] ?? 'Pengguna').toString().trim();

                  if (!disetujui) {
                    pendingCount++;
                  } else {
                    if (roleNorm == 'Ketua') ketuaNama = nama.isNotEmpty ? nama : 'Ketua';
                    if (roleNorm == 'Sekretaris') sekretarisNama = nama.isNotEmpty ? nama : 'Sekretaris';
                    if (roleNorm == 'Bendahara') bendaharaNama = nama.isNotEmpty ? nama : 'Bendahara';
                  }
                }
                pendingText = '$pendingCount';
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                pendingText = '...';
                ketuaNama = '...';
                sekretarisNama = '...';
                bendaharaNama = '...';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.badgeOrangeBg,
                      borderRadius: AppRadius.r12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          pendingText,
                          style: AppTextStyles.statCount.copyWith(
                            color: AppColors.badgeOrangeText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Pengurus Menunggu ACC',
                            style: AppTextStyles.statLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pemegang Jabatan Inti:', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 6),
                  _buildBarisJabatan('Ketua', ketuaNama),
                  _buildBarisJabatan('Sekretaris', sekretarisNama),
                  _buildBarisJabatan('Bendahara', bendaharaNama),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      appBar: AppHeader(title: 'Kelola Anggota'),
                      body: HalamanAnggotaAdmin(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Kelola Anggota', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarisJabatan(String jabatan, String nama) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              jabatan,
              style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': ', style: AppTextStyles.cardSubtitle),
          Expanded(
            child: Text(
              nama,
              style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
