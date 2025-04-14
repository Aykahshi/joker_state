import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerPortal<T>', () {
    testWidgets('provides Joker via JokerPortal.of()', (tester) async {
      final joker = Joker<int>(0, tag: 'test');

      late Joker<int> received;

      await tester.pumpWidget(
        JokerPortal<int>(
          joker: joker,
          child: Builder(
            builder: (context) {
              received = JokerPortal.of<int>(context);
              return const Placeholder();
            },
          ),
        ),
      );

      expect(received, isNotNull);
      expect(received, equals(joker));
      expect(received.state, 0);
    });

    testWidgets('provides Joker via context.joker<T>() extension',
        (tester) async {
      final joker = Joker<String>('hello', tag: 'greeting');

      late Joker<String> selected;

      await tester.pumpWidget(
        JokerPortal<String>(
          joker: joker,
          child: Builder(
            builder: (context) {
              selected = context.joker<String>();
              return const Placeholder();
            },
          ),
        ),
      );

      expect(selected, isNotNull);
      expect(selected, equals(joker));
      expect(selected.state, 'hello');
    });

    testWidgets('rebuilds descendant when Joker state changes', (tester) async {
      final joker = Joker<int>(0, tag: 'counter');

      int buildCount = 0;

      await tester.pumpWidget(
        JokerPortal<int>(
          joker: joker,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final j = context.joker<int>();
                buildCount++;
                return Text('${j.state}', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      joker.trick(1);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('maybeOf returns null if no JokerPortal exists',
        (tester) async {
      Joker<int>? maybe;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            maybe = JokerPortal.maybeOf<int>(context); // No portal
            return const Placeholder();
          },
        ),
      );

      expect(maybe, isNull);
    });

    testWidgets('of throws when no JokerPortal exists (assert)',
        (tester) async {
      // assert throws only in debug mode
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(
              () => JokerPortal.of<int>(context),
              throwsA(predicate(
                (e) =>
                    e is AssertionError &&
                    e.message == 'No JokerPortal<int> found in context.',
              )),
            );
            return const Placeholder();
          },
        ),
      );
    });
  });
}
