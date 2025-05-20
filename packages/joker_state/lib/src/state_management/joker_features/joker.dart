import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../joker_exception.dart';
import '../rx_interface/rx_batch.dart';
import '../rx_interface/rx_interface.dart';

/// Joker - A lightweight, locally reactive state container with auto-dispose capability.
///
/// Joker wraps a single value and notifies its listeners when the value changes.
/// When there are no more listeners, it automatically disposes itself,
/// making it ideal for managing local, transient state within widgets.
///
/// Features:
/// - Lightweight: manages a single value
/// - Auto-dispose: releases resources when there are no listeners
/// - Simple API: value getter/setter, addListener
///
/// Example:
///
/// ```dart
/// final counter = Joker<int>(0);
///
/// print(counter.value); // Output: 0
///
/// counter.addListener((value) {
///   print('Counter changed: $value');
/// });
///
/// counter.state = 1; // Output: Counter changed: 1
/// counter.state = 2; // Output: Counter changed: 2
/// ```
/// When all listeners are removed, Joker will automatically dispose itself
///
/// A lightweight, locally reactive state container that extends RxInterface
///
/// Provides a concise API with auto-dispose capability, suitable for managing local, transient state.
/// Also implements the Listenable interface to maintain compatibility with Flutter widgets.
class Joker<T> extends RxInterface<T> implements Listenable {
  /// Creates a Joker instance with the given initial state.
  Joker(
    super.initialState, {
    this.tag,
    super.autoNotify = true,
    super.keepAlive = false,
    super.autoDisposeDelay,
    this.enableDebugLog = kDebugMode,
  }) {
    _previousState = state;
    if (enableDebugLog) {
      _log('Joker created: $runtimeType tag: $tag');
    }
  }

  /// Optional tag for identification or debugging purposes
  final String? tag;

  /// Optional flag to enable debug logging
  final bool enableDebugLog;

  /// Previous state value
  T? _previousState;

  /// Returns the previous state value
  T? get previousState => _previousState;

  /// Subscribes to value changes, returns an object that can be used to cancel the subscription
  StreamSubscription<T> listen(void Function(T value) listener) {
    return super.subscribe(listener);
  }

  // Compatibility API for supporting existing Flutter widgets
  final List<VoidCallback> _legacyListeners = [];
  final Map<VoidCallback, StreamSubscription<T>> _subscriptions = {};

  /// Adds a no-parameter listener (implements Listenable interface)
  @override
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }

    if (!_legacyListeners.contains(listener)) {
      _legacyListeners.add(listener);

      // Wrap the no-parameter listener as a parameterized listener
      final subscription = super.subscribe((value) {
        // Ensure the listener is called for each state update
        listener();
      });

      // Store the subscription for cleanup
      _subscriptions[listener] = subscription;

      // Call the listener immediately with the current state
      // This ensures consistency with Flutter's ChangeNotifier behavior
      listener();
    }
  }

  /// Removes a listener (compatible with ChangeNotifier API)
  @override
  void removeListener(VoidCallback listener) {
    if (isDisposed) return;

    // Remove from legacy listeners collection
    _legacyListeners.remove(listener);

    // Cancel and remove the subscription
    // This will trigger the onCancel callback in _subject if it's the last listener
    _subscriptions[listener]?.cancel();
    _subscriptions.remove(listener);
  }

  /// Notifies all legacy listeners (compatible with ChangeNotifier API)
  @override
  void notifyListeners() {
    if (isDisposed) return;
    super.notifyListeners();
  }

  // ------------- State Update APIs -------------

  /// Updates the value and notifies listeners
  void trick(T newValue) {
    _previousState = state;
    state = newValue;
  }

  /// Updates the value using a function
  void trickWith(T Function(T currentState) updater) {
    _previousState = state;
    state = updater(state);
  }

  /// Updates the value asynchronously
  Future<void> trickAsync(Future<T> Function(T currentState) performer) async {
    _previousState = state;
    state = await performer(state);
  }

  @override
  void dispose() {
    // Clean up compatibility resources
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _legacyListeners.clear();

    super.dispose();
    if (enableDebugLog) {
      _log('Joker disposed: $runtimeType tag: $tag');
    }
  }

  // ------------- Manual Notification APIs -------------

  /// Silently updates state (no notification)
  ///
  /// Only usable in non-autoNotify mode
  /// Throws [JokerException] if the Joker is already disposed
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
  /// Throws [JokerException] if the Joker is already disposed
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
  /// Does nothing if the Joker is already disposed
  void yell() => notifyListeners();

  /// Starts a batch update session
  ///
  /// Use [RxBatch.commit] to notify once after multiple updates
  /// Throws [JokerException] if the Joker is already disposed
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
  log('--- $message ---', name: 'Joker');
}
