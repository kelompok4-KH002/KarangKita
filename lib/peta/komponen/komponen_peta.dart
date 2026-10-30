import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// Titik awal peta jika belum ada lokasi dipilih (Jakarta); pengguna bisa cari atau geser peta
const LatLng kTitikAwalPeta = LatLng(-6.2088, 106.8456);

// Peta OpenStreetMap: gratis dan tanpa API key
const String _urlTilePeta = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _paketAplikasi = 'com.example.karang_kita';

// Hasil pemilihan lokasi dari peta
class HasilLokasi {
  final double lat;
  final double lng;
  final String? alamat; // diisi jika dipilih dari hasil pencarian

  const HasilLokasi({required this.lat, required this.lng, this.alamat});
}

// Buka titik koordinat di aplikasi/situs Google Maps
Future<bool> bukaDiGoogleMaps(double lat, double lng) {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Marker _buatMarker(LatLng titik) {
  return Marker(
    point: titik,
    width: 44,
    height: 44,
    alignment: Alignment.topCenter,
    child: const Icon(Icons.location_on, color: AppColors.danger, size: 44),
  );
}

// Pratinjau peta statis (tidak bisa digeser) dengan penanda lokasi
class PetaPratinjau extends StatelessWidget {
  final double lat;
  final double lng;
  final double tinggi;
  final bool tampilkanTombolMaps;

  const PetaPratinjau({
    super.key,
    required this.lat,
    required this.lng,
    this.tinggi = 180,
    this.tampilkanTombolMaps = true,
  });

  @override
  Widget build(BuildContext context) {
    final titik = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.r12,
          child: SizedBox(
            height: tinggi,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: titik,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(urlTemplate: _urlTilePeta, userAgentPackageName: _paketAplikasi),
                MarkerLayer(markers: [_buatMarker(titik)]),
                const SimpleAttributionWidget(source: Text('© OpenStreetMap contributors')),
              ],
            ),
          ),
        ),
        if (tampilkanTombolMaps) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r10),
            ),
            onPressed: () async {
              final pesan = ScaffoldMessenger.of(context);
              final berhasil = await bukaDiGoogleMaps(lat, lng);
              if (!berhasil) {
                pesan.showSnackBar(
                  const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Buka di Google Maps'),
          ),
        ],
      ],
    );
  }
}

// Field "Titik lokasi di peta" untuk dipakai di form kegiatan & usulan
class PemilihTitikPeta extends StatelessWidget {
  final double? lat;
  final double? lng;
  final String? kataKunciAwal;
  final ValueChanged<HasilLokasi?> onChanged;

  const PemilihTitikPeta({
    super.key,
    required this.lat,
    required this.lng,
    required this.onChanged,
    this.kataKunciAwal,
  });

  bool get _adaTitik => lat != null && lng != null;

  Future<void> _pilih(BuildContext context) async {
    final hasil = await Navigator.push<HasilLokasi>(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanPilihLokasi(
          awal: _adaTitik ? LatLng(lat!, lng!) : null,
          kataKunciAwal: kataKunciAwal,
        ),
      ),
    );
    if (hasil != null) onChanged(hasil);
  }

  @override
  Widget build(BuildContext context) {
    if (!_adaTitik) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.cardBorder),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.r10),
        ),
        onPressed: () => _pilih(context),
        icon: const Icon(Icons.map_outlined, size: 18),
        label: const Text('Tandai lokasi di peta'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PetaPratinjau(lat: lat!, lng: lng!, tinggi: 150, tampilkanTombolMaps: false),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pilih(context),
                icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                label: const Text('Ubah titik'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.location_off_outlined, size: 16),
                label: const Text('Hapus titik'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HasilCari {
  final String nama;
  final LatLng titik;
  _HasilCari(this.nama, this.titik);
}

// Halaman layar penuh untuk memilih titik lokasi: ketuk peta atau cari alamat
class HalamanPilihLokasi extends StatefulWidget {
  final LatLng? awal;
  final String? kataKunciAwal;

  const HalamanPilihLokasi({super.key, this.awal, this.kataKunciAwal});

  @override
  State<HalamanPilihLokasi> createState() => _HalamanPilihLokasiState();
}

class _HalamanPilihLokasiState extends State<HalamanPilihLokasi> {
  final MapController _mapController = MapController();
  late final TextEditingController _cariController;
  LatLng? _terpilih;
  String? _alamat;
  List<_HasilCari> _hasilCari = [];
  bool _sedangMencari = false;
  String? _pesanCari;

  @override
  void initState() {
    super.initState();
    _terpilih = widget.awal;
    _cariController = TextEditingController(text: widget.kataKunciAwal ?? '');
  }

  @override
  void dispose() {
    _cariController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // Cari alamat lewat Nominatim (OpenStreetMap), dibatasi wilayah Indonesia
  Future<void> _cari() async {
    final kata = _cariController.text.trim();
    if (kata.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _sedangMencari = true;
      _pesanCari = null;
      _hasilCari = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'limit': '5',
        'countrycodes': 'id',
        'q': kata,
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Status ${res.statusCode}');
      }

      final data = jsonDecode(res.body) as List<dynamic>;
      final hasil = data.map((e) {
        final m = e as Map<String, dynamic>;
        return _HasilCari(
          (m['display_name'] ?? '').toString(),
          LatLng(double.parse(m['lat'].toString()), double.parse(m['lon'].toString())),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _hasilCari = hasil;
        _pesanCari = hasil.isEmpty ? 'Alamat tidak ditemukan. Coba kata kunci lain atau ketuk peta.' : null;
        _sedangMencari = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pesanCari = 'Pencarian gagal, periksa koneksi internet. Anda tetap bisa mengetuk peta.';
        _sedangMencari = false;
      });
    }
  }

  void _pilihHasilCari(_HasilCari h) {
    setState(() {
      _terpilih = h.titik;
      _alamat = h.nama;
      _hasilCari = [];
    });
    _mapController.move(h.titik, 17);
  }

  @override
  Widget build(BuildContext context) {
    final pusat = _terpilih ?? kTitikAwalPeta;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Lokasi', style: AppTextStyles.headerTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pusat,
              initialZoom: _terpilih == null ? 12 : 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, titik) {
                setState(() {
                  _terpilih = titik;
                  _alamat = null; // titik digeser manual, alamat hasil cari tidak berlaku lagi
                });
              },
            ),
            children: [
              TileLayer(urlTemplate: _urlTilePeta, userAgentPackageName: _paketAplikasi),
              if (_terpilih != null) MarkerLayer(markers: [_buatMarker(_terpilih!)]),
              const SimpleAttributionWidget(source: Text('© OpenStreetMap contributors')),
            ],
          ),

          // Kotak pencarian + hasil
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: AppRadius.r12,
                  child: TextField(
                    controller: _cariController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _cari(),
                    decoration: InputDecoration(
                      hintText: 'Cari alamat atau nama tempat...',
                      hintStyle: AppTextStyles.inputHint,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.r12,
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _sedangMencari
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search, color: AppColors.primary),
                              onPressed: _cari,
                            ),
                    ),
                  ),
                ),
                if (_pesanCari != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.r10,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(_pesanCari!, style: AppTextStyles.cardSubtitle),
                  ),
                if (_hasilCari.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.r10,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _hasilCari.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final h = _hasilCari[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                          title: Text(h.nama, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _pilihHasilCari(h),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _terpilih == null
                    ? 'Ketuk peta untuk menandai lokasi kegiatan'
                    : 'Titik: ${_terpilih!.latitude.toStringAsFixed(5)}, ${_terpilih!.longitude.toStringAsFixed(5)}',
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
                    elevation: 0,
                  ),
                  onPressed: _terpilih == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            HasilLokasi(
                              lat: _terpilih!.latitude,
                              lng: _terpilih!.longitude,
                              alamat: _alamat,
                            ),
                          ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Gunakan lokasi ini', style: AppTextStyles.buttonPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
