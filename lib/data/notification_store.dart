import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Satu notifikasi yang tersimpan di daftar (belum dibaca).
///
/// `id` harus unik dalam daftar — [NotificationStore.add] memberi akhiran
/// bila bertabrakan. Bila `id` berupa bilangan desimal (dari
/// `PushService.showLocal`), id yang sama juga dipakai sebagai id notifikasi
/// sistem sehingga banner-nya bisa dihapus lewat `dismissLocal`.
class StoredNotification {
  const StoredNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;

  /// Rute tujuan saat item dibaca (hasil `routeFromMessage`).
  final String route;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'route': route,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoredNotification.fromJson(Map<String, dynamic> json) {
    return StoredNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      route: json['route'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Penyimpanan daftar notifikasi di file JSON.
///
/// File-based (bukan SharedPreferences/sqflite): ukurannya kecil, isinya
/// bukan data sensitif, dan perilaku "survive restart" mudah diuji dengan
/// direktori temp. File korup diperlakukan sebagai daftar kosong — app
/// tidak boleh crash hanya karena sisa penulisan terpotong.
class NotificationStore {
  NotificationStore.withFile(this._file);

  final File _file;

  /// State reaktif; halaman daftar dan badge membaca dari sini.
  final ValueNotifier<List<StoredNotification>> items =
      ValueNotifier<List<StoredNotification>>(const []);

  /// Resolve file di direktori dokumen app. **Belum load** — pemanggil
  /// (Notifier) yang memuat lewat [load], supaya store hasil injeksi tes
  /// ikut melewati jalur yang sama.
  static Future<NotificationStore> create() async {
    final dir = await getApplicationDocumentsDirectory();
    return NotificationStore.withFile(File(p.join(dir.path, 'notifications.json')));
  }

  Future<void> load() async {
    if (!_file.existsSync()) {
      items.value = const [];
      return;
    }
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      final list = (decoded as List)
          .map((e) => StoredNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      items.value = list;
    } catch (_) {
      // JSON korup (tertulis separuh, dsb.) -> mulai dari daftar kosong.
      items.value = const [];
    }
  }

  Future<void> add(StoredNotification n) async {
    // Cegah tabrakan id (mis. dua push dalam milidetik yang sama):
    // akhiran -2, -3, dst. sampai unik.
    var candidate = n.id;
    var i = 2;
    while (items.value.any((e) => e.id == candidate)) {
      candidate = '${n.id}-$i';
      i++;
    }
    final unique = n.id == candidate
        ? n
        : StoredNotification(
            id: candidate,
            title: n.title,
            body: n.body,
            route: n.route,
            createdAt: n.createdAt,
          );
    items.value = [unique, ...items.value];
    await _save();
  }

  Future<void> remove(String id) async {
    items.value = items.value.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> clear() async {
    items.value = const [];
    await _save();
  }

  Future<void> _save() async {
    await _file.writeAsString(jsonEncode(items.value));
  }

  void dispose() => items.dispose();
}
