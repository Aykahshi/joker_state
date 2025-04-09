import 'package:flutter/foundation.dart';

typedef PeekFunc<T> = void Function(T? oldValue, T newValue);

/// JokerCard - a reactive state container that notifies listeners when its value changes
class JokerCard<T> extends ValueNotifier<T> {
  /// Creates a JokerCard with an initial value
  JokerCard(
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
      // If the card is stopped, we don't notify listeners
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
  void update(T newValue) {
    value = newValue;
  }

  /// Updates the value using a function
  void updateWith(T Function(T currentValue) updater) {
    value = updater(value);
  }

  /// Updates the value using an async function
  Future<void> updateWithAsync(
    Future<T> Function(T currentValue) updater,
  ) async {
    value = await updater(value);
  }

  /// Compare previous and current values
  bool hasChanged() => value != _previousValue;

  /// Execute a callback with current and previous values
  void peek(
    void Function(T? previousValue, T currentValue) callback,
  ) {
    callback(_previousValue, value);
  }
}
