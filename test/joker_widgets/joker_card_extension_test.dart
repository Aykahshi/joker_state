import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card_extension.dart';
import 'package:joker_state/src/state_management/joker_deck/joker_deck.dart';
import 'package:joker_state/src/state_management/joker_hand/joker_hand.dart';

void main() {
  group('JokerCardToBox Extension', () {
    testWidgets('reveal() should create a JokerHand with the card',
        (WidgetTester tester) async {
      // Arrange
      final card = JokerCard<int>(42);
      bool handBuilderCalled = false;
      int? handValue;

      // Act
      final hand = card.reveal((context, value, _) {
        handBuilderCalled = true;
        handValue = value;
        return Text('$value');
      });

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: hand,
          ),
        ),
      );

      // Assert
      expect(hand, isA<JokerHand<int>>());
      expect(handBuilderCalled, isTrue);
      expect(handValue, equals(42));

      // Verify text is displayed
      expect(find.text('42'), findsOneWidget);

      // Test reactivity
      card.value = 100;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('reveal() should respect autoDispose parameter',
        (WidgetTester tester) async {
      // Arrange
      final card = JokerCard<int>(42);

      // Act - create hand with autoDispose = false
      final hand = card.reveal(
        (context, value, _) => Text('$value'),
        autoDispose: false,
      );

      // Build and dispose the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: hand,
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Dispose widget

      // Assert card still works
      card.value = 100;
      expect(card.value, 100); // Should not throw if not disposed
    });
  });

  group('PokerTableExtension', () {
    testWidgets('onDeck() should create a JokerDeck with the cards',
        (WidgetTester tester) async {
      // Arrange
      final card1 = JokerCard<int>(10);
      final card2 = JokerCard<String>('test');
      final card3 = JokerCard<bool>(true);
      final cards = [card1, card2, card3];

      bool deckBuilderCalled = false;
      List<dynamic>? deckValues;

      // Act
      final deck = cards.onDeck(builder: (context, values, _) {
        deckBuilderCalled = true;
        deckValues = values;
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
            body: deck,
          ),
        ),
      );

      // Assert
      expect(deck, isA<JokerDeck>());
      expect(deckBuilderCalled, isTrue);
      expect(deckValues, isNotNull);
      expect(deckValues![0], equals(10));
      expect(deckValues![1], equals('test'));
      expect(deckValues![2], isTrue);

      // Verify texts are displayed
      expect(find.text('10'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);

      // Test reactivity
      card1.value = 20;
      await tester.pump();
      expect(find.text('20'), findsOneWidget);

      card2.value = 'updated';
      await tester.pump();
      expect(find.text('updated'), findsOneWidget);
    });
  });

  group('JokerCardExtension', () {
    late CircusRing ring;

    setUp(() {
      ring = CircusRing();
      ring.deleteAll();
    });

    test('putCard() should register a JokerCard with the given tag', () {
      // Act
      final card = ring.putCard<int>(42, tag: 'counter');

      // Assert
      expect(card, isA<JokerCard<int>>());
      expect(card.value, equals(42));
      expect(ring.isRegistered<JokerCard<int>>('counter'), isTrue);
    });

    test('putCard() should set the stopped parameter correctly', () {
      // Arrange
      bool listenerCalled = false;

      // Act
      final card = ring.putCard<int>(42, tag: 'counter', stopped: true);
      card.addListener(() {
        listenerCalled = true;
      });

      // Modify the value
      card.value = 100;

      // Assert
      expect(card.value, equals(100)); // Value should be updated
      expect(listenerCalled, isFalse); // But listener shouldn't be called
    });

    test('drawCard() should find a registered JokerCard', () {
      // Arrange
      final card = ring.putCard<String>('hello', tag: 'greeting');

      // Act
      final foundCard = ring.drawCard<String>(tag: 'greeting');

      // Assert
      expect(foundCard, isA<JokerCard<String>>());
      expect(foundCard.value, equals('hello'));
      expect(foundCard, equals(card)); // Should be the same instance
    });

    test('drawCard() should throw when card not found', () {
      // Act & Assert
      expect(() => ring.drawCard<int>(tag: 'nonexistent'), throwsException);
    });

    test('tryDrawCard() should return null when card not found', () {
      // Act
      final card = ring.tryDrawCard<int>(tag: 'nonexistent');

      // Assert
      expect(card, isNull);
    });

    test('tryDrawCard() should find a registered card', () {
      // Arrange
      final card = ring.putCard<bool>(true, tag: 'flag');

      // Act
      final foundCard = ring.tryDrawCard<bool>(tag: 'flag');

      // Assert
      expect(foundCard, isNotNull);
      expect(foundCard!.value, isTrue);
      expect(foundCard, equals(card)); // Should be the same instance
    });

    test('discard() should delete a registered JokerCard', () {
      // Arrange
      ring.putCard<int>(42, tag: 'counter');

      // Act
      final result = ring.discard<int>(tag: 'counter');

      // Assert
      expect(result, isTrue);
      expect(ring.isRegistered<JokerCard<int>>('counter'), isFalse);
    });

    test('discard() should return false when card not found', () {
      // Act
      final result = ring.discard<String>(tag: 'nonexistent');

      // Assert
      expect(result, isFalse);
    });
  });
}
