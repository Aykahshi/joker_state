import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';

/// A builder that receives a combined, strongly-typed state from multiple [Joker]s.
typedef JokerTroupeBuilder<T extends Record> = Widget Function(
  BuildContext context,
  T states,
);

/// A function that converts a list of dynamic state values into a strongly-typed [Record].
typedef JokerTroupeConverter<T extends Record> = T Function(List<dynamic> states);

/// A widget that combines multiple [JokerAct] instances into a single UI representation.
///
/// [JokerTroupe] listens to a list of [JokerAct]s (e.g., [Joker] or [Presenter])
/// and rebuilds whenever any one of them notifies a change. It uses a [converter]
/// function to transform the individual state values into a single, strongly-typed
/// Dart [Record], which is then passed to the [builder].
///
/// This is a powerful tool for building widgets that depend on several
/// independent pieces of state, such as a form.
///
/// {@tool snippet}
/// ### Direct Instantiation
///
/// ```dart
/// final nameAct = Joker<String>('Alice');
/// final ageAct = Joker<int>(30);
///
/// // Define the record type for the combined state.
/// typedef UserProfile = (String name, int age);
///
/// class ProfileView extends StatelessWidget {
///   const ProfileView({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return JokerTroupe<UserProfile>(
///       acts: [nameAct, ageAct],
///       converter: (values) => (values[0] as String, values[1] as int),
///       builder: (context, profile) {
///         final (name, age) = profile;
///         return Text('$name is $age years old');
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using the `.assemble()` Extension
///
/// ```dart
/// // In your build method:
/// [nameAct, ageAct].assemble<(String, int)>(
///   converter: (values) => (values[0] as String, values[1] as int),
///   builder: (context, profile) {
///     final (name, age) = profile;
///     return Text('$name is $age');
///   },
/// );
/// ```
/// {@end-tool}
class JokerTroupe<T extends Record> extends StatefulWidget {
  /// Creates a [JokerTroupe] widget.
  const JokerTroupe({
    super.key,
    required this.acts,
    required this.converter,
    required this.builder,
  });

  /// The list of [JokerAct] instances to observe for changes.
  final List<JokerAct> acts;

  /// A function that converts the list of raw state values from [acts]
  /// into a single, typed [Record] of type [T].
  final JokerTroupeConverter<T> converter;

  /// The builder function that rebuilds when any of the observed [JokerAct]s change.
  final JokerTroupeBuilder<T> builder;

  @override
  State<JokerTroupe<T>> createState() => _JokerTroupeState<T>();
}

class _JokerTroupeState<T extends Record> extends State<JokerTroupe<T>> {
  late List<dynamic> _states;
  final Map<JokerAct, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _initStates();
    _addListeners();
  }

  @override
  void didUpdateWidget(JokerTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.acts.length != oldWidget.acts.length ||
        !_areActsEqual(widget.acts, oldWidget.acts)) {
      _removeListeners();
      _initStates();
      _addListeners();
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  void _initStates() {
    _states = List.from(widget.acts.map((act) => act.value));
  }

  void _addListeners() {
    for (int i = 0; i < widget.acts.length; i++) {
      final act = widget.acts[i];
      final index = i;

      void listener() {
        if (mounted) {
          setState(() {
            if (index < _states.length) {
              _states[index] = act.value;
            }
          });
        }
      }

      _listeners[act] = listener;
      act.addListener(listener);
    }
  }

  void _removeListeners() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
  }

  bool _areActsEqual(List<JokerAct> list1, List<JokerAct> list2) {
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final typedStates = widget.converter(_states);
    return widget.builder(context, typedStates);
  }
}

