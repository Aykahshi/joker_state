import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

// A helper class to represent a complex state object for testing selectors.
class User {
  final String name;
  final int age;

  const User({required this.name, required this.age});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

// A helper widget to count how many times its builder is called.
// Useful for verifying that a widget does *not* rebuild unnecessarily.
// ignore: must_be_immutable
class BuildCounter extends StatelessWidget {
  final Widget Function(BuildContext context, VoidCallback markBuilt) builder;
  int buildCount = 0;

  BuildCounter({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, () => buildCount++);
  }
}

void main() {
  // --- Test Suite for Joker Widgets ---
  // This file contains tests for all the UI widgets provided by the Joker state
  // management package. Each widget is tested for its core functionality,
  // including initial state rendering, reactivity to state changes, and
  // handling of conditional logic.

  // Note: All Joker instances are created with `keepAlive: true` to prevent
  // auto-disposal during tests, which could lead to unpredictable behavior.

  group('JokerStage', () {
    testWidgets('should build with initial state and rebuild on state change',
        (WidgetTester tester) async {
      // ARRANGE: Create a Joker with an initial state.
      final counterJoker = Joker<int>(0, keepAlive: true);

      // ACT: Build the widget.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JokerStage<int>(
              act: counterJoker,
              builder: (context, count) => Text('Count: $count'),
            ),
          ),
        ),
      );

      // ASSERT: Verify the initial state is displayed.
      expect(find.text('Count: 0'), findsOneWidget);

      // ACT: Update the state.
      counterJoker.trick(1);
      await tester.pump(); // Rebuild the widget tree.

      // ASSERT: Verify the UI reflects the new state.
      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('JokerFrame', () {
    late Joker<User> userJoker;
    late BuildCounter buildCounter;

    setUp(() {
      userJoker = Joker<User>(
        const User(name: 'Alice', age: 30),
        keepAlive: true,
      );
    });

    testWidgets('should build with initial selected state',
        (WidgetTester tester) async {
      // ARRANGE & ACT
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JokerFrame<User, String>(
              act: userJoker,
              selector: (user) => user.name,
              builder: (context, name) => Text('Name: $name'),
            ),
          ),
        ),
      );

      // ASSERT
      expect(find.text('Name: Alice'), findsOneWidget);
    });

    testWidgets('should rebuild only when selected state changes',
        (WidgetTester tester) async {
      // ARRANGE
      buildCounter = BuildCounter(
        builder: (context, markBuilt) => JokerFrame<User, String>(
          act: userJoker,
          selector: (user) => user.name,
          builder: (context, name) {
            markBuilt();
            return Text('Name: $name');
          },
        ),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: buildCounter)));

      // ASSERT: Initial build.
      expect(find.text('Name: Alice'), findsOneWidget);
      expect(buildCounter.buildCount, 1);

      // ACT: Change a part of the state that is NOT selected.
      userJoker.trick(const User(name: 'Alice', age: 31));
      await tester.pump();

      // ASSERT: Widget should NOT have rebuilt.
      expect(find.text('Name: Alice'), findsOneWidget);
      expect(buildCounter.buildCount, 1);

      // ACT: Change the selected part of the state.
      userJoker.trick(const User(name: 'Bob', age: 31));
      await tester.pump();

      // ASSERT: Widget SHOULD have rebuilt.
      expect(find.text('Name: Bob'), findsOneWidget);
      expect(buildCounter.buildCount, 2);
    });
  });

  group('JokerWatch', () {
    testWidgets('should call onStateChange when state changes',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(0, keepAlive: true);
      int? callbackValue;

      await tester.pumpWidget(
        JokerWatch<int>(
          act: counterJoker,
          onStateChange: (context, state) {
            callbackValue = state;
          },
          child: const SizedBox(),
        ),
      );

      // ACT
      counterJoker.trick(5);
      await tester.pump();

      // ASSERT
      expect(callbackValue, 5);
    });

    testWidgets('should only call onStateChange when watchWhen is true',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(0, keepAlive: true);
      int callCount = 0;

      await tester.pumpWidget(
        JokerWatch<int>(
          act: counterJoker,
          watchWhen: (prev, curr) => curr > 5,
          onStateChange: (context, state) {
            callCount++;
          },
          child: const SizedBox(),
        ),
      );

      // ACT: This change should be ignored by watchWhen.
      counterJoker.trick(3);
      await tester.pump();

      // ASSERT: Callback should not have been called.
      expect(callCount, 0);

      // ACT: This change should be accepted by watchWhen.
      counterJoker.trick(10);
      await tester.pump();

      // ASSERT: Callback should have been called.
      expect(callCount, 1);
    });

    testWidgets('should call onStateChange on build if runOnBuild is true',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(10, keepAlive: true);
      int? initialValue;

      // ACT
      await tester.pumpWidget(
        JokerWatch<int>(
          act: counterJoker,
          runOnBuild: true,
          onStateChange: (context, state) {
            initialValue = state;
          },
          child: const SizedBox(),
        ),
      );

      // ASSERT: Callback was called with the initial value after the first frame.
      expect(initialValue, 10);
    });
  });

  group('JokerRehearse', () {
    testWidgets('should build and call onStateChange on state change',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(0, keepAlive: true);
      int? callbackValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JokerRehearse<int>(
              act: counterJoker,
              builder: (context, state) => Text('State: $state'),
              onStateChange: (context, state) {
                callbackValue = state;
              },
            ),
          ),
        ),
      );

      // ASSERT: Initial state is correct.
      expect(find.text('State: 0'), findsOneWidget);
      expect(callbackValue, isNull);

      // ACT
      counterJoker.trick(7);
      await tester.pump();

      // ASSERT: Both builder and callback were triggered.
      expect(find.text('State: 7'), findsOneWidget);
      expect(callbackValue, 7);
    });

    testWidgets(
        'should respect performWhen for rebuilds and watchWhen for callbacks',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(0, keepAlive: true);
      int watchCallbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JokerRehearse<int>(
              act: counterJoker,
              // Only rebuild for even numbers
              performWhen: (prev, curr) => curr.isEven,
              // Only trigger callback for multiples of 3
              watchWhen: (prev, curr) => curr % 3 == 0,
              builder: (context, state) => Text('State: $state'),
              onStateChange: (context, state) {
                watchCallbackCount++;
              },
            ),
          ),
        ),
      );

      // Initial state
      expect(find.text('State: 0'), findsOneWidget);
      expect(watchCallbackCount, 0);

      // ACT 1: Should not rebuild or call back
      counterJoker.trick(1);
      await tester.pump();
      expect(find.text('State: 0'), findsOneWidget); // Not rebuilt
      expect(watchCallbackCount, 0);

      // ACT 2: Should rebuild but not call back
      counterJoker.trick(2);
      await tester.pump();
      expect(find.text('State: 2'), findsOneWidget); // Rebuilt
      expect(watchCallbackCount, 0);

      // ACT 3: Should not rebuild but should call back
      counterJoker.trick(3);
      await tester.pump();
      expect(find.text('State: 2'), findsOneWidget); // Not rebuilt
      expect(watchCallbackCount, 1);

      // ACT 4: Should rebuild and call back
      counterJoker.trick(6);
      await tester.pump();
      expect(find.text('State: 6'), findsOneWidget); // Rebuilt
      expect(watchCallbackCount, 2);
    });
  });

  group('JokerTroupe', () {
    testWidgets(
        'should build with combined initial states and rebuild on any change',
        (WidgetTester tester) async {
      // ARRANGE
      final nameJoker = Joker<String>('A', keepAlive: true);
      final numberJoker = Joker<int>(1, keepAlive: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JokerTroupe<(String, int)>(
              acts: [nameJoker, numberJoker],
              converter: (values) => (values[0] as String, values[1] as int),
              builder: (context, states) {
                return Text('${states.$1}, ${states.$2}');
              },
            ),
          ),
        ),
      );

      // ASSERT: Initial state is correct.
      expect(find.text('A, 1'), findsOneWidget);

      // ACT: Change the first Joker.
      nameJoker.trick('B');
      await tester.pump();

      // ASSERT: UI updates.
      expect(find.text('B, 1'), findsOneWidget);

      // ACT: Change the second Joker.
      numberJoker.trick(2);
      await tester.pump();

      // ASSERT: UI updates again.
      expect(find.text('B, 2'), findsOneWidget);
    });
  });

  group('JokerRing', () {
    testWidgets('provides a JokerAct to descendants which can be watched',
        (WidgetTester tester) async {
      // ARRANGE
      final counterJoker = Joker<int>(10, keepAlive: true);

      // A test widget that consumes the JokerAct from context.
      final testWidget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Use the context extension to watch the act.
              final act = context.watchJoker<int>();
              return Text('Value: ${act.value}');
            },
          ),
        ),
      );

      // ACT
      await tester.pumpWidget(
        JokerRing<int>(
          act: counterJoker,
          child: testWidget,
        ),
      );

      // ASSERT: The widget displays the initial value from the provided Joker.
      expect(find.text('Value: 10'), findsOneWidget);

      // ACT: Update the joker's state.
      counterJoker.trick(20);
      await tester.pump();

      // ASSERT: The widget rebuilt and displays the new value.
      expect(find.text('Value: 20'), findsOneWidget);
    });
  });
}
