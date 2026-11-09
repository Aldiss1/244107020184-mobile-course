import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_providers.dart';
import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

/// Halaman detail post yang menampilkan judul dan isi lengkap post,
/// beserta daftar komentar terkait.
///
/// Mendukung dua sumber data:
/// 1. Dari navigasi list (`initialPost` melalui GoRouter `extra`) -> instan tanpa loading.
/// 2. Dari URL langsung `/post/:id` (deep link) -> diambil via [postDetailProvider].
class PostDetailPage extends ConsumerWidget {
  final int postId;
  final Post? initialPost;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialPost != null) {
      return _buildScaffold(context, ref, initialPost!);
    }

    final postAsync = ref.watch(postDetailProvider(postId));

    return postAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Post #$postId')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text('Post #$postId')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  friendlyErrorMessage(err),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (post) => _buildScaffold(context, ref, post),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, Post post) {
    final commentsAsync = ref.watch(commentsProvider(post.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Post #${post.id}'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(postDetailProvider(post.id));
          await ref.read(commentsProvider(post.id).notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header Card: Title & Body Lengkap
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          avatar: const Icon(Icons.tag, size: 16),
                          label: Text('Post ID: ${post.id}'),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text('User: ${post.userId}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    Text(
                      post.body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bagian Komentar (integrasi commentsProvider dari challenge sebelumnya)
            Row(
              children: [
                const Icon(Icons.comment_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Komentar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            commentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        commentFriendlyError(err),
                        style: TextStyle(color: Colors.red.shade900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.read(commentsProvider(post.id).notifier).refresh(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Belum ada komentar.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              comment.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.body,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
