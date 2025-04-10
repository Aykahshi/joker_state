import 'package:flutter/foundation.dart';

import '../joker_exception.dart';

/// Joker - a reactive state container based on ChangeNotifier
///
/// A lightweight state management solution that wraps a state with change
/// notification capabilities. It can operate in automatic or manual
/// notification modes.

/// Usage examples:
///
/// Basic usage:
/// ```dart
/// // Create a counter Joker
/// final counter = Joker<int>(0);
///
/// // Read the state
/// print(counter.state); // Output: 0
///
/// // Update state and notify listeners (auto-notify mode)
/// counter.trick(1);
/// print(counter.state); // Output: 1
/// print(counter.previousState); // Output: 0
///
/// // Use a function to update the state
/// counter.trickWith((state) => state + 1);
/// print(counter.state); // Output: 2
///
/// // Async update
/// await counter.trickAsync((state) async {
///   await Future.delayed(Duration(seconds: 1));
///   return state + 1;
/// });
/// print(counter.state); // Output: 3
///
/// // Batch updates (only one notification at the end)
/// counter.batch()
///   .apply((state) => state + 1)
///   .apply((state) => state * 2)
///   .commit();
/// print(counter.state); // Output: 8
/// ```
///
/// Manual notification mode:
/// ```dart
/// // Create a Joker with manual notifications
/// final manualCounter = Joker<int>(0, autoNotify: false);
///
/// // Update state without notification
/// manualCounter.whisper(1);
/// print(manualCounter.state); // Output: 1
///
/// // Update using a function without notification
/// manualCounter.whisperWith((state) => state + 1);
/// print(manualCounter.state); // Output: 2
///
/// // Manually trigger notification
/// manualCounter.yell();
/// ```
///
/// Using CircusRing extension:
/// ```dart
/// // Register an auto-notify Joker in CircusRing
/// final counter = Circus.summon<int>(0, tag: 'counter');
///
/// // Register a manual-notify Joker in CircusRing
/// final manualCounter = Circus.recruit<int>(0, tag: 'manualCounter');
///
/// // Retrieve a registered Joker
/// final retrievedCounter = Circus.spotlight<int>(tag: 'counter');
///
/// // Safely try to retrieve a registered Joker
/// final maybeCounter = Circus.trySpotlight<int>(tag: 'unknown');
/// if (maybeCounter != null) {
///   // Use the counter
/// }
///
/// // Remove a registered Joker
/// Circus.vanish<int>(tag: 'counter');
/// ```

class Joker<T> extends ChangeNotifier {
  /// Creates a Joker with an initial state
  ///
  /// [initialState]: The initial state to store
  /// [autoNotify]: Whether to automatically notify listeners when the state changes
  /// [tag]: Optional identifier for this Joker instance
  Joker(
    T initialState, {
    this.autoNotify = true,
    this.tag,
  })  : _state = initialState,
        _previousState = initialState;

  /// Optional tag for identifying this Joker
  ///
  /// Useful for debugging and dependency injection systems
  final String? tag;

  /// Whether this Joker uses automatic notification mode
  ///
  /// When true, functions like [trick] will automatically notify listeners
  /// When false, you must manually call [yell] to notify listeners
  final bool autoNotify;

  /// Internal state storage
  T _state;

  /// Previous state before the last update
  ///
  /// Useful for comparing changes or implementing undo functionality
  T? _previousState;

  /// Get the current state
  T get state => _state;

  /// Get the previous state
  ///
  /// Returns null if the state has never been updated
  T? get previousState => _previousState;

  // --------- Auto-notify methods ---------

  /// Updates the state with notification
  ///
  /// Only available when [autoNotify] is true
  /// Automatically notifies listeners after the update
  void trick(T newState) {
    if (!autoNotify) {
      throw JokerException(
          'trick() cannot be used on a manual Joker. Use whisper() and yell() instead.');
    }
    _previousState = _state;
    _state = newState;
    notifyListeners();
  }

  /// Updates the state using a function with notification
  ///
  /// Only available when [autoNotify] is true
  /// The [performer] function receives the current state and should return the new state
  /// Automatically notifies listeners after the update
  void trickWith(T Function(T currentState) performer) {
    if (!autoNotify) {
      throw JokerException(
          'trickWith() cannot be used on a manual Joker. Use whisperWith() and yell() instead.');
    }
    _previousState = _state;
    _state = performer(_state);
    notifyListeners();
  }

  /// Updates the state using an async function with notification
  ///
  /// Only available when [autoNotify] is true
  /// The [performer] function receives the current state and should return a Future of the new state
  /// Automatically notifies listeners after the update completes
  Future<void> trickAsync(Future<T> Function(T currentState) performer) async {
    if (!autoNotify) {
      throw JokerException(
          'trickAsync() cannot be used on a manual Joker. Use whisperWith() and yell() instead.');
    }
    _previousState = _state;
    _state = await performer(_state);
    notifyListeners();
  }

  // --------- Manual notification methods ---------

  /// Silently update state without notification
  ///
  /// Only available when [autoNotify] is false
  /// Updates the state but doesn't notify listeners
  /// Returns the new state for chaining
  T whisper(T newState) {
    if (autoNotify) {
      throw JokerException(
          'whisper() cannot be used on an automatic Joker. Use trick() instead.');
    }
    _previousState = _state;
    _state = newState;
    return _state;
  }

  /// Silently update state using a function without notification
  ///
  /// Only available when [autoNotify] is false
  /// The [updater] function receives the current state and should return the new state
  /// Returns the new state for chaining
  T whisperWith(T Function(T currentState) updater) {
    if (autoNotify) {
      throw JokerException(
          'whisperWith() cannot be used on an automatic Joker. Use trickWith() instead.');
    }
    _previousState = _state;
    _state = updater(_state);
    return _state;
  }

  /// Force send notification to listeners
  ///
  /// Triggers a rebuild of any UI depending on this Joker
  /// Typically used after [whisper] or [whisperWith] in manual notification mode
  void yell() {
    notifyListeners();
  }

  /// Compare current and previous states
  ///
  /// Returns true if the states are different
  bool isDifferent() => _state != _previousState;

  /// Execute a callback with current and previous states
  ///
  /// Useful for handling side effects based on state changes
  void peek(void Function(T? previousState, T currentState) callback) {
    callback(_previousState, _state);
  }

  /// Start a batch of updates
  ///
  /// Returns a [JokerBatch] that can apply multiple updates efficiently
  /// and notify listeners only once at the end
  JokerBatch<T> batch() {
    return JokerBatch<T>(this);
  }
}

/// Helper class for batch updates
///
/// Allows multiple updates to a Joker while deferring notifications
/// until all changes are ready to be committed
class JokerBatch<T> {
  final Joker<T> _joker;
  final T _originalState;
  final bool _isAutoNotify;

  /// Creates a batch operation for the given Joker
  JokerBatch(this._joker)
      : _originalState = _joker.state,
        _isAutoNotify = _joker.autoNotify;

  /// Apply multiple updates without notifications
  ///
  /// The [updater] function receives the current state and should return the new state
  /// Returns this batch instance for chaining multiple updates
  JokerBatch<T> apply(T Function(T state) updater) {
    if (_isAutoNotify) {
      final currentState = _joker.state;
      final newState = updater(currentState);
      (_joker as dynamic)._state = newState;
    } else {
      _joker.whisperWith(updater);
    }
    return this;
  }

  /// Commit the batch changes and notify if there were changes
  ///
  /// Notifies listeners only if the state has changed from the original
  void commit() {
    if (_joker.state != _originalState) {
      _joker.yell();
    }
  }

  /// Discard changes and revert to original state
  ///
  /// Restores the state to what it was when the batch was started
  void discard() {
    if (_isAutoNotify) {
      (_joker as dynamic)._state = _originalState;
    } else {
      _joker.whisper(_originalState);
    }
  }
}
