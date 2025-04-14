import 'package:flutter/foundation.dart';

import '../joker_exception.dart';

/// Joker - a reactive state container based on [ChangeNotifier].
///
/// A lightweight state management solution that wraps any Dart object as a reactive
/// state unit. Joker supports two notification modes:
///
/// - autoNotify = true (default): automatically notifies listeners on change
/// - autoNotify = false: changes occur silently and require manual [yell()]
///
/// 🎯 Ideal for reactive UI patterns like Flutter widgets.
///
/// Use with companion widgets like [JokerStage], [JokerFrame], and [JokerTroupe]
/// for efficient UI updates.
///
/// 🎮 Basic example (auto-notify mode):
///
/// ```dart
/// final counter = Joker<int>(0);
///
/// counter.trick(1);             // state = 1, auto notifies
/// counter.trickWith((s) => s + 1); // state = 2
///
/// counter.batch()
///   .apply((s) => s * 2)
///   .commit();                  // state = 4, notifies once
/// ```
///
/// 🔇 Manual mode example:
///
/// ```dart
/// final manualCounter = Joker<int>(0, autoNotify: false);
/// manualCounter.whisper(42);   // silently set state
/// manualCounter.yell();        // manually notify
/// ```
///
/// 🎪 With CircusRing dependency injection:
///
/// ```dart
/// final counter = Circus.summon<int>(0, tag: 'counter');
/// final retrieved = Circus.spotlight<int>(tag: 'counter');
/// Circus.vanish<int>(tag: 'counter');
/// ```
class Joker<T> extends ChangeNotifier {
  /// Creates a Joker with the given [initialState].
  ///
  /// If [autoNotify] is true, all mutations will auto-call [notifyListeners()].
  ///
  /// Optional [tag] may be used for identification in CircusRing or debugging.
  Joker(
    T initialState, {
    this.autoNotify = true,
    this.tag,
  })  : _state = initialState,
        _previousState = initialState;

  /// Optional global tag for Joker registration or debugging.
  final String? tag;

  /// Controls whether [trick] and friends automatically call [notifyListeners].
  final bool autoNotify;

  /// The current state.
  T _state;

  /// The previous state before the most recent update.
  ///
  /// Useful for comparison, undo, or transition analysis.
  T? _previousState;

  /// Returns the current state.
  T get state => _state;

  /// Returns the previous state.
  T? get previousState => _previousState;

  // ----------------- Auto-notify APIs -----------------

  /// Updates state and automatically calls [notifyListeners].
  ///
  /// Only usable in autoNotify mode.
  void trick(T newState) {
    if (!autoNotify) {
      throw JokerException(
        'trick() called on manual Joker. Use whisper() and yell() instead.',
      );
    }
    _previousState = _state;
    _state = newState;
    notifyListeners();
  }

  /// Updates state using a transform function and notifies.
  void trickWith(T Function(T currentState) performer) {
    if (!autoNotify) {
      throw JokerException(
        'trickWith(): Use whisperWith() in manual mode.',
      );
    }
    _previousState = _state;
    _state = performer(_state);
    notifyListeners();
  }

  /// Async version of [trickWith].
  ///
  /// Waits for value transformation then notifies listeners.
  Future<void> trickAsync(Future<T> Function(T current) performer) async {
    if (!autoNotify) {
      throw JokerException(
        'trickAsync(): Use whisperWith() and yell() in manual mode.',
      );
    }
    _previousState = _state;
    _state = await performer(_state);
    notifyListeners();
  }

  // ------------- Manual-notify APIs -------------

  /// Updates state silently (no notify).
  ///
  /// Only usable when [autoNotify] is false.
  T whisper(T newState) {
    if (autoNotify) {
      throw JokerException('whisper() is not allowed in autoNotify mode.');
    }
    _previousState = _state;
    _state = newState;
    return _state;
  }

  /// Functor version of [whisper].
  T whisperWith(T Function(T currentState) updater) {
    if (autoNotify) {
      throw JokerException('whisperWith() is not allowed in autoNotify mode.');
    }
    _previousState = _state;
    _state = updater(_state);
    return _state;
  }

  /// Manually triggers all registered listeners.
  ///
  /// Used in manual mode after one or more silent updates ([whisper]).
  void yell() {
    notifyListeners();
  }

  /// Whether the state has changed since the previous update.
  bool isDifferent() => _state != _previousState;

  /// Begins a batch update session.
  ///
  /// Use [JokerBatch.commit] to notify once after multiple updates.
  JokerBatch<T> batch() => JokerBatch<T>(this);
}

/// A batch update session for a [Joker].
///
/// Use [apply] multiple times to mutate state, and
/// notify listeners once via [commit]. Use [discard] to undo changes.
class JokerBatch<T> {
  final Joker<T> _joker;
  final T _originalState;
  final bool _isAutoNotify;

  JokerBatch(this._joker)
      : _originalState = _joker.state,
        _isAutoNotify = _joker.autoNotify;

  /// Applies a field-level change to the Joker state.
  JokerBatch<T> apply(T Function(T state) updater) {
    if (_isAutoNotify) {
      final newState = updater(_joker.state);
      (_joker as dynamic)._state = newState;
    } else {
      _joker.whisperWith(updater);
    }
    return this;
  }

  /// Commits and triggers force update if any change occurred.
  void commit() {
    if (_joker.state != _originalState) {
      _joker.yell();
    }
  }

  /// Restores original snapshot and discards any changes.
  void discard() {
    if (_isAutoNotify) {
      (_joker as dynamic)._state = _originalState;
    } else {
      _joker.whisper(_originalState);
    }
  }
}
