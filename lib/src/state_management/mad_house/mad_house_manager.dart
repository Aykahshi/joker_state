import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// MadHouseManager - a holder for state that can be accessed through the widget tree
class MadHouseState<T> {
  T _value;

  /// The current state value
  T get value => _value;

  /// Updates the state value and rebuilds dependent widgets
  set value(T newValue) {
    _value = newValue;
    _notifyListeners();
  }

  final List<VoidCallback> _listeners = [];

  MadHouseState(this._value);

  /// Adds a listener to be called when the value changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifies all registered listeners
  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Updates the value using a callback function
  void update(T Function(T currentValue) updater) {
    value = updater(value);
  }
}

/// A special MadHouseManager that wraps a JokerCard
class MadHouseManager<T> extends MadHouseState<T> {
  final Joker<T> joker;

  MadHouseManager(this.joker) : super(joker.value) {
    // Listen to JokerCard changes
    joker.addListener(_onJokerChanged);
  }

  void _onJokerChanged() {
    _value = joker.value;
    _notifyListeners();
  }

  @override
  set value(T newValue) {
    joker.value = newValue;
    // No need to call _notifyListeners() - joker will notify us
  }

  /// Clean up when no longer needed
  void dispose() {
    joker.removeListener(_onJokerChanged);
  }
}
