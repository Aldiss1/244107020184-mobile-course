import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Token store palsu: meniru kontrak TokenStore tanpa menyentuh Keychain.
class FakeTokenStore {
  String? access;
  String? refresh;

  void save({required String access, required String refresh}) {
    this.access = access;
    this.refresh = refresh;
  }

  void clear() {
    access = null;
    refresh = null;
  }

  bool get hasSession => access != null && access!.isNotEmpty;
}

void main() {
  group('routeFromMessage', () {
    test('rute kosong jatuh ke home', () {
      expect(routeFromMessage({}), Routes.home);
      expect(routeFromMessage({'route': ''}), Routes.home);
      expect(routeFromMessage({'route': '   '}), Routes.home);
    });

    test('menambahkan garis miring di depan', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('memakai id bila route tidak dikirim', () {
      expect(routeFromMessage({'id': '3'}), '/pengumuman/3');
    });

    test('data payload lengkap membawa id pengumuman', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), Routes.announcement('3'));
    });

    test('memangkas spasi di ujung', () {
      expect(routeFromMessage({'route': ' /pengumuman/9 '}), '/pengumuman/9');
    });
  });

  group('sesi & refresh', () {
    test('login menyimpan access + refresh', () async {
      final store = FakeTokenStore();
      final session = await AuthRepository(
        latency: Duration.zero,
      ).login(email: 'mahasiswa@polinema.ac.id', password: 'rahasia123');

      store.save(access: session.access, refresh: session.refresh);

      expect(store.hasSession, isTrue);
      expect(store.refresh, isNotEmpty);
    });

    test('kredensial tidak valid ditolak', () async {
      final repo = AuthRepository(latency: Duration.zero);
      expect(
        () => repo.login(email: 'tanpa-at', password: 'rahasia123'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => repo.login(email: 'a@b.c', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('refresh berhasil menghasilkan access token baru', () async {
      final repo = AuthRepository(latency: Duration.zero);
      final renewed = await repo.refresh('mock-refresh');
      expect(renewed, startsWith('mock-access-renewed-'));
    });

    test('refresh kosong -> sesi dibersihkan dan wajib login ulang', () async {
      final store = FakeTokenStore()
        ..access = 'mock-access'
        ..refresh = '';

      var needsLogin = false;
      try {
        await AuthRepository(latency: Duration.zero).refresh(store.refresh!);
      } catch (_) {
        store.clear();
        needsLogin = true;
      }

      expect(needsLogin, isTrue);
      expect(store.hasSession, isFalse);
    });
  });

  group('friendlyError', () {
    test('401 diterjemahkan menjadi pesan sesi berakhir', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/devices'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/devices'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(friendlyError(error), contains('masuk kembali'));
    });

    test('connection error diterjemahkan menjadi pesan jaringan', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyError(error), contains('koneksi internet'));
    });

    test('AuthException tampil apa adanya tanpa prefix Exception:', () {
      expect(friendlyError(const AuthException('Refresh token hilang')), 'Refresh token hilang');
    });
  });
}
