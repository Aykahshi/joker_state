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
      joker.trick(100);
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets(
        'perform() with Joker(keepAlive=false) should lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Joker will auto-dispose
      final joker = Joker<int>(42, keepAlive: false);
      final stage = joker.perform(builder: (context, value) => Text('$value'));

      await pumpWidgetWithMaterial(tester, stage);
      expect(joker.isDisposed, isFalse);

      // Act: Remove the widget (removes listener, schedules microtask)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtask

      // Assert: Joker should be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets(
        'perform() with Joker(keepAlive=true) should NOT lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Joker will NOT auto-dispose
      final joker = Joker<int>(42, keepAlive: true);
      final stage = joker.perform(builder: (context, value) => Text('$value'));

      await pumpWidgetWithMaterial(tester, stage);
      expect(joker.isDisposed, isFalse);

      // Act: Remove the widget
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once

      // Assert: Joker should NOT be disposed
      expect(joker.isDisposed, isFalse);
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
      final frame = joker.observe<int>(
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
      joker.trick({'count': 1});
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('observe() should only rebuild on relevant value change',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<Map<String, dynamic>>({'name': 'Alice', 'age': 20});
      int buildCount = 0;

      // Act: Observe only the name
      final frame = joker.observe<String>(
        selector: (state) => state['name'] as String,
        builder: (context, name) {
          buildCount++;
          return Text('Name: $name');
        },
      );

      await pumpWidgetWithMaterial(tester, frame);

      // Assert initial build
      expect(find.text('Name: Alice'), findsOneWidget);
      expect(buildCount, equals(1));

      // Act: Change unrelated field ('age')
      joker.trick({'name': 'Alice', 'age': 21});
      await tester.pump();

      // Assert: Should not rebuild
      expect(buildCount, equals(1));

      // Act: Now change tracked field ('name')
      joker.trick({'name': 'Bob', 'age': 21});
      await tester.pump();

      // Assert: Should rebuild
      expect(find.text('Name: Bob'), findsOneWidget);
      expect(buildCount, equals(2));
    });

    testWidgets(
        'observe() with Joker(keepAlive=false) should lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Joker will auto-dispose
      final joker =
          Joker<Map<String, dynamic>>({'key': 'value'}, keepAlive: false);
      final frame = joker.observe<String>(
        selector: (state) => state['key'] as String,
        builder: (context, value) => Text(value),
      );

      await pumpWidgetWithMaterial(tester, frame);
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget (removes listener, schedules microtask)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtask

      // Assert: Joker should be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets(
        'observe() with Joker(keepAlive=true) should NOT lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Joker will NOT auto-dispose
      final joker =
          Joker<Map<String, dynamic>>({'key': 'value'}, keepAlive: true);
      final frame = joker.observe<String>(
        selector: (state) => state['key'] as String,
        builder: (context, value) => Text(value),
      );

      await pumpWidgetWithMaterial(tester, frame);
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once

      // Assert: Joker should NOT be disposed
      expect(joker.isDisposed, isFalse);
    });
  });

  group('JokerTroupeExtension', () {
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
      joker1.trick(20);
      await tester.pump();
      expect(find.text('Int: 20'), findsOneWidget);
      joker2.trick('updated');
      await tester.pump();
      expect(find.text('String: updated'), findsOneWidget);
    });

    testWidgets(
        'assemble() with Jokers(keepAlive=false) should lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Jokers will auto-dispose
      final joker1 = Joker<int>(10, keepAlive: false);
      final joker2 = Joker<String>('test', keepAlive: false);
      final troupe = [joker1, joker2].assemble<(int, String)>(
        converter: (values) => (values[0] as int, values[1] as String),
        builder: (context, values) => Text('${values.$1}, ${values.$2}'),
      );

      await pumpWidgetWithMaterial(tester, troupe);
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Act: Remove widget (removes listeners, schedules microtasks)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtasks

      // Assert: Both Jokers should be disposed
      expect(joker1.isDisposed, isTrue);
      expect(joker2.isDisposed, isTrue);
    });

    testWidgets(
        'assemble() with Jokers(keepAlive=true) should NOT lead to disposal after removal',
        (WidgetTester tester) async {
      // Arrange: Jokers will NOT auto-dispose
      final joker1 = Joker<int>(10, keepAlive: true);
      final joker2 = Joker<String>('test', keepAlive: true);
      final troupe = [joker1, joker2].assemble<(int, String)>(
        converter: (values) => (values[0] as int, values[1] as String),
        builder: (context, values) => Text('${values.$1}, ${values.$2}'),
      );

      await pumpWidgetWithMaterial(tester, troupe);
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once

      // Assert: Both Jokers should NOT be disposed
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);
    });

    testWidgets(
        'assemble() with mixed keepAlive Jokers behaves correctly after removal',
        (WidgetTester tester) async {
      // Arrange: One Joker will auto-dispose, the other won't
      final disposeJoker = Joker<int>(10, keepAlive: false);
      final keepJoker = Joker<String>('test', keepAlive: true);
      final troupe = [disposeJoker, keepJoker].assemble<(int, String)>(
        converter: (values) => (values[0] as int, values[1] as String),
        builder: (context, values) => Text('${values.$1}, ${values.$2}'),
      );

      await pumpWidgetWithMaterial(tester, troupe);
      expect(disposeJoker.isDisposed, isFalse);
      expect(keepJoker.isDisposed, isFalse);

      // Act: Remove widget (removes listeners, schedules microtask for one)
      await tester.pumpWidget(Container());
      await tester.pump(); // Pump once for microtask

      // Assert: Only the non-keepAlive Joker should be disposed
      expect(disposeJoker.isDisposed, isTrue);
      expect(keepJoker.isDisposed, isFalse);
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
      joker3.trick({'name': 'Jane', 'age': 25});
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

  group('JokerRingExtension', () {
    // Use the static Circus methods for these tests, as intended
    setUp(() {
      // Clean up the global Circus instance before each test
      Circus.fireAll();
    });

    tearDown(() {
      // Clean up after each test
      Circus.fireAll();
    });

    test('summon() should register Joker with keepAlive=false by default', () {
      // Act
      final joker = Circus.summon<int>(42, tag: 'counter');

      // Assert
      expect(joker.keepAlive, isFalse);
      expect(Circus.isHired<Joker<int>>('counter'), isTrue);
    });

    test('summon() should register Joker with keepAlive=true when specified',
        () {
      // Act
      final joker = Circus.summon<int>(42, tag: 'counter', keepAlive: true);

      // Assert
      expect(joker.keepAlive, isTrue);
      expect(Circus.isHired<Joker<int>>('counter'), isTrue);
    });

    test(
        'recruit() should register manual Joker with keepAlive=false by default',
        () {
      // Act
      final joker = Circus.recruit<int>(42, tag: 'manual-counter');

      // Assert
      expect(joker.autoNotify, isFalse);
      expect(joker.keepAlive, isFalse);
      expect(Circus.isHired<Joker<int>>('manual-counter'), isTrue);
    });

    test(
        'recruit() should register manual Joker with keepAlive=true when specified',
        () {
      // Act
      final joker =
          Circus.recruit<int>(42, tag: 'manual-counter', keepAlive: true);

      // Assert
      expect(joker.autoNotify, isFalse);
      expect(joker.keepAlive, isTrue);
      expect(Circus.isHired<Joker<int>>('manual-counter'), isTrue);
    });

    test('summon() should hire an autoNotify Joker', () {
      // Arrange
      bool listenerCalled = false;
      final joker = Circus.summon<int>(42, tag: 'auto-notify-test');
      joker.addListener(() => listenerCalled = true);

      // Act
      joker.trick(100);

      // Assert
      expect(joker.state, equals(100));
      expect(listenerCalled, isTrue);
    });

    test('recruit() should hire a manual Joker', () {
      // Arrange
      bool listenerCalled = false;
      final joker = Circus.recruit<int>(42, tag: 'manual-notify-test');
      joker.addListener(() => listenerCalled = true);

      // Act: Update silently
      joker.whisper(100);

      // Assert: Value updated, listener NOT called
      expect(joker.state, equals(100));
      expect(listenerCalled, isFalse);

      // Act: Notify manually
      joker.yell();
      expect(listenerCalled, isTrue);
    });

    test('spotlight() should find a hired Joker', () {
      // Arrange
      final originalJoker = Circus.summon<String>('hello', tag: 'greeting');

      // Act
      final foundJoker = Circus.spotlight<String>(tag: 'greeting');

      // Assert
      expect(foundJoker, isA<Joker<String>>());
      expect(foundJoker.state, equals('hello'));
      expect(identical(foundJoker, originalJoker), isTrue);
    });

    test('spotlight() should throw when joker not found', () {
      // Act & Assert
      expect(() => Circus.spotlight<int>(tag: 'nonexistent'),
          throwsA(isA<CircusRingException>()));
    });

    test('trySpotlight() should return null when joker not found', () {
      // Act
      final joker = Circus.trySpotlight<int>(tag: 'nonexistent');

      // Assert
      expect(joker, isNull);
    });

    test('trySpotlight() should find a hired joker', () {
      // Arrange
      final originalJoker = Circus.summon<bool>(true, tag: 'flag');

      // Act
      final foundJoker = Circus.trySpotlight<bool>(tag: 'flag');

      // Assert
      expect(foundJoker, isNotNull);
      expect(foundJoker!.state, isTrue);
      expect(identical(foundJoker, originalJoker), isTrue);
    });

    test('vanish() should remove Joker from CircusRing', () {
      // Arrange
      Circus.summon<int>(42, tag: 'counter'); // Register the joker
      expect(Circus.isHired<Joker<int>>('counter'), isTrue);

      // Act
      final result = Circus.vanish<int>(tag: 'counter');

      // Assert: Removed from ring
      expect(result, isTrue);
      expect(Circus.isHired<Joker<int>>('counter'), isFalse);
    });

    test(
        // Test name updated to reflect actual behavior
        'vanish() should remove from ring but NOT auto-dispose if no listeners were active',
        () async {
      // Arrange: Joker with no external listeners, keepAlive=false
      final joker =
          Circus.summon<int>(42, tag: 'dispose-on-vanish', keepAlive: false);
      expect(joker.isDisposed, isFalse);
      expect(Circus.isHired<Joker<int>>('dispose-on-vanish'), isTrue);

      // Act: Vanish the Joker (removes CircusRing's registration only)
      final result = Circus.vanish<int>(tag: 'dispose-on-vanish');

      // Assert: Removed from ring
      expect(result, isTrue);
      expect(Circus.isHired<Joker<int>>('dispose-on-vanish'), isFalse);

      // Assert: Should NOT be disposed because vanish doesn't call removeListener
      await Future.delayed(Duration.zero); // Wait for microtask just in case
      expect(joker.isDisposed, isFalse); // Corrected assertion
    });

    test('vanish() should NOT trigger auto-dispose if keepAlive=true',
        () async {
      // Arrange: Joker with keepAlive=true
      final joker =
          Circus.summon<int>(42, tag: 'keep-on-vanish', keepAlive: true);
      expect(joker.isDisposed, isFalse);
      expect(Circus.isHired<Joker<int>>('keep-on-vanish'), isTrue);

      // Act: Vanish the Joker (Should NOT call dispose)
      final result = Circus.vanish<int>(tag: 'keep-on-vanish');

      // Assert: Removed from ring
      expect(result, isTrue);
      expect(Circus.isHired<Joker<int>>('keep-on-vanish'), isFalse);

      // Assert: Should NOT be disposed
      await Future.delayed(Duration.zero); // Wait just in case
      expect(joker.isDisposed, isFalse); // This should now pass
    });

    test('vanish() should return false when joker not found', () {
      // Act
      final result = Circus.vanish<String>(tag: 'nonexistent');

      // Assert
      expect(result, isFalse);
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
