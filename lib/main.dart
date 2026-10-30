import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'karang_kita.dart';
import 'kegiatan/admin/halaman/halaman_beranda_admin.dart';
import 'tamu/halaman/halaman_beranda_tamu.dart';

// Pesan error inisialisasi Firebase (null jika berhasil)
String? _galatFirebase;

// Inisialisasi awal aplikasi
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Konek ke Firebase Cloud
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Inisialisasi Firebase: $e');
    _galatFirebase = e.toString();
  }
  runApp(const MyApp());
}

// Widget root MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karang Kita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: _galatFirebase == null ? const _GerbangSesi() : _LayarGalat(pesan: _galatFirebase!),
    );
  }
}

// Gerbang sesi: sudah login -> beranda pengguna, belum login -> beranda tamu
class _GerbangSesi extends StatefulWidget {
  const _GerbangSesi();

  @override
  State<_GerbangSesi> createState() => _GerbangSesiState();
}

class _GerbangSesiState extends State<_GerbangSesi> {
  // Satu aliran status login saja, supaya tidak berlangganan ulang di setiap rebuild
  late final Stream<User?> _statusLogin = FirebaseAuth.instance.authStateChanges();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: LayananAutentikasi.sesiDitahan,
      builder: (context, ditahan, _) {
        return StreamBuilder<User?>(
          stream: _statusLogin,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!ditahan && snapshot.data != null) {
              return const HalamanBerandaAdmin();
            }
            return const HalamanBerandaTamu();
          },
        );
      },
    );
  }
}

// Ditampilkan jika Firebase gagal diinisialisasi, supaya penyebabnya terlihat
class _LayarGalat extends StatelessWidget {
  final String pesan;

  const _LayarGalat({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Firebase gagal diinisialisasi:\n$pesan',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
