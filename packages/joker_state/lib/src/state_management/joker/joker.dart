import 'dart:async';

import 'package:flutter/widgets.dart';

import '../joker_exception.dart';

/// Joker - A simple, locally reactive state container with auto-dispose capabilities.
///
/// Joker wraps a single value and notifies its listeners when the value changes.
/// It automatically disposes itself when it no longer has any listeners,
/// making it suitable for managing local, transient state within widgets or services.
///
/// For more complex state management, involving multiple interdependent states,
/// asynchronous operations with loading/error states, or business logic, consider
/// using a `Presenter` or a more comprehensive state management solution.
///
/// 🎯 Ideal for simple reactive UI updates for local variables.
///
/// Example:
///
/// ```dart
/// final counter = Joker<int>(0);
///
/// print(counter.value); // Output: 0
///
/// counter.addListener(() {
///   print('Counter changed: ${counter.value}');
/// });
///
/// counter.value = 1; // Output: Counter changed: 1
/// counter.value = 2; // Output: Counter changed: 2
///
/// // When all listeners are removed, Joker will automatically dispose itself.
/// ```
class Joker<T> extends ChangeNotifier {
  /// Creates a Joker with the given [initialState].
  Joker(T initialState) : _value = initialState;

  T _value;
  bool _isDisposed = false;

  /// Returns the current value.
  T get value {
    if (_isDisposed) {
      throw JokerException('Cannot access value on a disposed $runtimeType');
    }
    return _value;
  }

  /// Sets the current value and notifies listeners if the new value is different.
  ///
  /// Throws [JokerException] if called on a disposed Joker.
  set value(T newValue) {
    if (_isDisposed) {
      throw JokerException('Cannot set value on a disposed $runtimeType');
    }
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) return;

    super.removeListener(listener);

    if (!hasListeners && !_isDisposed) {
      dispose();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // --- Deprecated Methods ---
  // The following methods are deprecated and will be removed in a future version.
  // For simple state updates, use the `value` setter.
  // For more complex scenarios, consider using a Presenter.

  /// Deprecated: Optional global tag for Joker registration or debugging.
  /// Jokers are now intended for local, auto-disposing variables.
  @Deprecated('Tags are no longer supported as Jokers are for local state. Consider Presenter for tagged/global state. This will be removed in a future version.')
  final String? tag = null; // ignore: deprecated_member_use_from_same_package

  /// Deprecated: Controls whether mutations automatically call [notifyListeners].
  /// Joker now always auto-notifies via the `value` setter.
  @Deprecated('autoNotify is no longer supported. Joker always auto-notifies. Consider Presenter for manual control. This will be removed in a future version.')
  final bool autoNotify = true; // ignore: deprecated_member_use_from_same_package

  /// Deprecated: If true, prevents the Joker from being auto-disposed.
  /// Joker now always auto-disposes when listeners drop to zero.
  @Deprecated('keepAlive is no longer supported. Joker always auto-disposes. Consider Presenter if state needs to be explicitly kept alive. This will be removed in a future version.')
  final bool keepAlive = false; // ignore: deprecated_member_use_from_same_package

  /// Deprecated: Returns the current state. Use `value` instead.
  @Deprecated('Use `value` getter instead. This will be removed in a future version.')
  T get state => value;

  /// Deprecated: Returns the previous state. This functionality is removed for simplicity.
  /// Manage previous state externally if needed, or use a Presenter.
  @Deprecated('Previous state tracking is removed. Manage externally or use Presenter. This will be removed in a future version.')
  T? get previousState {
    throw JokerException('previousState is removed. Manage externally or use Presenter.');
  }

  /// Deprecated: Use `value = newValue` instead.
  /// For complex scenarios, consider using a Presenter.
  @Deprecated('Use `value = newValue` instead. For complex scenarios, consider Presenter. This will be removed in a future version.')
  void trick(T newState) {
    if (_isDisposed) {
      throw JokerException('Cannot call trick() on a disposed $runtimeType');
    }
    value = newState;
  }

  /// Deprecated: Use `value = performer(value)` instead.
  /// For complex scenarios, consider using a Presenter.
  @Deprecated('Use `value = performer(value)` instead. For complex scenarios, consider Presenter. This will be removed in a future version.')
  void trickWith(T Function(T currentState) performer) {
    if (_isDisposed) {
      throw JokerException('Cannot call trickWith() on a disposed $runtimeType');
    }
    value = performer(value);
  }

  /// Deprecated: Use `value = await performer(value)` instead.
  /// For complex scenarios, consider using a Presenter.
  @Deprecated('Use `value = await performer(value)` instead. For complex scenarios, consider Presenter. This will be removed in a future version.')
  Future<void> trickAsync(Future<T> Function(T current) performer) async {
    if (_isDisposed) {
      throw JokerException('Cannot call trickAsync() on a disposed $runtimeType');
    }
    value = await performer(value);
  }

  /// Deprecated: This method is removed. Joker now always notifies on change via `value` setter.
  /// For complex non-notifying scenarios, consider using a Presenter.
  @Deprecated('whisper() is removed. Use `value = newValue` (always notifies) or Presenter. This will be removed in a future version.')
  T whisper(T newState) {
    throw JokerException('whisper() is removed. Use `value = newValue` (always notifies) or Presenter for more complex needs.');
  }

  /// Deprecated: This method is removed. Joker now always notifies on change via `value` setter.
  /// For complex non-notifying scenarios, consider using a Presenter.
  @Deprecated('whisperWith() is removed. Use `value = updater(value)` (always notifies) or Presenter. This will be removed in a future version.')
  T whisperWith(T Function(T currentState) updater) {
    throw JokerException('whisperWith() is removed. Use `value = updater(value)` (always notifies) or Presenter for more complex needs.');
  }

  /// Deprecated: This method is removed. Joker now always notifies on change via `value` setter.
  /// For complex manual notification scenarios, consider using a Presenter.
  @Deprecated('yell() is removed. Joker auto-notifies via `value` setter. Consider Presenter for manual control. This will be removed in a future version.')
  void yell() {
    throw JokerException('yell() is removed. Joker auto-notifies. Consider Presenter for manual control.');
  }

  /// Deprecated: This functionality is removed due to removal of previousState.
  /// Compare externally if needed, or use a Presenter.
  @Deprecated('isDifferent() is removed. Compare externally or use Presenter. This will be removed in a future version.')
  bool isDifferent() {
    throw JokerException('isDifferent() is removed. Compare externally or use Presenter.');
  }

  /// Deprecated: Batch updates are removed. For complex scenarios requiring batching, use a Presenter.
  @Deprecated('batch() and JokerBatch are removed. Use a Presenter for complex state management. This will be removed in a future version.')
  JokerBatch<T> batch() {
    throw JokerException('batch() and JokerBatch are removed. Use a Presenter for complex state management.');
  }
}

/// Deprecated: JokerBatch is removed. For complex scenarios requiring batch updates, use a Presenter.
@Deprecated('JokerBatch is removed. Use a Presenter for complex state management. This will be removed in a future version.')
class JokerBatch<T> {
  // This class is kept for backward compatibility to avoid breaking changes immediately,
  // but its functionality is removed.
  JokerBatch(dynamic joker) {
    throw JokerException('JokerBatch is deprecated and non-functional. Use a Presenter for complex state management.');
  }

  JokerBatch<T> apply(T Function(T state) updater) {
    throw JokerException('JokerBatch is deprecated and non-functional.');
  }

  void commit() {
    throw JokerException('JokerBatch is deprecated and non-functional.');
  }

  void discard() {
    throw JokerException('JokerBatch is deprecated and non-functional.');
  }
}
