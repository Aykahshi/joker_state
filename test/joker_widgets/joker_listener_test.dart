import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  test('joker.listen should receive previous and current state', () {
    final joker = Joker<int>(0);
    final logs = <String>[];

    final stop = joker.listen((prev, next) {
      logs.add('$prev → $next');
    });

    joker.trick(1);
    joker.trick(5);
    stop();
    joker.trick(10); // This won't trigger

    expect(logs, ['0 → 1', '1 → 5']);
  });

  test('multiple listen() calls should work independently', () {
    final joker = Joker<String>('start');

    String? copy1;
    String? copy2;

    final stop1 = joker.listen((_, curr) {
      copy1 = curr;
    });

    // ignore: unused_local_variable
    final stop2 = joker.listen((_, curr) {
      copy2 = 'Hello $curr';
    });

    joker.trick('move');
    expect(copy1, equals('move'));
    expect(copy2, equals('Hello move'));

    stop1();
    joker.trick('again');
    expect(copy1, equals('move')); // didn’t update
    expect(copy2, equals('Hello again'));
  });

  test('listenWhen triggers only when condition met', () {
    final joker = Joker<int>(0);
    final logs = <String>[];

    final cancel = joker.listenWhen(
      listener: (prev, curr) => logs.add('Grow: $prev → $curr'),
      shouldListen: (prev, curr) => (prev ?? 0) < curr,
    );

    joker.trick(1); // ✅ triggered
    joker.trick(2); // ✅ triggered
    joker.trick(1); // ❌ skipped
    joker.trick(3); // ✅ triggered

    expect(logs, ['Grow: 0 → 1', 'Grow: 1 → 2', 'Grow: 1 → 3']);
    cancel();
  });
}
