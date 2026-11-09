// ===========================================================================
// Provider: CommentsNotifier & commentsProvider
// ---------------------------------------------------------------------------
// Menggunakan AsyncNotifierProvider.family dari flutter_riverpod untuk
// mengelola state daftar komentar berdasarkan postId.
//
// Alur state otomatis:
//   1. AsyncLoading  → saat data sedang diambil dari API
//   2. AsyncData     → saat data berhasil diterima
//   3. AsyncError    → saat terjadi error (otomatis dari exception)
//
// Cara penggunaan di UI:
//   final state = ref.watch(commentsProvider(postId));
//   state.when(
//     loading: () => CircularProgressIndicator(),
//     error:   (e, _) => Text(commentFriendlyError(e)),
//     data:    (comments) => ListView(...),
//   );
// ===========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'network_errors.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

// ---------------------------------------------------------------------------
// Provider: commentRepositoryProvider
// ---------------------------------------------------------------------------
// Menggunakan dioProvider terpusat sehingga baseUrl dan konfigurasi timeout
// 10 detik dikelola di satu tempat (single source of truth).
// ---------------------------------------------------------------------------

/// Provider untuk [CommentRepository].
///
/// Menggunakan instance Dio terpusat dari [dioProvider].
/// Dapat dioverride saat unit test dengan Fake/Mock repository.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

// ---------------------------------------------------------------------------
// AsyncNotifier: CommentsNotifier
// ---------------------------------------------------------------------------
// Kelas ini mengelola state asinkron untuk daftar Comment milik satu post.
// postId diteruskan melalui constructor saat family provider memanggil factory.
// ---------------------------------------------------------------------------

/// Notifier yang mengelola state daftar komentar untuk satu [postId].
///
/// Menggunakan [AsyncNotifier] sehingga state (loading/data/error)
/// dikelola secara otomatis oleh Riverpod.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  /// ID post yang komentarnya dikelola oleh notifier ini.
  final int postId;

  CommentsNotifier(this.postId);

  /// build() dipanggil otomatis pertama kali oleh Riverpod.
  /// Exception yang dilempar oleh repository otomatis diubah menjadi [AsyncError].
  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  /// Memuat ulang daftar komentar untuk post ini (pull-to-refresh / retry).
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider: commentsProvider
// ---------------------------------------------------------------------------
// AsyncNotifierProvider.family digunakan untuk membuat provider berparameter (postId).
// Setiap postId memiliki instance notifier dan state tersendiri.
// ---------------------------------------------------------------------------

/// Provider utama untuk daftar komentar berdasarkan [postId].
///
/// Contoh: `ref.watch(commentsProvider(postId))`
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
  (postId) => CommentsNotifier(postId),
  retry: (retryCount, error) => null,
);

// ---------------------------------------------------------------------------
// Helper: commentFriendlyError (wrapper dari friendlyErrorMessage)
// ---------------------------------------------------------------------------
/// Mengkonversi error apapun menjadi pesan string yang ramah pengguna.
///
/// Penanganan:
/// - Timeout (connect/send/receive)
/// - Connection error (tanpa internet)
/// - 404 (Data tidak ditemukan)
/// - 500 (Server bermasalah)
String commentFriendlyError(Object error) {
  return friendlyErrorMessage(error);
}
