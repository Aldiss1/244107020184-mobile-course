import 'dart:convert';
import 'dart:io';

import 'package:campus_notify/data/notification_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('notif_store_test');
    file = File('${tmp.path}/notifications.json');
  });

  tearDown(() async => tmp.delete(recursive: true));

  StoredNotification make(String id) => StoredNotification(
        id: id,
        title: 'Judul $id',
        body: 'Isi $id',
        route: '/pengumuman/$id',
        createdAt: DateTime(2026, 11, 2, 10, 0),
      );

  test('add menyimpan ke file dan bisa dibaca ulang (persist)', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('3'));

    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items.value.length, 1);
    expect(again.items.value.first.id, '3');
    expect(again.items.value.first.route, '/pengumuman/3');
  });

  test('add newest-first', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.add(make('2'));
    expect(store.items.value.map((e) => e.id).toList(), ['2', '1']);
  });

  test('id duplikat diberi akhiran unik', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('7'));
    await store.add(make('7'));
    expect(store.items.value.map((e) => e.id).toList(), ['7-2', '7']);
  });

  test('remove menghapus satu item dan menulis ulang file', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.add(make('2'));
    await store.remove('1');

    expect(store.items.value.map((e) => e.id).toList(), ['2']);
    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items.value.length, 1);
  });

  test('clear mengosongkan daftar dan file', () async {
    final store = NotificationStore.withFile(file);
    await store.add(make('1'));
    await store.clear();
    expect(store.items.value, isEmpty);
    final again = NotificationStore.withFile(file);
    await again.load();
    expect(again.items.value, isEmpty);
  });

  test('file hilang -> daftar kosong, tanpa error', () async {
    final store = NotificationStore.withFile(file);
    await store.load();
    expect(store.items.value, isEmpty);
  });

  test('file JSON korup -> daftar kosong, tanpa error', () async {
    file.writeAsStringSync('{"id": "1", rusak');
    final store = NotificationStore.withFile(file);
    await store.load();
    expect(store.items.value, isEmpty);
  });

  test('round-trip JSON mempertahankan createdAt', () async {
    final n = make('9');
    final back =
        StoredNotification.fromJson(jsonDecode(jsonEncode(n.toJson())));
    expect(back.createdAt, n.createdAt);
  });
}
