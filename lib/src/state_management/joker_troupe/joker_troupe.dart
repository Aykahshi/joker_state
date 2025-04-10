import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';

/// Builder function for JokerTroupe
///
/// Takes a BuildContext and the strongly typed record states, and returns a Widget
typedef JokerTroupeBuilder<T> = Widget Function(
  BuildContext context,
  T states,
);

/// Converter function for JokerTroupe
///
/// Takes a list of dynamic states and converts them to a strongly typed record
typedef JokerTroupeConverter<T> = T Function(List states);

/// JokerTroupe - A widget that observes multiple Joker instances with strong typing
///
/// Uses Dart Records to provide type-safe access to multiple reactive states.
/// This widget automatically rebuilds when any of the observed Jokers change.

/// JokerTroupe is a widget that observes multiple Jokers and combines their states
/// using Dart Records for type safety
///
/// Usage examples:
///
/// Basic usage:
/// ```dart
/// // Create multiple Jokers
/// final nameJoker = Joker<String>('John');
/// final ageJoker = Joker<int>(30);
/// final activeJoker = Joker<bool>(true);
///
/// // Define a record type for type-safe access
/// typedef UserRecord = (String name, int age, bool active);
///
/// // Use JokerTroupe to combine multiple Jokers
/// @override
/// Widget build(BuildContext context) {
///   return JokerTroupe<UserRecord>(
///     jokers: [nameJoker, ageJoker, activeJoker],
///     converter: (states) => (states[0], states[1], states[2]),
///     builder: (context, record) {
///       final (name, age, active) = record;
///       return Card(
///         child: ListTile(
///           title: Text(name),
///           subtitle: Text('Age: $age'),
///           trailing: active ? Icon(Icons.check) : Icon(Icons.close),
///         ),
///       );
///     },
///   );
/// }
///
/// // Later, update any of the Jokers
/// nameJoker.trick('Jane');
/// ageJoker.trick(31);
/// // JokerTroupe will automatically rebuild
/// ```
///
/// Using extension method:
/// ```dart
/// // Create multiple Jokers
/// final nameJoker = Joker<String>('John');
/// final ageJoker = Joker<int>(30);
/// final activeJoker = Joker<bool>(true);
///
/// // Define a record type
/// typedef UserRecord = (String name, int age, bool active);
///
/// // Use the assemble extension for a cleaner API
/// @override
/// Widget build(BuildContext context) {
///   return [nameJoker, ageJoker, activeJoker].assemble<UserRecord>(
///     converter: (states) => (states[0], states[1], states[2]),
///     builder: (context, record) {
///       final (name, age, active) = record;
///       return Card(
///         child: ListTile(
///           title: Text(name),
///           subtitle: Text('Age: $age'),
///           trailing: active ? Icon(Icons.check) : Icon(Icons.close),
///         ),
///       );
///     },
///   );
/// }
/// ```
///
/// With CircusRing integration:
/// ```dart
/// // In a setup or initialization method
/// Circus.summon<String>('John', tag: 'userName');
/// Circus.summon<int>(30, tag: 'userAge');
/// Circus.summon<bool>(true, tag: 'userActive');
///
/// // In a widget build method
/// @override
/// Widget build(BuildContext context) {
///   final nameJoker = Circus.spotlight<String>(tag: 'userName');
///   final ageJoker = Circus.spotlight<int>(tag: 'userAge');
///   final activeJoker = Circus.spotlight<bool>(tag: 'userActive');
///
///   typedef UserRecord = (String name, int age, bool active);
///
///   return [name, age, active].assemble<UserRecord>(
///     converter: (states) => (states[0], states[1], states[2]),
///     builder: (context, record) {
///       final (name, age, active) = record;
///       return Card(
///         child: Column(
///           children: [
///             ListTile(
///               title: Text(name),
///               subtitle: Text('Age: $age'),
///               trailing: active ? Icon(Icons.check) : Icon(Icons.close),
///             ),
///             Row(
///               children: [
///                 TextButton(
///                   onPressed: () => nameJoker.trick('Jane'),
///                   child: Text('Change Name'),
///                 ),
///                 TextButton(
///                   onPressed: () => ageJoker.trick(age + 1),
///                   child: Text('Increment Age'),
///                 ),
///                 TextButton(
///                   onPressed: () => activeJoker.trick(!active),
///                   child: Text('Toggle Active'),
///                 ),
///               ],
///             ),
///           ],
///         ),
///       );
///     },
///   );
/// }
/// ```

class JokerTroupe<T extends Record> extends StatefulWidget {
  /// The list of Joker instances to observe
  final List<Joker> jokers;

  /// Function that converts raw Joker states to a strongly typed Record
  ///
  /// This converter transforms the raw states into the specified record type T,
  /// allowing for type-safe access in the builder function
  final JokerTroupeConverter converter;

  /// UI builder function that receives the strongly typed states
  ///
  /// Called whenever any of the Joker states change, providing the latest
  /// states in a strongly typed Record T
  final JokerTroupeBuilder<T> builder;

  /// Whether to automatically dispose Jokers when the widget is removed
  ///
  /// When true, all Joker instances will be disposed of when this widget
  /// is removed from the widget tree
  final bool autoDispose;

  /// Creates a JokerTroupe widget
  ///
  /// [jokers]: List of Joker instances to observe
  /// [converter]: Function to convert raw states to Record type T
  /// [builder]: UI builder function called when states change
  /// [autoDispose]: Whether to dispose Jokers when widget is disposed
  const JokerTroupe({
    super.key,
    required this.jokers,
    required this.converter,
    required this.builder,
    this.autoDispose = true,
  });

  @override
  _JokerTroupeState<T> createState() => _JokerTroupeState<T>();
}

/// State for JokerTroupe widget
class _JokerTroupeState<T extends Record> extends State<JokerTroupe<T>> {
  /// Stores the current states of all observed Jokers
  late List<dynamic> _states;

  /// Maps each Joker to its listener callback for clean removal
  final Map<Joker, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _initStates();
    _addListeners();
  }

  /// Initialize the states list with current Joker states
  void _initStates() {
    _states = List.from(widget.jokers.map((joker) => joker.state));
  }

  /// Add listeners to all Jokers
  void _addListeners() {
    for (int i = 0; i < widget.jokers.length; i++) {
      final joker = widget.jokers[i];
      final index = i;
      final listener = () {
        if (mounted) {
          setState(() {
            if (index < _states.length) {
              _states[index] = joker.state;
            }
          });
        }
      };
      _listeners[joker] = listener;
      joker.addListener(listener);
    }
  }

  /// Remove all listeners from Jokers
  void _removeListeners() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
  }

  @override
  void didUpdateWidget(JokerTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the Jokers list changed, update listeners and states
    if (widget.jokers.length != oldWidget.jokers.length ||
        !_areJokersEqual(widget.jokers, oldWidget.jokers)) {
      _removeListeners();
      _initStates();
      _addListeners();
    }
  }

  /// Compare two lists of Jokers for equality
  bool _areJokersEqual(List<Joker> list1, List<Joker> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _removeListeners();

    // Clean up Jokers if autoDispose is enabled
    if (widget.autoDispose) {
      for (final joker in widget.jokers) {
        final tag = joker.tag;
        if (tag != null && tag.isNotEmpty) {
          // Try to remove from CircusRing if it has a tag
          // If cannot fireByTag, dispose it directly
          if (!Circus.fireByTag(tag)) {
            joker.dispose();
          }
        } else {
          // No tag, just dispose directly
          joker.dispose();
        }
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert raw states to typed record and pass to builder
    final typedStates = widget.converter(_states);
    return widget.builder(context, typedStates);
  }
}
