import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utilitas/layanan_cloudinary.dart';
import '../layanan/layanan_email_akun.dart';

// Halaman Edit Profil Pengguna (Foto Profil, Nama, WhatsApp, & Password)
class HalamanEditProfil extends StatefulWidget {
  const HalamanEditProfil({super.key});

  @override
  State<HalamanEditProfil> createState() => _HalamanEditProfilState();
}

class _HalamanEditProfilState extends State<HalamanEditProfil> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _namaController;
  late TextEditingController _whatsappController;
  late TextEditingController _passwordController;

  String _emailFirestore = '';
  String _peran = 'Anggota';
  String? _fotoUrl;
  XFile? _fotoBaru;
  bool _sedangMemuatData = true;
  bool _sedangMenyimpan = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _whatsappController = TextEditingController();
    _passwordController = TextEditingController();
    _muatDataProfil();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _muatDataProfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _sedangMemuatData = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _namaController.text = (data['nama'] ?? data['username'] ?? '').toString();
        _whatsappController.text = (data['whatsapp'] ?? '').toString();
        _emailFirestore = (data['email'] ?? user.email ?? '').toString();
        _peran = AppConstants.normalisasiPeran(data['role'] ?? data['jabatan']);
        _fotoUrl = (data['fotoUrl'] ?? data['foto'] ?? '').toString();
      } else {
        _emailFirestore = user.email ?? '';
        _namaController.text = user.displayName ?? '';
      }
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
    } finally {
      if (mounted) {
        setState(() => _sedangMemuatData = false);
      }
    }
  }

  Future<void> _pilihFoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _fotoBaru = picked;
        });
      }
    } catch (e) {
      debugPrint('Gagal memilih foto: $e');
    }
  }

  void _tampilkanPilihanSumberFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Foto Profil', style: AppTextStyles.formTitle),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Galeri Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pilihFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pilihFoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bukaDialogUbahEmail() {
    final emailBaruCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? pesanError;
    bool sedangProses = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
            title: const Text('Ubah Alamat Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tautan verifikasi akan dikirimkan ke email baru Anda. Email resmi berubah setelah tautan diklik.',
                  style: AppTextStyles.cardSubtitle,
                ),
                const SizedBox(height: 16),
                const Text('Email Baru', style: AppTextStyles.inputLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailBaruCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('nama@gmail.com', Icons.email_outlined),
                ),
                const SizedBox(height: 14),
                const Text('Kata Sandi Saat Ini', style: AppTextStyles.inputLabel),
                const SizedBox(height: 6),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: _inputDecoration('Konfirmasi kata sandi', Icons.lock_outline),
                ),
                if (pesanError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    pesanError!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: sedangProses ? null : () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
                ),
                onPressed: sedangProses
                    ? null
                    : () async {
                        final eBaru = emailBaruCtrl.text.trim();
                        final pSaatIni = passwordCtrl.text.trim();

                        if (eBaru.isEmpty || pSaatIni.isEmpty) {
                          setDialogState(() {
                            pesanError = 'Semua kolom wajib diisi';
                          });
                          return;
                        }

                        setDialogState(() {
                          sedangProses = true;
                          pesanError = null;
                        });

                        final hasilErr = await LayananEmailAkun.mintaUbahEmail(
                          emailBaru: eBaru,
                          passwordSaatIni: pSaatIni,
                        );

                        if (!context.mounted) return;

                        if (hasilErr == null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tautan verifikasi dikirim ke $eBaru. Email berubah setelah tautan diklik.'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          setDialogState(() {
                            sedangProses = false;
                            pesanError = hasilErr;
                          });
                        }
                      },
                child: sedangProses
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2),
                      )
                    : const Text('Kirim Tautan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sedangMenyimpan = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _sedangMenyimpan = false);
      return;
    }

    try {
      String? updatedFotoUrl = _fotoUrl;

      // 1. Unggah foto ke Cloudinary jika ada foto baru
      if (_fotoBaru != null) {
        final hasilUnggah = await LayananCloudinary.unggahGambar(_fotoBaru!);
        if (hasilUnggah != null && hasilUnggah['secure_url'] != null) {
          updatedFotoUrl = hasilUnggah['secure_url'];
        }
      }

      final namaBaru = _namaController.text.trim();
      final waBaru = _whatsappController.text.trim();
      final passBaru = _passwordController.text.trim();

      // 2. Update Firestore users & kontak secara atomik (tanpa field email)
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final Map<String, dynamic> updatePayload = {
        'nama': namaBaru,
        'whatsapp': waBaru,
      };

      if (updatedFotoUrl != null && updatedFotoUrl.isNotEmpty) {
        updatePayload['fotoUrl'] = updatedFotoUrl;
      }

      batch.set(db.collection('users').doc(user.uid), updatePayload, SetOptions(merge: true));

      final Map<String, dynamic> kontakPayload = {
        'nama': namaBaru,
      };
      batch.set(db.collection('kontak').doc(user.uid), kontakPayload, SetOptions(merge: true));

      await batch.commit();

      // 3. Update Firebase Auth Display Name & Password jika diisi
      try {
        await user.updateDisplayName(namaBaru);
      } catch (_) {}

      if (passBaru.isNotEmpty) {
        try {
          await user.updatePassword(passBaru);
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          if (e.code == 'requires-recent-login') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demi keamanan, silakan re-login untuk mengubah kata sandi.'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sedangMenyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil Saya', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _sedangMemuatData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar & Edit Foto
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                                color: AppColors.primaryLight,
                              ),
                              child: ClipOval(
                                child: _fotoBaru != null
                                    ? Image.file(
                                        File(_fotoBaru!.path),
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      )
                                    : (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                        ? Image.network(
                                            _fotoUrl!,
                                            fit: BoxFit.cover,
                                            width: 110,
                                            height: 110,
                                            errorBuilder: (_, _, _) => _avatarPlaceholder(),
                                          )
                                        : _avatarPlaceholder(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _tampilkanPilihanSumberFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.textWhite,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Role: $_peran',
                        style: AppTextStyles.cardSubtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      // Container Input Form
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
                            const Text('Nama Lengkap', style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _namaController,
                              decoration: _inputDecoration('Nama lengkap Anda', Icons.person_outline),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Nama lengkap wajib diisi';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Nomor WhatsApp
                            const Text('Nomor WhatsApp', style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _whatsappController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration('081234567890', Icons.phone_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
                                if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                                  return 'Nomor WhatsApp hanya boleh berupa angka';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email (Read-Only + Tombol Ubah Email)
                            const Text('Alamat Email', style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppRadius.r10,
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _emailFirestore.isNotEmpty ? _emailFirestore : 'Belum diatur',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: _bukaDialogUbahEmail,
                                    child: const Text('Ubah email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Kata Sandi Baru (Opsional)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Kata Sandi Baru', style: AppTextStyles.inputLabel),
                                Text('Opsional', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: 'Kosongkan jika tidak ingin diubah',
                                hintStyle: AppTextStyles.inputHint,
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                                  },
                                ),
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
                              ),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                          ),
                          onPressed: _sedangMenyimpan ? null : _simpanPerubahan,
                          icon: _sedangMenyimpan
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: AppColors.textWhite, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Simpan Perubahan', style: AppTextStyles.buttonPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _avatarPlaceholder() {
    final nama = _namaController.text.trim();
    return Center(
      child: Text(
        nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.inputHint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
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
