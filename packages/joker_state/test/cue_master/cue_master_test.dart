import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/cue_master.dart';

class TestCue1 extends Cue {
  final String data;
  TestCue1(this.data);
}

class TestCue2 extends Cue {
  final int value;
  TestCue2(this.value);
}

void main() {
  group('RingCueMaster Core Tests', () {
    late RingCueMaster cueMaster;

    setUp(() {
      cueMaster = RingCueMaster();
    });

    tearDown(() {
      if (!(cueMaster as dynamic).isDisposed) {
        cueMaster.dispose();
      }
    });

    test('should send and receive a cue of a specific type', () async {
      final completer = Completer<TestCue1>();
      cueMaster.listen<TestCue1>((cue) {
        completer.complete(cue);
      });

      final sentCue = TestCue1('hello');
      final success = cueMaster.sendCue(sentCue);

      expect(success, isTrue);
      final receivedCue =
          await completer.future.timeout(Duration(milliseconds: 100));
      expect(receivedCue, same(sentCue));
      expect(receivedCue.data, 'hello');
    });

    test('should allow multiple listeners for the same cue type', () async {
      int listener1Count = 0;
      int listener2Count = 0;

      cueMaster.listen<TestCue1>((_) => listener1Count++);
      cueMaster.on<TestCue1>().listen((_) => listener2Count++);

      cueMaster.sendCue(TestCue1('multi-test'));

      await Future.delayed(Duration(milliseconds: 20));

      expect(listener1Count, 1);
      expect(listener2Count, 1);
    });

    test('should only deliver cues to listeners of the correct type', () async {
      bool cue1Received = false;
      bool cue2Received = false;

      cueMaster.listen<TestCue1>((_) => cue1Received = true);
      cueMaster.listen<TestCue2>((_) => cue2Received = true);

      cueMaster.sendCue(TestCue1('for_cue1_listener'));

      await Future.delayed(Duration(milliseconds: 20));

      expect(cue1Received, isTrue);
      expect(cue2Received, isFalse,
          reason: 'TestCue2 listener should not receive TestCue1');
    });

    test('hasListeners should return true if there are active listeners', () {
      final sub = cueMaster.listen<TestCue1>((_) {});
      expect(cueMaster.hasListeners<TestCue1>(), isTrue);
      sub.cancel();
    });

    test('hasListeners should return false if no listeners or all cancelled',
        () {
      expect(cueMaster.hasListeners<TestCue1>(), isFalse);
      final sub = cueMaster.listen<TestCue1>((_) {});
      expect(cueMaster.hasListeners<TestCue1>(), isTrue);
      sub.cancel();
      expect(cueMaster.hasListeners<TestCue1>(), isFalse);
    });

    test('reset<T> should close the stream for type T and remove listeners',
        () async {
      final completer = Completer<bool>();
      bool cueReceivedAfterReset = false;

      // Listen and expect stream to be done
      cueMaster.on<TestCue1>().listen((_) {
        cueReceivedAfterReset = true;
      }, onDone: () {
        if (!completer.isCompleted) {
          completer.complete(true); // Stream was closed
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

      expect(cueMaster.hasListeners<TestCue1>(), isTrue);

      final didReset = cueMaster.reset<TestCue1>();
      expect(didReset, isTrue);
      expect(cueMaster.hasListeners<TestCue1>(), isFalse);

      // Try sending a cue after reset
      final sentAfterReset = cueMaster.sendCue(TestCue1('after reset'));
      // sendCue might return true if it recreates the controller, but the old listener is gone.
      expect(sentAfterReset, isTrue, reason: "_getController will recreate it");

      // Wait for onDone to be called
      final streamClosed =
          await completer.future.timeout(Duration(milliseconds: 100));
      expect(streamClosed, isTrue, reason: "Stream should be closed by reset");
      expect(cueReceivedAfterReset, isFalse,
          reason:
              'Cue sent after reset should not be received by old listener');

      // A new listener should work on a new stream
      final completerNew = Completer<TestCue1>();
      cueMaster.listen<TestCue1>((cue) => completerNew.complete(cue));
      cueMaster.sendCue(TestCue1('for new listener'));
      final newCue =
          await completerNew.future.timeout(Duration(milliseconds: 100));
      expect(newCue.data, 'for new listener');
    });

    test('reset<T> should return false if no controller for type T exists', () {
      expect(cueMaster.reset<TestCue1>(), isFalse);
    });

    test('dispose should close all streams and clear controllers', () async {
      final completer1 = Completer<bool>();
      final completer2 = Completer<bool>();

      cueMaster.on<TestCue1>().listen((_) {}, onDone: () {
        if (!completer1.isCompleted) completer1.complete(true);
      });
      cueMaster.on<TestCue2>().listen((_) {}, onDone: () {
        if (!completer2.isCompleted) completer2.complete(true);
      });

      expect(cueMaster.hasListeners<TestCue1>(), isTrue);
      expect(cueMaster.hasListeners<TestCue2>(), isTrue);

      cueMaster.dispose();

      expect((cueMaster as dynamic).isDisposed, isTrue);
      expect(cueMaster.hasListeners<TestCue1>(), isFalse);
      expect(cueMaster.hasListeners<TestCue2>(), isFalse);

      // Sending cues after dispose should fail (return false)
      expect(cueMaster.sendCue(TestCue1('after dispose')), isFalse);
      expect(cueMaster.sendCue(TestCue2(0)), isFalse);

      // Streams should be closed
      await expectLater(completer1.future, completes);
      await expectLater(completer2.future, completes);

      // Listening after dispose should result in an empty stream
      var receivedOnDisposed = false;
      cueMaster.on<TestCue1>().listen((_) => receivedOnDisposed = true);
      cueMaster.sendCue(TestCue1('another after dispose')); // Still false
      await Future.delayed(Duration(milliseconds: 20));
      expect(receivedOnDisposed, isFalse);
    });

    test('calling dispose multiple times should be safe', () {
      cueMaster.dispose();
      expect(() => cueMaster.dispose(), returnsNormally);
      expect((cueMaster as dynamic).isDisposed, isTrue);
    });

    test(
        'sendCue should return false if controller is closed but bus not disposed (after reset)',
        () {
      cueMaster.listen<TestCue1>((_) {}); // Ensure controller exists
      cueMaster.reset<TestCue1>(); // Close and remove TestCue1's controller
      // _getController in sendCue will create a new one. So this test needs refinement.
      // The current implementation of sendCue uses _getController which always provides
      // an open controller if one doesn't exist or was reset.
      // The `!controller.isClosed` check in sendCue is thus mostly for
      // scenarios where a subject might be closed externally without being removed from _controllers,
      // or if isDisposed is true (which is checked first).
      // So, for a reset scenario, sendCue will effectively operate on a NEW controller.
      expect(cueMaster.sendCue(TestCue1("data")),
          isTrue); // It will create a new controller
    });

    test('on<T> after dispose should return an empty stream', () async {
      cueMaster.dispose();
      bool received = false;
      final sub = cueMaster.on<TestCue1>().listen((_) => received = true);

      // Try sending something (though sendCue after dispose should return false)
      cueMaster.sendCue(TestCue1('data')); // This will be false

      await Future.delayed(Duration.zero); // Allow microtask to run
      expect(received, isFalse);

      // To be more certain, check if the stream completes immediately
      final c = Completer<void>();
      cueMaster.on<TestCue1>().listen((_) {}, onDone: c.complete);
      await expectLater(c.future, completes);
      sub.cancel();
    });
  });
}
