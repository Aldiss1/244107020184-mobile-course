import 'package:flutter_test/flutter_test.dart';

import 'package:week2/main.dart';

void main() {
  testWidgets('Memverifikasi tombol Next dan Back berpindah lirik lagu', (WidgetTester tester) async {
    await tester.pumpWidget(const Aldisurya());

    // Verifikasi judul AppBar
    expect(find.text('Informasi Musik'), findsOneWidget);

    // Verifikasi lirik bagian 1 awal
    expect(find.textContaining('Kasih hatiku'), findsOneWidget);

    // Scroll ke tombol Next dan tap
    final nextButton = find.text('Next');
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verifikasi lirik bagian 2
    expect(find.textContaining('La la la la la'), findsOneWidget);

    // Scroll ke tombol Back dan tap
    final backButton = find.text('Back');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Verifikasi kembali ke lirik bagian 1
    expect(find.textContaining('Kasih hatiku'), findsOneWidget);
  });
}
