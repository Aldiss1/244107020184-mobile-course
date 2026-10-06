import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';

class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  Future<void> _editNote(BuildContext context, WidgetRef ref, Note note) async {
    final result = await showDialog<NoteFormResult>(
      context: context,
      builder: (_) => NoteFormDialog(initial: note),
    );
    if (result == null) return;
    await ref.read(noteActionsProvider).update(
          note.copyWith(title: result.title, body: result.body),
        );
    ref.invalidate(noteByIdProvider(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteByIdProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          noteAsync.maybeWhen(
            data: (note) => note != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Catatan',
                    onPressed: () => _editNote(context, ref, note),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          noteAsync.maybeWhen(
            data: (note) => note != null
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Hapus Catatan',
                    onPressed: () async {
                      await ref.read(noteActionsProvider).delete(id);
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: noteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat catatan: $e')),
        data: (note) {
          if (note == null) {
            return const Center(child: Text('Catatan tidak ditemukan'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (note.dirty)
                      const Chip(
                        avatar: Icon(
                          Icons.cloud_upload_outlined,
                          size: 14,
                          color: Colors.orange,
                        ),
                        label: Text(
                          'belum tersinkron',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: Colors.orange),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Diperbarui: ${note.updatedAt.toLocal().toString().split('.').first}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      note.body.isEmpty ? '(Tidak ada isi catatan)' : note.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
