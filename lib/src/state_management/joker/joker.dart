import 'dart:async';

import 'package:flutter/widgets.dart';

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
/// Joker instances manage their own lifecycle based on listeners and the [keepAlive] flag.
/// When the last listener is removed and [keepAlive] is false, the Joker will
/// schedule itself for disposal after a short delay. Adding a listener before
/// disposal cancels the process.
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
class Joker<T> extends ChangeNotifier {
  /// Creates a Joker with the given [initialState].
  ///
  /// If [autoNotify] is true, all mutations will auto-call [notifyListeners()].
  ///
  /// Optional [tag] may be used for identification in CircusRing or debugging.
  ///
  /// If [keepAlive] is true, the Joker will not be automatically disposed
  /// when it has no listeners. Defaults to false.
  Joker(
    T initialState, {
    this.autoNotify = true,
    this.keepAlive = false,
    this.tag,
  })  : _state = initialState,
        _previousState = initialState;

  /// Optional global tag for Joker registration or debugging.
  /// Jokers now should only be used for local variables.
  @Deprecated('Joker is no longer CircusRing dependent')
  final String? tag;

  /// Controls whether [trick] and friends automatically call [notifyListeners].
  final bool autoNotify;

  /// If true, prevents the Joker from being auto-disposed when listeners drop to zero.
  final bool keepAlive;

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

  // Flag to track if dispose has been called explicitly or internally
  bool _isDisposed = false;

  // Flag to track if a microtask for disposal has been scheduled
  bool _isDisposalScheduled = false;

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }
    // Cancel any pending disposal microtask by resetting the flag
    _isDisposalScheduled = false;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    // Don't try to remove listener if already disposed
    if (_isDisposed) return;

    super.removeListener(listener);

    // If no listeners left, not kept alive, and disposal not already scheduled
    if (!hasListeners && !keepAlive && !_isDisposalScheduled) {
      _scheduleDispose();
    }
  }

  // Schedules disposal via a microtask.
  void _scheduleDispose() {
    // Set flag first
    _isDisposalScheduled = true;
    // Wait for next frame to dispose
    _engine.addPostFrameCallback((_) {
      _disposeIfUnused();
    });
  }

  // Disposes the Joker if it's still unused and disposal was scheduled.
  void _disposeIfUnused() {
    // Only dispose if the microtask was scheduled and conditions still hold
    if (_isDisposalScheduled && !hasListeners && !keepAlive && !_isDisposed) {
      dispose();
    }
    // Reset the flag regardless of whether dispose was called
    _isDisposalScheduled = false;
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _isDisposalScheduled = false; // Ensure flag is reset on explicit dispose
      super.dispose();
    }
  }

  /// Returns true if the Joker has been disposed.
  bool get isDisposed => _isDisposed;

  // ----------------- Auto-notify APIs -----------------

  /// Updates state and automatically calls [notifyListeners].
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed Joker.
  void trick(T newState) {
    if (_isDisposed) {
      throw JokerException('Cannot call trick() on a disposed $runtimeType');
    }
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
  /// Throws [JokerException] if called on a disposed Joker.
  void trickWith(T Function(T currentState) performer) {
    if (_isDisposed) {
      throw JokerException(
          'Cannot call trickWith() on a disposed $runtimeType');
    }
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
  /// Throws [JokerException] if called on a disposed Joker.
  Future<void> trickAsync(Future<T> Function(T current) performer) async {
    if (_isDisposed) {
      throw JokerException(
          'Cannot call trickAsync() on a disposed $runtimeType');
    }
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
  /// Throws [JokerException] if called on a disposed Joker.
  T whisper(T newState) {
    if (_isDisposed) {
      throw JokerException('Cannot call whisper() on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('whisper() is not allowed in autoNotify mode.');
    }
    _previousState = _state;
    _state = newState;
    return _state;
  }

  /// Functor version of [whisper].
  /// Throws [JokerException] if called on a disposed Joker.
  T whisperWith(T Function(T currentState) updater) {
    if (_isDisposed) {
      throw JokerException(
          'Cannot call whisperWith() on a disposed $runtimeType');
    }
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
  /// Does nothing if the Joker is disposed.
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Alias for [notifyListeners] specific to manual mode clarity.
  /// Does nothing if the Joker is disposed.
  void yell() {
    notifyListeners();
  }

  /// Whether the state has changed since the previous update.
  bool isDifferent() => _state != _previousState;

  /// Begins a batch update session.
  ///
  /// Use [JokerBatch.commit] to notify once after multiple updates.
  /// Throws [JokerException] if called on a disposed Joker.
  JokerBatch<T> batch() {
    if (_isDisposed) {
      throw JokerException('Cannot start batch on a disposed $runtimeType');
    }
    return JokerBatch<T>(this);
  }
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
    if (_joker.isDisposed) {
      throw JokerException(
          'Cannot apply batch update to a disposed $runtimeType');
    }
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
    if (_joker.isDisposed) return; // Do nothing if disposed
    if (_joker.state != _originalState) {
      _joker.yell();
    }
  }

  /// Restores original snapshot and discards any changes.
  void discard() {
    if (_joker.isDisposed) return; // Do nothing if disposed
    if (_isAutoNotify) {
      (_joker as dynamic)._state = _originalState;
    } else {
      _joker.whisper(_originalState);
    }
  }
}

final _engine = WidgetsFlutterBinding.ensureInitialized();
