import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  // Helper function to build a widget within MaterialApp
  Future<void> pumpWidgetWithMaterial(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  group('JokerStage Extension', () {
    testWidgets('perform() should create a JokerStage that observes the joker',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      bool builderCalled = false;
      int? builderValue;

      // Act: Use the perform extension
      final stage = joker.perform(builder: (context, value) {
        builderCalled = true;
        builderValue = value;
        return Text('$value');
      });

      // Build the widget
      await pumpWidgetWithMaterial(tester, stage);

      // Assert: Correct widget type, builder called, initial value displayed
      expect(stage, isA<JokerStage<int>>());
      expect(builderCalled, isTrue);
      expect(builderValue, equals(42));
      expect(find.text('42'), findsOneWidget);

      // Test reactivity
      joker.value = 100;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets(
        'perform() with Joker should lead to disposal after removal if no other listeners',
        (WidgetTester tester) async {
      // Arrange: Joker will auto-dispose if no other listeners
      final joker = Joker<int>(42);
      final stage = joker.perform(builder: (context, value) => Text('$value'));

      await pumpWidgetWithMaterial(tester, stage);
      // Joker is listened to by JokerStage

      // Act: Remove the widget (removes listener from JokerStage, then Joker)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtask or synchronous dispose

      // Assert: Joker should be disposed
      expect(() => joker.value, throwsA(isA<JokerException>()));
      expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });

    testWidgets(
        'perform() with Joker should NOT lead to disposal after removal if other listeners exist',
        (WidgetTester tester) async {
      // Arrange: Joker has an external listener
      final joker = Joker<int>(42);
      void myListener() {}
      joker.addListener(myListener);

      final stage = joker.perform(builder: (context, value) => Text('$value'));

      await pumpWidgetWithMaterial(tester, stage);

      // Act: Remove the JokerStage widget
      await tester.pumpWidget(Container());
      await tester.pump(); 

      // Assert: Joker should NOT be disposed due to myListener
      expect(() => joker.value = 50, returnsNormally); // Should not throw
      expect(joker.value, 50);

      // Clean up
      joker.removeListener(myListener);
      await tester.pump(); // Allow disposal to occur
      expect(() => joker.value, throwsA(isA<JokerException>()));
    });
  });

  group('JokerFrame Extension', () {
    testWidgets('observe() should create JokerFrame observing selected value',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<Map<String, dynamic>>({'count': 0});
      bool builderCalled = false;
      int? observedValue;

      // Act: Use the observe extension
      final frame = joker.focusOn<int>(
        selector: (state) => state['count'] as int,
        builder: (context, count) {
          builderCalled = true;
          observedValue = count;
          return Text('Count: $count');
        },
      );

      await pumpWidgetWithMaterial(tester, frame);

      // Assert: Correct widget type, builder called, initial value
      expect(frame, isA<JokerFrame<Map<String, dynamic>, int>>());
      expect(builderCalled, isTrue);
      expect(observedValue, 0);
      expect(find.text('Count: 0'), findsOneWidget);

      // Test reactivity (change tracked value)
      joker.value = {'count': 1};
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('observe() should only rebuild on relevant value change',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<Map<String, dynamic>>({'name': 'Alice', 'age': 20});
      int buildCount = 0;

      // Act: Observe only the name
      final frame = joker.focusOn<String>(
        selector: (state) => state['name'] as String,
        builder: (context, name) {
          buildCount++;
          return Text('Name: $name');
        },
      );

      await pumpWidgetWithMaterial(tester, frame);
      expect(buildCount, 1);

      // Change non-observed value (age) -> no rebuild
      joker.value = {'name': 'Alice', 'age': 21};
      await tester.pump();
      expect(buildCount, 1);

      // Change observed value (name) -> rebuild
      joker.value = {'name': 'Bob', 'age': 21};
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('Name: Bob'), findsOneWidget);
    });

    testWidgets(
        'observe() with Joker should lead to disposal after removal if no other listeners',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<Map<String, dynamic>>({'name': 'Test'});
      final frame = joker.focusOn<String>(
        selector: (state) => state['name'] as String,
        builder: (context, name) => Text(name),
      );

      await pumpWidgetWithMaterial(tester, frame);
      // Joker is listened to by JokerFrame

      // Act: Remove the widget
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump for dispose

      // Assert: Joker should be disposed
      expect(() => joker.value, throwsA(isA<JokerException>()));
      expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });

    testWidgets(
        'observe() with Joker should NOT lead to disposal after removal if other listeners exist',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<Map<String, dynamic>>({'name': 'Test'});
      void myListener() {}
      joker.addListener(myListener);

      final frame = joker.focusOn<String>(
        selector: (state) => state['name'] as String,
        builder: (context, name) => Text(name),
      );
      await pumpWidgetWithMaterial(tester, frame);

      // Act: Remove the JokerFrame widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Assert: Joker should NOT be disposed due to myListener
      expect(() => joker.value = {'name': 'NewName'}, returnsNormally);
      expect(joker.value['name'], 'NewName');

      // Clean up
      joker.removeListener(myListener);
      await tester.pump(); // Allow disposal
      expect(() => joker.value, throwsA(isA<JokerException>()));
    });
  });

  group('JokerTroupe Extension', () {
    testWidgets(
        'assemble() should create JokerTroupe observing multiple Jokers',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');
      final joker3 = Joker<bool>(true);
      final jokers = [joker1, joker2, joker3];
      bool builderCalled = false;
      late (int, String, bool) capturedValues;

      // Act: Use the assemble extension
      final troupe = jokers.assemble<(int, String, bool)>(
        converter: (values) =>
            (values[0] as int, values[1] as String, values[2] as bool),
        builder: (context, values) {
          builderCalled = true;
          capturedValues = values;
          return Column(
            children: [
              Text('Int: ${values.$1}'),
              Text('String: ${values.$2}'),
              Text('Bool: ${values.$3}'),
            ],
          );
        },
      );

      // Build the widget
      await pumpWidgetWithMaterial(tester, troupe);

      // Assert: Correct widget type, builder called, initial values
      expect(troupe, isA<JokerTroupe<(int, String, bool)>>());
      expect(builderCalled, isTrue);
      expect(capturedValues.$1, equals(10));
      expect(capturedValues.$2, equals('test'));
      expect(capturedValues.$3, isTrue);
      expect(find.text('Int: 10'), findsOneWidget);
      expect(find.text('String: test'), findsOneWidget);
      expect(find.text('Bool: true'), findsOneWidget);

      // Test reactivity
      joker1.value = 20;
      await tester.pump();
      expect(find.text('Int: 20'), findsOneWidget);
      joker2.value = 'updated';
      await tester.pump();
      expect(find.text('String: updated'), findsOneWidget);
    });

    testWidgets('assemble() should handle disposal of jokers correctly when troupe is removed',
        (WidgetTester tester) async {
      // Arrange
      final jokerA = Joker<int>(10);
      final jokerB = Joker<String>('test');
      final troupe = [jokerA, jokerB].assemble<(int, String)>(
        converter: (values) => (values[0] as int, values[1] as String),
        builder: (context, values) => Text('${values.$1}, ${values.$2}'),
      );

      await pumpWidgetWithMaterial(tester, troupe);
      // Both jokers are listened to by JokerTroupe

      // Act: Remove widget (removes listeners from JokerTroupe, then from Jokers)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump for dispose

      // Assert: Both Jokers should be disposed as JokerTroupe was their only listener
      expect(() => jokerA.value, throwsA(isA<JokerException>()));
      expect(() => jokerB.value, throwsA(isA<JokerException>()));
    });

    testWidgets('assemble() should handle complex Record types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('test');
      final joker3 = Joker<Map<String, dynamic>>({'name': 'John', 'age': 30});
      final jokers = [joker1, joker2, joker3];

      // Act - Use with complex Record type
      final troupe = jokers.assemble<(int, String, _User)>(
        converter: (values) {
          return (
            values[0] as int,
            values[1] as String,
            _User.fromJson(values[2] as Map<String, dynamic>),
          );
        },
        builder: (context, values) {
          final (count, message, user) = values;
          return Column(
            children: [
              Text('Count: $count'),
              Text('Message: $message'),
              Text('User: ${user.name}, ${user.age}'),
            ],
          );
        },
      );

      // Build widget
      await pumpWidgetWithMaterial(tester, troupe);

      // Assert
      expect(find.text('Count: 42'), findsOneWidget);
      expect(find.text('Message: test'), findsOneWidget);
      expect(find.text('User: John, 30'), findsOneWidget);

      // Test update
      joker3.value = {'name': 'Jane', 'age': 25};
      await tester.pump();
      expect(find.text('User: Jane, 25'), findsOneWidget);
    });

    testWidgets('assemble() should work with different Record sizes',
        (WidgetTester tester) async {
      // Test with 2-element Record
      {
        final jokers = [Joker<int>(1), Joker<String>('a')];
        final troupe = jokers.assemble<(int, String)>(
          converter: (values) => (values[0] as int, values[1] as String),
          builder: (context, values) => Text('${values.$1}, ${values.$2}'),
        );

        await pumpWidgetWithMaterial(tester, troupe);
        expect(find.text('1, a'), findsOneWidget);
      }

      // Test with 4-element Record
      {
        final jokers = [
          Joker<int>(1),
          Joker<double>(2.0),
          Joker<String>('a'),
          Joker<bool>(true)
        ];
        final troupe = jokers.assemble<(int, double, String, bool)>(
          converter: (values) => (
            values[0] as int,
            values[1] as double,
            values[2] as String,
            values[3] as bool,
          ),
          builder: (context, values) =>
              Text('${values.$1}, ${values.$2}, ${values.$3}, ${values.$4}'),
        );

        await pumpWidgetWithMaterial(tester, troupe);
        expect(find.text('1, 2.0, a, true'), findsOneWidget);
      }
    });
  });
}

// Helper class for complex record test
class _User {
  final String name;
  final int age;

  _User(this.name, this.age);

  // Factory constructor for JSON conversion
  factory _User.fromJson(Map<String, dynamic> json) {
    return _User(json['name'] as String, json['age'] as int);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
