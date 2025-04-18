import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

// Define a unique class for testing type-based lookup without tag
class UniqueType {
  final String value;
  UniqueType(this.value);
}

void main() {
  testWidgets('JokerPortal.of finds Joker by unique type without tag',
      (tester) async {
    // Arrange
    final joker = Joker<UniqueType>(UniqueType('unique'));
    final testKey = GlobalKey();

    // Act
    await tester.pumpWidget(
      JokerPortal<UniqueType>(
        joker: joker,
        child: Builder(
          key: testKey,
          builder: (context) {
            final foundJoker = JokerPortal.of<UniqueType>(
                context); // No tag needed for unique type
            return Text(foundJoker.state.value,
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('unique'), findsOneWidget);
    joker.dispose();
  });

  testWidgets('JokerPortal.of finds Joker by common type WITH tag',
      (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');
    final testKey = GlobalKey();

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter', // Tag provided
        child: Builder(
          key: testKey,
          builder: (context) {
            final foundJoker = JokerPortal.of<int>(context,
                tag: 'counter'); // Tag used for lookup
            return Text('${foundJoker.state}',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('42'), findsOneWidget);
    joker.dispose();
  });

  testWidgets(
      'JokerPortal.of throws assertion error for common type WITHOUT tag when ambiguous',
      (tester) async {
    // Arrange: Two portals with the same common type <int>
    final joker1 = Joker<int>(1, tag: 'c1');
    final joker2 = Joker<int>(2, tag: 'c2');

    // Act & Assert
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker1,
        tag: 'c1',
        child: JokerPortal<int>(
          joker: joker2,
          tag: 'c2',
          child: Builder(
            builder: (context) {
              // Attempting to find <int> without a tag should fail because it's ambiguous
              expect(
                () => JokerPortal.of<int>(context), // No tag provided!
                throwsAssertionError,
              );
              // Verify we can find them with tags
              expect(JokerPortal.of<int>(context, tag: 'c1').state, 1);
              expect(JokerPortal.of<int>(context, tag: 'c2').state, 2);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    joker1.dispose();
    joker2.dispose();
  });

  testWidgets(
      'JokerPortal.maybeOf returns null for common type WITHOUT tag when ambiguous',
      (tester) async {
    // Arrange
    final joker1 = Joker<int>(1, tag: 'c1');
    final joker2 = Joker<int>(2, tag: 'c2');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker1,
        tag: 'c1',
        child: JokerPortal<int>(
          joker: joker2,
          tag: 'c2',
          child: Builder(
            builder: (context) {
              final foundJoker = JokerPortal.maybeOf<int>(context); // No tag
              expect(foundJoker, isNull); // Should return null due to ambiguity
              // Verify finding with tags still works
              expect(JokerPortal.maybeOf<int>(context, tag: 'c1')?.state, 1);
              expect(JokerPortal.maybeOf<int>(context, tag: 'c2')?.state, 2);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    joker1.dispose();
    joker2.dispose();
  });

  testWidgets(
      'JokerPortal.maybeOf returns null when no matching Joker (type or tag) exists',
      (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Builder(
          builder: (context) {
            // Try finding wrong type
            final wrongType = JokerPortal.maybeOf<String>(context);
            expect(wrongType, isNull);
            // Try finding wrong tag
            final wrongTag =
                JokerPortal.maybeOf<int>(context, tag: 'nonexistent');
            expect(wrongTag, isNull);
            // Correct one
            final correct = JokerPortal.maybeOf<int>(context, tag: 'counter');
            expect(correct?.state, 42);
            return const SizedBox();
          },
        ),
      ),
    );
    joker.dispose();
  });

  testWidgets(
      'JokerPortal.of throws assertion error when Joker not found (wrong type)',
      (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');

    // Act & Assert
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Builder(
          builder: (context) {
            expect(
              () => JokerPortal.of<String>(context), // Wrong type
              throwsAssertionError,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    joker.dispose();
  });

  testWidgets(
      'JokerPortal.of throws assertion error when Joker not found (wrong tag)',
      (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');

    // Act & Assert
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Builder(
          builder: (context) {
            expect(
              () =>
                  JokerPortal.of<int>(context, tag: 'nonexistent'), // Wrong tag
              throwsAssertionError,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    joker.dispose();
  });

  testWidgets('context.joker extension method finds Joker correctly with tag',
      (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Builder(
          builder: (context) {
            final foundJoker =
                context.joker<int>(tag: 'counter'); // Use extension with tag
            return Text('${foundJoker.state}',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('42'), findsOneWidget);
    joker.dispose();
  });

  testWidgets(
      'context.joker throws assertion error for common type WITHOUT tag when ambiguous',
      (tester) async {
    // Arrange: Two portals with the same common type <int>
    final joker1 = Joker<int>(1, tag: 'c1');
    final joker2 = Joker<int>(2, tag: 'c2');

    // Act & Assert
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker1,
        tag: 'c1',
        child: JokerPortal<int>(
          joker: joker2,
          tag: 'c2',
          child: Builder(
            builder: (context) {
              expect(
                () => context.joker<int>(), // Extension without tag!
                throwsAssertionError,
              );
              // Verify finding with tags still works
              expect(context.joker<int>(tag: 'c1').state, 1);
              expect(context.joker<int>(tag: 'c2').state, 2);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    joker1.dispose();
    joker2.dispose();
  });

  testWidgets('nested JokerPortals work correctly with tags', (tester) async {
    // Arrange
    final jokerA = Joker<int>(42, tag: 'counterA');
    final jokerB = Joker<String>('hello', tag: 'textB');
    final jokerC = Joker<int>(100, tag: 'counterC'); // Another int portal

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: jokerA, // Outer int portal
        tag: 'counterA',
        child: JokerPortal<String>(
          joker: jokerB,
          tag: 'textB',
          child: JokerPortal<int>(
            // Inner int portal
            joker: jokerC,
            tag: 'counterC',
            child: Builder(
              builder: (context) {
                // Find specific portals using tags
                final counterJokerA = context.joker<int>(tag: 'counterA');
                final textJokerB = context.joker<String>(tag: 'textB');
                final counterJokerC = context.joker<int>(tag: 'counterC');
                return Text(
                  '${counterJokerA.state}-${textJokerB.state}-${counterJokerC.state}',
                  textDirection: TextDirection.ltr,
                );
              },
            ),
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('42-hello-100'), findsOneWidget);
    jokerA.dispose();
    jokerB.dispose();
    jokerC.dispose();
  });
}
