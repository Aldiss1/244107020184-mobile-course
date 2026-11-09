import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/data/local/note.dart';
import 'package:offline_notes/data/repositories/note_repository.dart';
import 'package:offline_notes/data/sync.dart';
import 'package:offline_notes/providers/note_providers.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({List<Note> items = const [], this.throwError = false})
      : items = [...items],
        super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;

  @override
  Future<void> markAllSynced() async {
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(dirty: false);
    }
  }
}

Note _note(String title, {bool dirty = false, DateTime? at}) =>
    Note(title: title, updatedAt: at ?? DateTime(2026, 9, 18), dirty: dirty);

void main() {
  group('Model Note', () {
    test('fromMap aman terhadap field yang hilang', () {
      final note = Note.fromMap({'title': 'Belanja'});
      expect(note.title, 'Belanja');
      expect(note.body, '');
      expect(note.dirty, isFalse);
    });

    test('flag dirty bertahan pada serialisasi', () {
      final note = _note('a', dirty: true);
      final restored = Note.fromMap(note.toMap());
      expect(restored.dirty, isTrue);
      expect(restored.updatedAt, note.updatedAt);
    });
  });

  group('Provider dengan repository palsu', () {
    test('notesProvider sukses', () async {
      final fake = FakeNoteRepository(items: [_note('Beli susu'), _note('PR')]);
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final notes = await container.read(notesProvider.future);
      expect(notes.length, 2);
      expect(notes.first.title, 'Beli susu');
    });

    test('notesProvider error diteruskan', () async {
      final fake = FakeNoteRepository(throwError: true);
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      container.read(notesProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(notesProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });

  group('syncNotes', () {
    test('mengembalikan 0 bila tidak ada catatan dirty', () async {
      final repo = FakeNoteRepository(items: [_note('Bersih')]);
      final count = await syncNotes(repo);
      expect(count, 0);
    });

    test('mengembalikan jumlah catatan dirty dan menandainya bersih', () async {
      final repo = FakeNoteRepository(items: [
        _note('A', dirty: true),
        _note('B', dirty: true),
        _note('C'),
      ], );
      final count = await syncNotes(repo, latency: Duration.zero);
      expect(count, 2);
      expect(repo.items.every((n) => !n.dirty), isTrue);
    });

    test('melempar OfflineException bila offline = true', () async {
      final repo = FakeNoteRepository(items: [_note('X', dirty: true)]);
      expect(
        () => syncNotes(repo, offline: true),
        throwsA(isA<OfflineException>()),
      );
    });
  });

  group('resolveConflict', () {
    test('menggunakan versi remote bila lebih baru', () {
      final local = _note('lokal', at: DateTime(2026, 9, 1));
      final remote = _note('remote', at: DateTime(2026, 9, 10));
      expect(resolveConflict(local, remote).title, 'remote');
    });

    test('menggunakan versi lokal bila lebih baru', () {
      final local = _note('lokal', at: DateTime(2026, 9, 10));
      final remote = _note('remote', at: DateTime(2026, 9, 1));
      expect(resolveConflict(local, remote).title, 'lokal');
    });
  });
}
