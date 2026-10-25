import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/category_chip.dart';

// Model Data Anggota Admin
class ModelAnggotaAdmin {
  final String id;
  final String nama;
  final String jabatan;
  final String whatsapp;
  final bool disetujui;

  ModelAnggotaAdmin({
    required this.id,
    required this.nama,
    required this.jabatan,
    required this.whatsapp,
    this.disetujui = true,
  });
}

// Halaman Kelola Anggota Admin High-Fidelity Sesuai Mockup Figma (`admin_pengurus_kelola_anggota.png`)
class HalamanAnggotaAdmin extends StatefulWidget {
  const HalamanAnggotaAdmin({super.key});

  @override
  State<HalamanAnggotaAdmin> createState() => _HalamanAnggotaAdminState();
}

class _HalamanAnggotaAdminState extends State<HalamanAnggotaAdmin> {
  final TextEditingController _searchController = TextEditingController();
  late List<ModelAnggotaAdmin> _daftarAnggota;
  bool _sedangMemuat = true;

  @override
  void initState() {
    super.initState();
    _daftarAnggota = [];
    _muatUserFirestore();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Muat data anggota dari Cloud Firestore
  void _muatUserFirestore() async {
    setState(() => _sedangMemuat = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      if (snap.docs.isNotEmpty) {
        final List<ModelAnggotaAdmin> cloudList = [];
        for (var doc in snap.docs) {
          final data = doc.data();
          cloudList.add(ModelAnggotaAdmin(
            id: doc.id,
            nama: data['nama'] ?? data['username'] ?? 'Pengguna',
            jabatan: data['role'] ?? 'Anggota',
            whatsapp: data['whatsapp'] ?? '081234567890',
            disetujui: data['disetujui'] ?? true,
          ));
        }
        if (mounted) {
          setState(() {
            _daftarAnggota = cloudList;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _sedangMemuat = false);
  }

  List<ModelAnggotaAdmin> _getFiltered() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return _daftarAnggota;
    return _daftarAnggota.where((item) {
      return item.nama.toLowerCase().contains(query) ||
          item.jabatan.toLowerCase().contains(query) ||
          item.whatsapp.contains(query);
    }).toList();
  }

  void _simpanAnggota(ModelAnggotaAdmin item, bool isEdit) async {
    final currentList = List<ModelAnggotaAdmin>.from(_daftarAnggota);
    if (isEdit) {
      final idx = currentList.indexWhere((a) => a.id == item.id);
      if (idx != -1) currentList[idx] = item;
    } else {
      currentList.insert(0, item);
    }

    setState(() {
      _daftarAnggota = currentList;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(item.id).set({
        'uid': item.id,
        'nama': item.nama,
        'role': item.jabatan,
        'whatsapp': item.whatsapp,
        'disetujui': item.disetujui,
      }, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isEdit ? 'Data anggota berhasil diperbarui' : 'Anggota baru berhasil ditambahkan')),
    );
  }

  void _setujuiAkun(ModelAnggotaAdmin item) async {
    final updated = ModelAnggotaAdmin(
      id: item.id,
      nama: item.nama,
      jabatan: item.jabatan,
      whatsapp: item.whatsapp,
      disetujui: true,
    );

    _simpanAnggota(updated, true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Akun Pengurus ${item.nama} berhasil disetujui (ACC)!')),
    );
  }

  void _hapusAnggota(ModelAnggotaAdmin item) {
    // Proteksi: Mencegah Admin menghapus akunnya sendiri
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (item.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak dapat menghapus akun Anda sendiri!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        title: const Text('Hapus anggota?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${item.nama}" dari daftar anggota? Tindakan ini tidak dapat dibatalkan.'),
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
              Navigator.pop(context); // Tutup dialog konfirmasi
              
              setState(() {
                _daftarAnggota.removeWhere((a) => a.id == item.id);
              });

              try {
                await FirebaseFirestore.instance.collection('users').doc(item.id).delete();
              } catch (_) {}

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Anggota ${item.nama} berhasil dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _bukaModalForm([ModelAnggotaAdmin? editItem]) {
    showDialog(
      context: context,
      builder: (context) => DialogTambahEditAnggota(
        anggotaEdit: editItem,
        onSimpan: (newItem) => _simpanAnggota(newItem, editItem != null),
        onSetujui: editItem != null && !editItem.disetujui ? () => _setujuiAkun(editItem) : null,
        onHapus: editItem != null ? () => _hapusAnggota(editItem) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listFiltered = _getFiltered();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
                hintStyle: AppTextStyles.inputHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.r30,
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.r30,
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.r30,
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // List Items atau Empty States
          Expanded(
            child: _sedangMemuat
                ? const Center(child: CircularProgressIndicator())
                : _daftarAnggota.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada anggota terdaftar',
                          style: AppTextStyles.statLabel,
                        ),
                      )
                    : listFiltered.isEmpty
                        ? const Center(
                            child: Text(
                              'Anggota tidak ditemukan',
                              style: AppTextStyles.statLabel,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            itemCount: listFiltered.length,
                            itemBuilder: (context, index) {
                              final item = listFiltered[index];
                              return _buildMemberCard(item);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaModalForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMemberCard(ModelAnggotaAdmin item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Lingkaran Inisial
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              item.nama.isNotEmpty ? item.nama[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Member
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CategoryChip(
                      kategori: item.disetujui ? item.jabatan : 'Menunggu persetujuan',
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${item.whatsapp}',
                      style: AppTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons: Edit (Pensil) & Hapus (X)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
            onPressed: () => _bukaModalForm(item),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
            onPressed: () => _hapusAnggota(item),
          ),
        ],
      ),
    );
  }
}

// Dialog Form Tambah / Edit Anggota
class DialogTambahEditAnggota extends StatefulWidget {
  final ModelAnggotaAdmin? anggotaEdit;
  final Function(ModelAnggotaAdmin) onSimpan;
  final VoidCallback? onSetujui;
  final VoidCallback? onHapus;

  const DialogTambahEditAnggota({
    super.key,
    this.anggotaEdit,
    required this.onSimpan,
    this.onSetujui,
    this.onHapus,
  });

  @override
  State<DialogTambahEditAnggota> createState() => _DialogTambahEditAnggotaState();
}

class _DialogTambahEditAnggotaState extends State<DialogTambahEditAnggota> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _whatsappController;
  late String _peranTerpilih;
  bool _prosesSimpan = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.anggotaEdit;
    _namaController = TextEditingController(text: edit?.nama ?? '');
    _whatsappController = TextEditingController(text: edit?.whatsapp ?? '');
    
    final peran = edit?.jabatan ?? 'Anggota';
    _peranTerpilih = AppConstants.kDaftarPeranUtama.contains(peran) ? peran : 'Anggota';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.anggotaEdit != null;
    final isPendingAcc = editPendingAcc(widget.anggotaEdit);

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
                      isEdit ? 'Edit Data Anggota' : 'Tambah Anggota Baru',
                      style: AppTextStyles.formTitle,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Container Form
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
                      // Nama Lengkap
                      _buildInputLabel('Nama Lengkap'),
                      TextFormField(
                        controller: _namaController,
                        decoration: _buildInputDecoration(hintText: 'Nama lengkap anggota'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Peran / Jabatan
                      _buildInputLabel('Peran / Jabatan'),
                      DropdownButtonFormField<String>(
                        value: _peranTerpilih,
                        decoration: _buildInputDecoration(hintText: 'Pilih Peran'),
                        items: AppConstants.kDaftarPeranUtama
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _peranTerpilih = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nomor WhatsApp
                      _buildInputLabel('Nomor WhatsApp'),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hintText: '081234567890',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor WhatsApp wajib diisi';
                          }
                          final clean = val.trim();
                          if (!RegExp(r'^[0-9]+$').hasMatch(clean)) {
                            return 'Nomor WhatsApp hanya boleh berupa angka';
                          }
                          if (clean.length < 10 || clean.length > 14) {
                            return 'Nomor WhatsApp harus berpanjang 10-14 digit';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol ACC Khusus (Opsi A) jika status disetujui == false
                if (isPendingAcc && widget.onSetujui != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.badgeOrangeText,
                        foregroundColor: AppColors.textWhite,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSetujui!();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Setujui Akun Pengurus (ACC)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

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
                    onPressed: _prosesSimpan
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _prosesSimpan = true);
                              final hasil = ModelAnggotaAdmin(
                                id: widget.anggotaEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                nama: _namaController.text.trim(),
                                jabatan: _peranTerpilih,
                                whatsapp: _whatsappController.text.trim(),
                                disetujui: widget.anggotaEdit?.disetujui ?? true,
                              );
                              widget.onSimpan(hasil);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                    child: _prosesSimpan
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
                const SizedBox(height: 16),

                // Red Link: Hapus Anggota (if editing)
                if (isEdit && widget.onHapus != null)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onHapus!();
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          SizedBox(width: 6),
                          Text('Hapus Anggota', style: AppTextStyles.linkDanger),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool editPendingAcc(ModelAnggotaAdmin? item) {
    return item != null && !item.disetujui;
  }

  static Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(label, style: AppTextStyles.inputLabel),
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
