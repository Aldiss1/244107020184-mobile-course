import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_store.dart';
import '../../data/app_badge.dart';

/// Daftar notifikasi belum dibaca.
///
/// Satu sumber reaktif untuk halaman daftar dan badge ikon bel.
/// "Dibaca" = dihapus dari daftar (sesuai perilaku yang diminta).
final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<StoredNotification>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends Notifier<List<StoredNotification>> {
  NotificationStore? _store;

  /// Dipakai tes: mengunci store dengan file di direktori temp supaya
  /// [NotificationStore.create] (path_provider) tidak tersentuh.
  @visibleForTesting
  NotificationStore? get store => _store;

  @visibleForTesting
  set store(NotificationStore? value) => _store = value;

  @override
  List<StoredNotification> build() => const [];

  /// Idempoten: buat store (bila belum ada), muat file, sinkronkan state.
  /// Dipanggil sekali saat bootstrap aplikasi.
  Future<void> init() async {
    _store ??= await NotificationStore.create();
    await _store!.load();
    state = _store!.items.value;
  }

  Future<void> add(StoredNotification n) async {
    final store = _store;
    if (store == null) {
      // init() belum selesai (notifikasi tiba sebelum bootstrap rampung):
      // buat store on-the-fly supaya notifikasi tidak hilang.
      await init();
    }
    await _store!.add(n);
    state = _store!.items.value;
    unawaited(AppBadge().setBadge(state.length));
  }

  Future<void> remove(String id) async {
    final store = _store;
    if (store == null) return;
    await store.remove(id);
    state = store.items.value;
    unawaited(AppBadge().setBadge(state.length));
  }

  Future<void> clearAll() async {
    final store = _store;
    if (store == null) return;
    await store.clear();
    state = store.items.value;
    unawaited(AppBadge().setBadge(state.length));
  }
}
