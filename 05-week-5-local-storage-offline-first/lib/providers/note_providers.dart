import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';
import 'offline_providers.dart';

final noteRepositoryProvider =
    Provider<NoteRepository>((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>(
  (ref) => ref.watch(noteRepositoryProvider).fetchNotes(),
);

final dirtyCountProvider = FutureProvider<int>(
  (ref) => ref.watch(noteRepositoryProvider).countDirty(),
);

final noteByIdProvider = FutureProvider.family<Note?, int>(
  (ref, id) => ref.watch(noteRepositoryProvider).getNoteById(id),
);

final noteActionsProvider = Provider<NoteActions>((ref) => NoteActions(ref));

/// Kumpulan aksi yang mengubah data. Setiap mutasi diakhiri invalidate
/// agar provider baca (notes & dirty count) memuat ulang dari database.
class NoteActions {
  NoteActions(this._ref);

  final Ref _ref;

  NoteRepository get _repo => _ref.read(noteRepositoryProvider);

  Future<void> add(String title, String body) async {
    await _repo.addNote(title: title, body: body);
    _refresh();
  }

  Future<void> update(Note note) async {
    await _repo.updateNote(note);
    _refresh();
  }

  Future<void> delete(int id) async {
    await _repo.deleteNote(id);
    _refresh();
  }

  Future<int> sync() async {
    final offline = _ref.read(forceOfflineProvider);
    final count = await syncNotes(_repo, offline: offline);
    _refresh();
    return count;
  }

  void _refresh() {
    _ref.invalidate(notesProvider);
    _ref.invalidate(dirtyCountProvider);
  }
}
