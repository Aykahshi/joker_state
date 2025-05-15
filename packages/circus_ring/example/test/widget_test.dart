import 'package:circus_ring/circus_ring.dart';
import 'package:circus_ring_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Ensure the hired string is set before each test
    Ring.hire('This is Example');
  });

  testWidgets('ExampleScreen displays hired string',
      (WidgetTester tester) async {
    // Pump the app widget tree
    await tester.pumpWidget(const MyApp());

    // Find the Text widget with the expected content
    final textFinder = find.text('This is Example');

    // Verify that the Text widget is found exactly once
    expect(textFinder, findsOneWidget);
  });
}
