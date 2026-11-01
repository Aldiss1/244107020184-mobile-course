import 'package:campus_notify/messaging/native_push_bridge.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Menguji normalisasi payload yang dikirim `AppDelegate.swift`.
///
/// Native-nya sendiri tidak bisa dijalankan di `flutter test`, jadi yang
/// diuji adalah kontrak bentuk data: `{title, body, data}`.
void main() {
  group('BridgePushPayload.fromMap', () {
    test('membaca title, body, dan data', () {
      final payload = BridgePushPayload.fromMap({
        'title': 'Jadwal kuliah berubah',
        'body': 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
        'data': {'route': '/pengumuman/3', 'id': '3'},
      });

      expect(payload.title, 'Jadwal kuliah berubah');
      expect(payload.body, contains('Ruang A2'));
      expect(routeFromMessage(payload.data), '/pengumuman/3');
    });

    test('payload tanpa data tetap menghasilkan rute home', () {
      final payload = BridgePushPayload.fromMap({
        'title': 'Tanpa route',
        'body': '',
        'data': <String, dynamic>{},
      });

      expect(routeFromMessage(payload.data), Routes.home);
    });

    test('field yang hilang tidak menyebabkan crash', () {
      final payload = BridgePushPayload.fromMap(<dynamic, dynamic>{});

      expect(payload.title, isEmpty);
      expect(payload.body, isEmpty);
      expect(payload.data, isEmpty);
      expect(routeFromMessage(payload.data), Routes.home);
    });

    test('data bertipe dinamis dikoersi menjadi Map<String, dynamic>', () {
      final payload = BridgePushPayload.fromMap({
        'title': 'x',
        'body': 'y',
        'data': <dynamic, dynamic>{'route': 'pengumuman/9'},
      });

      expect(payload.data.keys.first, isA<String>());
      expect(routeFromMessage(payload.data), '/pengumuman/9');
    });
  });

  group('routeFromMessage konsisten untuk kedua sumber', () {
    test('payload FCM dan payload bridge menghasilkan rute identik', () {
      final fromFcm = routeFromMessage({
        'route': '/pengumuman/3',
        'id': '3',
      });
      final fromBridge = routeFromMessage(
        BridgePushPayload.fromMap({
          'title': 't',
          'body': 'b',
          'data': {'route': '/pengumuman/3', 'id': '3'},
        }).data,
      );

      expect(fromFcm, fromBridge);
    });
  });
}
