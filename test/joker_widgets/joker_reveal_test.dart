import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/special_widgets/joker_reveal/joker_reveal.dart';

void main() {
  group('JokerReveal (immediate)', () {
    testWidgets('renders whenTrue when condition is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JokerReveal(
            condition: true,
            whenTrue: Text('YES'),
            whenFalse: Text('NO'),
          ),
        ),
      );

      expect(find.text('YES'), findsOneWidget);
      expect(find.text('NO'), findsNothing);
    });

    testWidgets('renders whenFalse when condition is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JokerReveal(
            condition: false,
            whenTrue: Text('YES'),
            whenFalse: Text('NO'),
          ),
        ),
      );

      expect(find.text('NO'), findsOneWidget);
      expect(find.text('YES'), findsNothing);
    });
  });

  group('JokerReveal.lazy (builder mode)', () {
    testWidgets('calls only whenTrueBuilder', (tester) async {
      var trueBuilt = false;
      var falseBuilt = false;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerReveal.lazy(
            condition: true,
            whenTrueBuilder: (_) {
              trueBuilt = true;
              return const Text('TRUE ✅');
            },
            whenFalseBuilder: (_) {
              falseBuilt = true;
              return const Text('FALSE ❌');
            },
          ),
        ),
      );

      expect(trueBuilt, isTrue);
      expect(falseBuilt, isFalse);
      expect(find.text('TRUE ✅'), findsOneWidget);
    });

    testWidgets('calls only whenFalseBuilder for false condition',
        (tester) async {
      var trueBuilt = false;
      var falseBuilt = false;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerReveal.lazy(
            condition: false,
            whenTrueBuilder: (_) {
              trueBuilt = true;
              return const Text('TRUE ✅');
            },
            whenFalseBuilder: (_) {
              falseBuilt = true;
              return const Text('FALSE ❌');
            },
          ),
        ),
      );

      expect(trueBuilt, isFalse);
      expect(falseBuilt, isTrue);
      expect(find.text('FALSE ❌'), findsOneWidget);
    });
  });
  group('Boolean.reveal extension (immediate)', () {
    testWidgets('reveal() returns whenTrue for true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: true.reveal(
            whenTrue: const Text('YES 🎯'),
            whenFalse: const Text('NO ❌'),
          ),
        ),
      );
      expect(find.text('YES 🎯'), findsOneWidget);
      expect(find.text('NO ❌'), findsNothing);
    });

    testWidgets('reveal() returns whenFalse for false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: false.reveal(
            whenTrue: const Text('YES 🎯'),
            whenFalse: const Text('NO ❌'),
          ),
        ),
      );
      expect(find.text('NO ❌'), findsOneWidget);
      expect(find.text('YES 🎯'), findsNothing);
    });
  });

  group('Boolean.lazyReveal extension', () {
    testWidgets('lazyReveal() builds only whenTrueBuilder if true',
        (tester) async {
      bool builtTrue = false;
      bool builtFalse = false;

      await tester.pumpWidget(
        MaterialApp(
          home: true.lazyReveal(
            whenTrueBuilder: (_) {
              builtTrue = true;
              return const Text('Success ✅');
            },
            whenFalseBuilder: (_) {
              builtFalse = true;
              return const Text('Fail ❌');
            },
          ),
        ),
      );

      expect(builtTrue, isTrue);
      expect(builtFalse, isFalse);
      expect(find.text('Success ✅'), findsOneWidget);
    });

    testWidgets('lazyReveal() builds only whenFalseBuilder if false',
        (tester) async {
      bool builtTrue = false;
      bool builtFalse = false;

      await tester.pumpWidget(
        MaterialApp(
          home: false.lazyReveal(
            whenTrueBuilder: (_) {
              builtTrue = true;
              return const Text('Success ✅');
            },
            whenFalseBuilder: (_) {
              builtFalse = true;
              return const Text('Fail ❌');
            },
          ),
        ),
      );

      expect(builtTrue, isFalse);
      expect(builtFalse, isTrue);
      expect(find.text('Fail ❌'), findsOneWidget);
    });
  });
}
