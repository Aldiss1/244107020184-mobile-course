import 'package:flutter/material.dart';

import '../data/local/note.dart';

typedef NoteFormResult = ({String title, String body});

class NoteFormDialog extends StatefulWidget {
  const NoteFormDialog({super.key, this.initial});

  final Note? initial;

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.initial?.body ?? '');
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Judul wajib diisi');
      return;
    }
    Navigator.of(context).pop<NoteFormResult>(
      (title: title, body: _body.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Catatan baru' : 'Ubah catatan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Judul', errorText: _error),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Isi catatan'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
