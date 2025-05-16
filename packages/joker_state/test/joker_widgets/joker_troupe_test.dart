import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerTroupe', () {
    testWidgets('should display initial values with correct types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) {
              final (count, text) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Text: $text'),
                ],
              );
            },
          ),
        ),
      );

      // Assert
      expect(find.text('Count: 10'), findsOneWidget);
      expect(find.text('Text: test'), findsOneWidget);
    });

    testWidgets('should update when any joker changes',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1);
      final joker2 = Joker<bool>(false);

      // Act - build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, bool)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as bool),
            builder: (context, values) {
              final (count, isActive) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Active: ${isActive ? 'Yes' : 'No'}'),
                ],
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Active: No'), findsOneWidget);

      // Update first joker
      joker1.trick(10);
      await tester.pump();

      // Check updated state
      expect(find.text('Count: 10'), findsOneWidget);

      // Update second joker
      joker2.trick(true);
      await tester.pump();

      // Check updated state
      expect(find.text('Active: Yes'), findsOneWidget);
    });

    testWidgets('should provide properly typed values to builder',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('hello');
      final joker3 = Joker<bool>(true);

      bool builderCalled = false;
      late int intValue;
      late String stringValue;
      late bool boolValue;

      // Act - build widget
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String, bool)>(
            jokers: [joker1, joker2, joker3],
            converter: (values) =>
                (values[0] as int, values[1] as String, values[2] as bool),
            builder: (context, values) {
              builderCalled = true;
              final (a, b, c) = values;
              intValue = a;
              stringValue = b;
              boolValue = c;
              return Text('$a, $b, $c');
            },
          ),
        ),
      );

      // Assert
      expect(builderCalled, isTrue);
      expect(intValue, equals(42));
      expect(stringValue, equals('hello'));
      expect(boolValue, isTrue);
      expect(find.text('42, hello, true'), findsOneWidget);
    });

    testWidgets(
        'Jokers with keepAlive=false should dispose after troupe removal',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1, keepAlive: false); // Default, but explicit
      final joker2 = Joker<String>('test', keepAlive: false);
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Act - build and then remove widget
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget
      await tester.pumpAndSettle(); // Wait for dispose timers

      // Assert
      expect(joker1.isDisposed, isTrue);
      expect(joker2.isDisposed, isTrue);
    });

    testWidgets(
        'Jokers with keepAlive=true should NOT dispose after troupe removal',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1, keepAlive: true);
      final joker2 = Joker<String>('test', keepAlive: true);
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Act - build and then remove widget
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget
      await tester.pumpAndSettle(); // Wait potential dispose time

      // Assert - should not be disposed
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Verify jokers still work
      expect(() => joker1.trick(100), returnsNormally);
      expect(() => joker2.trick('updated'), returnsNormally);
      expect(joker1.state, equals(100));
      expect(joker2.state, equals('updated'));
    });

    testWidgets('Mixed keepAlive Jokers dispose correctly after troupe removal',
        (WidgetTester tester) async {
      // Arrange
      final disposeJoker = Joker<int>(1, keepAlive: false);
      final keepJoker = Joker<String>('keep', keepAlive: true);
      expect(disposeJoker.isDisposed, isFalse);
      expect(keepJoker.isDisposed, isFalse);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String)>(
            jokers: [disposeJoker, keepJoker],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Assert
      expect(disposeJoker.isDisposed, isTrue); // Should be disposed
      expect(keepJoker.isDisposed, isFalse); // Should NOT be disposed
    });

    testWidgets('assemble() extension builds and reacts correctly',
        (WidgetTester tester) async {
      // Arrange
      final name = Joker<String>('Alice');
      final age = Joker<int>(30);

      // Act - Use assemble extension
      await tester.pumpWidget(
        MaterialApp(
          home: [name, age].assemble<(String, int)>(
            converter: (values) => (values[0] as String, values[1] as int),
            builder: (context, data) {
              return Text('${data.$1} - ${data.$2}');
            },
          ),
        ),
      );

      // Assert initial
      expect(find.text('Alice - 30'), findsOneWidget);

      // Update age
      age.trick(31);
      await tester.pump();
      expect(find.text('Alice - 31'), findsOneWidget);
    });

    testWidgets('should properly convert complex record types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('hello');
      final joker3 = Joker<bool>(true);
      final joker4 = Joker<double>(3.14);

      // Act - build with complex record type
      await tester.pumpWidget(
        MaterialApp(
          home: JokerTroupe<(int, String, (bool, double))>(
            jokers: [joker1, joker2, joker3, joker4],
            converter: (values) => (
              values[0] as int,
              values[1] as String,
              (values[2] as bool, values[3] as double) // Nested record
            ),
            builder: (context, values) {
              final (count, message, (isActive, rating)) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Message: $message'),
                  Text('Active: $isActive'),
                  Text('Rating: $rating'),
                ],
              );
            },
          ),
        ),
      );

      // Assert
      expect(find.text('Count: 42'), findsOneWidget);
      expect(find.text('Message: hello'), findsOneWidget);
      expect(find.text('Active: true'), findsOneWidget);
      expect(find.text('Rating: 3.14'), findsOneWidget);
    });
  });
}
