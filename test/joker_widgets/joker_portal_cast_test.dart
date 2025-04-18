import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker_cast/joker_cast.dart';
import 'package:joker_state/src/state_management/joker_portal/joker_portal.dart';

void main() {
  testWidgets('JokerCast rebuilds only affected widgets when state changes',
      (tester) async {
    // Arrange
    final counterJoker = Joker<int>(0, tag: 'counter');
    final nameJoker = Joker<String>('Flutter', tag: 'name');

    int counterBuildCount = 0;
    int nameBuildCount = 0;

    // Act - Initial build
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
                builder: (context, value) {
                  counterBuildCount++;
                  return Text('Count($counterBuildCount): $value',
                      textDirection: TextDirection.ltr);
                },
              ),
              JokerCast<String>(
                tag: 'name',
                builder: (context, value) {
                  nameBuildCount++;
                  return Text('Name($nameBuildCount): $value',
                      textDirection: TextDirection.ltr);
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Assert - Initial state
    expect(counterBuildCount, 1);
    expect(nameBuildCount, 1);
    expect(find.text('Count(1): 0'), findsOneWidget);
    expect(find.text('Name(1): Flutter'), findsOneWidget);

    // Act - Change only counter state
    counterJoker.trick(99);
    await tester.pump();

    // Assert - Only counter rebuilt
    expect(counterBuildCount, 2);
    expect(nameBuildCount, 1);
    expect(find.text('Count(2): 99'), findsOneWidget);
    expect(find.text('Name(1): Flutter'), findsOneWidget);

    // Act - Change only name state
    nameJoker.trick('Dart');
    await tester.pump();

    // Assert - Only name rebuilt
    expect(counterBuildCount, 2);
    expect(nameBuildCount, 2);
    expect(find.text('Count(2): 99'), findsOneWidget);
    expect(find.text('Name(2): Dart'), findsOneWidget);

    // Clean up
    counterJoker.dispose();
    nameJoker.dispose();
  });

  testWidgets('JokerCast works with complex widget hierarchies',
      (tester) async {
    // Arrange
    final counterJoker = Joker<int>(0, tag: 'counter');

    // Act - Setup a complex widget tree
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JokerPortal<int>(
          joker: counterJoker,
          tag: 'counter',
          child: Column(
            children: [
              const Text('Static Text', textDirection: TextDirection.ltr),
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 50,
                      child: JokerCast<int>(
                        tag: 'counter',
                        builder: (context, value) => Text(
                          'Count: $value',
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Assert - Initial state
    expect(find.text('Static Text'), findsOneWidget);
    expect(find.text('Count: 0'), findsOneWidget);

    // Act - Change state
    counterJoker.trick(42);
    await tester.pump();

    // Assert - Only dynamic part updated
    expect(find.text('Static Text'), findsOneWidget);
    expect(find.text('Count: 42'), findsOneWidget);

    // Clean up
    counterJoker.dispose();
  });
}
