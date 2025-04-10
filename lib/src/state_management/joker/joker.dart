import 'package:flutter/foundation.dart';

typedef PeekFunc<T> = void Function(T? oldValue, T newValue);

/// Joker - a reactive state container that notifies listeners when its value changes
class Joker<T> extends ValueNotifier<T> {
  /// Creates a Joker with an initial value
  Joker(
    T initialValue, {
    this.stopped = false,
    this.tag,
  }) : super(initialValue) {
    this._previousValue = initialValue;
  }

  final String? tag;
  final bool stopped;
  T? _previousValue;

  @override
  set value(T newValue) {
    _previousValue = value;
    if (stopped) {
      // If joker is stopped, we don't notify listeners
      super.value = newValue;
    }
    super.value = newValue;
  }

  @override
  void notifyListeners() {
    if (!stopped) {
      super.notifyListeners();
    }
  }

  /// Updates the value
  void trick(T newValue) {
    value = newValue;
  }

  /// Updates the value using a function
  void trickWith(T Function(T currentValue) performer) {
    value = performer(value);
  }

  /// Updates the value using an async function
  Future<void> trickAsync(
    Future<T> Function(T currentValue) performer,
  ) async {
    value = await performer(value);
  }

  /// Compare previous and current values
  bool isDifferent() => value != _previousValue;

  /// Execute a callback with current and previous values
  void peek(
    void Function(T? previousValue, T currentValue) callback,
  ) {
    callback(_previousValue, value);
  }
}
