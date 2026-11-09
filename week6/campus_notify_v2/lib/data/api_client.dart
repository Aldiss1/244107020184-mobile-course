import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

/// Kunci `extra` penanda bahwa request ini sudah pernah di-retry.
const String _retriedKey = 'retried_after_refresh';

/// Dio dengan refresh token otomatis.
///
/// Alur saat menerima 401:
/// 1. ambil refresh token dari secure storage,
/// 2. tukar jadi access token baru,
/// 3. ulangi request **sekali**,
/// 4. kalau refresh sendiri gagal/kedaluwarsa -> `clear()` dan lempar error
///    supaya lapisan auth memaksa login ulang.
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      // API kampus digantikan dummyjson.com: login, refresh, dan profil
      // user semuanya endpoint publik yang terdokumentasi.
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = options.extra[_retriedKey] == true;

        // Bukan 401, atau sudah pernah di-retry -> jangan looping.
        if (!isUnauthorized || alreadyRetried) {
          return handler.next(error);
        }

        final refreshToken = await store.readRefresh();
        if (refreshToken == null || refreshToken.isEmpty) {
          await store.clear();
          return handler.next(error);
        }

        try {
          final renewed = await auth.refresh(refreshToken);
          // Refresh token ikut berotasi (dummyjson menerbitkan pasangan
          // baru), jadi keduanya disimpan ke secure storage.
          await store.save(access: renewed.access, refresh: renewed.refresh);

          options.extra[_retriedKey] = true;
          // onRequest akan menimpa header Authorization dengan token baru.
          final retried = await dio.fetch<dynamic>(options);
          return handler.resolve(retried);
        } catch (_) {
          // Refresh ikut mati -> paksa login ulang.
          await store.clear();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
}
