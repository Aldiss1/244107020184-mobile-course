import 'package:flutter_test/flutter_test.dart';
import 'package:week5/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoMusicApp());
  });
}
