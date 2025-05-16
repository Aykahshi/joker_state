import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/timing_control/cue_gate/cue_gate.dart';

void main() {
  group('CueGate (debounce)', () {
    test('executes only the last call', () async {
      var counter = 0;
      final gate = CueGate.debounce(delay: const Duration(milliseconds: 200));

      gate.trigger(() => counter++);
      gate.trigger(() => counter++);
      gate.trigger(() => counter++);

      expect(counter, 0);
      await Future.delayed(const Duration(milliseconds: 250));
      expect(counter, 1);
    });

    test('releases timer after execution to prevent memory leaks', () async {
      final gate = CueGate.debounce(delay: const Duration(milliseconds: 150));

      gate.trigger(() {
        /* do something */
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // After execution, _timer should be null (i.e., isScheduled == false)
      expect(gate.isScheduled, isFalse);
    });

    test('cancel prevents execution', () async {
      var triggered = false;
      final gate = CueGate.debounce(delay: const Duration(milliseconds: 150));

      gate.trigger(() => triggered = true);
      gate.cancel();

      await Future.delayed(const Duration(milliseconds: 200));

      expect(triggered, isFalse);
      expect(gate.isScheduled, isFalse);
    });
  });

  group('CueGate (throttle)', () {
    test('only triggers once within interval', () async {
      var calls = 0;
      final gate =
          CueGate.throttle(interval: const Duration(milliseconds: 300));

      gate.trigger(() => calls++);
      gate.trigger(() => calls++); // Should be ignored
      gate.trigger(() => calls++); // Should be ignored

      await Future.delayed(const Duration(milliseconds: 400));

      gate.trigger(() => calls++); // Should be accepted

      expect(calls, 2);
    });
  });
}
