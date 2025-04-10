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
      final stage = joker.perform((context, value, _) {
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
      joker.value = 100;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('perform() should respect autoDispose parameter',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);

      // Act - create stage with autoDispose = false
      final stage = joker.perform(
        (context, value, _) => Text('$value'),
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
      joker.value = 100;
      expect(joker.value, 100); // Should not throw if not disposed
    });
  });

  group('JokerTroupe Extension', () {
    testWidgets('assemble() should create a JokerTroupe with the jokers',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');
      final joker3 = Joker<bool>(true);
      final jokers = [joker1, joker2, joker3];

      bool troupeBuilderCalled = false;
      List<dynamic>? troupeValues;

      // Act
      final troupe = jokers.assemble(builder: (context, values, _) {
        troupeBuilderCalled = true;
        troupeValues = values;
        return Column(
          children: [
            Text('${values[0]}'),
            Text('${values[1]}'),
            Text('${values[2]}'),
          ],
        );
      });

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: troupe,
          ),
        ),
      );

      // Assert
      expect(troupe, isA<JokerTroupe>());
      expect(troupeBuilderCalled, isTrue);
      expect(troupeValues, isNotNull);
      expect(troupeValues![0], equals(10));
      expect(troupeValues![1], equals('test'));
      expect(troupeValues![2], isTrue);

      // Verify texts are displayed
      expect(find.text('10'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);

      // Test reactivity
      joker1.value = 20;
      await tester.pump();
      expect(find.text('20'), findsOneWidget);

      joker2.value = 'updated';
      await tester.pump();
      expect(find.text('updated'), findsOneWidget);
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
      expect(joker.value, equals(42));
      expect(circus.isHired<Joker<int>>('counter'), isTrue);
    });

    test('summon() should set the stopped parameter correctly', () {
      // Arrange
      bool listenerCalled = false;

      // Act
      final joker = circus.summon<int>(42, tag: 'counter', stopped: true);
      joker.addListener(() {
        listenerCalled = true;
      });

      // Modify the value
      joker.value = 100;

      // Assert
      expect(joker.value, equals(100)); // Value should be updated
      expect(listenerCalled, isFalse); // But listener shouldn't be called
    });

    test('spotlight() should find a hired Joker', () {
      // Arrange
      final joker = circus.summon<String>('hello', tag: 'greeting');

      // Act
      final foundJoker = circus.spotlight<String>(tag: 'greeting');

      // Assert
      expect(foundJoker, isA<Joker<String>>());
      expect(foundJoker.value, equals('hello'));
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
      expect(foundJoker!.value, isTrue);
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
