import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  testWidgets('JokerCast rebuilds when Joker state changes', (tester) async {
    // Arrange
    final joker = Joker<int>(0, tag: 'counter');

    // Act - Initial rendering
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: JokerCast<int>(
          tag: 'counter',
          builder: (context, value) =>
              Text('Count: $value', textDirection: TextDirection.ltr),
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('Count: 0'), findsOneWidget);

    // Act - Change state and trigger rebuild
    joker.trick(42);
    await tester.pump();

    // Assert - Updated state
    expect(find.text('Count: 42'), findsOneWidget);
  });

  testWidgets('JokerCast works without explicit tag if type is unique',
      (tester) async {
    // Arrange
    final joker = Joker<int>(0);

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        child: JokerCast<int>(
          builder: (context, value) =>
              Text('Count: $value', textDirection: TextDirection.ltr),
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('Count: 0'), findsOneWidget);

    // Act - Change state
    joker.trick(99);
    await tester.pump();

    // Assert - Updated state
    expect(find.text('Count: 99'), findsOneWidget);
  });

  testWidgets(
    'JokerCast throws assertion error when no matching Joker is found',
    (tester) async {
      await tester.pumpWidget(
        JokerCast<int>(
          tag: 'nonexistent',
          builder: (context, value) => SizedBox(),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    },
  );

  testWidgets('Multiple JokerCast widgets can listen to the same Joker',
      (tester) async {
    // Arrange
    final joker = Joker<int>(0, tag: 'counter');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Column(
          children: [
            JokerCast<int>(
              tag: 'counter',
              builder: (context, value) =>
                  Text('First: $value', textDirection: TextDirection.ltr),
            ),
            JokerCast<int>(
              tag: 'counter',
              builder: (context, value) =>
                  Text('Second: $value', textDirection: TextDirection.ltr),
            ),
          ],
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('First: 0'), findsOneWidget);
    expect(find.text('Second: 0'), findsOneWidget);

    // Act - Change state
    joker.trick(42);
    await tester.pump();

    // Assert - Updated state
    expect(find.text('First: 42'), findsOneWidget);
    expect(find.text('Second: 42'), findsOneWidget);
  });

  testWidgets('JokerCast with multiple portals and different types',
      (tester) async {
    // Arrange
    final counterJoker = Joker<int>(0, tag: 'counter');
    final nameJoker = Joker<String>('Flutter', tag: 'name');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: counterJoker,
        tag: 'counter',
        child: JokerPortal<String>(
          joker: nameJoker,
          tag: 'name',
          child: Column(
            children: [
              JokerCast<int>(
                tag: 'counter',
                builder: (context, value) =>
                    Text('Count: $value', textDirection: TextDirection.ltr),
              ),
              JokerCast<String>(
                tag: 'name',
                builder: (context, value) =>
                    Text('Name: $value', textDirection: TextDirection.ltr),
              ),
            ],
          ),
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('Count: 0'), findsOneWidget);
    expect(find.text('Name: Flutter'), findsOneWidget);

    // Act - Change states
    counterJoker.trick(99);
    nameJoker.trick('Dart');
    await tester.pump();

    // Assert - Updated state
    expect(find.text('Count: 99'), findsOneWidget);
    expect(find.text('Name: Dart'), findsOneWidget);
  });
}
