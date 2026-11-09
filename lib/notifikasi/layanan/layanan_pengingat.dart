import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Layanan Pengingat Perangkat (Local Notifications) H-1 & 1 Jam Sebelum Kegiatan
class LayananPengingat {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _terinisialisasi = false;

  static Future<void> inisialisasi() async {
    if (_terinisialisasi) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(initSettings);

      // Meminta izin notifikasi di Android 13+ (API 33+)
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _terinisialisasi = true;
    } catch (e) {
      debugPrint('Gagal inisialisasi LayananPengingat: $e');
    }
  }

  // Parse string jam & menit dari teks seperti "07:30 WIB" atau "19:30 - 21:00 WIB"
  static TimeOfDay _parseJam(String rawWaktu) {
    try {
      final w = rawWaktu.contains('-') ? rawWaktu.split('-')[0].trim() : rawWaktu.trim();
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(w);
      if (match != null) {
        final jam = int.parse(match.group(1)!);
        final menit = int.parse(match.group(2)!);
        return TimeOfDay(hour: jam, minute: menit);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 8, minute: 0); // Default 08:00
  }

  // Sinkronisasi pengingat lokal untuk kegiatan yang berstatus 'Mendatang'
  static Future<void> sinkronkanPengingat(List<Map<String, dynamic>> daftarKegiatan) async {
    await inisialisasi();
    final now = DateTime.now();

    for (final k in daftarKegiatan) {
      final idDoc = (k['id'] ?? '').toString();
      final status = (k['status'] ?? 'Mendatang').toString();
      final judul = (k['judul'] ?? 'Kegiatan KarangTaruna').toString();
      final lokasi = (k['lokasi'] ?? '').toString();
      final rawTanggal = (k['tanggal'] ?? '').toString();
      final rawWaktu = (k['waktu'] ?? '08:00').toString();

      final idHMinus1 = (idDoc.hashCode & 0x3FFFFFFF);
      final id1Jam = ((idDoc.hashCode + 50000) & 0x3FFFFFFF);

      // Jika bukan kegiatan 'Mendatang' atau tanggal kosong, batalkan pengingat
      if (status != 'Mendatang' || rawTanggal.isEmpty) {
        await _notificationsPlugin.cancel(idHMinus1);
        await _notificationsPlugin.cancel(id1Jam);
        continue;
      }

      final tglBase = DateTime.tryParse(rawTanggal);
      if (tglBase == null) continue;

      final jam = _parseJam(rawWaktu);
      final tglAcara = DateTime(
        tglBase.year,
        tglBase.month,
        tglBase.day,
        jam.hour,
        jam.minute,
      );

      // Pengingat 1: H-1 Pukul 19:00 WIB
      final tglHMinus1 = DateTime(tglAcara.year, tglAcara.month, tglAcara.day - 1, 19, 0);
      if (tglHMinus1.isAfter(now)) {
        await _jadwalkan(
          id: idHMinus1,
          judul: 'Pengingat Besok: $judul',
          isi: 'Kegiatan "$judul" dilaksanakan besok jam ${jam.hour.toString().padLeft(2, '0')}:${jam.minute.toString().padLeft(2, '0')} WIB di $lokasi.',
          waktuTarget: tglHMinus1,
        );
      } else {
        await _notificationsPlugin.cancel(idHMinus1);
      }

      // Pengingat 2: 1 Jam Sebelum Acara
      final tgl1Jam = tglAcara.subtract(const Duration(hours: 1));
      if (tgl1Jam.isAfter(now)) {
        await _jadwalkan(
          id: id1Jam,
          judul: 'Pengingat 1 Jam Lagi: $judul',
          isi: 'Kegiatan "$judul" akan dimulai dalam 1 jam di $lokasi.',
          waktuTarget: tgl1Jam,
        );
      } else {
        await _notificationsPlugin.cancel(id1Jam);
      }
    }
  }

  static Future<void> _jadwalkan({
    required int id,
    required String judul,
    required String isi,
    required DateTime waktuTarget,
  }) async {
    try {
      final tzTarget = tz.TZDateTime.from(waktuTarget, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'pengingat_kegiatan',
        'Pengingat Kegiatan',
        channelDescription: 'Pengingat H-1 dan 1 jam sebelum kegiatan KarangKita',
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        judul,
        isi,
        tzTarget,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi lokal ($id): $e');
    }
  }
}
