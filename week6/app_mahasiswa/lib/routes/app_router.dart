import 'package:go_router/go_router.dart';

import '../data/models/post.dart';
import '../pages/paged_post_page.dart';
import '../pages/post_detail_page.dart';

/// Konfigurasi routing aplikasi menggunakan GoRouter.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PagedPostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        // Ambil ID dari path parameter
        final idStr = state.pathParameters['id'] ?? '0';
        final postId = int.tryParse(idStr) ?? 0;

        // Ambil objek Post jika diteruskan via `extra` saat navigasi dari list
        final post = state.extra as Post?;

        return PostDetailPage(
          postId: postId,
          initialPost: post,
        );
      },
    ),
  ],
);
