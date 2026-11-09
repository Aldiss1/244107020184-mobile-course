import 'dart:io';

import 'package:campus_notify/data/notification_store.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/presentation/providers/auth_provider.dart';
import 'package:campus_notify/presentation/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes.dart';

ProviderContainer makeContainer(File storeFile) {
  // TokenStore asli + secure storage palsu: logout() tidak boleh menyentuh
  // MethodChannel sungguhan di lingkungan test.
  return ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(
        TokenStore(storage: FakeSecureStorage()),
      ),
    ],
  )..read(notificationsProvider.notifier).store =
      NotificationStore.withFile(storeFile);
}

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('notif_prov'));
  tearDown(() async => tmp.delete(recursive: true));

  test('add -> remove -> clearAll memperbarui state', () async {
    final container = makeContainer(File('${tmp.path}/n.json'));
    addTearDown(container.dispose);
    final n = container.read(notificationsProvider.notifier);
    await n.init();

    await n.add(
      StoredNotification(
        id: '1',
        title: 'a',
        body: 'b',
        route: '/',
        createdAt: _ts,
      ),
    );
    expect(container.read(notificationsProvider).length, 1);

    await n.remove('1');
    expect(container.read(notificationsProvider), isEmpty);

    await n.add(
      StoredNotification(
        id: '2',
        title: 'a',
        body: 'b',
        route: '/',
        createdAt: _ts,
      ),
    );    await n.clearAll();
    expect(container.read(notificationsProvider), isEmpty);
  });

  test('logout mengosongkan daftar notifikasi', () async {
    final container = makeContainer(File('${tmp.path}/n.json'));
    addTearDown(container.dispose);
    final n = container.read(notificationsProvider.notifier);
    await n.init();
    await n.add(
      StoredNotification(
        id: '3',
        title: 'a',
        body: 'b',
        route: '/',
        createdAt: _ts,
      ),
    );

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(notificationsProvider), isEmpty);
  });
}

final _ts = DateTime(2026, 11, 2, 10, 0);
