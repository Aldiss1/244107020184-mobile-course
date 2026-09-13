import 'Lirik.dart';

class Musik {
  String judul;
  String artis;
  int tahun;
  Lirik lirik;

  Musik({
    required this.judul,
    required this.artis,
    required this.tahun,
    required this.lirik,
  });

  void tampilkanInfo() {
    print('Judul: $judul');
    print('Artis: $artis');
    print('Tahun: $tahun');
    lirik.tampilkanLirik();
  }
}

