/// Hasil login: sepasang token yang harus disimpan di secure storage.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Mock auth provider.
///
/// Titik migrasi ke Firebase Auth: ganti isi [login] dengan
/// `FirebaseAuth.instance.signInWithEmailAndPassword(...)` lalu ambil
/// `await user.getIdToken()` sebagai access token. Bentuk [AuthSession] dan
/// seluruh lapisan di atasnya (TokenStore, Dio interceptor, AuthNotifier)
/// tidak perlu berubah.
class AuthRepository {
  AuthRepository({this.latency = const Duration(milliseconds: 400)});

  /// Dikurangi di unit test supaya cepat.
  final Duration latency;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    if (!email.contains('@') || password.length < 6) {
      throw const AuthException('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT (header.payload.signature). Jangan pernah mem-parse JWT
    // secara manual untuk keputusan keamanan — verifikasi selalu di server.
    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
    );
  }

  /// Menukar refresh token dengan access token baru.
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(latency);
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
