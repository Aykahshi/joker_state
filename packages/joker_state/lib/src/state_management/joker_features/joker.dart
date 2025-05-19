import 'dart:async';

import 'package:flutter/foundation.dart';

import '../joker_exception.dart';
import '../rx_interface/rx_interface.dart';

/// Joker - A lightweight, locally reactive state container with auto-dispose capability.
///
/// Joker wraps a single value and notifies its listeners when the value changes.
/// When there are no more listeners, it automatically disposes itself,
/// making it ideal for managing local, transient state within widgets.
///
/// For more complex state management involving multiple interdependent states,
/// asynchronous operations, loading/error states, or business logic, consider using Presenter.
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
///
/// // When all listeners are removed, Joker will automatically dispose itself
/// ```
/// A lightweight, locally reactive state container that extends RxInterface
///
/// Provides a concise API with auto-dispose capability, suitable for managing local, transient state.
/// Also implements the Listenable interface to maintain compatibility with Flutter widgets.
class Joker<T> extends RxInterface<T> implements Listenable {
  /// Creates a Joker instance with the given initial value.
  Joker(super.initialValue, {super.autoDisposeDelay}) : super(keepAlive: false);

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

  /// Updates the value and notifies listeners
  void trick(T newValue) {
    state = newValue;
  }

  /// Updates the value using a function
  void trickWith(T Function(T currentState) updater) {
    state = updater(state);
  }

  /// Updates the value asynchronously
  Future<void> trickAsync(Future<T> Function(T currentState) performer) async {
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
  }

  // --- Deprecated API ---
  @Deprecated(
      'Joker is not support manual mode now. For complex state management, consider using a Presenter.')
  T whisper(T newState) {
    throw JokerException('Cannot call whisper() on a Joker');
  }

  @Deprecated(
      'Joker is not support manual mode now. For complex state management, consider using a Presenter.')
  T whisperWith(T Function(T s) updater) {
    throw JokerException('Cannot call whisperWith() on a Joker');
  }

  @Deprecated(
      'Joker is not support manual mode now. For complex state management, consider using a Presenter.')
  void yell() {
    throw JokerException('Cannot call yell() on a Joker');
  }

  @Deprecated(
      'Joker is not support batch update now. For complex state management, consider using a Presenter.')
  JokerBatch<T> batch() {
    throw JokerException('Cannot call batch() on a Joker');
  }
}

@Deprecated(
    'Joker is not support batch update now. For complex state management, consider using a Presenter.')
class JokerBatch<T> {}
