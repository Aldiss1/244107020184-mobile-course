// Note Form Dialog Widget (Praktikum 3)
import 'package:flutter/material.dart';

class NoteFormDialog extends StatelessWidget {
  const NoteFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note Form'),
      content: const Text('Note Form Fields'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
