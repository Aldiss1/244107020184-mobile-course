  import 'package:dio/dio.dart';

/// Endpoint tempat token FCM didaftarkan.
///
/// Default-nya `https://dummyjson.com/devices` — endpoint itu **tidak ada**
/// (selalu 404), jadi default ini sengaja dipertahankan sebagai penanda bahwa
/// backend kampus belum tersambung. Untuk pengujian lokal, arahkan ke mock
/// backend yang disertakan:
///
/// ```bash
/// dart run tool/mock_backend.dart
/// flutter run --dart-define=DEVICES_URL=http://10.0.2.2:8787/devices
/// ```
///
/// `10.0.2.2` = localhost mesin host dari dalam emulator Android.
const String kDevicesUrl = String.fromEnvironment(
  'DEVICES_URL',
  defaultValue: 'https://dummyjson.com/devices',
);

/// Hasil satu percobaan pendaftaran token.
class DeviceRegistration {
  const DeviceRegistration({
    required this.ok,
    required this.label,
    this.statusCode,
  });

  /// `true` bila server membalas 2xx.
  final bool ok;

  /// Ringkasan siap tampil di layar Debug (tanpa membocorkan token penuh).
  final String label;

  final int? statusCode;

  String get shortLabel => ok ? 'terkirim (${statusCode ?? 200})' : label;
}

/// Mengirim token FCM ke backend.
///
/// Memakai [Dio] tersendiri, bukan `apiClientProvider`: Dio itu punya
/// `baseUrl` dummyjson + interceptor refresh yang tidak relevan untuk
/// endpoint perangkat, dan URL di sini bisa berupa alamat absolut.
class DeviceRegistrar {
  DeviceRegistrar({Dio? dio, String? url})
    : _url = url ?? kDevicesUrl,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              // 4xx bukan exception: kita ingin membaca status apa adanya
              // supaya pesan di UI jujur ("404") bukan "DioException".
              validateStatus: (_) => true,
            ),
          );

  final Dio _dio;
  final String _url;

  String get url => _url;

  Future<DeviceRegistration> register({
    required String token,
    required String platform,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        _url,
        data: {'fcm_token': token, 'platform': platform},
      );
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return DeviceRegistration(
          ok: true,
          label: 'terkirim',
          statusCode: code,
        );
      }
      return DeviceRegistration(
        ok: false,
        label: code == 404
            ? 'HTTP 404 — endpoint belum ada'
            : 'HTTP $code — ditolak server',
        statusCode: code,
      );
    } on DioException catch (error) {
      return DeviceRegistration(
        ok: false,
        label: 'gagal jaringan: ${error.type.name}',
      );
    }
  }
}
