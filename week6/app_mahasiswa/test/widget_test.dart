import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mahasiswa/data/api_client.dart';
import 'package:app_mahasiswa/data/models/comment.dart';
import 'package:app_mahasiswa/data/models/post.dart';
import 'package:app_mahasiswa/data/providers.dart';
import 'package:app_mahasiswa/data/repositories/post_repository.dart';
import 'package:app_mahasiswa/data/repositories/comment_repository.dart';
import 'package:flutter/material.dart';
import 'package:app_mahasiswa/data/comment_providers.dart';
import 'package:app_mahasiswa/widgets/post_tile.dart';

// ===========================================================================
// Fake Repository untuk Post (digunakan di test lama)
// ---------------------------------------------------------------------------
// Mengextend PostRepository dan override fetchPosts agar tidak
// melakukan request HTTP sungguhan selama testing.
// ===========================================================================
class FakePostRepository extends PostRepository {
  FakePostRepository({this.items, this.throwError = false})
      : super(Dio());
  final List<Post>? items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    return items ?? const [];
  }
}

// ===========================================================================
// Fake Repository untuk Comment
// ---------------------------------------------------------------------------
// Mengextend CommentRepository dan override fetchComments agar tidak
// melakukan request HTTP sungguhan selama testing.
//
// Mendukung dua mode:
//   - items != null → kembalikan daftar comment palsu
//   - throwError = true → lempar DioException untuk test error handling
// ===========================================================================
class FakeCommentRepository extends CommentRepository {
  /// [items] adalah data palsu yang akan dikembalikan saat fetchComments dipanggil.
  /// [throwError] jika true, akan melempar DioException (simulasi gagal jaringan).
  FakeCommentRepository({this.items, this.throwError = false}) : super(Dio());

  final List<Comment>? items;
  final bool throwError;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    // Simulasi error jaringan jika throwError = true
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionTimeout,
        message: 'Simulated timeout',
      );
    }
    // Kembalikan data palsu jika ada, atau list kosong jika tidak ada
    return items ?? const [];
  }
}

void main() {
  // =========================================================================
  // Group 1: Test lama untuk Post (tidak diubah)
  // =========================================================================
  group('Unit Test Tanpa Internet (Dio + Riverpod)', () {
    // 1. fromJson aman terhadap field yang hilang
    test('fromJson aman terhadap field yang hilang', () {
      final post = Post.fromJson({});
      expect(post.userId, 0);
      expect(post.id, 0);
      expect(post.title, '');
      expect(post.body, '');
    });

    // 2. friendlyErrorMessage untuk connection error
    test('friendlyErrorMessage untuk connection error', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
      final message = friendlyErrorMessage(error);
      expect(
        message,
        'Tidak dapat terhubung ke server. Periksa internet Anda.',
      );
    });

    // 3. Provider sukses dengan repository palsu
    test('Provider sukses dengan repository palsu', () async {
      final fakePosts = [
        const Post(userId: 1, id: 1, title: 'Test Post 1', body: 'Body 1'),
        const Post(userId: 1, id: 2, title: 'Test Post 2', body: 'Body 2'),
      ];

      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(items: fakePosts),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(postListProvider.future);
      expect(result.length, 2);
      expect(result.first.title, 'Test Post 1');
      expect(result.last.title, 'Test Post 2');
    });

    // 4. Provider error dengan repository palsu
    test('Provider error dengan repository palsu', () async {
      final container = ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(throwError: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(postListProvider.future),
        throwsA(isA<DioException>()),
      );
    });
  });

  // =========================================================================
  // Group 2: Test baru untuk Comment (sesuai requirement challenge)
  // =========================================================================
  group('Comment — Unit Tests', () {
    // -----------------------------------------------------------------------
    // Test 1: fromJson dengan field yang LENGKAP
    // -----------------------------------------------------------------------
    // Memverifikasi bahwa Comment.fromJson benar mem-parse semua field
    // dari JSON yang valid dan lengkap.
    // -----------------------------------------------------------------------
    test('Comment.fromJson dengan field lengkap', () {
      // Arrange: siapkan data JSON yang lengkap seperti respons API
      final json = {
        'postId': 1,
        'id': 42,
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'body': 'Ini adalah komentar yang sangat berguna.',
      };

      // Act: parse JSON menjadi objek Comment
      final comment = Comment.fromJson(json);

      // Assert: pastikan semua field ter-parse dengan benar
      expect(comment.postId, 1);
      expect(comment.id, 42);
      expect(comment.name, 'Budi Santoso');
      expect(comment.email, 'budi@example.com');
      expect(comment.body, 'Ini adalah komentar yang sangat berguna.');
    });

    // -----------------------------------------------------------------------
    // Test 2: fromJson dengan field yang HILANG (null-safety test)
    // -----------------------------------------------------------------------
    // Ini adalah test utama yang diminta oleh challenge.
    // Memverifikasi bahwa Comment.fromJson TIDAK crash saat field tidak ada.
    // Semua field yang hilang harus menggunakan nilai default:
    //   - int  → 0
    //   - String → ''
    // -----------------------------------------------------------------------
    test('Comment.fromJson aman saat semua field hilang (JSON kosong)', () {
      // Arrange: JSON kosong — tidak ada field sama sekali
      final json = <String, dynamic>{};

      // Act: parse JSON kosong — seharusnya tidak throw exception
      final comment = Comment.fromJson(json);

      // Assert: semua field menggunakan nilai default
      expect(comment.postId, 0,  reason: 'postId harus default ke 0');
      expect(comment.id,     0,  reason: 'id harus default ke 0');
      expect(comment.name,   '', reason: 'name harus default ke string kosong');
      expect(comment.email,  '', reason: 'email harus default ke string kosong');
      expect(comment.body,   '', reason: 'body harus default ke string kosong');
    });

    // -----------------------------------------------------------------------
    // Test 3: fromJson dengan field SEBAGIAN yang hilang
    // -----------------------------------------------------------------------
    // Memverifikasi bahwa field yang ada ter-parse benar,
    // sementara field yang hilang menggunakan nilai default.
    // -----------------------------------------------------------------------
    test('Comment.fromJson dengan field sebagian hilang', () {
      // Arrange: hanya postId dan email yang ada
      final json = <String, dynamic>{
        'postId': 5,
        'email': 'andi@test.com',
        // 'id', 'name', 'body' sengaja dihilangkan
      };

      // Act
      final comment = Comment.fromJson(json);

      // Assert: field yang ada ter-parse benar
      expect(comment.postId, 5);
      expect(comment.email, 'andi@test.com');

      // Field yang hilang menggunakan nilai default
      expect(comment.id,   0,  reason: 'id yang hilang harus default ke 0');
      expect(comment.name, '', reason: 'name yang hilang harus default ke ""');
      expect(comment.body, '', reason: 'body yang hilang harus default ke ""');
    });

    // -----------------------------------------------------------------------
    // Edge Case 1 (Mandiri): fromJson dengan nilai eksplisit NULL
    // -----------------------------------------------------------------------
    // Seringkali API backend mengirimkan: `{"postId": null, "name": null, ...}`
    // Ini menguji bahwa fromJson tidak crash saat menerima `null` eksplisit.
    // -----------------------------------------------------------------------
    test('Edge Case: Comment.fromJson aman saat field bernilai eksplisit null', () {
      final json = <String, dynamic>{
        'postId': null,
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });

    // -----------------------------------------------------------------------
    // Edge Case 2 (Mandiri): fromJson saat ID bertipe num / floating point
    // -----------------------------------------------------------------------
    // Kadang JSON parser membaca angka sebagai double (misal 10.0 atau 99.0).
    // Menggunakan (json['id'] as num?)?.toInt() memastikan tidak runtime cast error.
    // -----------------------------------------------------------------------
    test('Edge Case: Comment.fromJson aman saat ID berupa num / floating point', () {
      final json = <String, dynamic>{
        'postId': 1.0,
        'id': 99.0,
        'name': 'Edge Case User',
        'email': 'edge@test.com',
        'body': 'Komentar edge case',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 99);
      expect(comment.name, 'Edge Case User');
    });

    // -----------------------------------------------------------------------
    // Edge Case 3 (Mandiri): friendlyErrorMessage untuk cancel & 503 error
    // -----------------------------------------------------------------------
    test('Edge Case: friendlyErrorMessage untuk 503 Service Unavailable dan cancel', () {
      final cancelError = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.cancel,
      );
      expect(friendlyErrorMessage(cancelError), 'Permintaan dibatalkan.');

      final serviceUnavailableError = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 503,
        ),
      );
      expect(
        friendlyErrorMessage(serviceUnavailableError),
        'Server bermasalah (503). Coba lagi nanti.',
      );
    });

    // -----------------------------------------------------------------------
    // Test 4: friendlyErrorMessage untuk timeout (simulasi koneksi lambat)
    // -----------------------------------------------------------------------
    // Memverifikasi pesan error yang ramah pengguna untuk kasus timeout.
    // Ini relevan karena CommentRepository menggunakan timeout 10 detik.
    // -----------------------------------------------------------------------
    test('friendlyErrorMessage untuk timeout menghasilkan pesan yang tepat', () {
      // Arrange: buat DioException dengan tipe connectionTimeout
      final timeoutError = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.connectionTimeout,
      );

      // Act: konversi ke pesan ramah pengguna
      final message = friendlyErrorMessage(timeoutError);

      // Assert: pesan seharusnya menyebut "timeout"
      expect(
        message,
        'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.',
      );
    });

    // -----------------------------------------------------------------------
    // Test 5: friendlyErrorMessage untuk 404 Not Found
    // -----------------------------------------------------------------------
    test('friendlyErrorMessage untuk 404 menghasilkan pesan yang tepat', () {
      // Arrange: buat DioException dengan respons 404
      final notFoundError = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 404,
        ),
      );

      // Act
      final message = friendlyErrorMessage(notFoundError);

      // Assert
      expect(message, 'Data tidak ditemukan (404).');
    });

    // -----------------------------------------------------------------------
    // Test 6: friendlyErrorMessage untuk 500 Server Error
    // -----------------------------------------------------------------------
    test('friendlyErrorMessage untuk 500 menghasilkan pesan yang tepat', () {
      // Arrange: buat DioException dengan respons 500
      final serverError = DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: 500,
        ),
      );

      // Act
      final message = friendlyErrorMessage(serverError);

      // Assert: pesan harus menyebut kode status 500
      expect(message, 'Server bermasalah (500). Coba lagi nanti.');
    });

    // -----------------------------------------------------------------------
    // Test 7: CommentsProvider berhasil mengembalikan data
    // -----------------------------------------------------------------------
    // Menggunakan FakeCommentRepository untuk override provider
    // sehingga tidak perlu internet sungguhan.
    // -----------------------------------------------------------------------
    test('commentsProvider sukses mengembalikan daftar komentar', () async {
      // Arrange: siapkan data komentar palsu
      final fakeComments = [
        const Comment(
          postId: 1, id: 1,
          name: 'Ani', email: 'ani@test.com', body: 'Komentar 1',
        ),
        const Comment(
          postId: 1, id: 2,
          name: 'Budi', email: 'budi@test.com', body: 'Komentar 2',
        ),
      ];

      // Buat ProviderContainer dengan override repository palsu
      final container = ProviderContainer(
        overrides: [
          // Override commentRepositoryProvider dengan FakeCommentRepository
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(items: fakeComments),
          ),
        ],
      );
      addTearDown(container.dispose); // Pastikan container dibersihkan setelah test

      // Act: baca data dari provider (gunakan postId = 1)
      final result = await container.read(commentsProvider(1).future);

      // Assert: pastikan data sesuai
      expect(result.length, 2);
      expect(result.first.name, 'Ani');
      expect(result.last.email, 'budi@test.com');
    });

    // -----------------------------------------------------------------------
    // Test 8: CommentsProvider error → state menjadi AsyncError
    // -----------------------------------------------------------------------
    // Memverifikasi bahwa saat repository melempar exception,
    // provider secara otomatis masuk ke state AsyncError.
    // -----------------------------------------------------------------------
    test('commentsProvider error → AsyncError saat repository gagal', () async {
      // Arrange: buat container dengan repository yang akan throw error
      final container = ProviderContainer(
        overrides: [
          commentRepositoryProvider.overrideWithValue(
            FakeCommentRepository(throwError: true), // Akan throw DioException
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(commentsProvider(1).future),
        throwsA(isA<DioException>()),
      );
    });
  });

  // =========================================================================
  // Group 3: Widget Tests (PostTile Refactoring)
  // =========================================================================
  group('PostTile Widget Tests', () {
    testWidgets('PostTile menampilkan ID, title, dan body serta merespon tap', (tester) async {
      const post = Post(
        userId: 1,
        id: 7,
        title: 'Judul Post Uji',
        body: 'Isi lengkap deskripsi post uji coba.',
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostTile(
              post: post,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Pastikan teks ID avatar, title, dan body tampil
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Judul Post Uji'), findsOneWidget);
      expect(find.text('Isi lengkap deskripsi post uji coba.'), findsOneWidget);

      // Uji tap callback
      await tester.tap(find.byType(PostTile));
      expect(tapped, isTrue);
    });
  });
}

