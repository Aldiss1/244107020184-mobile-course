// ===========================================================================
// Repository: CommentRepository
// ---------------------------------------------------------------------------
// Bertugas berkomunikasi langsung dengan JSONPlaceholder API untuk mengambil
// data komentar berdasarkan postId.
//
// Endpoint: GET https://jsonplaceholder.typicode.com/comments?postId={id}
//
// Pattern: Repository Pattern — memisahkan logika pengambilan data (network)
// dari logika bisnis (provider) dan UI (widget).
// ===========================================================================

import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository yang bertanggung jawab mengambil data komentar dari API.
///
/// Menerima instance [Dio] melalui constructor (dependency injection),
/// sehingga mudah di-mock saat unit testing.
class CommentRepository {
  /// Instance Dio yang digunakan untuk melakukan HTTP request.
  final Dio _dio;

  /// Constructor — menerima [Dio] dari luar (dependency injection).
  /// Ini memudahkan pengujian karena kita bisa inject Dio palsu (fake/mock).
  CommentRepository(this._dio);

  // ---------------------------------------------------------------------------
  // Method: fetchComments
  // ---------------------------------------------------------------------------
  // Melakukan GET request ke /comments?postId={postId}.
  // Timeout sudah dikonfigurasi di ApiClient (10 detik untuk connect & receive).
  // Jika terjadi error (timeout, no internet, 404, 500), DioException
  // akan dilempar dan ditangkap oleh provider di layer atas.
  // ---------------------------------------------------------------------------

  /// Mengambil daftar komentar untuk sebuah post berdasarkan [postId].
  ///
  /// Mengembalikan [List<Comment>] jika berhasil.
  /// Melempar [DioException] jika terjadi error jaringan atau server.
  ///
  /// Timeout: 10 detik (dikonfigurasi di [createDio] pada api_client.dart).
  Future<List<Comment>> fetchComments(int postId) async {
    // Melakukan HTTP GET ke endpoint /comments dengan query parameter postId.
    // Contoh URL yang dihasilkan: /comments?postId=1
    final response = await _dio.get(
      '/comments',
      queryParameters: {
        'postId': postId, // Filter komentar berdasarkan ID post
      },
    );

    // response.data berisi List<dynamic> dari JSON yang sudah di-parse Dio.
    // Kita cast ke List<dynamic> lalu map setiap item ke objek Comment.
    final List<dynamic> data = response.data as List<dynamic>;

    // Setiap item di-cast ke Map<String, dynamic> lalu dikonversi
    // menggunakan Comment.fromJson yang aman terhadap field yang hilang.
    return data
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
