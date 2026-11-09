import 'dart:convert';
import 'package:http/http.dart' as http;
import '../remote/post.dart';

class PostRepository {
  final http.Client client;
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  PostRepository({http.Client? client}) : client = client ?? http.Client();

  Future<List<Post>> fetchPosts() async {
    final response = await client.get(Uri.parse('$baseUrl/posts'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<Post> createPost(String title, String body) async {
    final response = await client.post(
      Uri.parse('$baseUrl/posts'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'title': title, 'body': body, 'userId': 1}),
    );

    if (response.statusCode == 201) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create post');
    }
  }
}
