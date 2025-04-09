import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card.dart';
import 'package:joker_state/src/state_management/joker_hand/joker_hand.dart';

void main() {
  group('JokerHand Widget', () {
    late JokerCard<int> card;

    setUp(() {
      card = JokerCard<int>(42);
      Circus.deleteAll();
    });

    testWidgets('should display card value', (WidgetTester tester) async {
      // Arrange
      bool builderCalled = false;

      // Act - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: card,
          builder: (context, value, child) {
            builderCalled = true;
            return Text('Value: $value');
          },
        ),
      ));

      // Assert
      expect(builderCalled, isTrue);
      expect(find.text('Value: 42'), findsOneWidget);
    });

    testWidgets('should rebuild when card value changes',
        (WidgetTester tester) async {
      // Arrange - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: card,
          builder: (context, value, child) {
            return Text('Value: $value');
          },
        ),
      ));

      // Initial state
      expect(find.text('Value: 42'), findsOneWidget);

      // Act - change card value
      card.update(100);
      await tester.pump();

      // Assert
      expect(find.text('Value: 100'), findsOneWidget);
      expect(find.text('Value: 42'), findsNothing);
    });

    testWidgets('should pass child widget to builder',
        (WidgetTester tester) async {
      // Arrange
      final childWidget = Container(key: Key('child'));
      Widget? passedChild;

      // Act - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: card,
          builder: (context, value, child) {
            passedChild = child;
            return Column(children: [
              Text('Value: $value'),
              if (child != null) child,
            ]);
          },
          child: childWidget,
        ),
      ));

      // Assert
      expect(passedChild, equals(childWidget));
      expect(find.byKey(Key('child')), findsOneWidget);
    });

    testWidgets('should dispose card when autoDispose is true',
        (WidgetTester tester) async {
      // Arrange
      final localCard = JokerCard<String>('test');
      bool listenerCalled = false;

      localCard.addListener(() {
        listenerCalled = true;
      });

      // Act - build and dispose widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<String>(
          joker: localCard,
          autoDispose: true,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Try to update card after disposal
      try {
        localCard.update('updated');
        fail('Card should be disposed and throw exception');
      } catch (e) {
        // Expected
      }

      expect(listenerCalled, isFalse);
    });

    testWidgets('should not dispose card when autoDispose is false',
        (WidgetTester tester) async {
      // Arrange
      final localCard = JokerCard<String>('test');

      // Act - build and dispose widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<String>(
          joker: localCard,
          autoDispose: false,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Update card after widget disposal
      localCard.update('updated');

      // Assert - card should still work
      expect(localCard.value, equals('updated'));
    });

    testWidgets('should handle CircusRing registered cards correctly',
        (WidgetTester tester) async {
      // Arrange - register card in CircusRing
      final taggedCard = JokerCard<int>(100, tag: 'counter');
      Circus.put(taggedCard, tag: 'counter');

      // Act - build widget with registered card
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: taggedCard,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Check initial display
      expect(find.text('Value: 100'), findsOneWidget);

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - card should be removed from CircusRing
      expect(Circus.tryFind<JokerCard<int>>('counter'), isNull);
    });

    testWidgets('should handle card with null tag',
        (WidgetTester tester) async {
      // Arrange - card with null tag
      final untaggedCard = JokerCard<int>(200);

      // Act - build widget with untagged card
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: untaggedCard,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Check initial display
      expect(find.text('Value: 200'), findsOneWidget);

      // Dispose widget should not crash with null tag
      await tester.pumpWidget(Container());
    });

    testWidgets('should not dispose CircusRing card if autoDispose is false',
        (WidgetTester tester) async {
      // Arrange - register card in CircusRing
      final taggedCard = JokerCard<int>(100, tag: 'persistent');
      Circus.put(taggedCard, tag: 'persistent');

      // Act - build widget with autoDispose = false
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<int>(
          joker: taggedCard,
          autoDispose: false,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - card should still be in CircusRing
      expect(Circus.isRegistered<JokerCard<int>>('persistent'), isTrue);

      // Clean up
      Circus.delete<JokerCard<int>>(tag: 'persistent');
    });

    testWidgets('should handle edge case - using tag for CircusRing lookup',
        (WidgetTester tester) async {
      // This test ensures the dispose logic properly uses tag for CircusRing operations

      // Arrange - register a card with a specific tag
      final tag = 'special_tag';
      final cardA = JokerCard<String>('Card A', tag: tag);
      Circus.put(cardA, tag: tag);

      // Act - create JokerHand with this card
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerHand<String>(
          joker: cardA,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Verify initial state
      expect(find.text('Card A'), findsOneWidget);
      expect(Circus.isRegistered<JokerCard<String>>(tag), isTrue);

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - card should be removed from CircusRing using the correct tag
      expect(Circus.isRegistered<JokerCard<String>>(tag), isFalse);
    });
  });
}
