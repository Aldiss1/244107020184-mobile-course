import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/network_errors.dart';
import '../data/paged_posts.dart';
import '../widgets/post_tile.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // Muat halaman pertama saat halaman dibuka
    Future.microtask(
      () => ref.read(pagedPostsProvider.notifier).loadNextPage(),
    );

    // Listener pemicu 200px sebelum ujung list
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Scroll Posts'),
      ),
      body: Builder(
        builder: (context) {
          // 1. Error saat items masih kosong -> Layar penuh + tombol Coba lagi
          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      friendlyErrorMessage(state.error!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(pagedPostsProvider.notifier).refresh(),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Loading awal saat items masih kosong
          if (state.isLoadingMore && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. ListView dengan RefreshIndicator dan footer indikator
          return RefreshIndicator(
            onRefresh: () => ref.read(pagedPostsProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _controller,
              itemCount: state.items.length + 1, // +1 untuk footer
              itemBuilder: (context, index) {
                // Item terakhir = footer indikator
                if (index == state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: state.hasMore
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Semua data termuat.',
                              style: TextStyle(color: Colors.grey),
                            ),
                    ),
                  );
                }

                final post = state.items[index];
                return PostTile(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}
