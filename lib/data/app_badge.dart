import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Badge jumlah notifikasi belum dibaca di ikon aplikasi.
///
/// - Android: MethodChannel `campus_notify/badge` (lihat MainActivity.kt).
///   Launcher Google standar (termasuk emulator) TIDAK menampilkan badge
///   aplikasi — broadcast itu untuk launcher bermerek (Samsung/Xiaomi/Oppo/
///   Vivo). Bukti badge yang selalu terlihat ada di dalam app (ikon bel).
/// - iOS: tidak diimplementasikan pada run ini (target pengujian Android).
///   Di v22 API Dart `setBadgeNumber` sudah tidak ada; badge iOS diset per
///   notifikasi lewat `DarwinNotificationDetails.badgeNumber`.
///
/// Badge bukan fitur fatal: semua error di-swallow agar notifikasi tetap
/// masuk daftar walau channel/plugin bermasalah.
class AppBadge {
  static const _channel = MethodChannel('campus_notify/badge');

  Future<void> setBadge(int count) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final safe = count.clamp(0, 99);
    try {
      await _channel.invokeMethod<void>('setBadge', {'count': safe});
    } catch (_) {
      // MethodChannel belum terdaftar (mis. di unit test) atau launcher
      // tidak mendukung — abaikan.
    }
  }
}
