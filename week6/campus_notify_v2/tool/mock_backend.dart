// Mock backend untuk membuktikan alur `POST /devices` berhasil.
//
// Kenapa perlu: `dummyjson.com` tidak punya endpoint `/devices`, jadi aplikasi
// selalu menerima 404 dan token FCM tidak pernah benar-benar tersimpan di
// server. Dengan server ini, alur "ambil token -> kirim ke backend -> server
// menyimpan" bisa dibuktikan ujung ke ujung, tanpa perlu backend kampus nyata.
//
// Jalankan:
//   dart run tool/mock_backend.dart
//
// Lalu jalankan aplikasi dengan endpoint diarahkan ke sini:
//   flutter run --dart-define=DEVICES_URL=http://10.0.2.2:8787/devices
//
// `10.0.2.2` adalah alias localhost mesin host dari dalam Android Emulator.
// Untuk perangkat fisik, ganti dengan IP LAN mesin ini (mis. 192.168.1.10).
//
// Endpoint:
//   POST /devices  { "fcm_token": "...", "platform": "android" }
//                  -> 201 { "ok": true, "total": N }
//   GET  /devices  -> daftar token yang tersimpan
//   POST /push     { "title": "...", "body": "...", "route": "..." }
//                  -> 200 { "ok": true, "sent_to": N }  (mencatat permintaan;
//                     pengiriman FCM sungguhan butuh service account Firebase)
//   GET  /health   -> { "ok": true }

import 'dart:convert';
import 'dart:io';

const int _port = 8787;

/// Token yang tersimpan, di-key dengan nilai token supaya kiriman berulang
/// (mis. `onTokenRefresh` mengirim ulang token yang sama) tidak menumpuk.
final Map<String, Map<String, dynamic>> _devices = {};

/// Permintaan push yang pernah masuk — berguna untuk melihat payload apa yang
/// akan dikirim ke FCM.
final List<Map<String, dynamic>> _pushLog = [];

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? _port;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Mock backend jalan di http://localhost:$port');
  stdout.writeln('Dari emulator Android: http://10.0.2.2:$port');
  stdout.writeln('Endpoint: POST /devices, GET /devices, POST /push, GET /health');
  stdout.writeln('Tekan Ctrl+C untuk berhenti.\n');

  await for (final request in server) {
    try {
      await _handle(request);
    } catch (error, stack) {
      stderr.writeln('ERROR ${request.method} ${request.uri.path}: $error');
      stderr.writeln(stack);
      await _json(request, HttpStatus.internalServerError, {
        'ok': false,
        'error': error.toString(),
      });
    }
  }
}

Future<void> _handle(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  // CORS supaya bisa dicoba juga dari browser.
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add(
    'Access-Control-Allow-Methods',
    'GET, POST, OPTIONS',
  );
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

  if (method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (path == '/health' && method == 'GET') {
    return _json(request, HttpStatus.ok, {'ok': true});
  }

  if (path == '/devices' && method == 'POST') {
    final body = await _readJson(request);
    final token = (body['fcm_token'] as String?)?.trim() ?? '';
    final platform = (body['platform'] as String?)?.trim() ?? 'unknown';

    if (token.isEmpty) {
      return _json(request, HttpStatus.badRequest, {
        'ok': false,
        'error': 'fcm_token wajib diisi',
      });
    }

    _devices[token] = {
      'fcm_token': token,
      'platform': platform,
      'registered_at': DateTime.now().toIso8601String(),
    };

    stdout.writeln(
      '[devices] tersimpan token ${_preview(token)} platform=$platform '
      '(total ${_devices.length})',
    );

    return _json(request, HttpStatus.created, {
      'ok': true,
      'total': _devices.length,
    });
  }

  if (path == '/devices' && method == 'GET') {
    return _json(request, HttpStatus.ok, {
      'total': _devices.length,
      'items': _devices.values.toList(),
    });
  }

  if (path == '/push' && method == 'POST') {
    final body = await _readJson(request);
    final entry = {
      'title': body['title'] ?? '',
      'body': body['body'] ?? '',
      'route': body['route'] ?? '/',
      'requested_at': DateTime.now().toIso8601String(),
      'devices': _devices.length,
    };
    _pushLog.add(entry);
    stdout.writeln('[push] permintaan: ${jsonEncode(entry)}');
    return _json(request, HttpStatus.ok, {
      'ok': true,
      'sent_to': _devices.length,
      // Catatan jujur: server ini TIDAK mengirim FCM sungguhan. Itu butuh
      // service account Firebase (FCM HTTP v1) yang kredensialnya tidak
      // boleh ditanam di repo.
      'note': 'dicatat saja; pengiriman FCM butuh service account',
    });
  }

  return _json(request, HttpStatus.notFound, {
    'ok': false,
    'error': 'Endpoint tidak ada: $method $path',
    'available': ['GET /health', 'POST /devices', 'GET /devices', 'POST /push'],
  });
}

Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
  final raw = await utf8.decoder.bind(request).join();
  if (raw.trim().isEmpty) return {};
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : {};
}

Future<void> _json(
  HttpRequest request,
  int status,
  Map<String, dynamic> body,
) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

String _preview(String token) =>
    token.length <= 12 ? token : '${token.substring(0, 12)}...';
