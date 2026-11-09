import 'package:flutter/material.dart';

/// Palet bersama untuk halaman materi kuliah (deck Clean Architecture).
///
/// Nilainya diambil dari deck asli supaya semua halaman materi terlihat
/// satu keluarga dengan slide-nya.
abstract final class MateriColors {
  static const Color navy = Color(0xFF16303F);
  static const Color teal = Color(0xFF3D7C8C);
  static const Color slate = Color(0xFF7B8B96);
  static const Color brick = Color(0xFFC0563A);
  static const Color card = Color(0xFFEDF1F4);
  static const Color ink = Color(0xFF24333D);

  /// Latar blok kode gelap pada slide.
  static const Color code = Color(0xFF1E2A33);
  static const Color codeText = Color(0xFFE8E8E8);
}
