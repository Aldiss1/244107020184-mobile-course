import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/api_errors.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fakes.dart';

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

  group('UserProfile', () {
    test('membaca field dan menyusun nama lengkap', () {
      final p = UserProfile.fromJson({
        'firstName': 'Emily',
        'lastName': 'Johnson',
        'email': 'emily@x.com',
        'image': 'https://example.com/i.png',
      });
      expect(p.fullName, 'Emily Johnson');
      expect(p.email, 'emily@x.com');
    });
  });

  group('auth dummyjson', () {
    test('login mengembalikan sepasang token', () async {
      final repo = AuthRepository(
        dio: dioCanned((_) => {'accessToken': 'ACC', 'refreshToken': 'REF'}),
      );
      final session =
          await repo.login(username: 'emilys', password: 'emilyspass');
      expect(session.access, 'ACC');
      expect(session.refresh, 'REF');
    });

    test('login 400 melempar AuthException dengan pesan ramah', () async {
      final repo = AuthRepository(
        dio: dioCanned(
          (_) => {'message': 'Invalid credentials'},
          status: 400,
        ),
      );
      Object? caught;
      try {
        await repo.login(username: 'x', password: 'y');
      } catch (e) {
        caught = e;
      }
      expect(caught, isA<AuthException>());
      expect(caught.toString(), 'Username atau kata sandi salah.');
    });

    test('refresh mengembalikan pasangan token baru', () async {
      final repo = AuthRepository(
        dio: dioCanned(
          (_) => {'accessToken': 'ACC2', 'refreshToken': 'REF2'},
        ),
      );
      final session = await repo.refresh('REF');
      expect(session.access, 'ACC2');
      expect(session.refresh, 'REF2');
    });

    test('refresh 400 melempar AuthException (paksa login ulang)', () async {
      final repo = AuthRepository(
        dio: dioCanned((_) => {'message': 'bad'}, status: 400),
      );
      expect(
        () => repo.refresh('REF'),
        throwsA(isA<AuthException>()),
      );
    });

    test('network down diteruskan sebagai DioException (bukan AuthException)',
        () async {
      final repo = AuthRepository(
        dio: Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
          ..httpClientAdapter = CannedAdapter((options) async {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            );
          }),
      );
      expect(
        () => repo.login(username: 'x', password: 'y'),
        throwsA(isA<DioException>()),
      );
    });

    test('interceptor: 401 -> refresh -> retry sekali -> sukses', () async {
      final store = TokenStore(storage: FakeSecureStorage());
      await store.save(access: 'expired', refresh: 'REF');
      final authDio = dioCanned(
        (path) =>
            path.contains('/auth/refresh')
                ? {'accessToken': 'NEW', 'refreshToken': 'REF2'}
                : {},
      );
      var meCalls = 0;
      final api = buildApiClient(store, AuthRepository(dio: authDio))
        ..httpClientAdapter = CannedAdapter((options) async {
          meCalls++;
          if (meCalls == 1) {
            throw DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
                data: {'message': 'expired'},
              ),
            );
          }
          return jsonBody({'id': 1});
        });

      final res = await api.get<dynamic>('/users/me');

      expect(res.statusCode, 200);
      expect(meCalls, 2);
      expect(await store.readAccess(), 'NEW');
      expect(await store.readRefresh(), 'REF2');
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
