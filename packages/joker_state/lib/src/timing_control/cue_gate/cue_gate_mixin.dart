import 'package:flutter/widgets.dart';

import 'cue_gate.dart';

/// Provides debounce / throttle capabilities inside a [StatefulWidget].
///
/// Use [debounceGate] or [throttleGate] for triggering, and they will
/// be automatically disposed on widget teardown.
mixin CueGateMixin<T extends StatefulWidget> on State<T> {
  CueGate? _debounce;
  CueGate? _throttle;

  /// Call the action only after [delay] ms of silence (debounce).
  void debounceTrigger(VoidCallback action, Duration delay) {
    _debounce ??= CueGate.debounce(delay: delay);
    _debounce!.trigger(action);
  }

  /// Run the action at most every [interval] duration (throttle).
  void throttleTrigger(VoidCallback action, Duration interval) {
    _throttle ??= CueGate.throttle(interval: interval);
    _throttle!.trigger(action);
  }

  @override
  void dispose() {
    _debounce?.dispose();
    _throttle?.dispose();
    super.dispose();
  }
}
