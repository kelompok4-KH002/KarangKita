import 'package:flutter/material.dart';
import '../komponen/komponen_autentikasi.dart';
import '../layanan/pengalihan_role.dart';
import 'halaman_registrasi.dart';

// Halaman Login utama aplikasi (High-Fidelity)
class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  // Key form untuk validasi input
  final _formKey = GlobalKey<FormState>();

  // Controller input username dan password
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _belumVerifikasi = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Kirim ulang email verifikasi
  void _kirimUlangVerifikasi() async {
    final emailInput = _usernameController.text.trim();
    final passInput = _passwordController.text.trim();

    if (emailInput.isEmpty || passInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi email dan kata sandi terlebih dahulu untuk mengirim ulang verifikasi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    final hasil = await LayananAutentikasi.kirimUlangVerifikasi(
      email: emailInput,
      password: passInput,
    );

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil.pesan),
        backgroundColor: hasil.sukses ? const Color(0xFF1E3A8A) : Colors.redAccent,
      ),
    );
  }

  // Tampilkan dialog reset kata sandi
  void _tampilkanDialogLupaPassword() {
    final controller = TextEditingController(text: _usernameController.text.trim());
    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Lupa Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan email Anda yang terdaftar untuk menerima tautan pemulihan kata sandi.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'contoh: nama@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final emailInput = controller.text.trim();
                          if (emailInput.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email wajib diisi'), backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          final hasil = await LayananAutentikasi.resetPassword(emailInput);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(hasil.pesan),
                              backgroundColor: hasil.sukses ? const Color(0xFF1E3A8A) : Colors.redAccent,
                            ),
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Link Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi proses login
  void _prosesLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _belumVerifikasi = false;
    });

    // Panggil fungsi login
    final hasil = await LayananAutentikasi.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (hasil.sukses) {
      if (!mounted) return;
      // Gerbang di main.dart otomatis menampilkan beranda sesuai sesi login
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _errorMessage = hasil.pesan;
        _belumVerifikasi = hasil.belumVerifikasi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A); // Tema biru tua seragam Figma

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HeaderLogoKarangKita(),
                  const SizedBox(height: 32),

                  // Tampilkan banner error jika login gagal
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_belumVerifikasi) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _isResending ? null : _kirimUlangVerifikasi,
                                icon: _isResending
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                      )
                                    : const Icon(Icons.send_rounded, size: 14, color: primaryColor),
                                label: const Text(
                                  'Kirim ulang',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Field input username / email
                  InputFieldCustom(
                    controller: _usernameController,
                    label: 'Email / Username',
                    hint: 'Masukkan email/username',
                    prefixIcon: Icons.email_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email / Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field input password
                  InputFieldCustom(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Masukkan password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Tautan Lupa Kata Sandi
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _tampilkanDialogLupaPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lupa kata sandi?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol submit login
                  TombolUtama(
                    text: 'Masuk Ke Sistem',
                    onPressed: _prosesLogin,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Lihat sebagai Tamu'),
                  ),
                  const SizedBox(height: 8),

                  // Footer Link ke Registrasi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HalamanRegistrasi()),
                          );
                        },
                        child: const Text(
                          'Daftar Akun',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
