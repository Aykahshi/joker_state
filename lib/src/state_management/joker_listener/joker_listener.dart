import 'package:flutter/foundation.dart';

import '../joker/joker.dart';

/// A side-effect callback triggered when Joker state updates.
typedef JokerListener<T> = void Function(T? previous, T current);

/// A predicate to determine whether to trigger a [JokerListener].
typedef JokerListenCondition<T> = bool Function(T? previous, T current);

/// Extension methods on Joker<T> to support side-effect listeners.
extension JokerListenerExtension<T> on Joker<T> {
  /// Listen to all state changes of a Joker.
  ///
  /// - Automatically compares previous state and current state.
  /// - Triggers [listener] on each state change (before rebuild).
  /// - Returns a function to cancel the subscription.
  ///
  /// Example:
  /// ```dart
  /// final cancel = counter.listen((prev, curr) {
  ///   print('[LOG] State changed: $prev -> $curr');
  /// });
  /// ```
  VoidCallback listen(JokerListener<T> listener) {
    return listenWhen(
      listener: listener,
      // Always listen
      shouldListen: (prev, next) => true,
    );
  }

  /// Listen only when [shouldListen] returns true.
  ///
  /// - [shouldListen] receives previous and current state.
  /// - If it returns true, [listener] will be called.
  /// - Returns a disposer function to stop monitoring.
  ///
  /// Example:
  /// ```dart
  /// final cancel = joker.listenWhen(
  ///   (prev, next) => print('count grew!'),
  ///   (prev, next) => next > (prev ?? 0),
  /// );
  /// ```
  VoidCallback listenWhen({
    required JokerListener<T> listener,
    JokerListenCondition<T>? shouldListen,
  }) {
    T? previous = state;

    void callback() {
      final current = state;
      if (shouldListen != null && shouldListen(previous, current)) {
        listener(previous, current);
      }
      previous = current;
    }

    addListener(callback);

    return () => removeListener(callback);
  }
}
