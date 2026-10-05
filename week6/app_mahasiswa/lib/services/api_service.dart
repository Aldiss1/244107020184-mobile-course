import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/mahasiswa.dart';

class ApiService {
  // Emulator Android: 10.0.2.2, Lainnya (macOS / iOS / Web): 127.0.0.1
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/mahasiswa';
    }
    return 'http://127.0.0.1:8000/api/mahasiswa';
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // READ - ambil semua data
  Future<List<Mahasiswa>> getAll() async {
    final res = await http.get(Uri.parse(baseUrl), headers: headers);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);          // String -> Map
      final List data = body['data'];             // ambil array "data"
      return data.map((e) => Mahasiswa.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat data (${res.statusCode})');
  }

  // CREATE - tambah data
  Future<Mahasiswa> create(Mahasiswa m) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(m.toJson()),
    );
    if (res.statusCode == 201) {
      return Mahasiswa.fromJson(jsonDecode(res.body)['data']);
    }
    throw Exception(_pesanError(res));
  }

  // UPDATE - ubah data berdasarkan id
  Future<Mahasiswa> update(int id, Mahasiswa m) async {
    final res = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(m.toJson()),
    );
    if (res.statusCode == 200) {
      return Mahasiswa.fromJson(jsonDecode(res.body)['data']);
    }
    throw Exception(_pesanError(res));
  }

  // DELETE - hapus data berdasarkan id
  Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(_pesanError(res));
    }
  }

  // Ambil pesan error dari JSON Laravel
  String _pesanError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      return body['message'] ?? 'Error ${res.statusCode}';
    } catch (_) {
      return 'Error ${res.statusCode}';
    }
  }
}
