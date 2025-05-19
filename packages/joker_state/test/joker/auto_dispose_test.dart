import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

// Test model class
class UserModel {
  final String name;
  final int age;

  const UserModel({required this.name, required this.age});
}

void main() {
  group('AutoDispose Mechanism Tests', () {
    testWidgets(
        'Test autoDispose cancellation - adding new listener during debounce period should prevent disposal',
        (tester) async {
      // Arrange - Create a Joker instance with a longer autoDisposeDelay for testing
      final joker =
          Joker<int>(10, autoDisposeDelay: const Duration(seconds: 1));
      bool listenerCalled = false;

      // Add a listener
      void listener1() {
        listenerCalled = true;
      }

      joker.addListener(listener1);

      // Verify Joker works correctly
      expect(joker.state, 10);
      joker.state = 15;
      expect(listenerCalled, true);
      listenerCalled = false;

      // Remove the listener, which should trigger the autoDispose debounce timer
      joker.removeListener(listener1);

      // Wait for a short period, but not enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Add a new listener before the debounce period completes ("change of mind")
      void listener2() {
        listenerCalled = true;
      }

      // Use try-catch to handle potential exceptions
      try {
        joker.addListener(listener2);

        // Test if Joker is still working correctly
        joker.state = 20;
        expect(listenerCalled, true);
        expect(joker.state, 20);

        // Clean up
        joker.removeListener(listener2);

        // Wait long enough for autoDispose to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to access state, should throw an exception
        expect(joker.isDisposed, isTrue);
      } catch (e) {
        // If an exception is thrown when adding a listener, the test will fail
        fail('Failed to add listener: $e');
      }
    });

    testWidgets(
        'Test custom autoDisposeDelay - longer delay should provide more time for reconsideration',
        (tester) async {
      // Arrange - Create a Joker instance with a longer autoDisposeDelay
      final joker =
          Joker<String>('test', autoDisposeDelay: const Duration(seconds: 2));
      bool listenerCalled = false;

      // Add a listener
      void listener() {
        listenerCalled = true;
      }

      try {
        joker.addListener(listener);

        // Verify the listener works correctly
        joker.state = 'updated';
        expect(listenerCalled, true);
        listenerCalled = false;

        // Remove the listener, which should trigger the autoDispose debounce timer
        joker.removeListener(listener);

        // Wait for 1 second, which is enough for the default 500ms delay but not enough for 2s delay
        await tester.pump(const Duration(seconds: 1));

        // Add a new listener before the extended debounce period completes
        joker.addListener(listener);

        // Test if Joker is still working correctly
        joker.state = 'updated again';
        expect(listenerCalled, true);
        expect(joker.state, 'updated again');

        // Clean up
        joker.removeListener(listener);

        // Wait long enough for the extended autoDispose to complete
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Try to access state, should throw an exception
        expect(joker.isDisposed, isTrue);
      } catch (e) {
        fail('Test failed: $e');
      }
    });

    testWidgets(
        'Test multiple reconsiderations - repeatedly adding and removing listeners',
        (tester) async {
      // Arrange - Create a Joker instance
      final joker = Joker<int>(1);

      // Loop 5 times, each time adding and then removing a listener
      for (int i = 0; i < 5; i++) {
        // Add a listener
        void listener() {}
        joker.addListener(listener);

        // Update state
        joker.state = i + 1;
        expect(joker.state, i + 1);

        // Remove the listener, triggering the autoDispose debounce timer
        joker.removeListener(listener);

        // Wait for a short period, but not enough for autoDispose to complete
        await tester.pump(const Duration(milliseconds: 200));
      }

      // After the last loop iteration, wait long enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Assert: Joker should now be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets('Test autoDispose reconsideration in Widget tree - JokerStage',
        (tester) async {
      // Arrange - Create a Joker instance
      final joker = Joker<String>('initial');

      // Build a Widget using JokerStage
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, state) => Text('Value: $state'),
          ),
        ),
      );

      // Verify the Widget displays correctly
      expect(find.text('Value: initial'), findsOneWidget);

      // Remove the Widget, triggering the autoDispose debounce timer
      await tester.pumpWidget(Container());

      // Wait for a short period, but not enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 200));

      // Add the Widget back before the debounce period completes ("change of mind")
      await tester.pumpWidget(
        MaterialApp(
          home: joker.perform(
            builder: (context, state) => Text('Value: $state'),
          ),
        ),
      );

      // Update Joker state
      joker.state = 'updated';
      await tester.pump();

      // Verify the Widget updates correctly
      expect(find.text('Value: updated'), findsOneWidget);

      // Remove the Widget again
      await tester.pumpWidget(Container());

      // Wait long enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Assert: Joker should now be disposed
      expect(joker.isDisposed, isTrue);
    });
  });

  group('JokerTroupe and autoDispose interaction tests', () {
    testWidgets(
        'After JokerTroupe removal, reusing a Joker during debounce period should prevent its disposal',
        (tester) async {
      // Arrange - Create multiple Joker instances
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');

      // Build a Widget using JokerTroupe
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (states) => (states[0] as int, states[1] as String),
            builder: (context, states) => Column(
              children: [
                Text('Int: ${states.$1}'),
                Text('String: ${states.$2}'),
              ],
            ),
          ),
        ),
      );

      // Verify the Widget displays correctly
      expect(find.text('Int: 10'), findsOneWidget);
      expect(find.text('String: test'), findsOneWidget);

      // Remove the Widget, triggering the autoDispose debounce timer for both Jokers
      await tester.pumpWidget(Container());

      // Wait for a short period, but not enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 200));

      // Use one of the Jokers before the debounce period completes
      void listener() {}
      joker1.addListener(listener);

      // Wait long enough for the debounce period to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Assert: joker1 should not be disposed (because we added a listener), but joker2 should be disposed
      expect(() => joker1.state, returnsNormally);
      expect(() => joker2.state, throwsA(isA<JokerException>()));

      // Clean up
      joker1.removeListener(listener);
      await tester.pump(const Duration(milliseconds: 600));

      // Assert: joker1 should now also be disposed
      expect(joker1.isDisposed, isTrue);
    });
  });

  group('JokerFrame and autoDispose interaction tests', () {
    testWidgets(
        'After JokerFrame removal, reusing Joker during debounce period should prevent disposal',
        (tester) async {
      // Arrange - Create a Joker instance with test model
      final joker = Joker<UserModel>(const UserModel(name: 'Test', age: 30));

      // Build a Widget using JokerFrame
      await tester.pumpWidget(
        MaterialApp(
          home: joker.focusOn<String>(
            selector: (model) => model.name,
            builder: (context, name) => Text('Name: $name'),
          ),
        ),
      );

      // Verify the Widget displays correctly
      expect(find.text('Name: Test'), findsOneWidget);

      // Remove the Widget, triggering the autoDispose debounce timer
      await tester.pumpWidget(Container());

      // Wait for a short period, but not enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 200));

      // Add the Widget back before the debounce period completes
      await tester.pumpWidget(
        MaterialApp(
          home: joker.focusOn<String>(
            selector: (model) => model.name,
            builder: (context, name) => Text('Name: $name'),
          ),
        ),
      );

      // Update Joker state
      joker.state = const UserModel(name: 'Updated', age: 31);
      await tester.pump();

      // Verify the Widget updates correctly
      expect(find.text('Name: Updated'), findsOneWidget);

      // Remove the Widget again
      await tester.pumpWidget(Container());

      // Wait long enough for autoDispose to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Assert: Joker should now be disposed
      expect(joker.isDisposed, isTrue);
    });
  });
}
