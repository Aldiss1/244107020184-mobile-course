import 'package:dio/dio.dart';

/// Menerjemahkan error teknis menjadi kalimat yang layak ditampilkan ke UI.
///
/// UI tidak boleh menampilkan `DioException` mentah ("DioException
/// [connection error] ...") kepada mahasiswa.
String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi terlalu lambat. Coba lagi sebentar.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid. Hubungi admin kampus.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 400) return 'Data yang dikirim tidak valid.';
        if (code == 401) return 'Sesi Anda berakhir. Silakan masuk kembali.';
        if (code == 403) return 'Anda tidak punya akses ke data ini.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code != null && code >= 500) {
          return 'Server kampus sedang bermasalah. Coba beberapa saat lagi.';
        }
        return 'Permintaan gagal (kode $code).';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan jaringan. Periksa koneksi Anda.';
    }
  }
  // AuthException dan error domain lain sudah membawa pesan ramah.
  final text = error.toString().replaceFirst('Exception: ', '');
  return text.isEmpty ? 'Terjadi kesalahan tak terduga.' : text;
}
