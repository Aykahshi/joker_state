import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

// Define a unique class for testing type-based lookup without tag
class UniqueType {
  final String value;
  UniqueType(this.value);
}

void main() {
  testWidgets(
      'JokerCast rebuilds when Joker state changes (common type with tag)',
      (tester) async {
    // Arrange
    final joker = Joker<int>(0, tag: 'counter');

    // Act - Initial rendering
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: JokerCast<int>(
          tag: 'counter', // Tag provided to JokerCast
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
    joker.dispose();
  });

  testWidgets('JokerCast works with unique type without tag', (tester) async {
    // Arrange
    final joker = Joker<UniqueType>(UniqueType('init'));

    // Act
    await tester.pumpWidget(
      JokerPortal<UniqueType>(
        joker: joker, // No tag needed for JokerPortal with unique type
        child: JokerCast<UniqueType>(
          // No tag needed for JokerCast
          builder: (context, value) =>
              Text('Val: ${value.value}', textDirection: TextDirection.ltr),
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('Val: init'), findsOneWidget);

    // Act - Change state
    joker.trick(UniqueType('updated'));
    await tester.pump();

    // Assert - Updated state
    expect(find.text('Val: updated'), findsOneWidget);
    joker.dispose();
  });

  testWidgets(
    'JokerCast throws assertion error when no matching Joker (wrong type)',
    (tester) async {
      final joker = Joker<int>(1);
      await tester.pumpWidget(JokerPortal<int>(
        joker: joker,
        child: JokerCast<String>(
          // Expecting String, but Portal provides int
          builder: (context, value) => const SizedBox(),
        ),
      ));
      expect(tester.takeException(), isAssertionError);
      joker.dispose();
    },
  );

  testWidgets(
    'JokerCast throws assertion error when no matching Joker (wrong tag)',
    (tester) async {
      final joker = Joker<int>(1, tag: 'correct');
      await tester.pumpWidget(JokerPortal<int>(
        joker: joker,
        tag: 'correct',
        child: JokerCast<int>(
          tag: 'wrong', // Using wrong tag
          builder: (context, value) => const SizedBox(),
        ),
      ));
      expect(tester.takeException(), isAssertionError);
      joker.dispose();
    },
  );

  testWidgets(
    'JokerCast throws assertion error for common type WITHOUT tag when ambiguous',
    (tester) async {
      final joker1 = Joker<int>(1, tag: 'c1');
      final joker2 = Joker<int>(2, tag: 'c2');
      await tester.pumpWidget(JokerPortal<int>(
        joker: joker1,
        tag: 'c1',
        child: JokerPortal<int>(
          joker: joker2,
          tag: 'c2',
          child: JokerCast<int>(
            // No tag provided!
            builder: (context, value) => const SizedBox(),
          ),
        ),
      ));
      expect(tester.takeException(), isAssertionError);
      joker1.dispose();
      joker2.dispose();
    },
  );

  testWidgets('Multiple JokerCast widgets listen correctly with tags',
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
              tag: 'counter', // Tag specified
              builder: (context, value) =>
                  Text('First: $value', textDirection: TextDirection.ltr),
            ),
            JokerCast<int>(
              tag: 'counter', // Tag specified
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
    joker.dispose();
  });

  testWidgets(
      'JokerCast with multiple portals and different types works with tags',
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
                tag: 'counter', // Tag specified
                builder: (context, value) =>
                    Text('Count: $value', textDirection: TextDirection.ltr),
              ),
              JokerCast<String>(
                tag: 'name', // Tag specified
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
    counterJoker.dispose();
    nameJoker.dispose();
  });
}
