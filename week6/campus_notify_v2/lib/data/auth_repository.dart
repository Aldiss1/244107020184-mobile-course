import 'package:dio/dio.dart';

/// Hasil login: sepasang token yang harus disimpan di secure storage.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Profil user dari `GET /users/me` (bukti token Bearer bekerja).
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.image,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String image;

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      image: json['image'] as String,
    );
  }
}

/// Auth provider berbasis API dummyjson.com (https://dummyjson.com).
///
/// Memakai **Dio polos** (tanpa interceptor refresh): endpoint
/// `/auth/refresh` sendiri tidak boleh lewat interceptor, kalau tidak
/// 401 pada refresh bisa memicu loop tukar-token. Dio ber-interceptor
/// (lihat `api_client.dart`) memanggil [refresh] dari luar.
class AuthRepository {
  AuthRepository({Dio? dio})
    : _dio = dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://dummyjson.com',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  /// `POST /auth/login` -> sepasang token.
  ///
  /// HTTP 400 (kredensial salah) diterjemahkan jadi [AuthException] supaya
  /// UI menampilkan kalimat ramah; error jaringan diteruskan apa adanya
  /// (DioException) agar `friendlyError` memberi pesan yang tepat.
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return _sessionFrom(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const AuthException('Username atau kata sandi salah.');
      }
      rethrow;
    }
  }

  /// `POST /auth/refresh` -> pasangan token **baru** (access + refresh).
  ///
  /// Semua kegagalan berarti refresh token sudah tidak bisa dipakai:
  /// pengguna wajib login ulang.
  Future<AuthSession> refresh(String refreshToken) async {
    try {
      final res = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return _sessionFrom(res.data as Map<String, dynamic>);
    } on DioException {
      throw const AuthException('Refresh token tidak valid. Silakan masuk kembali.');
    }
  }

  AuthSession _sessionFrom(Map<String, dynamic> json) {
    return AuthSession(
      access: json['accessToken'] as String,
      refresh: json['refreshToken'] as String,
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
