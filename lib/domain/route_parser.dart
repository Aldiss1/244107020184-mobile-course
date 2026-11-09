import '../routes.dart';

/// Mengubah `data` payload FCM menjadi path rute yang valid.
///
/// Fungsi ini **murni** (tidak menyentuh Firebase, BuildContext, atau I/O)
/// sehingga bisa diuji lewat `flutter test` tanpa perangkat.
///
/// Aturan:
/// - `route` kosong/absen  -> coba `id`, kalau ada arahkan ke `/pengumuman/<id>`,
///   kalau tidak ada sama sekali jatuh ke [Routes.home].
/// - `route` tanpa garis miring di depan -> ditambahkan otomatis.
/// - `route` berisi spasi di ujung -> di-trim.
String routeFromMessage(Map<String, dynamic> data) {
  final raw = (data['route'] as String?)?.trim() ?? '';
  if (raw.isEmpty) {
    final id = (data['id'] as String?)?.trim() ?? '';
    return id.isEmpty ? Routes.home : Routes.announcement(id);
  }
  return raw.startsWith('/') ? raw : '/$raw';
}
