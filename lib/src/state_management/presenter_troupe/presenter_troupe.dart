import 'dart:async';

import 'package:flutter/widgets.dart';

import '../presenter/presenter_interface.dart';

/// Builder function for [PresenterTroupe].
///
/// Provides access to the strongly typed state from multiple [Presenter]s after conversion.
///
/// This function is called every time any Presenter's state changes.
typedef PresenterTroupeBuilder<T> = Widget Function(
  BuildContext context,
  T states,
);

/// Converter function for [PresenterTroupe].
///
/// Receives raw states (a dynamic List of values from [Presenter]) and maps
/// it to a strongly typed Dart [Record].
typedef PresenterTroupeConverter<T> = T Function(List states);

/// Pair of [Presenter] and its [StreamSubscription].
typedef PresenterTroupePair = Map<PresenterInterface, StreamSubscription>;

/// PresenterTroupe - Combines multiple [Presenter]s using Dart Records into a single widget.
///
/// This widget listens to any number of [Presenter]s, and rebuilds whenever any of them
/// updates. All Presenter states are passed to a [converter] that transforms a List of dynamic
/// into a strongly-typed Dart record T, enabling safe and expressive UI updates.
///
/// This is a powerful way to bind multiple reactive states into a single widget tree.
///
/// Example usage:
///
/// ```dart
/// final namePresenter = NamePresenter('Alice'); // Extends Presenter<String>
/// final agePresenter = AgePresenter(22);         // Extends Presenter<int>
/// final isActivePresenter = ActivePresenter(true); // Extends Presenter<bool>
///
/// typedef UserData = (String name, int age, bool active);
///
/// PresenterTroupe<UserData>(
///   presenters: [namePresenter, agePresenter, isActivePresenter],
///   converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
///   builder: (context, user) {
///     final (name, age, active) = user;
///     return Column(
///       children: [
///         Text('Name: $name'),
///         Text('Age: $age'),
///         Icon(active ? Icons.check : Icons.close),
///       ],
///     );
///   },
/// );
/// ```
class PresenterTroupe<T extends Record> extends StatefulWidget {
  /// Creates a [PresenterTroupe] widget from multiple Presenters.
  ///
  /// The [presenters] list provides the reactive state sources.
  /// The [converter] maps the dynamic state list into a [Record] of type T.
  /// The [builder] uses the converted record to build the UI.
  const PresenterTroupe({
    super.key,
    required this.presenters,
    required this.converter,
    required this.builder,
  });

  /// The list of [Presenter]s to observe for changes.
  ///
  /// This can contain different types, as long as your [converter]
  /// maps them correctly into a strongly-typed record.
  final List<PresenterInterface> presenters;

  /// Converts the raw, unordered dynamic list of values from [presenters]
  /// into a Typed [Record] T.
  ///
  /// This is required to ensure consistency and to cast from dynamic to Record.
  final PresenterTroupeConverter<T> converter;

  /// Builder function that rebuilds when any of the Presenter states change.
  ///
  /// The converted record T is passed for safe access.
  final PresenterTroupeBuilder<T> builder;

  @override
  State<PresenterTroupe<T>> createState() => _PresenterTroupeState<T>();
}

/// Internal state of [PresenterTroupe].
///
/// Responsible for managing state snapshots and listener cleanup.
class _PresenterTroupeState<T extends Record>
    extends State<PresenterTroupe<T>> {
  /// Current snapshot of all Presenter states.
  late List<dynamic> _states;

  /// Maps each Presenter to its bound listener's subscription.
  final PresenterTroupePair _cancelSubscriptions = {};

  @override
  void initState() {
    super.initState();
    _initStates();
    _addListeners();
  }

  /// Initializes [_states] from current presenter values.
  void _initStates() {
    _states = List.from(widget.presenters.map((presenter) => presenter.state));
  }

  /// Adds listeners to all [Presenter]s so we can detect changes and rebuild.
  void _addListeners() {
    for (int i = 0; i < widget.presenters.length; i++) {
      final presenter = widget.presenters[i];
      final index = i;

      final subscription = presenter.addListener((state) {
        if (mounted) {
          setState(() {
            if (index < _states.length) {
              _states[index] = state;
            }
          });
        }
      });

      _cancelSubscriptions[presenter] = subscription;
    }
  }

  /// Clean removal of all registered listeners.
  void _removeListeners() {
    for (final entry in _cancelSubscriptions.entries) {
      entry.value.cancel();
    }
    _cancelSubscriptions.clear();
  }

  @override
  void didUpdateWidget(PresenterTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the list of presenters changed, refresh listeners and state snapshots
    if (widget.presenters.length != oldWidget.presenters.length ||
        !_arePresentersEqual(widget.presenters, oldWidget.presenters)) {
      _removeListeners();
      _initStates();
      _addListeners();
    }
  }

  /// Shallow equality check between two Presenter lists.
  bool _arePresentersEqual(
      List<PresenterInterface> list1, List<PresenterInterface> list2) {
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typedStates = widget.converter(_states);
    return widget.builder(context, typedStates);
  }
}
