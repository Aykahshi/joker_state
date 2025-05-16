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
      joker1.value = 10;
      await tester.pump();

      // Check updated state
      expect(find.text('Count: 10'), findsOneWidget);

      // Update second joker
      joker2.value = true;
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
        'Jokers should dispose after troupe removal if no other listeners',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1);
      final joker2 = Joker<String>('test');

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

      // Assert - should be disposed
      expect(() => joker1.value, throwsA(isA<JokerException>()));
      expect(() => joker2.value, throwsA(isA<JokerException>()));
    });

    testWidgets(
        'Jokers should NOT dispose after troupe removal if other listeners exist',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1);
      final joker2 = Joker<String>('test');

      void listener1() {}
      void listener2() {}
      joker1.addListener(listener1);
      joker2.addListener(listener2);

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

      // Assert - should not be disposed due to external listeners
      expect(() => joker1.value = 100, returnsNormally);
      expect(() => joker2.value = 'updated', returnsNormally);
      expect(joker1.value, equals(100));
      expect(joker2.value, equals('updated'));

      // Clean up and verify disposal
      joker1.removeListener(listener1);
      joker2.removeListener(listener2);
      await tester.pumpAndSettle(); // Allow time for disposal
      expect(() => joker1.value, throwsA(isA<JokerException>()));
      expect(() => joker2.value, throwsA(isA<JokerException>()));
    });

    testWidgets('Jokers dispose correctly based on external listeners after troupe removal',
        (WidgetTester tester) async {
      // Arrange
      final disposeJoker = Joker<int>(1); // No external listener, should dispose
      final keepJoker = Joker<String>('keep'); // Has external listener, should not dispose initially
      
      void externalListener() {}
      keepJoker.addListener(externalListener);

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
      expect(() => disposeJoker.value, throwsA(isA<JokerException>())); // Should be disposed
      expect(() => keepJoker.value = 'new value', returnsNormally); // Should NOT be disposed yet
      expect(keepJoker.value, 'new value');

      // Clean up keepJoker and verify its disposal
      keepJoker.removeListener(externalListener);
      await tester.pumpAndSettle(); // Allow time for disposal
      expect(() => keepJoker.value, throwsA(isA<JokerException>()));
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
      age.value = 31;
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
