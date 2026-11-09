/// Satu sumber kebenaran untuk semua path rute.
///
/// Dipakai bersama oleh GoRouter dan oleh deep link dari FCM, supaya
/// `data.route` pada payload notifikasi tidak pernah "nyasar" karena
/// string literal yang berbeda antara dua tempat.
abstract final class Routes {
  /// Halaman tunggu selama status sesi masih dibaca dari secure storage.
  static const String splash = '/splash';

  static const String login = '/login';
  static const String home = '/';
  static const String debug = '/debug';
  static const String notifications = '/notifikasi';

  /// Pola rute (dipakai GoRouter).
  static const String announcementPattern = '/pengumuman/:id';

  /// Nama rute (dipakai `context.goNamed` bila perlu).
  static const String announcementName = 'pengumuman';

  /// Membangun path konkret untuk satu pengumuman.
  static String announcement(String id) => '/pengumuman/$id';
}
