import 'package:circus_ring/circus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerStage', () {
    setUp(() async {
      // Clean up CircusRing before each test
      await Circus.fireAll();
    });

    testWidgets('should display initial value of joker',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<String>('Hello');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text(value),
          ),
        ),
      );

      // Assert
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('should update when joker value changes',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(10);

      // Act - build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('Count: $value'),
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 10'), findsOneWidget);

      // Update joker
      joker.trick(20);
      await tester.pump(); // Rebuild the widget

      // Assert
      expect(find.text('Count: 20'), findsOneWidget);
    });

    testWidgets(
        'Joker with keepAlive=false should dispose after stage is removed',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42, keepAlive: false);
      expect(joker.isDisposed, isFalse);

      // Act - build widget
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('$value'),
          ),
        ),
      );
      expect(joker.isDisposed, isFalse);

      // Remove widget - this schedules the dispose microtask
      await tester.pumpWidget(Container());
      // One pump should process the microtask
      await tester.pump();

      // Assert: Joker should now be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets(
        'Joker with keepAlive=true should NOT dispose after stage is removed',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42, keepAlive: true);
      expect(joker.isDisposed, isFalse);

      // Act - build and then remove widget
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget
      await tester
          .pump(); // Pump once to be safe, although it shouldn't dispose

      // Assert
      expect(joker.isDisposed, isFalse);
      // Verify it still works
      expect(() => joker.trick(100), returnsNormally);
      expect(joker.state, 100);
    });

    testWidgets('should handle joker without tag correctly',
        (WidgetTester tester) async {
      // Arrange - joker without tag, keepAlive=false (default)
      final joker = Joker<String>('No tag');
      expect(joker.isDisposed, isFalse);

      // Act - build and then remove
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text(value),
          ),
        ),
      );
      expect(find.text('No tag'), findsOneWidget);

      // Remove widget - schedules dispose microtask
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtask

      // Assert - Joker should be disposed automatically
      expect(joker.isDisposed, isTrue);
    });

    testWidgets('should handle multiple stages with same joker',
        (WidgetTester tester) async {
      // Arrange - single joker used by multiple stages
      final joker =
          Joker<int>(10, keepAlive: true); // Use keepAlive for simplicity here

      // Act - build multiple stages
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              joker.perform(
                builder: (context, value) => Text('First: $value'),
              ),
              joker.perform(
                builder: (context, value) => Text('Second: $value'),
              ),
            ],
          ),
        ),
      );

      // Initial state
      expect(find.text('First: 10'), findsOneWidget);
      expect(find.text('Second: 10'), findsOneWidget);

      // Update joker
      joker.trick(20);
      await tester.pump();

      // Both should update
      expect(find.text('First: 20'), findsOneWidget);
      expect(find.text('Second: 20'), findsOneWidget);

      // Remove one stage
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              joker.perform(
                builder: (context, value) => Text('First: $value'),
              ),
              // Second stage removed
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Joker should not be disposed as one listener remains and keepAlive=true
      expect(joker.isDisposed, isFalse);
      expect(find.text('First: 20'), findsOneWidget);

      // Update again
      joker.trick(30);
      await tester.pump();
      expect(find.text('First: 30'), findsOneWidget);
    });

    testWidgets('should work correctly with manual jokers',
        (WidgetTester tester) async {
      // Arrange - manual joker (autoNotify=false)
      final joker = Joker<int>(5, autoNotify: false);

      // Act - build with manual joker
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('Value: $value'),
          ),
        ),
      );

      // Initial state
      expect(find.text('Value: 5'), findsOneWidget);

      // Update without notification
      joker.whisper(10);
      await tester.pump();

      // Should not update yet
      expect(find.text('Value: 5'), findsOneWidget);

      // Now send notification
      joker.yell();
      await tester.pump();

      // Should update now
      expect(find.text('Value: 10'), findsOneWidget);
    });
  });
}
