import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('OfflineNotesApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflineNotesApp());
  });
}
