import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider =
    Provider<PrefsRepository>((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final previous = state.value ?? false;
    final next = !previous;
    // Optimistic update: UI langsung berubah tanpa menunggu disk.
    state = AsyncData(next);
    try {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
    } catch (_) {
      // Gagal menyimpan: kembalikan ke nilai sebelumnya.
      state = AsyncData(previous);
      rethrow;
    }
  }
}

/// Membaca waktu terakhir dibuka (dari sesi sebelumnya),
/// lalu mencatat waktu sekarang untuk sesi berikutnya.
final lastOpenedProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(prefsRepositoryProvider);
  final previous = await repo.getLastOpened();
  await repo.markOpenedNow();
  return previous;
});
