import 'dart:async';

import 'package:flutter/widgets.dart';

import 'presenter.dart';

/// Extension for Presenter to easily create a StreamBuilder widget.
///
/// Provides a builder-like API for "showing" the entire state managed by the Presenter.
extension PresenterStageExtension<T> on Presenter<T> {
  /// Creates a StreamBuilder that rebuilds whenever this Presenter's state changes.
  ///
  /// The [builder] is used to construct the UI based on the current state [T].
  /// [onError] is called when the stream encounters an error.
  /// [onLoading] provides a widget to display during initial loading (when there's no data yet).
  ///
  /// Returns a StreamBuilder widget linked to this Presenter's stream.
  Widget perform({
    Key? key,
    required Widget Function(BuildContext context, T state) builder,
    Widget Function(BuildContext context, Object error)? onError,
    Widget Function(BuildContext context)? onLoading,
  }) {
    return StreamBuilder<T>(
      key: key,
      stream: stream,
      initialData: state,
      builder: (context, snapshot) {
        if (snapshot.hasError && onError != null) {
          return onError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as T);
        }

        return onLoading?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}

/// Extension for Presenter to easily create a StreamBuilder with a selector.
///
/// Allows "focusing" on a specific part of the Presenter's state via a [selector].
/// The UI only rebuilds when the selected value changes.
extension PresenterFrameExtension<T> on Presenter<T> {
  /// Creates a StreamBuilder that focuses on a selected portion ([S]) of this Presenter's state ([T]).
  ///
  /// [selector]: A function that extracts the specific piece of state to observe.
  /// [builder]: A function that builds the UI based on the selected state [S].
  /// [distinct]: If true, only emits when the selected value changes (compared with ==).
  /// [onError]: Called when the stream encounters an error.
  /// [onLoading]: Provides a widget to display during initial loading.
  ///
  /// Returns a StreamBuilder widget with transformation, optimized for selective rebuilds.
  Widget focusOn<S>({
    Key? key,
    required S Function(T state) selector,
    required Widget Function(BuildContext context, S selectedState) builder,
    bool distinct = true,
    Widget Function(BuildContext context, Object error)? onError,
    Widget Function(BuildContext context)? onLoading,
  }) {
    Stream<S> selectedStream = stream.map(selector);

    if (distinct) {
      selectedStream = selectedStream.distinct();
    }

    return StreamBuilder<S>(
      key: key,
      stream: selectedStream,
      initialData: selector(state),
      builder: (context, snapshot) {
        if (snapshot.hasError && onError != null) {
          return onError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data as S);
        }

        return onLoading?.call(context) ?? const SizedBox.shrink();
      },
    );
  }

  /// Creates a builder that focuses on multiple selected portions of state.
  ///
  /// Similar to [focusOn] but allows selecting multiple values and only rebuilds
  /// when any of the selected values change.
  ///
  /// Example:
  /// ```dart
  /// presenter.focusOnMulti(
  ///   selectors: [
  ///     (state) => state.name,
  ///     (state) => state.age
  ///   ],
  ///   builder: (context, [name, age]) =>
  ///     Text('$name is $age years old'),
  /// )
  /// ```
  Widget focusOnMulti({
    Key? key,
    required List<Function(T state)> selectors,
    required Widget Function(BuildContext context, List<dynamic> selected)
        builder,
    bool distinct = true,
    Widget Function(BuildContext context, Object error)? onError,
    Widget Function(BuildContext context)? onLoading,
  }) {
    final initialValues = selectors.map((selector) => selector(state)).toList();

    Stream<List<dynamic>> combinedStream = stream
        .map((state) => selectors.map((selector) => selector(state)).toList());

    if (distinct) {
      combinedStream = combinedStream.distinct((previous, current) {
        if (previous.length != current.length) return false;
        for (int i = 0; i < previous.length; i++) {
          if (previous[i] != current[i]) return false;
        }
        return true;
      });
    }

    return StreamBuilder<List<dynamic>>(
      key: key,
      stream: combinedStream,
      initialData: initialValues,
      builder: (context, snapshot) {
        if (snapshot.hasError && onError != null) {
          return onError(context, snapshot.error!);
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        return onLoading?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}
