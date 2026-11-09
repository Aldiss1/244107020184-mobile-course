import 'package:campus_notify/presentation/pages/solid_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lima prinsip lengkap dan berurutan S-O-L-I-D', () {
    expect(kSolidPrinciples.map((p) => p.letter).join(), 'SOLID');
    for (final principle in kSolidPrinciples) {
      expect(principle.name, isNotEmpty);
      expect(principle.meaning, isNotEmpty);
      expect(principle.symptom, isNotEmpty);
    }
  });

  testWidgets('layar sempit menampilkan kelima prinsip', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SolidPage()));

    for (final principle in kSolidPrinciples) {
      expect(find.text(principle.name), findsOneWidget);
      expect(find.text(principle.letter), findsOneWidget);
      expect(find.text(principle.symptom), findsOneWidget);
    }
    expect(find.text('Arti praktis'), findsNWidgets(kSolidPrinciples.length));
  });

  testWidgets('layar lebar memakai tata letak tiga kolom', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SolidPage()));

    expect(find.text('Arti praktis'), findsOneWidget);
    expect(find.text('Gejala pelanggaran di Flutter'), findsOneWidget);
    for (final principle in kSolidPrinciples) {
      expect(find.text(principle.name), findsOneWidget);
      expect(find.text(principle.symptom), findsOneWidget);
    }
  });
}
