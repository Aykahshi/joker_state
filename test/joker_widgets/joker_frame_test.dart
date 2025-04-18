import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerFrame', () {
    setUp(() {
      // Clean up CircusRing before each test
      Circus.fireAll();
    });

    testWidgets('rebuilds when selected value changes', (tester) async {
      final joker = Joker<Map<String, dynamic>>({'count': 0});
      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<Map<String, dynamic>, int>(
            joker: joker,
            selector: (state) => state['count'] as int,
            builder: (context, count) {
              return Text('$count');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Update count - should rebuild
      joker.trick({'count': 1});
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does not rebuild when selected value is unchanged',
        (tester) async {
      final joker = Joker<Map<String, dynamic>>({'count': 0, 'other': 'a'});
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<Map<String, dynamic>, int>(
            joker: joker,
            selector: (state) => state['count'] as int,
            builder: (context, count) {
              buildCount++;
              return Text('$count');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      // Trick with same selected value ('count') but different state
      joker.trick({'count': 0, 'other': 'b'});
      await tester.pump();

      // Should not rebuild because selected value (count) didn't change
      expect(buildCount, 1);
    });

    testWidgets('handles custom object with overridden equality',
        (tester) async {
      final joker = Joker<_UserModel>(const _UserModel(name: 'Alice', age: 20));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<_UserModel, String>(
            // Select only the name
            joker: joker,
            selector: (user) => user.name,
            builder: (context, name) {
              buildCount++;
              return Text('User: $name');
            },
          ),
        ),
      );

      expect(find.text('User: Alice'), findsOneWidget);
      expect(buildCount, 1);

      // Age change only (selected name is unchanged)
      joker.trick(const _UserModel(name: 'Alice', age: 25));
      await tester.pump();
      // Should not rebuild
      expect(buildCount, 1);

      // Name change (selected name changed)
      joker.trick(const _UserModel(name: 'Bob', age: 25));
      await tester.pump();
      expect(find.text('User: Bob'), findsOneWidget);
      // Should rebuild
      expect(buildCount, 2);
    });

    testWidgets('observe() extension builds and reacts correctly',
        (tester) async {
      final joker = Joker<_UserModel>(const _UserModel(name: 'Dan', age: 40));
      int buildCalls = 0;

      // Use the observe extension method
      final widget = joker.observe<String>(
        selector: (user) => user.name,
        builder: (context, name) {
          buildCalls++;
          return Text('Name: $name');
        },
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.text('Name: Dan'), findsOneWidget);
      expect(buildCalls, 1);

      // Unchanged selected value -> no rebuild
      joker.trick(const _UserModel(name: 'Dan', age: 41));
      await tester.pump();
      expect(buildCalls, 1);

      // Changed selected value -> rebuild
      joker.trick(const _UserModel(name: 'Ed', age: 41));
      await tester.pump();
      expect(find.text('Name: Ed'), findsOneWidget);
      expect(buildCalls, 2);
    });

    testWidgets('Joker with keepAlive=false should dispose after frame removal',
        (tester) async {
      // Arrange
      final joker = Joker<_UserModel>(
        const _UserModel(name: 'DisposeMe', age: 0),
        keepAlive: false,
      );
      expect(joker.isDisposed, isFalse);

      final widget = joker.observe<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait for dispose timer

      // Assert: Joker should be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets(
        'Joker with keepAlive=true should NOT dispose after frame removal',
        (tester) async {
      // Arrange
      final joker = Joker<_UserModel>(
        const _UserModel(name: 'KeepMe', age: 0),
        keepAlive: true,
      );
      expect(joker.isDisposed, isFalse);

      final widget = joker.observe<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait potential dispose time

      // Assert: Joker should NOT be disposed
      expect(joker.isDisposed, isFalse);
      expect(() => joker.trick(const _UserModel(name: 'Still Alive', age: 1)),
          returnsNormally);
      expect(joker.state.name, 'Still Alive');
    });
  });
}

// --- Helper Class --- //

class _UserModel {
  final String name;
  final int age;

  const _UserModel({required this.name, required this.age});

  /// Custom equality based on value
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name && // Only name matters for equality in some tests
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
