import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../foundation/joker_act.dart';
import '../foundation/joker_sleight.dart';
import 'joker_exception.dart';

/// A lightweight, reactive state container built on [ChangeNotifier].
///
/// [Joker] wraps a single value and notifies its listeners when the value changes.
/// It is designed for simple, local state management and can be used in any
/// Dart environment that supports Flutter's foundation library.
///
/// It supports both automatic and manual notification modes and can automatically
/// dispose itself when it is no longer in use, preventing memory leaks.
///
/// ### Example
/// ```dart
/// // Auto-notifying Joker
/// final counter = Joker(0);
/// counter.addListener(() => print(counter.value));
/// counter.trick(1); // Prints: 1
///
/// // Manual-notifying Joker
/// final name = Joker('Initial', autoNotify: false);
/// name.whisper('John'); // State changes, but no notification
/// name.yell(); // Manually triggers notification
/// ```
class Joker<T> extends JokerAct<T> {
  /// Creates a new [Joker] instance.
  ///
  /// - [initialState]: The starting value of the state.
  /// - [tag]: An optional identifier for debugging purposes.
  /// - [autoNotify]: If `true`, any state change automatically notifies listeners.
  /// - [keepAlive]: If `true`, prevents the Joker from auto-disposing.
  /// - [autoDisposeDelay]: The delay before auto-disposing.
  /// - [enableDebugLog]: If `true`, logs creation and disposal events.
  Joker(
    super.initialState, {
    this.tag,
    super.autoNotify = true,
    super.keepAlive = false,
    super.autoDisposeDelay,
    this.enableDebugLog = kDebugMode,
  }) {
    _previousState = value;
    if (enableDebugLog) {
      _log('Joker created: $runtimeType tag: $tag, value: $value');
    }
  }

  /// An optional tag for identification or debugging purposes.
  final String? tag;

  /// If `true`, logs creation and disposal events to the console.
  final bool enableDebugLog;

  T? _previousState;
  JokerSleight<T>? _activeBatch;

  /// The state of the [Joker] before the most recent change.
  T? get previousState => _previousState;

  // --- State API ---

  /// Gets the current state. An alias for [value].
  T get state => value;

  /// Sets the state. If in [autoNotify] mode, notifies listeners.
  set state(T newValue) {
    _previousState = value;
    value = newValue;
  }

  /// Updates the value and notifies listeners.
  ///
  /// This method is only allowed when [autoNotify] is `true`.
  /// Throws a [JokerException] if called in manual mode.
  void trick(T newValue) {
    if (!autoNotify) {
      throw JokerException(
          'trick() is not allowed in manual mode. Use whisper() and yell().');
    }
    state = newValue;
  }

  /// Updates the value using a function and notifies listeners.
  ///
  /// This method is only allowed when [autoNotify] is `true`.
  /// Throws a [JokerException] if called in manual mode.
  void trickWith(T Function(T currentState) updater) {
    if (!autoNotify) {
      throw JokerException(
          'trickWith() is not allowed in manual mode. Use whisperWith() and yell().');
    }
    state = updater(state);
  }

  /// Updates the value asynchronously and notifies listeners.
  ///
  /// This method is only allowed when [autoNotify] is `true`.
  /// Throws a [JokerException] if called in manual mode.
  Future<void> trickAsync(Future<T> Function(T currentState) performer) async {
    if (!autoNotify) {
      throw JokerException(
          'trickAsync() is not allowed in manual mode. Use whisperWith() and yell().');
    }
    state = await performer(state);
  }

  /// Starts a batch update session for this [Joker].
  ///
  /// This method is only allowed when [autoNotify] is `false`.
  /// It returns a [JokerSleight] instance that can be used to apply multiple
  /// changes and commit them with a single notification.
  ///
  /// If there's already an active batch, returns the existing one.
  JokerSleight<T> batch() {
    if (autoNotify) {
      throw JokerException('batch() is not allowed in autoNotify mode.');
    }
    return _activeBatch ??= JokerSleight<T>(this);
  }

  // --- Lifecycle ---

  @override
  void dispose() {
    if (isDisposed) return;
    if (enableDebugLog) {
      _log('Joker disposed: $runtimeType tag: $tag');
    }
    super.dispose();
  }

  void _log(String message) {
    log('--- $message ---', name: 'Joker');
  }
}
