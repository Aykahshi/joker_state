import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';
import '../foundation/joker_sleight.dart';
import 'joker_exception.dart';

final _engine = WidgetsFlutterBinding.ensureInitialized();

/// A powerful state management solution for complex business logic and UI interactions.
///
/// [Presenter] extends [JokerAct] and provides a comprehensive lifecycle
/// management system ([onInit], [onReady], [onDone]), making it ideal for
/// implementing patterns like Clean Architecture or MVVM.
///
/// It supports both automatic and manual notification modes, batch updates,
/// and automatic disposal.
class Presenter<T> extends JokerAct<T> {
  /// Creates a new [Presenter] instance.
  ///
  /// - [initialState]: The initial state of the Presenter.
  /// - [tag]: An optional identifier for debugging or dependency injection.
  /// - [enableDebugLog]: If `true`, logs lifecycle and disposal events.
  /// - [autoDisposeDelay]: The delay before auto-disposing.
  /// - [keepAlive]: If `true`, prevents the Presenter from auto-disposing.
  /// - [autoNotify]: If `true`, state changes automatically notify listeners.
  Presenter(
    super.initialState, {
    this.tag,
    this.enableDebugLog = kDebugMode,
    super.autoDisposeDelay,
    super.keepAlive = false,
    super.autoNotify = true,
  }) {
    _previousState = value;
    _safeCall(onInit, 'onInit');

    // Schedule onReady after the first frame.
    _engine.addPostFrameCallback((_) {
      // Only call onReady if the instance hasn't been disposed in the meantime.
      if (!isDisposed) {
        _safeCall(onReady, 'onReady');
      }
    });
  }

  /// An optional tag for identification or debugging purposes.
  final String? tag;

  /// If `true`, logs lifecycle and disposal events to the console.
  final bool enableDebugLog;

  T? _previousState;

  /// The state of the [Presenter] before the most recent change.
  T? get previousState => _previousState;

  /// Called immediately after the [Presenter] instance is constructed.
  ///
  /// Ideal for basic setup and internal initializations that do not depend
  /// on the Flutter widget tree being built.
  @protected
  @mustCallSuper
  void onInit() {
    if (enableDebugLog) {
      _log('onInit: $runtimeType tag: $tag');
    }
  }

  /// Called 1 frame after [onInit].
  ///
  /// Suitable for actions requiring the first frame to be built
  /// (e.g., showing dialogs, navigation, async calls based on initial UI).
  @protected
  @mustCallSuper
  void onReady() {
    if (enableDebugLog) {
      _log('onReady: $runtimeType tag: $tag');
    }
  }

  /// Called just before the [Presenter] instance is disposed.
  ///
  /// Use this for cleanup (canceling timers, closing streams, etc.) to prevent
  /// memory leaks.
  @protected
  @mustCallSuper
  void onDone() {
    if (enableDebugLog) {
      _log('onDone: $runtimeType tag: $tag');
    }
  }

  // --- State API ---

  /// Gets the current state. An alias for [value].
  T get state => value;

  /// Sets the state. If in [autoNotify] mode, notifies listeners.
  @override
  set value(T newValue) {
    _previousState = value;
    super.value = newValue;
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
    value = newValue;
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
    value = updater(value);
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
    value = await performer(value);
  }

  /// Starts a batch update session for this [Presenter].
  ///
  /// This method is only allowed when [autoNotify] is `false`.
  /// It returns a [JokerSleight] instance that can be used to apply multiple
  /// changes and commit them with a single notification.
  JokerSleight<T> batch() {
    if (autoNotify) {
      throw JokerException('batch() is not allowed in autoNotify mode.');
    }
    return JokerSleight<T>(this);
  }

  // --- Lifecycle ---

  @override
  void dispose() {
    if (isDisposed) return;
    _safeCall(onDone, 'onDone');
    if (enableDebugLog) {
      _log('Presenter disposed: $runtimeType tag: $tag');
    }
    super.dispose();
  }

  void _log(String message) {
    log('--- $message ---', name: 'Presenter');
  }

  /// Safely calls a lifecycle method with error handling.
  void _safeCall(VoidCallback callback, String methodName) {
    try {
      callback();
    } catch (e, s) {
      _log('Error during $methodName in $runtimeType: $e\n$s');
    }
  }
}
