import 'package:flutter/material.dart';
import '../layanan/pengalihan_role.dart';
import 'halaman_login.dart';

// Halaman Registrasi Akun Terpadu (Slicing High-Fidelity Figma)
class HalamanRegistrasi extends StatefulWidget {
  const HalamanRegistrasi({super.key});

  @override
  State<HalamanRegistrasi> createState() => _HalamanRegistrasiState();
}

class _HalamanRegistrasiState extends State<HalamanRegistrasi> {
  final _formKey = GlobalKey<FormState>();

  // Role pilihan default: Anggota
  String _peranTerpilih = 'Anggota';

  // Controller input form
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi submit pendaftaran
  void _prosesDaftar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final hasil = await LayananAutentikasi.daftar(
      nama: _namaController.text,
      username: _usernameController.text,
      whatsapp: _whatsappController.text,
      password: _passwordController.text,
      peranString: _peranTerpilih,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (hasil.sukses) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi berhasil! Silakan login dengan username: ${_usernameController.text.trim()}'),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );

      // Kembali ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HalamanLogin()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil.pesan),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A8A); // Warna biru tua

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Back
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const Text(
                    '',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Form Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Icon Header
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Judul & Subtitle
                      const Text(
                        'Daftar Akun',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih peran dan lengkapi data untuk mulai',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Segmented Selector Pilih Peran
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PILIH PERAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: ['Pengurus', 'Anggota', 'Warga'].map((peran) {
                                final isSelected = _peranTerpilih == peran;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _peranTerpilih = peran;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          peran,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Form Input Nama Lengkap
                      _buildInputLabel('Nama Lengkap'),
                      TextFormField(
                        controller: _namaController,
                        decoration: _buildInputDecoration(
                          hintText: 'Nama lengkap Anda',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Form Input Username
                      _buildInputLabel('Username'),
                      TextFormField(
                        controller: _usernameController,
                        decoration: _buildInputDecoration(
                          hintText: 'contoh: namauser',
                          prefixIcon: Icons.alternate_email,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Username wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Form Input Nomor WhatsApp
                      _buildInputLabel('Nomor WhatsApp'),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(
                          hintText: '81234567890',
                          prefixWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: const Text(
                              '+62',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Form Input Kata Sandi
                      _buildInputLabel('Kata Sandi'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: _buildInputDecoration(
                          hintText: 'Minimal 6 karakter',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Kata sandi wajib diisi';
                          if (val.trim().length < 6) return 'Kata sandi minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _prosesDaftar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Daftar Sekarang',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Link ke Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HalamanLogin()),
                              );
                            },
                            child: const Text(
                              'Masuk ke Akun',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Label form input
  static Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  // Style input field sesuai mockup
  static InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? prefixWidget,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 20) : null),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
      ),
    );
  }
}
