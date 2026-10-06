import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/sync.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';
import 'posts_page.dart';
import 'settings_page.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Note? note,
  ]) async {
    final result = await showDialog<NoteFormResult>(
      context: context,
      builder: (_) => NoteFormDialog(initial: note),
    );
    if (result == null) return; // dibatalkan
    final actions = ref.read(noteActionsProvider);
    if (note == null) {
      await actions.add(result.title, result.body);
    } else {
      await actions.update(
        note.copyWith(title: result.title, body: result.body),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirty = ref.watch(dirtyCountProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Tooltip(
            message: 'Catatan belum tersinkron',
            child: Badge(
              isLabelVisible: dirty > 0,
              label: Text('$dirty'),
              child: const Icon(Icons.cloud_upload_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Posts (cache-first)',
            icon: const Icon(Icons.article_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostsPage()),
            ),
          ),
          IconButton(
            tooltip: 'Sinkronkan',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final count =
                    await ref.read(noteActionsProvider).sync();
                messenger.showSnackBar(SnackBar(
                  content: Text(count == 0
                      ? 'Semua catatan sudah tersinkron'
                      : '$count catatan berhasil disinkronkan'),
                ));
              } on OfflineException catch (e) {
                messenger.showSnackBar(
                    SnackBar(content: Text(e.message)));
              }
            },
          ),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat catatan: $e')),
        data: (notes) => notes.isEmpty
            ? const Center(child: Text('Belum ada catatan'))
            : ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                      note.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note.dirty)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 18,
                              color: Colors.orange,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            if (note.id != null) {
                              ref.read(noteActionsProvider).delete(note.id!);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () => _openForm(context, ref, note),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
