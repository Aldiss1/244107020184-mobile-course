import 'package:flutter/material.dart';

import 'materi_colors.dart';

/// Slide "Layer-first" (Pemrograman Mobile · Clean Architecture).
///
/// Menampilkan struktur folder layer-first, lalu tiga catatan praktisnya.
class LayerFirstPage extends StatelessWidget {
  const LayerFirstPage({super.key});

  /// Isi blok kode, satu baris per entri.
  static const List<String> _tree = [
    'lib/',
    '├── data/',
    '├── domain/',
    '└── presentation/',
  ];

  static const List<String> _notes = [
    'Cocok untuk project kecil satu fitur.',
    'Cepat dibuat, tetapi berantakan saat fitur bertambah.',
    'Seperti pindahan dengan satu kardus khusus piring, satu khusus baju '
        '— untuk satu kamar harus buka semua kardus.',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Layer-first')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Layer-first',
                      style: textTheme.headlineMedium?.copyWith(
                        color: MateriColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _CodeBlock(lines: _tree),
                    const SizedBox(height: 28),
                    for (final note in _notes) ...[
                      _Bullet(text: note),
                      if (note != _notes.last) const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blok gelap berisi struktur folder, memakai font monospace agar
/// karakter garis pohon tetap sejajar.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 52),
      decoration: BoxDecoration(
        color: MateriColors.code,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lines.join('\n'),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: ['Menlo', 'Courier New', 'Roboto Mono'],
          fontSize: 16,
          height: 1.6,
          color: MateriColors.codeText,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: MateriColors.ink,
                height: 1.5,
              ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MateriColors.ink,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}
