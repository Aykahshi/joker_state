import 'package:flutter/foundation.dart';

import '../joker_exception.dart';

/// Joker - a reactive state container based on ChangeNotifier
class Joker<T> extends ChangeNotifier {
  /// Creates a Joker with an initial value
  Joker(
    T initialValue, {
    this.autoNotify = true,
    this.tag,
  })  : _value = initialValue,
        _previousValue = initialValue;

  /// Optional tag for identifying this Joker
  final String? tag;

  /// Whether this Joker uses automatic notification mode
  final bool autoNotify;

  /// Internal value storage
  T _value;

  /// Previous value before the last update
  T? _previousValue;

  /// Get the current value
  T get value => _value;

  /// Get the previous value
  T? get previousValue => _previousValue;

  // --------- Auto-notify methods ---------

  /// Updates the value with notification
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
  void yell() {
    notifyListeners();
  }

  /// Compare current and previous values
  bool isDifferent() => _value != _previousValue;

  /// Execute a callback with current and previous values
  void peek(void Function(T? previousValue, T currentValue) callback) {
    callback(_previousValue, _value);
  }

  /// Start a batch of updates
  JokerBatch<T> batch() {
    return JokerBatch<T>(this);
  }
}

/// Helper class for batch updates
class JokerBatch<T> {
  final Joker<T> _joker;
  final T _originalValue;
  final bool _isAutoNotify;

  JokerBatch(this._joker)
      : _originalValue = _joker.value,
        _isAutoNotify = _joker.autoNotify;

  /// Apply multiple updates without notifications
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
  void commit() {
    if (_joker.value != _originalValue) {
      _joker.yell();
    }
  }

  /// Discard changes and revert to original value
  void discard() {
    if (_isAutoNotify) {
      (_joker as dynamic)._value = _originalValue;
    } else {
      _joker.whisper(_originalValue);
    }
  }
}
