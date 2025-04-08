import 'package:flutter/foundation.dart';

typedef UpdateFunc<T> = void Function(T? oldValue, T newValue);

/// JokerCard - a reactive state container that notifies listeners when its value changes
class JokerCard<T> extends ValueNotifier<T> {
  /// Creates a JokerCard with an initial value
  JokerCard(T initialValue, {bool stopped = false}) : super(initialValue) {
    this._previousValue = initialValue;
    this.stopped = stopped;
  }

  T? _previousValue;
  bool? stopped;

  @override
  set value(T newValue) {
    _previousValue = value;
    if (stopped == true) {
      // If the card is stopped, we don't notify listeners
      value = newValue;
      return;
    }
    super.value = newValue;
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
  void compare(
    void Function(T? previousValue, T currentValue) callback,
  ) {
    callback(_previousValue, value);
  }

  /// Peek at the card without anyone noticing a change
  void peek(T newCard) {
    if (newCard == value) return;

    if (hasListeners) {
      super.value = newCard; // Directly set without notifying
      notifyListeners();
    } else {
      value = newCard;
    }
  }
}
