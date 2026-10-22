import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'karang_kita.dart';

// Inisialisasi awal aplikasi
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Konek ke Firebase Cloud
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Inisialisasi Firebase: $e');
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
      // Tampilan awal diatur ke HalamanLogin
      home: const HalamanLogin(),
    );
  }
}
