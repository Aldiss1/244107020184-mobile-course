// ===========================================================================
// Model: Comment
// ---------------------------------------------------------------------------
// Merepresentasikan satu objek komentar yang dikembalikan oleh API
// JSONPlaceholder pada endpoint GET /comments?postId={id}.
//
// Contoh respons JSON dari API:
// {
//   "postId": 1,
//   "id": 1,
//   "name": "id labore ex et quam laborum",
//   "email": "Eliseo@gardner.biz",
//   "body": "laudantium enim quasi est..."
// }
// ===========================================================================

/// Model data untuk satu komentar dari JSONPlaceholder API.
///
/// Semua field bersifat final (immutable) sesuai prinsip clean architecture.
class Comment {
  /// ID post yang memiliki komentar ini.
  final int postId;

  /// ID unik komentar ini.
  final int id;

  /// Nama pengirim komentar.
  final String name;

  /// Email pengirim komentar.
  final String email;

  /// Isi/body dari komentar.
  final String body;

  /// Constructor utama — semua field wajib diisi.
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  // ---------------------------------------------------------------------------
  // Factory constructor: fromJson
  // ---------------------------------------------------------------------------
  // Menggunakan operator null-safe dan konversi `as num?` untuk integer.
  // Jika field bernilai null, bertipe num/double, atau tidak ada di JSON,
  // nilai fallback yang aman akan digunakan tanpa menyebabkan crash.
  // ---------------------------------------------------------------------------

  /// Membuat objek [Comment] dari Map JSON.
  ///
  /// Aman terhadap field hilang, field bernilai null, ataupun tipe angka variatif.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // (num?)?.toInt() menangani jika API mengembalikan int, double, atau null
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengkonversi objek [Comment] kembali ke Map JSON.
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };

  @override
  String toString() =>
      'Comment(postId: $postId, id: $id, name: $name, email: $email)';
}
