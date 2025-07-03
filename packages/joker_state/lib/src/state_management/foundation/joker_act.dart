import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/joker_exception.dart';

/// A base notifier class built upon [ChangeNotifier], providing fine-grained
/// control over state updates and notifications, along with auto-disposal
/// capabilities.
///
/// This class serves as the foundation for state-holding objects like [Joker]
/// and [Presenter]. It encapsulates the core logic for managing a single value
/// ([T]), handling listeners, and orchestrating state changes either
/// automatically or manually.
abstract class JokerAct<T> extends ChangeNotifier {
  /// Creates a new [JokerAct] with an initial state.
  ///
  /// - [initialState]: The starting value of the state.
  /// - [autoNotify]: If `true`, any change to the [value] will automatically
  ///   trigger a notification to all listeners. If `false`, notifications must
  ///   be sent manually by calling [yell].
  /// - [keepAlive]: If `true`, this instance will not be automatically disposed
  ///   when it has no listeners.
  /// - [autoDisposeDelay]: The duration to wait after the last listener is
  ///   removed before automatically disposing this instance. Defaults to 500ms.
  JokerAct(
    T initialState, {
    this.autoNotify = true,
    this.keepAlive = false,
    this.autoDisposeDelay = const Duration(milliseconds: 500),
  }) : _value = initialState;

  /// If `true`, notifies listeners automatically whenever the state changes.
  final bool autoNotify;

  /// If `true`, prevents the instance from being disposed when listeners are removed.
  final bool keepAlive;

  /// The delay before auto-disposing after the last listener is removed.
  final Duration autoDisposeDelay;

  T _value;
  T? _previousValue;
  Timer? _disposeTimer;
  bool _isDisposed = false;

  /// Returns whether this instance has been disposed.
  ///
  /// Once disposed, this object can no longer be used.
  bool get isDisposed => _isDisposed;

  /// The state of the instance before the most recent change.
  ///
  /// This value is updated only when the [value] changes.
  T? get previousValue => _previousValue;

  /// The current state value.
  ///
  /// Accessing this value will throw a [JokerException] if the instance
  /// has been disposed.
  T get value {
    if (_isDisposed) {
      throw JokerException('Cannot access value on a disposed $runtimeType');
    }
    return _value;
  }

  /// Internal setter for the state.
  ///
  /// If in [autoNotify] mode, it notifies listeners immediately upon change.
  /// Throws a [JokerException] if the instance has been disposed.
  @protected
  set value(T newValue) {
    if (_isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    if (_value == newValue) return;

    _previousValue = _value;
    _value = newValue;

    if (autoNotify) {
      notifyListeners();
    }
  }

  /// Silently updates the state without notifying listeners.
  ///
  /// This method is only allowed when [autoNotify] is `false`.
  /// It changes the internal state but does not trigger a rebuild in listeners.
  ///
  /// Throws a [JokerException] if called in [autoNotify] mode.
  /// Returns the new state.
  T whisper(T newValue) {
    if (autoNotify) {
      throw JokerException('whisper() is not allowed in autoNotify mode.');
    }
    if (_value == newValue) return _value;
    _value = newValue;
    return _value;
  }

  /// Silently updates the state using an updater function.
  ///
  /// This method is only allowed when [autoNotify] is `false`.
  /// It computes a new state based on the current one and applies it without
  /// notifying listeners.
  ///
  /// Throws a [JokerException] if called in [autoNotify] mode.
  /// Returns the new state.
  T whisperWith(T Function(T s) updater) {
    if (autoNotify) {
      throw JokerException('whisperWith() is not allowed in autoNotify mode.');
    }
    final newValue = updater(_value);
    if (_value == newValue) return _value;
    _value = newValue;
    return _value;
  }

  /// Manually notifies all listeners of the current state.
  ///
  /// This is primarily intended for use when [autoNotify] is `false`.
  void yell() {
    if (_isDisposed) {
      throw JokerException('Cannot yell on a disposed $runtimeType');
    }
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }
    _disposeTimer?.cancel();
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) return;
    super.removeListener(listener);
    if (!hasListeners && !keepAlive) {
      _disposeTimer = Timer(autoDisposeDelay, dispose);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _disposeTimer?.cancel();
    super.dispose();
  }
}
