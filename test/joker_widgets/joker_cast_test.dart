import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerCast – advanced usage', () {
    testWidgets('state transitions are reflected in UI', (tester) async {
      final joker = Joker<int>(5, tag: 'count');

      await tester.pumpWidget(
        JokerPortal<int>(
          joker: joker,
          child: MaterialApp(
            home: Scaffold(
              body: JokerCast<int>(
                builder: (context, value) =>
                    Text('Count: $value', textDirection: TextDirection.ltr),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Count: 5'), findsOneWidget);

      // Update once
      joker.trick(12);
      await tester.pump();
      expect(find.text('Count: 12'), findsOneWidget);

      // Update multiple times
      joker.trickWith((c) => c + 1);
      await tester.pump();
      expect(find.text('Count: 13'), findsOneWidget);

      await joker.trickAsync((_) async => 42);
      await tester.pump();
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('JokerCast rebuilds only when value updates', (tester) async {
      final joker = Joker<String>('init', tag: 'label');
      int rebuilds = 0;

      await tester.pumpWidget(
        JokerPortal<String>(
          joker: joker,
          child: MaterialApp(
            home: Column(
              children: [
                JokerCast<String>(
                  builder: (context, value) {
                    rebuilds++;
                    return Text('Value: $value',
                        textDirection: TextDirection.ltr);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Value: init'), findsOneWidget);
      expect(rebuilds, equals(1));

      // Update value → should rebuild
      joker.trick('changed');
      await tester.pump();
      expect(rebuilds, equals(2));

      // Same value → should still rebuild (Joker doesn't skip, no selector)
      joker.trick('changed');
      await tester.pump();
      expect(rebuilds, equals(3)); // true as per default behavior
    });

    testWidgets('multiple JokerCast under same portal subscribe correctly',
        (tester) async {
      final joker = Joker<int>(7, tag: 'counter');
      int rebuild1 = 0;
      int rebuild2 = 0;

      await tester.pumpWidget(
        JokerPortal<int>(
          joker: joker,
          child: MaterialApp(
            home: Column(
              children: [
                JokerCast<int>(
                  builder: (_, count) {
                    rebuild1++;
                    return Text('A: $count', textDirection: TextDirection.ltr);
                  },
                ),
                JokerCast<int>(
                  builder: (_, count) {
                    rebuild2++;
                    return Text('B: $count', textDirection: TextDirection.ltr);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A: 7'), findsOneWidget);
      expect(find.text('B: 7'), findsOneWidget);
      expect(rebuild1, 1);
      expect(rebuild2, 1);

      joker.trick(8);
      await tester.pump();

      expect(find.text('A: 8'), findsOneWidget);
      expect(find.text('B: 8'), findsOneWidget);
      expect(rebuild1, equals(2));
      expect(rebuild2, equals(2));
    });

    testWidgets(
        'JokerCast works with multiple Joker types via different portals',
        (tester) async {
      final countJoker = Joker<int>(3, tag: 'count');
      final nameJoker = Joker<String>('Alice', tag: 'name');

      await tester.pumpWidget(
        Column(
          children: [
            JokerPortal<int>(
              joker: countJoker,
              child: MaterialApp(
                home: JokerCast<int>(
                  builder: (context, count) =>
                      Text('Count:$count', textDirection: TextDirection.ltr),
                ),
              ),
            ),
            JokerPortal<String>(
              joker: nameJoker,
              child: MaterialApp(
                home: JokerCast<String>(
                  builder: (context, name) =>
                      Text('User:$name', textDirection: TextDirection.ltr),
                ),
              ),
            ),
          ],
        ),
      );

      expect(find.text('Count:3'), findsOneWidget);
      expect(find.text('User:Alice'), findsOneWidget);

      countJoker.trick(9);
      nameJoker.trick('Bob');
      await tester.pump();

      expect(find.text('Count:9'), findsOneWidget);
      expect(find.text('User:Bob'), findsOneWidget);
    });

    testWidgets('maybeOf returns null if no JokerPortal matching',
        (tester) async {
      Joker<int>? maybe;

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            maybe = JokerPortal.maybeOf<int>(context);
            return const Placeholder();
          },
        ),
      ));

      expect(maybe, isNull);
    });

    testWidgets('JokerCast supports multiple setState trick calls efficiently',
        (tester) async {
      final joker = Joker<int>(100, tag: 'count');
      int rebuilds = 0;

      await tester.pumpWidget(
        JokerPortal<int>(
          joker: joker,
          child: MaterialApp(
            home: JokerCast<int>(
              builder: (context, value) {
                rebuilds++;
                return Text('Count: $value', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 100'), findsOneWidget);
      expect(rebuilds, 1);

      // Fire multiple quick updates
      joker.trick(101);
      joker.trick(102);
      joker.trick(103);
      await tester.pump();

      expect(find.text('Count: 103'), findsOneWidget);
      // One for init + 1 updates, because Flutter engine will batch updates
      expect(rebuilds, 2);
    });
  });
}
