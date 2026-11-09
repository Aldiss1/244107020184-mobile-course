import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../remote/post.dart';

class PostRepository {
  PostRepository({Dio? dio, Future<Database> Function()? openDb})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://jsonplaceholder.typicode.com',
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            )),
        _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  /// Baca cache dari tabel cached_posts (tanpa jaringan).
  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows
        .map((r) => Post.fromJson(
              jsonDecode(r['payload'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Ambil dari jaringan, lalu ganti isi cache dalam satu transaksi.
  Future<List<Post>> fetchAndCache() async {
    final res = await _dio.get<List<dynamic>>('/posts');
    final posts = (res.data ?? const [])
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();

    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      final batch = txn.batch();
      for (final post in posts) {
        batch.insert('cached_posts', {
          'id': post.id,
          'payload': jsonEncode(post.toJson()),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
    });
    return posts;
  }
}
