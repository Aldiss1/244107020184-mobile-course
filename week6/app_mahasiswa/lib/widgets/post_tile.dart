import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/post.dart';

/// Widget komponen baris post untuk [ListView.builder].
///
/// Komponen ini diekstrak agar tampilan daftar post modular,
/// rapi, serta mudah diuji secara isolated dalam unit/widget test.
class PostTile extends StatelessWidget {
  /// Objek post yang ditampilkan.
  final Post post;

  /// Aksi opsional saat tile ditekan.
  /// Jika tidak dispesifikasikan, default-nya bernavigasi ke route `/post/:id`.
  final VoidCallback? onTap;

  const PostTile({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${post.id}'),
      ),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        post.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ??
          () {
            // Navigasi ke halaman detail dengan membawa data post lewat extra
            context.push('/post/${post.id}', extra: post);
          },
    );
  }
}
