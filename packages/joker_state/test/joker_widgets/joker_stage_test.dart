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
      joker.value = 20;
      await tester.pump(); // Rebuild the widget

      // Assert
      expect(find.text('Count: 20'), findsOneWidget);
    });

    testWidgets(
        'Joker should dispose after stage is removed and no other listeners exist',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      // Initially, JokerStage will add a listener.

      // Act - build widget
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('$value'),
          ),
        ),
      );
      // At this point, JokerStage is listening.

      // Remove widget - this will trigger removeListener in JokerStage, then in Joker
      await tester.pumpWidget(Container());
      // One pump should process the dispose if it's synchronous or via a microtask
      await tester.pump();

      // Assert: Joker should now be disposed
      expect(() => joker.value, throwsA(isA<JokerException>()));
      expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });

    testWidgets(
        'Joker should NOT dispose after stage is removed IF other listeners exist',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      void myListener() {}
      joker.addListener(myListener); // Add an external listener

      // Act - build and then remove widget
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove JokerStage widget
      await tester.pump(); 

      // Assert: Joker should NOT be disposed because myListener still exists
      expect(() => joker.value = 100, returnsNormally);
      expect(joker.value, 100);

      // Clean up external listener for other tests
      joker.removeListener(myListener);
      // Now, if no other listeners (like from other tests artifacts), it should dispose.
      // We can verify this by trying to add a listener again.
      // If it was the last listener, it's disposed.
      // This part might be tricky if tests run in parallel or state leaks.
      // For this specific test, we've shown it didn't dispose while myListener was active.
      // To be absolutely sure it disposes *after* myListener is removed:
      await tester.pump(); // Allow potential dispose to happen after removeListener
      expect(() => joker.value, throwsA(isA<JokerException>()));

    });

    testWidgets('should handle joker correctly (auto-dispose scenario)',
        (WidgetTester tester) async {
      // Arrange - joker 
      final joker = Joker<String>('No tag');

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
       expect(() => joker.value, throwsA(isA<JokerException>()));
       expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });

    testWidgets('should handle multiple stages with same joker',
        (WidgetTester tester) async {
      // Arrange - single joker used by multiple stages
      final joker = Joker<int>(10);
      // Add an external listener to prevent disposal when one stage is removed
      // This makes the test focus on multiple stages rather than auto-dispose.
      void dummyListener() {}
      joker.addListener(dummyListener); 

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
      joker.value = 20;
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

      // Joker should not be disposed as one listener (from perform) and dummyListener remain.
      expect(() => joker.value, returnsNormally);
      expect(find.text('First: 20'), findsOneWidget);

      // Update again
      joker.value = 30;
      await tester.pump();
      expect(find.text('First: 30'), findsOneWidget);

      // Clean up the dummy listener
      joker.removeListener(dummyListener);
      // Now remove the last stage an expect disposal
      await tester.pumpWidget(Container());
      await tester.pump();
      expect(() => joker.value, throwsA(isA<JokerException>()));
    });
  });
}
