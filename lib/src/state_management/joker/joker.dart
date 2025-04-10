import 'package:flutter/foundation.dart';

import '../joker_exception.dart';

/// Joker - a reactive state container based on ChangeNotifier
///
/// A lightweight state management solution that wraps a value with change
/// notification capabilities. It can operate in automatic or manual
/// notification modes.

/// Usage examples:
///
/// Basic usage:
/// ```dart
/// // Create a counter Joker
/// final counter = Joker<int>(0);
///
/// // Read the value
/// print(counter.value); // Output: 0
///
/// // Update value and notify listeners (auto-notify mode)
/// counter.trick(1);
/// print(counter.value); // Output: 1
/// print(counter.previousValue); // Output: 0
///
/// // Use a function to update the value
/// counter.trickWith((value) => value + 1);
/// print(counter.value); // Output: 2
///
/// // Async update
/// await counter.trickAsync((value) async {
///   await Future.delayed(Duration(seconds: 1));
///   return value + 1;
/// });
/// print(counter.value); // Output: 3
///
/// // Batch updates (only one notification at the end)
/// counter.batch()
///   .apply((value) => value + 1)
///   .apply((value) => value * 2)
///   .commit();
/// print(counter.value); // Output: 8
/// ```
///
/// Manual notification mode:
/// ```dart
/// // Create a Joker with manual notifications
/// final manualCounter = Joker<int>(0, autoNotify: false);
///
/// // Update value without notification
/// manualCounter.whisper(1);
/// print(manualCounter.value); // Output: 1
///
/// // Update using a function without notification
/// manualCounter.whisperWith((value) => value + 1);
/// print(manualCounter.value); // Output: 2
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
  /// Creates a Joker with an initial value
  ///
  /// [initialValue]: The initial value to store
  /// [autoNotify]: Whether to automatically notify listeners when the value changes
  /// [tag]: Optional identifier for this Joker instance
  Joker(
    T initialValue, {
    this.autoNotify = true,
    this.tag,
  })  : _value = initialValue,
        _previousValue = initialValue;

  /// Optional tag for identifying this Joker
  ///
  /// Useful for debugging and dependency injection systems
  final String? tag;

  /// Whether this Joker uses automatic notification mode
  ///
  /// When true, functions like [trick] will automatically notify listeners
  /// When false, you must manually call [yell] to notify listeners
  final bool autoNotify;

  /// Internal value storage
  T _value;

  /// Previous value before the last update
  ///
  /// Useful for comparing changes or implementing undo functionality
  T? _previousValue;

  /// Get the current value
  T get value => _value;

  /// Get the previous value
  ///
  /// Returns null if the value has never been updated
  T? get previousValue => _previousValue;

  // --------- Auto-notify methods ---------

  /// Updates the value with notification
  ///
  /// Only available when [autoNotify] is true
  /// Automatically notifies listeners after the update
  void trick(T newValue) {
    if (!autoNotify) {
      throw JokerException(
          'trick() cannot be used on a manual Joker. Use whisper() and yell() instead.');
    }
    _previousValue = _value;
    _value = newValue;
    notifyListeners();
  }

  /// Updates the value using a function with notification
  ///
  /// Only available when [autoNotify] is true
  /// The [performer] function receives the current value and should return the new value
  /// Automatically notifies listeners after the update
  void trickWith(T Function(T currentValue) performer) {
    if (!autoNotify) {
      throw JokerException(
          'trickWith() cannot be used on a manual Joker. Use whisperWith() and yell() instead.');
    }
    _previousValue = _value;
    _value = performer(_value);
    notifyListeners();
  }

  /// Updates the value using an async function with notification
  ///
  /// Only available when [autoNotify] is true
  /// The [performer] function receives the current value and should return a Future of the new value
  /// Automatically notifies listeners after the update completes
  Future<void> trickAsync(Future<T> Function(T currentValue) performer) async {
    if (!autoNotify) {
      throw JokerException(
          'trickAsync() cannot be used on a manual Joker. Use whisperWith() and yell() instead.');
    }
    _previousValue = _value;
    _value = await performer(_value);
    notifyListeners();
  }

  // --------- Manual notification methods ---------

  /// Silently update value without notification
  ///
  /// Only available when [autoNotify] is false
  /// Updates the value but doesn't notify listeners
  /// Returns the new value for chaining
  T whisper(T newValue) {
    if (autoNotify) {
      throw JokerException(
          'whisper() cannot be used on an automatic Joker. Use trick() instead.');
    }
    _previousValue = _value;
    _value = newValue;
    return _value;
  }

  /// Silently update value using a function without notification
  ///
  /// Only available when [autoNotify] is false
  /// The [updater] function receives the current value and should return the new value
  /// Returns the new value for chaining
  T whisperWith(T Function(T currentValue) updater) {
    if (autoNotify) {
      throw JokerException(
          'whisperWith() cannot be used on an automatic Joker. Use trickWith() instead.');
    }
    _previousValue = _value;
    _value = updater(_value);
    return _value;
  }

  /// Force send notification to listeners
  ///
  /// Triggers a rebuild of any UI depending on this Joker
  /// Typically used after [whisper] or [whisperWith] in manual notification mode
  void yell() {
    notifyListeners();
  }

  /// Compare current and previous values
  ///
  /// Returns true if the values are different
  bool isDifferent() => _value != _previousValue;

  /// Execute a callback with current and previous values
  ///
  /// Useful for handling side effects based on value changes
  void peek(void Function(T? previousValue, T currentValue) callback) {
    callback(_previousValue, _value);
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
  final T _originalValue;
  final bool _isAutoNotify;

  /// Creates a batch operation for the given Joker
  JokerBatch(this._joker)
      : _originalValue = _joker.value,
        _isAutoNotify = _joker.autoNotify;

  /// Apply multiple updates without notifications
  ///
  /// The [updater] function receives the current value and should return the new value
  /// Returns this batch instance for chaining multiple updates
  JokerBatch<T> apply(T Function(T value) updater) {
    if (_isAutoNotify) {
      final currentValue = _joker.value;
      final newValue = updater(currentValue);
      (_joker as dynamic)._value = newValue;
    } else {
      _joker.whisperWith(updater);
    }
    return this;
  }

  /// Commit the batch changes and notify if there were changes
  ///
  /// Notifies listeners only if the value has changed from the original
  void commit() {
    if (_joker.value != _originalValue) {
      _joker.yell();
    }
  }

  /// Discard changes and revert to original value
  ///
  /// Restores the value to what it was when the batch was started
  void discard() {
    if (_isAutoNotify) {
      (_joker as dynamic)._value = _originalValue;
    } else {
      _joker.whisper(_originalValue);
    }
  }
}
