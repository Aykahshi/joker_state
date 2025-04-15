import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/event_bus/ring_cue_master/ring_cue_master.dart';

void main() {
  group('RingCueMaster', () {
    late RingCueMaster cueMaster;

    setUp(() {
      cueMaster = RingCueMaster();
    });

    tearDown(() {
      cueMaster.dispose();
    });

    test('can send and receive a cue', () async {
      final completer = Completer<_TestCue>();

      cueMaster.on<_TestCue>().listen(completer.complete);
      cueMaster.sendCue(_TestCue('Hello'));

      final received = await completer.future;
      expect(received.value, 'Hello');
    });

    test('multiple listeners receive cue', () async {
      final resultA = Completer<String>();
      final resultB = Completer<String>();

      cueMaster.listen<_TestCue>((cue) => resultA.complete('A:${cue.value}'));
      cueMaster.listen<_TestCue>((cue) => resultB.complete('B:${cue.value}'));

      cueMaster.sendCue(_TestCue('Multi'));

      expect(await resultA.future, 'A:Multi');
      expect(await resultB.future, 'B:Multi');
    });

    test('returns false if sendCue called with no listeners', () async {
      final success = cueMaster.sendCue(_TestCue('Nobody?'));
      expect(success, isFalse);
    });

    test('returns true if sendCue has at least one listener', () async {
      cueMaster.on<_TestCue>().listen((_) {});
      final success = cueMaster.sendCue(_TestCue('Hello'));
      expect(success, isTrue);
    });

    test('hasListeners works correctly', () async {
      expect(cueMaster.hasListeners<_TestCue>(), isFalse);

      final subscription = cueMaster.listen<_TestCue>((_) {});
      expect(cueMaster.hasListeners<_TestCue>(), isTrue);

      await subscription.cancel();
      await Future.delayed(Duration.zero); // wait for listener to clean up

      expect(cueMaster.hasListeners<_TestCue>(), isFalse);
    });

    test('reset<T> closes stream and drops listeners', () async {
      final received = <String>[];

      final sub = cueMaster.listen<_TestCue>((e) => received.add(e.value));
      cueMaster.sendCue(_TestCue('A'));

      final didReset = cueMaster.reset<_TestCue>();
      expect(didReset, isTrue);

      // Wait for stream to cleanup async unsubscribe
      await Future.delayed(Duration.zero);

      expect(cueMaster.hasListeners<_TestCue>(), isFalse);

      final result = cueMaster.sendCue(_TestCue('B'));
      expect(result, isFalse);

      expect(received, ['A']);
      await sub.cancel();
    });

    test('reset returns false for unregistered type', () {
      final result = cueMaster.reset<int>(); // not initialized
      expect(result, isFalse);
    });

    test('on<T> returns stream that supports multiple subscriptions', () async {
      final resultA = Completer<String>();
      final resultB = Completer<String>();

      cueMaster
          .on<_TestCue>()
          .listen((cue) => resultA.complete('A:${cue.value}'));
      cueMaster
          .on<_TestCue>()
          .listen((cue) => resultB.complete('B:${cue.value}'));

      cueMaster.sendCue(_TestCue('StreamTest'));

      expect(await resultA.future, 'A:StreamTest');
      expect(await resultB.future, 'B:StreamTest');
    });

    test('dispose closes all controllers and clears map', () {
      cueMaster.on<_TestCue>().listen((_) {});
      cueMaster.dispose();

      final result = cueMaster.sendCue(_TestCue('After dispose'));
      expect(result, isFalse);
    });
  });
}

class _TestCue {
  final String value;

  _TestCue(this.value);
}
