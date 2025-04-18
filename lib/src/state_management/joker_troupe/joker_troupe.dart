import 'package:flutter/widgets.dart';

import '../../di/circus_ring/src/circus_ring.dart';
import '../joker/joker.dart';

/// Builder function for [JokerTroupe].
///
/// Provides access to the strongly typed state from multiple [Joker]s after conversion.
///
/// This function is called every time any Joker's state changes.
typedef JokerTroupeBuilder<T> = Widget Function(
  BuildContext context,
  T states,
);

/// Converter function for [JokerTroupe].
///
/// Receives raw states (a dynamic List of values from [Joker]) and maps
/// it to a strongly typed Dart [Record].
typedef JokerTroupeConverter<T> = T Function(List states);

/// JokerTroupe - Combines multiple [Joker]s using Dart Records into a single widget.
///
/// This widget listens to any number of [Joker]s, and rebuilds whenever any of them
/// updates. All Joker states are passed to a [converter] that transforms a List of dynamic
/// into a strongly-typed Dart record T, enabling safe and expressive UI updates.
///
/// This is a powerful way to bind multiple reactive states into a single widget tree.
///
/// {@tool dart}
/// Example usage:
///
/// ```dart
/// final nameJoker = Joker<String>('Alice');
/// final ageJoker = Joker<int>(22);
/// final isActiveJoker = Joker<bool>(true);
///
/// typedef UserData = (String name, int age, bool active);
///
/// JokerTroupe<UserData>(
///   jokers: [nameJoker, ageJoker, isActiveJoker],
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
/// {@end-tool}
class JokerTroupe<T extends Record> extends StatefulWidget {
  /// Creates a [JokerTroupe] widget from multiple Jokers.
  ///
  /// The [jokers] list provides the reactive state sources.
  /// The [converter] maps the dynamic state list into a [Record] of type T.
  /// The [builder] uses the converted record to build the UI.
  ///
  /// If [autoDispose] is true (default), all [Joker]s will be disposed or
  /// removed from [CircusRing] upon widget destruction.
  /// The `autoDispose` parameter is removed, as Jokers now manage their own lifecycle.
  const JokerTroupe({
    super.key,
    required this.jokers,
    required this.converter,
    required this.builder,
  });

  /// The list of [Joker]s to observe for changes.
  ///
  /// This can contain different types, as long as your [converter]
  /// maps them correctly into a strongly-typed record.
  final List<Joker> jokers;

  /// Converts the raw, unordered dynamic list of values from [jokers]
  /// into a Typed [Record] T.
  ///
  /// This is required to ensure consistency and to cast from dynamic to Record.
  final JokerTroupeConverter<T> converter;

  /// Builder function that rebuilds when any of the Joker states change.
  ///
  /// The converted record T is passed for safe access.
  final JokerTroupeBuilder<T> builder;

  @override
  State<JokerTroupe<T>> createState() => _JokerTroupeState<T>();
}

/// Internal state of [JokerTroupe].
///
/// Responsible for managing state snapshots and listener cleanup.
class _JokerTroupeState<T extends Record> extends State<JokerTroupe<T>> {
  /// Current snapshot of all Joker states.
  late List<dynamic> _states;

  /// Maps each Joker to its bound listener — used for cleanup.
  final Map<Joker, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _initStates();
    _addListeners();
  }

  /// Initializes [_states] from current joker values.
  void _initStates() {
    _states = List.from(widget.jokers.map((joker) => joker.state));
  }

  /// Adds listeners to all [Joker]s so we can detect changes and rebuild.
  void _addListeners() {
    for (int i = 0; i < widget.jokers.length; i++) {
      final joker = widget.jokers[i];
      final index = i;

      listener() {
        if (mounted) {
          setState(() {
            if (index < _states.length) {
              _states[index] = joker.state;
            }
          });
        }
      }

      _listeners[joker] = listener;
      joker.addListener(listener);
    }
  }

  /// Clean removal of all registered listeners.
  void _removeListeners() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
  }

  @override
  void didUpdateWidget(JokerTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the list of jokers changed, refresh listeners and state snapshots
    if (widget.jokers.length != oldWidget.jokers.length ||
        !_areJokersEqual(widget.jokers, oldWidget.jokers)) {
      _removeListeners();
      _initStates();
      _addListeners();
    }
  }

  /// Shallow equality check between two Joker lists.
  bool _areJokersEqual(List<Joker> list1, List<Joker> list2) {
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _removeListeners();

    /* // Removed autoDispose logic
    if (widget.autoDispose) {
      for (final joker in widget.jokers) {
        final tag = joker.tag;
        if (tag != null && tag.isNotEmpty) {
          final removed = Circus.fireByTag(tag); // fireByTag also handles dispose
          if (!removed) {
            // If not found by tag (maybe registered differently or not at all), dispose manually
            if (!joker.isDisposed) joker.dispose();
          }
        } else {
          // If no tag, dispose manually
          if (!joker.isDisposed) joker.dispose();
        }
      }
    }
    */

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typedStates = widget.converter(_states);
    return widget.builder(context, typedStates);
  }
}
