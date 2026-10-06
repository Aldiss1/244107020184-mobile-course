import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_providers.dart';
import '../providers/post_providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);
    final offline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Posts (cache-first)')),
      body: Column(
        children: [
          if (offline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Mode offline: menampilkan data dari cache lokal',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e', textAlign: TextAlign.center),
                ),
              ),
              data: (posts) => RefreshIndicator(
                onRefresh: () async {
                  final ok =
                      await ref.read(postsProvider.notifier).refresh();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal refresh, menampilkan cache'),
                      ),
                    );
                  }
                },
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text(post.id.toString())),
                      title: Text(post.title, maxLines: 1),
                      subtitle: Text(post.body, maxLines: 2),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
