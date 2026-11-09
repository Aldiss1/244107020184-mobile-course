class Mhs {
  String name;
  String kelas;
  int umur;

  Mhs({
  required this.name, 
  required this.kelas, 
  required this.umur});

  void tampilkanInfo(){
    print('Nama: $name');
    print('Kelas: $kelas');
    print('Umur: $umur');
  }
}
