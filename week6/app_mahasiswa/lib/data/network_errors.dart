import 'package:dio/dio.dart';

/// Mengubah berbagai jenis [DioException] dan error umum menjadi pesan
/// yang ramah dan mudah dipahami oleh pengguna dalam bahasa Indonesia.
///
/// Mendukung:
/// - Timeout (connect, send, receive)
/// - Masalah koneksi internet (connectionError)
/// - Respon HTTP server bermasalah (404, 401/403, 500, dll)
/// - Pembatalan permintaan (cancel)
/// - Masalah sertifikat SSL (badCertificate)
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return 'Data tidak ditemukan (404).';
        } else if (statusCode == 401 || statusCode == 403) {
          return 'Akses ditolak ($statusCode). Periksa kredensial Anda.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server bermasalah ($statusCode). Coba lagi nanti.';
        } else {
          return 'Terjadi kesalahan pada respon server ($statusCode).';
        }
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan server tidak valid.';
      case DioExceptionType.unknown:
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
