import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/device_registrar.dart';
import '../data/token_store.dart';
import 'notification_provider.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final apiClientProvider = Provider<Dio>((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

/// Pengirim token FCM ke backend.
///
/// Endpoint diatur lewat `--dart-define=DEVICES_URL=...`; default-nya
/// `https://dummyjson.com/devices` yang memang belum ada (404), sehingga
/// aplikasi tidak berpura-pura berhasil.
final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => DeviceRegistrar(),
);

/// `true` bila ada access token di secure storage.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

/// Profil user yang sedang login (bukti token Bearer bekerja).
/// `null` bila tidak login atau fetch gagal — UI memakai sapaan netral.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final loggedIn = await ref.watch(authStateProvider.future);
  if (!loggedIn) return null;
  try {
    final res = await ref.watch(apiClientProvider).get<dynamic>('/users/me');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    // Notifikasi milik sesi yang berakhir: hapus supaya user berikutnya
    // tidak melihat daftar lama, dan badge sistem ikut reset ke 0.
    await ref.read(notificationsProvider.notifier).clearAll();
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
