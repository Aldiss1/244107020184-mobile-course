import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dio adapter yang membalas dengan respons buatan (tanpa jaringan).
///
/// Catatan: `HttpClientAdapter` di dio 5.11 hanya punya konstruktor
/// factory sehingga tidak bisa di-extend; di-`implements` saja, dan
/// `fetch` wajib mengembalikan `ResponseBody`.
class CannedAdapter implements HttpClientAdapter {
  CannedAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

/// `ResponseBody` berisi JSON, supaya transformer dio menghasilkan Map.
ResponseBody jsonBody(Object? data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio dioCanned(
  Map<String, dynamic> Function(String path) data, {
  int status = 200,
}) {
  return Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..httpClientAdapter = CannedAdapter((options) async {
      return jsonBody(data(options.path), status: status);
    });
}

/// FlutterSecureStorage palsu berbasis map, supaya TokenStore asli bisa
/// diuji tanpa Keychain. Signature mengikuti flutter_secure_storage 11
/// (termasuk parameter opsi platform yang diabaikan).
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> map = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      map[key];

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      map.clear();
}
