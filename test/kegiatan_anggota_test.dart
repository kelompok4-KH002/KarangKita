// Tes untuk pembacaan tanggal & data kegiatan (fitur anggota).
// Jalankan:  flutter test test/kegiatan_anggota_test.dart
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';

import 'package:karang_kita/kegiatan/anggota/layanan/kegiatan_service.dart';

void main() {
  bool dekatSekarang(DateTime d) => d.difference(DateTime.now()).abs() < const Duration(seconds: 5);

  group('bacaTanggal', () {
    test('String ISO seperti yang ditulis admin (toIso8601String)', () {
      final asli = DateTime(2026, 11, 20);
      expect(bacaTanggal(asli.toIso8601String()), asli);
    });

    test('String ISO dengan jam', () {
      final asli = DateTime(2026, 11, 20, 19, 30);
      expect(bacaTanggal(asli.toIso8601String()), asli);
    });

    test('String hanya tanggal (yyyy-MM-dd)', () {
      final d = bacaTanggal('2026-11-20');
      expect([d.year, d.month, d.day], [2026, 11, 20]);
    });

    test('Timestamp (data lama)', () {
      final asli = DateTime(2026, 11, 20, 8);
      final d = bacaTanggal(Timestamp.fromDate(asli));
      expect([d.year, d.month, d.day], [2026, 11, 20]);
    });

    test('kosong / null -> hari ini, tidak error', () {
      expect(dekatSekarang(bacaTanggal(null)), isTrue);
    });

    test('teks sampah -> hari ini, tidak error', () {
      expect(dekatSekarang(bacaTanggal('bukan tanggal')), isTrue);
    });
  });

  group('KegiatanItem.fromMap', () {
    test('bentuk dokumen dari admin (tanggal String, jam di "waktu")', () {
      final k = KegiatanItem.fromMap('abc', {
        'id': 'abc',
        'judul': 'Kerja Bakti',
        'waktu': '07:30 WIB',
        'lokasi': 'Balai RW',
        'kategori': 'Sosial',
        'deskripsi': 'Bersih-bersih lingkungan',
        'status': 'Mendatang',
        'tanggal': DateTime(2026, 11, 20).toIso8601String(),
        'lat': -6.2,
        'lng': 106.8,
      });
      expect(k.id, 'abc');
      expect(k.judul, 'Kerja Bakti');
      expect(k.jam, '07:30 WIB');
      expect(k.tanggal, DateTime(2026, 11, 20));
      expect(k.absensiDibuka, isFalse);
      expect(k.wajib, isFalse);
      expect(k.kuota, 0);
    });

    test('data lama (Timestamp + field "jam")', () {
      final k = KegiatanItem.fromMap('lama', {
        'judul': 'Rapat',
        'jam': '19:30 WIB',
        'tanggal': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'kuota': 30,
        'wajib': true,
      });
      expect(k.jam, '19:30 WIB');
      expect(k.tanggal.month, 5);
      expect(k.kuota, 30);
      expect(k.wajib, isTrue);
    });

    test('"waktu" didahulukan dibanding "jam"', () {
      final k = KegiatanItem.fromMap('x', {'waktu': '08:00 - 10:00', 'jam': '07:00 WIB'});
      expect(k.jam, '08:00 - 10:00');
    });

    test('dokumen hampir kosong tidak membuat error', () {
      final k = KegiatanItem.fromMap('kosong', {});
      expect(k.judul, '');
      expect(k.jam, '');
    });

    test('absensiDibuka dibaca dari dokumen', () {
      final k = KegiatanItem.fromMap('x', {'absensiDibuka': true});
      expect(k.absensiDibuka, isTrue);
    });

    test('hariIni dan sudahLewat', () {
      final n = DateTime.now();
      final hariIni = KegiatanItem.fromMap('a', {'tanggal': DateTime(n.year, n.month, n.day).toIso8601String()});
      final kemarin = KegiatanItem.fromMap('b', {'tanggal': DateTime(n.year, n.month, n.day - 1).toIso8601String()});
      final besok = KegiatanItem.fromMap('c', {'tanggal': DateTime(n.year, n.month, n.day + 1).toIso8601String()});
      expect(hariIni.hariIni, isTrue);
      expect(hariIni.sudahLewat, isFalse);
      expect(kemarin.sudahLewat, isTrue);
      expect(besok.sudahLewat, isFalse);
    });
  });
}