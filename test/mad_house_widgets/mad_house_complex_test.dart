import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/state_management/mad_house/mad_house.dart';
import 'package:joker_state/src/state_management/mad_house/mad_house_x.dart';
import 'package:joker_state/src/state_management/mad_house_builder/mad_house_builder.dart';
import 'package:joker_state/src/state_management/mad_keeper/mad_keeper.dart';

void main() {
  group('MadHouse Tests', () {
    testWidgets('MadKeeper provides initial state to MadHouse',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);
      bool onChangeCalled = false;

      await tester.pumpWidget(
        MadKeeper<TestState>(
          initialState: initialState,
          onChange: (_) {
            onChangeCalled = true;
          },
          child: Builder(
            builder: (context) {
              final state = MadHouse.of<TestState>(context).state;
              expect(state.value, equals(initialState.value));
              expect(state.count, equals(initialState.count));
              return const SizedBox();
            },
          ),
        ),
      );

      expect(onChangeCalled,
          false); // onChange shouldn't be called during initialization
    });

    testWidgets('MadHouse.of throws error when not found in context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(SizedBox));
      expect(
        () => MadHouse.of<TestState>(context),
        throwsFlutterError,
      );
    });

    testWidgets('MadHouse.tryOf returns null when not found in context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(SizedBox));
      final result = MadHouse.tryOf<TestState>(context);
      expect(result, isNull);
    });

    testWidgets('Context extension madState provides access to state',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);

      await tester.pumpWidget(
        MadKeeper<TestState>(
          initialState: initialState,
          child: Builder(
            builder: (context) {
              final state = context.madState<TestState>();
              expect(state.value, equals(initialState.value));
              expect(state.count, equals(initialState.count));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('MadManager can update state', (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);
      final updatedState = TestState(value: 'updated', count: 1);

      late TestState capturedState;

      await tester.pumpWidget(
        MaterialApp(
          home: MadKeeper<TestState>(
            initialState: initialState,
            child: Builder(
              builder: (context) {
                capturedState = context.madState<TestState>();

                return TextButton(
                  onPressed: () {
                    final manager = context.madManager<TestState>();
                    manager.updateState(updatedState);
                  },
                  child: const Text('Update'),
                );
              },
            ),
          ),
        ),
      );

      expect(capturedState.value, equals('initial'));
      expect(capturedState.count, equals(0));

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(capturedState.value, equals('updated'));
      expect(capturedState.count, equals(1));
    });

    testWidgets('MadManager can update state with a function',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);

      late TestState capturedState;

      await tester.pumpWidget(
        MaterialApp(
          home: MadKeeper<TestState>(
            initialState: initialState,
            child: Builder(
              builder: (context) {
                capturedState = context.madState<TestState>();

                return TextButton(
                  onPressed: () {
                    final manager = context.madManager<TestState>();
                    manager.updateStateWith(
                        (state) => state.copyWith(count: state.count + 1));
                  },
                  child: const Text('Increment'),
                );
              },
            ),
          ),
        ),
      );

      expect(capturedState.count, equals(0));

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(capturedState.count, equals(1));
    });

    testWidgets('MadHouseBuilder rebuilds when state changes',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MadKeeper<TestState>(
              initialState: initialState,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MadHouseBuilder<TestState>(
                    builder: (context, state) {
                      buildCount++;
                      return Text('Count: ${state.count}');
                    },
                  ),
                  Builder(
                    builder: (context) {
                      return TextButton(
                        onPressed: () {
                          final manager = context.madManager<TestState>();
                          manager.updateStateWith((state) =>
                              state.copyWith(count: state.count + 1));
                        },
                        child: const Text('Increment'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(buildCount, equals(2));
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('MadKeeper onChange callback is triggered',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);
      TestState? callbackState;

      await tester.pumpWidget(
        MaterialApp(
          home: MadKeeper<TestState>(
            initialState: initialState,
            onChange: (state) {
              callbackState = state;
            },
            child: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    final manager = context.madManager<TestState>();
                    manager.updateState(TestState(value: 'changed', count: 42));
                  },
                  child: const Text('Change'),
                );
              },
            ),
          ),
        ),
      );

      expect(callbackState, isNull);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(callbackState?.value, equals('changed'));
      expect(callbackState?.count, equals(42));
    });

    testWidgets('Multiple MadKeeper instances can coexist with different types',
        (WidgetTester tester) async {
      final stringState = 'String State';
      final intState = 42;

      await tester.pumpWidget(
        MadKeeper<String>(
          initialState: stringState,
          child: MadKeeper<int>(
            initialState: intState,
            child: Builder(
              builder: (context) {
                final string = context.madState<String>();
                final integer = context.madState<int>();

                expect(string, equals(stringState));
                expect(integer, equals(intState));

                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('MadHouse updateShouldNotify works correctly',
        (WidgetTester tester) async {
      final initialState = TestState(value: 'initial', count: 0);
      int rebuildCount = 0;

      Widget buildApp(TestState state) {
        return MaterialApp(
          home: MadKeeper<TestState>(
            initialState: state,
            child: Builder(
              builder: (context) {
                // This will make the widget depend on MadHouse
                MadHouse.of<TestState>(context);
                rebuildCount++;

                return const SizedBox();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp(initialState));
      expect(rebuildCount, equals(1));

      // Update with the same state value (shouldn't trigger rebuild)
      await tester.pumpWidget(buildApp(TestState(value: 'initial', count: 0)));
      expect(rebuildCount, equals(1)); // Still 1, no rebuild needed

      // Update with a different state value (should trigger rebuild)
      await tester.pumpWidget(buildApp(TestState(value: 'changed', count: 1)));
      expect(rebuildCount, equals(2)); // Now 2, rebuild happened
    });
  });
}

// Test Model
class TestState {
  final String value;
  final int count;

  TestState({required this.value, required this.count});

  TestState copyWith({String? value, int? count}) {
    return TestState(
      value: value ?? this.value,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestState && other.value == value && other.count == count;
  }

  @override
  int get hashCode => value.hashCode ^ count.hashCode;

  @override
  String toString() => 'TestState(value: $value, count: $count)';
}
