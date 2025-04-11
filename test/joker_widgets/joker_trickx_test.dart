import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker/joker_trickx.dart';
import 'package:joker_state/src/state_management/joker_stage/joker_stage.dart';
import 'package:joker_state/src/state_management/joker_troupe/joker_troupe.dart';

void main() {
  group('JokerStage Extension', () {
    testWidgets('perform() should create a JokerStage with the joker',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      bool handBuilderCalled = false;
      int? handValue;

      // Act
      final stage = joker.perform(builder: (context, value) {
        handBuilderCalled = true;
        handValue = value;
        return Text('$value');
      });

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: stage,
          ),
        ),
      );

      // Assert
      expect(stage, isA<JokerStage<int>>());
      expect(handBuilderCalled, isTrue);
      expect(handValue, equals(42));

      // Verify text is displayed
      expect(find.text('42'), findsOneWidget);

      // Test reactivity
      joker.trick(100);
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('perform() should respect autoDispose parameter',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);

      // Act - create stage with autoDispose = false
      final stage = joker.perform(
        builder: (context, value) => Text('$value'),
        autoDispose: false,
      );

      // Build and dispose the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: stage,
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Dispose widget

      // Assert joker still works
      joker.trick(100);
      expect(joker.state, 100); // Should not throw if not disposed
    });
  });

  group('JokerTroupeExtension', () {
    testWidgets(
        'assemble() should create a JokerTroupe with proper Record type',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');
      final joker3 = Joker<bool>(true);
      final jokers = [joker1, joker2, joker3];

      bool builderCalled = false;
      late (int, String, bool) capturedValues;

      // Act - Use the assemble extension method
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
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MaterialApp(
            home: Scaffold(
              body: troupe,
            ),
          ),
        ),
      );

      // Assert
      expect(troupe, isA<JokerTroupe<(int, String, bool)>>());
      expect(builderCalled, isTrue);
      expect(capturedValues.$1, equals(10));
      expect(capturedValues.$2, equals('test'));
      expect(capturedValues.$3, isTrue);

      // Verify texts are displayed
      expect(find.text('Int: 10'), findsOneWidget);
      expect(find.text('String: test'), findsOneWidget);
      expect(find.text('Bool: true'), findsOneWidget);

      // Test reactivity
      joker1.trick(20);
      await tester.pump();
      expect(find.text('Int: 20'), findsOneWidget);

      // Test another joker update
      joker2.trick('updated');
      await tester.pump();
      expect(find.text('String: updated'), findsOneWidget);
    });

    testWidgets('assemble() should respect autoDispose parameter',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = DisposableTracker<int>(10);
      final joker2 = DisposableTracker<String>('test');
      final jokers = [joker1, joker2];

      // Act - Create JokerTroupe with autoDispose = true
      final troupe = jokers.assemble<(int, String)>(
        converter: (values) => (values[0] as int, values[1] as String),
        builder: (context, values) => Text('${values.$1}, ${values.$2}'),
        autoDispose: true,
      );

      // Build and dispose widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: troupe,
        ),
      );

      // Initial state check
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Dispose widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Assert
      expect(joker1.isDisposed, isTrue);
      expect(joker2.isDisposed, isTrue);
    });

    testWidgets('assemble() should handle complex Record types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('test');
      final joker3 = Joker<Map<String, dynamic>>({'name': 'John', 'age': 30});
      final jokers = [joker1, joker2, joker3];

      // Act - Use with complex Record type
      final troupe = jokers.assemble<(int, String, User)>(
        converter: (values) {
          return (
            values[0] as int,
            values[1] as String,
            User.fromJson(values[2] as Map<String, dynamic>),
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
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: troupe,
        ),
      );

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

        await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: troupe));
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

        await tester.pumpWidget(
            Directionality(textDirection: TextDirection.ltr, child: troupe));
        expect(find.text('1, 2.0, a, true'), findsOneWidget);
      }
    });
  });

  group('JokerRingExtension', () {
    late CircusRing circus;

    setUp(() {
      circus = CircusRing();
      circus.fireAll();
    });

    test('summon() should register a Joker with the given tag', () {
      // Act
      final joker = circus.summon<int>(42, tag: 'counter');

      // Assert
      expect(joker, isA<Joker<int>>());
      expect(joker.state, equals(42));
      expect(circus.isHired<Joker<int>>('counter'), isTrue);
    });

    test('summon() should hire a autoNotify Joker', () {
      // Arrange
      bool listenerCalled = false;

      // Act
      final joker = circus.summon<int>(42, tag: 'counter');
      joker.addListener(() {
        listenerCalled = true;
      });

      // Modify the value
      joker.trick(100);

      // Assert
      expect(joker.state, equals(100)); // Value should be updated
      expect(listenerCalled, isTrue); // Listener should be called too
    });

    test('recruit() should hire a manual Joker', () {
      // Arrange
      bool listenerCalled = false;

      // Act
      final joker = circus.recruit<int>(42, tag: 'counter');
      joker.addListener(() {
        listenerCalled = true;
      });

      // Modify the value without notification
      joker.whisper(100);

      // Assert
      expect(joker.state, equals(100)); // Value should be updated
      expect(listenerCalled, isFalse); // But listener shouldn't be called
    });

    test('spotlight() should find a hired Joker', () {
      // Arrange
      final joker = circus.summon<String>('hello', tag: 'greeting');

      // Act
      final foundJoker = circus.spotlight<String>(tag: 'greeting');

      // Assert
      expect(foundJoker, isA<Joker<String>>());
      expect(foundJoker.state, equals('hello'));
      expect(foundJoker, equals(joker)); // Should be the same instance
    });

    test('spotlight() should throw when joker not found', () {
      // Act & Assert
      expect(() => circus.spotlight<int>(tag: 'nonexistent'), throwsException);
    });

    test('trySpotlight() should return null when joker not found', () {
      // Act
      final card = circus.trySpotlight<int>(tag: 'nonexistent');

      // Assert
      expect(card, isNull);
    });

    test('trySpotlight() should find a hired joker', () {
      // Arrange
      final card = circus.summon<bool>(true, tag: 'flag');

      // Act
      final foundJoker = circus.trySpotlight<bool>(tag: 'flag');

      // Assert
      expect(foundJoker, isNotNull);
      expect(foundJoker!.state, isTrue);
      expect(foundJoker, equals(card)); // Should be the same instance
    });

    test('vanish() should delete a hired Joker', () {
      // Arrange
      circus.summon<int>(42, tag: 'counter');

      // Act
      final result = circus.vanish<int>(tag: 'counter');

      // Assert
      expect(result, isTrue);
      expect(circus.isHired<Joker<int>>('counter'), isFalse);
    });

    test('vanish() should return false when joker not found', () {
      // Act
      final result = circus.vanish<String>(tag: 'nonexistent');

      // Assert
      expect(result, isFalse);
    });
  });
}

class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  static User fromJson(Map<String, dynamic> json) {
    return User(json['name'], json['age']);
  }
}

// Helper Tracker to tracking dispose calls
class DisposableTracker<T> extends Joker<T> {
  bool isDisposed = false;

  DisposableTracker(T initialValue, {String? tag})
      : super(initialValue, tag: tag);

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
