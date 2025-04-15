import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  testWidgets('JokerPortal.of finds Joker by type without tag', (tester) async {
    // Arrange
    final joker = Joker<int>(42);
    final testKey = GlobalKey();

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        child: Builder(
          key: testKey,
          builder: (context) {
            final foundJoker = JokerPortal.of<int>(context);
            return Text('${foundJoker.state}',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('JokerPortal.of finds Joker by type and tag', (tester) async {
    // Arrange
    final joker = Joker<int>(42, tag: 'counter');
    final testKey = GlobalKey();

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: joker,
        tag: 'counter',
        child: Builder(
          key: testKey,
          builder: (context) {
            final foundJoker = JokerPortal.of<int>(context, tag: 'counter');
            return Text('${foundJoker.state}',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('JokerPortal.maybeOf returns null when no matching Joker exists',
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
                JokerPortal.maybeOf<String>(context, tag: 'nonexistent');
            return Text(foundJoker == null ? 'not found' : 'found',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('not found'), findsOneWidget);
  });

  testWidgets('JokerPortal.of throws assertion error when Joker not found',
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
              () => JokerPortal.of<String>(context, tag: 'nonexistent'),
              throwsAssertionError,
            );
            return const SizedBox();
          },
        ),
      ),
    );
  });

  testWidgets('context.joker extension method finds Joker correctly',
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
            final foundJoker = context.joker<int>(tag: 'counter');
            return Text('${foundJoker.state}',
                textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    // Assert
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('nested JokerPortals work correctly', (tester) async {
    // Arrange
    final jokerA = Joker<int>(42, tag: 'counterA');
    final jokerB = Joker<String>('hello', tag: 'textB');

    // Act
    await tester.pumpWidget(
      JokerPortal<int>(
        joker: jokerA,
        tag: 'counterA',
        child: JokerPortal<String>(
          joker: jokerB,
          tag: 'textB',
          child: Builder(
            builder: (context) {
              final counterJoker =
                  JokerPortal.of<int>(context, tag: 'counterA');
              final textJoker = JokerPortal.of<String>(context, tag: 'textB');
              return Text(
                '${counterJoker.state}-${textJoker.state}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('42-hello'), findsOneWidget);
  });
}
