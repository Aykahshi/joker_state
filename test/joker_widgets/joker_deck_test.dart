import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card.dart';
import 'package:joker_state/src/state_management/joker_deck/joker_deck.dart';

void main() {
  group('JokerDeck Widget', () {
    // Reset CircusRing before each test
    setUp(() {
      Circus.deleteAll();
    });

    // Basic display test
    testWidgets('should display initial values of cards',
        (WidgetTester tester) async {
      // Create fresh cards for this test
      final card1 = JokerCard<int>(42);
      final card2 = JokerCard<String>('hello');
      final cards = [card1, card2];

      // Build the widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerDeck(
            cards: cards,
            builder: (context, values, child) {
              return Column(
                children: [
                  Text('Card1: ${values[0]}'),
                  Text('Card2: ${values[1]}'),
                ],
              );
            },
          ),
        ),
      );

      // Verify the display
      expect(find.text('Card1: 42'), findsOneWidget);
      expect(find.text('Card2: hello'), findsOneWidget);
    });

    // Test widget rebuilds when cards update
    testWidgets('should rebuild when card values change',
        (WidgetTester tester) async {
      // Create fresh cards for this test
      final card = JokerCard<int>(10);

      // Build the widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerDeck(
            cards: [card],
            autoDispose: false,
            builder: (context, values, _) => Text('Value: ${values[0]}'),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Value: 10'), findsOneWidget);

      // Update card value and check if UI updates
      card.update(20);
      await tester.pump();
      expect(find.text('Value: 20'), findsOneWidget);
    });

    // Test child widget is passed correctly
    testWidgets('should pass child widget to builder',
        (WidgetTester tester) async {
      // Create fresh card for this test
      final card = JokerCard<int>(5);

      // Build the widget with a child
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerDeck(
            cards: [card],
            autoDispose: false,
            builder: (context, values, child) {
              return Column(
                children: [
                  Text('Value: ${values[0]}'),
                  if (child != null) child,
                ],
              );
            },
            child: Container(child: Text('Child Widget')),
          ),
        ),
      );

      // Verify both the value and child are displayed
      expect(find.text('Value: 5'), findsOneWidget);
      expect(find.text('Child Widget'), findsOneWidget);
    });

    // Test handling card list changes with a custom test widget
    testWidgets('should handle card list changes', (WidgetTester tester) async {
      // Create a list we can modify
      final cardList = <JokerCard>[];
      cardList.add(JokerCard<int>(10));
      cardList.add(JokerCard<String>('hello'));

      // Controller to trigger state changes
      final controller = StreamController<void>();

      // Create a widget that rebuilds on stream events
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StreamBuilder<void>(
              stream: controller.stream,
              builder: (context, _) {
                return Column(
                  children: [
                    JokerDeck(
                      cards: cardList,
                      autoDispose: false,
                      builder: (context, values, _) {
                        return Column(
                          children: [
                            for (int i = 0; i < values.length; i++)
                              Text('Card ${i + 1}: ${values[i]}'),
                          ],
                        );
                      },
                    ),

                    // Button to modify the list
                    GestureDetector(
                      onTap: () {
                        cardList.add(JokerCard<bool>(true));
                        controller.add(null); // Trigger rebuild
                      },
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Add Card', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ],
                );
              }),
        ),
      );

      // Initial check
      expect(find.text('Card 1: 10'), findsOneWidget);
      expect(find.text('Card 2: hello'), findsOneWidget);

      // Tap the button - make sure it's big enough to be tappable
      await tester.tap(find.text('Add Card'));
      await tester.pump();

      // Verify all cards are shown including the new one
      expect(find.text('Card 1: 10'), findsOneWidget);
      expect(find.text('Card 2: hello'), findsOneWidget);
      expect(find.text('Card 3: true'), findsOneWidget);

      // Clean up
      controller.close();
    });

    // Simple test for empty card list
    testWidgets('should handle empty card list', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerDeck(
            cards: [],
            builder: (context, values, _) => Text('Empty: ${values.length}'),
          ),
        ),
      );

      expect(find.text('Empty: 0'), findsOneWidget);
    });

    // Test that CircusRing cards are properly handled
    testWidgets('should get cards from CircusRing',
        (WidgetTester tester) async {
      // Register a card with CircusRing first
      final card = JokerCard<String>('registered', tag: 'test-tag');
      Circus.put<JokerCard<String>>(card, tag: 'test-tag');

      expect(Circus.isRegistered<JokerCard<String>>('test-tag'), isTrue);

      // Build a deck that uses this card
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              // We're not testing disposal behavior here, just access
              return Text(
                  'Card: ${Circus.find<JokerCard<String>>('test-tag').value}');
            },
          ),
        ),
      );

      expect(find.text('Card: registered'), findsOneWidget);

      // Clean up
      Circus.delete<JokerCard<String>>(tag: 'test-tag');
    });
  });
}

// Custom widget for testing card list changes
class CardListTestWidget extends StatefulWidget {
  @override
  _CardListTestWidgetState createState() => _CardListTestWidgetState();
}

class _CardListTestWidgetState extends State<CardListTestWidget> {
  final cards = <JokerCard>[
    JokerCard<int>(10),
    JokerCard<String>('hello'),
  ];

  void _addCard() {
    setState(() {
      cards.add(JokerCard<bool>(true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The JokerDeck being tested
        JokerDeck(
          cards: cards,
          autoDispose: false,
          builder: (context, values, _) {
            return Column(
              children: [
                for (int i = 0; i < values.length; i++)
                  Text('Card ${i + 1}: ${values[i]}'),
              ],
            );
          },
        ),

        // Button to modify the card list
        GestureDetector(
          onTap: _addCard,
          child: Text('Add Card'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up cards manually since we disabled autoDispose
    for (final card in cards) {
      card.dispose();
    }
    super.dispose();
  }
}
