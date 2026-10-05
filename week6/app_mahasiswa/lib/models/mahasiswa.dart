class Mahasiswa {
  final int? id; // null jika data baru
  final String nim;
  final String nama;
  final String prodi;
  final String email;

  Mahasiswa({
    this.id,
    required this.nim,
    required this.nama,
    required this.prodi,
    required this.email,
  });

  // JSON dari server -> objek Dart
  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      id: json['id'],
      nim: json['nim'],
      nama: json['nama'],
      prodi: json['prodi'],
      email: json['email'],
    );
  }

  // Objek Dart -> JSON untuk dikirim ke server
  Map<String, dynamic> toJson() => {
    'nim': nim,
    'nama': nama,
    'prodi': prodi,
    'email': email,
  };
}
