import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../joker_state.dart';
import '../rx_interface/rx_batch.dart';

final _engine = WidgetsFlutterBinding.ensureInitialized();

/// Presenter - Complex state management and business logic controller
///
/// Provides lifecycle management (init -> ready -> done) and advanced state operation methods,
/// suitable for complex business logic, multi-variable coordination, async flow control, etc.
///
/// Compared to the lightweight Joker, Presenter offers more advanced features:
/// - State change methods (trick, trickWith, trickAsync)
/// - Batch updates (batch)
/// - Lifecycle callbacks (onInit, onReady, onDone)
/// - Optional manual notification mode
abstract class Presenter<T> extends RxInterface<T> {
  Presenter(
    super.initialState, {
    this.tag,
    this.enableDebugLog = kDebugMode,
    super.autoDisposeDelay,
    super.keepAlive = false,
    super.autoNotify = true,
  }) {
    _previousState = state;
    _safeCall(this, onInit, 'onInit');

    // Schedule onReady after the first frame.
    // Ensure WidgetsBinding is initialized before scheduling the callback.
    _engine.addPostFrameCallback((_) {
      // Only call onReady if the instance hasn't been disposed in the meantime.
      if (!isDisposed) {
        // Use the getter from PresenterInterface
        _safeCall(this, onReady, 'onReady');
      }
    });
  }

  /// Optional tag for identification or debugging purposes
  final String? tag;

  /// Optional flag to enable debug logging
  final bool enableDebugLog;

  /// Previous state value
  T? _previousState;

  /// Called immediately after the Presenter instance is constructed.
  /// Ideal for basic setup and internal initializations.
  @override
  @protected
  @mustCallSuper
  void onInit() {
    if (enableDebugLog) {
      _log('onInit: $runtimeType tag: $tag');
    }
  }

  /// Called 1 frame after [onInit].
  /// Suitable for actions requiring the first frame to be built
  /// (e.g., showing dialogs, navigation, async calls based on initial UI).
  @override
  @protected
  @mustCallSuper
  void onReady() {
    if (enableDebugLog) {
      _log('onReady: $runtimeType tag: $tag');
    }
  }

  /// Called just before the Presenter instance is disposed.
  /// Use this for cleanup (canceling timers, closing streams, etc.).
  @override
  @protected
  @mustCallSuper
  void onDone() {
    if (enableDebugLog) {
      _log('onDone: $runtimeType tag: $tag');
    }
  }

  /// Returns the previous state value
  T? get previousState => _previousState;

  /// Checks if the current state is different from the previous state
  bool get isDifferent => state != _previousState;

  // ------------- State Update APIs -------------

  /// Updates state and notifies all listeners
  ///
  /// Only usable in autoNotify mode
  /// Throws [JokerException] if the Presenter is already disposed
  void trick(T newState) {
    if (isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trick(): Use whisper() in manual mode.',
      );
    }
    _previousState = state;
    state = newState;
  }

  /// Updates state using a transform function and notifies all listeners
  ///
  /// Only usable in autoNotify mode
  /// Throws [JokerException] if the Presenter is already disposed
  void trickWith(T Function(T s) updater) {
    if (isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trickWith(): Use whisperWith() in manual mode.',
      );
    }
    _previousState = state;
    state = updater(state);
  }

  /// Async version of trickWith
  ///
  /// Only usable in autoNotify mode
  /// Throws [JokerException] if the Presenter is already disposed
  Future<void> trickAsync(Future<T> Function(T s) performer) async {
    if (isDisposed) {
      throw JokerException(
          'Cannot update state asynchronously on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trickAsync(): Use whisperWith() and yell() in manual mode.',
      );
    }
    _previousState = state;
    state = await performer(state);
  }

  // ------------- Manual Notification APIs -------------

  /// Silently updates state (no notification)
  ///
  /// Only usable in non-autoNotify mode
  /// Throws [JokerException] if the Presenter is already disposed
  T whisper(T newState) {
    if (isDisposed) {
      throw JokerException('Cannot call whisper() on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('whisper() is not allowed in autoNotify mode.');
    }
    _previousState = state;
    state = newState;
    return state;
  }

  /// Function version of whisper
  /// Throws [JokerException] if the Presenter is already disposed
  T whisperWith(T Function(T s) updater) {
    if (isDisposed) {
      throw JokerException(
          'Cannot call whisperWith() on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('whisperWith() is not allowed in autoNotify mode.');
    }
    _previousState = state;
    state = updater(state);
    return state;
  }

  /// Alias for notifyListeners, for clarity in manual mode
  /// Does nothing if the Presenter is already disposed
  void yell() => notifyListeners();

  /// Starts a batch update session
  ///
  /// Use [RxBatch.commit] to notify once after multiple updates
  /// Throws [JokerException] if the Presenter is already disposed
  RxBatch<T> batch() {
    if (isDisposed) {
      throw JokerException('Cannot start batch on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('batch() is not allowed in autoNotify mode.');
    }
    return RxBatch<T>(this);
  }
}

void _log(String message) {
  log('--- $message ---', name: 'Presenter');
}

/// Safely calls a lifecycle method with error handling
void _safeCall(
    RxInterface presenter, void Function() callback, String methodName) {
  try {
    callback();
  } catch (e) {
    _log('Error during $methodName in ${presenter.runtimeType}');
  }
}
