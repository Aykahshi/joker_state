import 'dart:async';
import 'dart:ui';

/// Modes for how [CueGate] operates.
enum CueGateMode {
  debounce,
  throttle,
}

/// The cue gatekeeper: delays or limits repetitive callbacks based on mode.
///
/// - debounce: only triggers after [duration] of silence
/// - throttle: only allows one trigger per [duration] window
class CueGate {
  final Duration duration;
  final CueGateMode mode;

  Timer? _timer;
  DateTime? _lastExecutionTime;

  // Private constructor — force use of factories
  CueGate._({
    required this.duration,
    required this.mode,
  });

  /// Creates a debounce gate: triggers only after idle.
  factory CueGate.debounce({required Duration delay}) {
    return CueGate._(duration: delay, mode: CueGateMode.debounce);
  }

  /// Creates a throttle gate: triggers at most once per interval.
  factory CueGate.throttle({required Duration interval}) {
    return CueGate._(duration: interval, mode: CueGateMode.throttle);
  }

  /// Triggers the given [action] based on current [mode].
  void trigger(VoidCallback action) {
    switch (mode) {
      case CueGateMode.debounce:
        _triggerDebounce(action);
        break;
      case CueGateMode.throttle:
        _triggerThrottle(action);
        break;
    }
  }

  void _triggerDebounce(VoidCallback action) {
    assert(
      mode == CueGateMode.debounce,
      'Attempted to use debounce logic in non-debounce mode.',
    );
    _timer?.cancel();
    _timer = Timer(duration, () {
      action();
      _timer = null;
    });
  }

  void _triggerThrottle(VoidCallback action) {
    assert(
      mode == CueGateMode.throttle,
      'Attempted to use throttle logic in non-throttle mode.',
    );
    final now = DateTime.now();
    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
    }
  }

  /// Whether debounce is waiting.
  bool get isScheduled {
    if (mode == CueGateMode.debounce) {
      return _timer?.isActive ?? false;
    }
    return false;
  }

  /// Manually cancel scheduled debounce (noop in throttle).
  void cancel() {
    if (mode == CueGateMode.debounce) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Cleanup all internal state.
  void dispose() {
    cancel();
    _lastExecutionTime = null;
  }
}
