import 'dart:async';

import 'package:flutter/widgets.dart';

import 'presenter.dart';

/// Extension for Presenter to easily create a StreamBuilder widget.
///
/// Provides a builder-like API for "showing" the entire state managed by the Presenter.
///
/// Example:
/// ```dart
/// final counterPresenter = CounterPresenter(); // Extends Presenter<int>
///
/// // Use the extension to build UI based on the presenter's state
/// counterPresenter.perform(
///   builder: (context, count) => Text('Count: $count'),
/// );
/// ```
extension PresenterStageExtension<T> on Presenter<T> {
  /// Creates a StreamBuilder that rebuilds whenever this Presenter's state changes.
  ///
  /// The [builder] is used to construct the UI based on the current state [T].
  ///
  /// Returns a StreamBuilder widget linked to this Presenter's stream.
  Widget perform({
    Key? key,
    required Widget Function(BuildContext context, T state) builder,
  }) {
    return StreamBuilder<T>(
      key: key,
      stream: stream,
      initialData: state,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }
        // 如果沒有資料，返回空容器
        return const SizedBox.shrink();
      },
    );
  }
}

/// Extension for Presenter to easily create a StreamBuilder with a selector.
///
/// Allows "focusing" on a specific part of the Presenter's state via a [selector].
/// The UI only rebuilds when the selected value changes.
///
/// Example:
/// ```dart
/// final userPresenter = UserPresenter(); // Extends Presenter<User>
///
/// // Focus on the user's name for the Text widget
/// userPresenter.focusOn<String>(
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Welcome, $name!'),
/// );
/// ```
extension PresenterFrameExtension<T> on Presenter<T> {
  /// Creates a StreamBuilder that focuses on a selected portion ([S]) of this Presenter's state ([T]).
  ///
  /// [selector]: A function that extracts the specific piece of state to observe.
  /// [builder]: A function that builds the UI based on the selected state [S].
  ///
  /// Returns a StreamBuilder widget with transformation, optimized for selective rebuilds.
  Widget focusOn<S>({
    Key? key,
    required S Function(T state) selector,
    required Widget Function(BuildContext context, S selectedState) builder,
  }) {
    // 使用 StreamTransformer 來轉換原始狀態流
    final transformer = StreamTransformer<T, S>.fromHandlers(
      handleData: (data, sink) {
        sink.add(selector(data));
      },
    );

    return StreamBuilder<S>(
      key: key,
      stream: stream.transform(transformer),
      initialData: selector(state),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(context, snapshot.data as S);
        }
        // 如果沒有資料，返回空容器
        return const SizedBox.shrink();
      },
    );
  }
}

/// A side-effect callback triggered when Presenter state updates.
typedef PresenterListener<T> = void Function(T? previous, T current);

/// A predicate to determine whether to trigger a [PresenterListener].
typedef PresenterListenCondition<T> = bool Function(T? previous, T current);

/// Extension methods on Presenter to support side-effect listeners.
extension PresenterListenerExtension<T> on Presenter<T> {
  /// Listen to all state changes of a Presenter.
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
  VoidCallback listen(PresenterListener<T> listener) {
    return listenWhen(
      listener: listener,
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
  /// final cancel = presenter.listenWhen(
  ///   listener: (prev, next) => print('count grew!'),
  ///   shouldListen: (prev, next) => next > (prev ?? 0),
  /// );
  /// ```
  VoidCallback listenWhen({
    required PresenterListener<T> listener,
    PresenterListenCondition<T>? shouldListen,
  }) {
    T? previous = state;

    final subscription = stream.listen((current) {
      if (shouldListen == null || shouldListen(previous, current)) {
        listener(previous, current);
      }
      previous = current;
    });

    return () => subscription.cancel();
  }
}
