import 'package:flutter/material.dart';
import '../../autentikasi/layanan/pengalihan_role.dart';
import '../../core/theme/app_colors.dart';
import '../halaman/halaman_notifikasi.dart';
import '../layanan/layanan_notifikasi.dart';

// Ikon lonceng dengan badge jumlah notifikasi belum dibaca (dipasang di AppHeader)
class IkonNotifikasi extends StatefulWidget {
  const IkonNotifikasi({super.key});

  @override
  State<IkonNotifikasi> createState() => _IkonNotifikasiState();
}

class _IkonNotifikasiState extends State<IkonNotifikasi> {
  ProfilSaya? _profil;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final profil = await LayananAutentikasi.muatProfilSaya();
    if (mounted) setState(() => _profil = profil);
  }

  @override
  Widget build(BuildContext context) {
    final profil = _profil;
    if (profil == null) {
      return const IconButton(
        icon: Icon(Icons.notifications_none, color: AppColors.textPrimary),
        onPressed: null,
      );
    }

    return StreamBuilder<List<ModelNotifikasi>>(
      stream: LayananNotifikasi.alirkan(profil.uid, profil.peran),
      builder: (context, snapshot) {
        final belumDibaca = (snapshot.data ?? const <ModelNotifikasi>[]).where((n) => !n.dibaca).length;

        return IconButton(
          tooltip: 'Notifikasi',
          icon: Badge(
            isLabelVisible: belumDibaca > 0,
            label: Text(belumDibaca > 9 ? '9+' : '$belumDibaca'),
            child: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HalamanNotifikasi(uid: profil.uid, peran: profil.peran),
              ),
            );
          },
        );
      },
    );
  }
}
