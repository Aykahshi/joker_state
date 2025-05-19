import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'presenter.dart';

/// Builder function for [PresenterTroupe].
///
/// Provides access to the strongly typed state from multiple [Presenter]s as a record.
///
/// This function is called every time any Presenter's state changes.
typedef PresenterTroupeBuilder<T extends Record> = Widget Function(
  BuildContext context,
  T states,
);

/// Converter function for [PresenterTroupe].
///
/// Receives raw states (a List of values from [Presenter]) and maps
/// it to a strongly typed Dart [Record].
typedef PresenterTroupeConverter<T extends Record> = T Function(
    List<dynamic> states);

/// PresenterTroupe - Combines multiple [Presenter]s using Dart Records into a single widget.
///
/// This widget listens to any number of [Presenter]s, and rebuilds whenever any of them
/// updates. All Presenter states are passed to a [converter] that transforms a List of states
/// into a strongly-typed Dart record T, enabling safe and expressive UI updates.
///
/// Example usage:
///
/// ```dart
/// final namePresenter = NamePresenter('Alice'); // Extends Presenter<String>
/// final agePresenter = AgePresenter(22);         // Extends Presenter<int>
/// final isActivePresenter = ActivePresenter(true); // Extends Presenter<bool>
///
/// PresenterTroupe<(String, int, bool)>(
///   presenters: [namePresenter, agePresenter, isActivePresenter],
///   converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
///   builder: (context, record) {
///     final (name, age, active) = record;
///     return Column(
///       children: [
///         Text('Name: $name'),
///         Text('Age: $age'),
///         Icon(active ? Icons.check : Icons.close),
///       ],
///     );
///   },
///   onError: (context, error) => Text('Error: $error'),
///   onLoading: (context) => CircularProgressIndicator(),
/// );
/// ```
class PresenterTroupe<T extends Record> extends StatefulWidget {
  /// Creates a [PresenterTroupe] widget from multiple Presenters.
  ///
  /// The [presenters] list provides the reactive state sources.
  /// The [converter] maps the state list into a [Record] of type T.
  /// The [builder] uses the converted record to build the UI.
  const PresenterTroupe({
    super.key,
    required this.presenters,
    required this.converter,
    required this.builder,
    this.distinct = true,
    this.onError,
    this.onLoading,
  });

  /// The list of [Presenter]s to observe for changes.
  ///
  /// This can contain different types, as long as your [converter]
  /// maps them correctly into a strongly-typed record.
  final List<Presenter> presenters;

  /// Converts the raw, dynamic list of values from [presenters]
  /// into a Typed [Record] T.
  final PresenterTroupeConverter<T> converter;

  /// Builder function that rebuilds when any of the Presenter states change.
  ///
  /// The converted record T is passed for safe access.
  final PresenterTroupeBuilder<T> builder;

  /// If true, only emits when the converted record changes (compared with ==).
  final bool distinct;

  /// Called when any of the presenter streams encounters an error.
  final Widget Function(BuildContext context, Object error)? onError;

  /// Provides a widget to display during initial loading.
  final Widget Function(BuildContext context)? onLoading;

  @override
  State<PresenterTroupe<T>> createState() => _PresenterTroupeState<T>();
}

class _PresenterTroupeState<T extends Record>
    extends State<PresenterTroupe<T>> {
  late StreamSubscription<T> _subscription;
  Object? _error;
  T? _latestState;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupCombinedStream();
  }

  void _setupCombinedStream() {
    final streams = widget.presenters.map((p) => p.stream).toList();

    final combinedStream = CombineLatestStream<dynamic, List<dynamic>>(
      streams,
      (values) => values,
    );

    Stream<T> recordStream = combinedStream.map(widget.converter);

    if (widget.distinct) {
      recordStream = recordStream.distinct();
    }

    try {
      final initialValues = widget.presenters.map((p) => p.state).toList();
      _latestState = widget.converter(initialValues);
      _hasInitialized = true;
    } catch (e) {
      _error = e;
    }

    _subscription = recordStream.listen(
      (record) {
        if (mounted) {
          setState(() {
            _latestState = record;
            _error = null;
            _hasInitialized = true;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = error;
          });
        }
      },
    );
  }

  @override
  void didUpdateWidget(PresenterTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the list of presenters changed, update the subscription
    if (!_arePresenterListsEqual(widget.presenters, oldWidget.presenters)) {
      _subscription.cancel();
      _setupCombinedStream();
    }
  }

  bool _arePresenterListsEqual(List<Presenter> list1, List<Presenter> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.onError != null) {
      return widget.onError!(context, _error!);
    }

    if (!_hasInitialized) {
      return widget.onLoading?.call(context) ?? const SizedBox.shrink();
    }

    return widget.builder(context, _latestState!);
  }
}

/// Extension method to easily create a Troupe from [Presenter]s using record patterns.
extension PresenterTroupeExtension on List<Presenter> {
  /// Creates a [PresenterTroupe] from a list of [Presenter]s.
  ///
  /// This is a more concise way to create a [PresenterTroupe] with Record types.
  ///
  /// Example:
  /// ```dart
  /// [namePresenter, agePresenter, activePresenter].troupe<(String, int, bool)>(
  ///   converter: (values) => (values[0], values[1], values[2]),
  ///   builder: (context, (name, age, active)) => Text('$name, $age, $active'),
  /// );
  /// ```
  Widget troupe<T extends Record>({
    Key? key,
    required PresenterTroupeConverter<T> converter,
    required PresenterTroupeBuilder<T> builder,
    bool distinct = true,
    Widget Function(BuildContext context, Object error)? onError,
    Widget Function(BuildContext context)? onLoading,
  }) {
    return PresenterTroupe<T>(
      key: key,
      presenters: this,
      converter: converter,
      builder: builder,
      distinct: distinct,
      onError: onError,
      onLoading: onLoading,
    );
  }
}

/// Extension to create typesafe record troupes for the most common combinations
extension PresenterPairExtension<T1, T2> on (Presenter<T1>, Presenter<T2>) {
  /// Creates a typesafe [PresenterTroupe] from a pair of [Presenter]s.
  ///
  /// Example:
  /// ```dart
  /// (namePresenter, agePresenter).pair(
  ///   builder: (context, (name, age)) => Text('$name: $age'),
  /// );
  /// ```
  Widget pair({
    Key? key,
    required Widget Function(BuildContext context, (T1, T2) record) builder,
    bool distinct = true,
    Widget Function(BuildContext context, Object error)? onError,
    Widget Function(BuildContext context)? onLoading,
  }) {
    return PresenterTroupe<(T1, T2)>(
      key: key,
      presenters: [
        $1 as Presenter,
        $2 as Presenter,
      ],
      converter: (values) => (values[0] as T1, values[1] as T2),
      builder: builder,
      distinct: distinct,
      onError: onError,
      onLoading: onLoading,
    );
  }
}
