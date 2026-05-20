import 'package:flutter_test/flutter_test.dart';
import 'package:study_companion/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyCompanionApp());
    await tester.pump();
    expect(find.byType(StudyCompanionApp), findsOneWidget);
  });
}
