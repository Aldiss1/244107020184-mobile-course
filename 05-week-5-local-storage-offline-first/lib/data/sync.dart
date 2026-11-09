import 'local/note.dart';
import 'repositories/note_repository.dart';

class OfflineException implements Exception {
  const OfflineException(this.message);

  final String message;

  @override
  String toString() => 'OfflineException: $message';
}

/// Mengirim catatan dirty ke "server" (simulasi) lalu menandainya bersih.
/// Mengembalikan jumlah catatan yang tersinkron.
Future<int> syncNotes(
  NoteRepository repo, {
  bool offline = false,
  Duration latency = const Duration(seconds: 1),
}) async {
  if (offline) {
    throw const OfflineException('Perangkat offline, sinkronisasi ditunda.');
  }
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;

  // Simulasi upload. Pada project nyata: kirim tiap catatan dirty
  // ke REST API, lalu tandai bersih HANYA bila server menjawab 2xx.
  await Future.delayed(latency);
  await repo.markAllSynced();
  return dirtyCount;
}

/// Aturan konflik: last-write-wins berdasarkan updatedAt.
Note resolveConflict(Note local, Note remote) {
  return remote.updatedAt.isAfter(local.updatedAt) ? remote : local;
}
