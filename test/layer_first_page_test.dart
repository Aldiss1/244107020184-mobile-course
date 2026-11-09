import 'package:campus_notify/presentation/pages/layer_first_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menampilkan judul, struktur folder, dan tiga catatan', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LayerFirstPage()));

    // Judul muncul dua kali: di AppBar dan sebagai judul slide.
    expect(find.text('Layer-first'), findsNWidgets(2));

    expect(find.textContaining('lib/'), findsOneWidget);
    expect(find.textContaining('├── data/'), findsOneWidget);
    expect(find.textContaining('├── domain/'), findsOneWidget);
    expect(find.textContaining('└── presentation/'), findsOneWidget);

    expect(find.text('Cocok untuk project kecil satu fitur.'), findsOneWidget);
    expect(
      find.text('Cepat dibuat, tetapi berantakan saat fitur bertambah.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('satu kardus khusus piring'),
      findsOneWidget,
    );
  });
}
