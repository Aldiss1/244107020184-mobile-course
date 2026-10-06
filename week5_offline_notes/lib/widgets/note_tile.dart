import 'package:flutter/material.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
              child: Chip(
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
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
