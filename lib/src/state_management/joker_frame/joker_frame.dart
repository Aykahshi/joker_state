import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// Builder function for [JokerFrame].
///
/// Provides the build context and a selected slice of the Joker's state.
typedef JokerFrameBuilder<S> = Widget Function(
  BuildContext context,
  S selected,
);

/// Selector function for [JokerFrame].
///
/// Maps the complete Joker state into a smaller value you want to observe.
typedef JokerFrameSelector<T, S> = S Function(T state);

/// JokerFrame - A widget that observes a derived slice of a Joker's state.
///
/// Instead of watching the whole state (like [JokerStage]), this widget takes
/// a selector function to extract only the relevant part of the state. It will
/// only rebuild when the selected value changes (`==` comparison).
///
/// Example:
///
/// Basic usage:
/// ```dart
/// Joker<UserData> userJoker = Joker(UserData(name: 'Alice', age: 20));
///
/// JokerFrame<UserData, String>(
///   joker: userJoker,
///   selector: (user) => user.name,
///   builder: (context, name) => Text('User: $name'),
/// );
/// ```
///
/// Selector-based optimization avoids unnecessary rebuilds when unrelated
/// parts of the state update:
///
/// ```dart
/// userJoker.trick(user.copyWith(age: 21)); // Builder won't rebuild
/// userJoker.trick(user.copyWith(name: 'Bob')); // Builder rebuilds
/// ```
///
/// Use [autoDispose] to clean up the Joker automatically on removal.
///
/// With CircusRing:
/// ```dart
/// final userJoker = Circus.spotlight<UserData>(tag: 'user');
///
/// JokerFrame<UserData, String>(
///   joker: userJoker,
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Hello $name'),
/// );
/// ```
class JokerFrame<T, S> extends StatefulWidget {
  /// Creates a JokerFrame that only rebuilds when the selected value changes.
  ///
  /// The [selector] should return a derived value from the Joker state to watch.
  /// The [builder] will be run only when this selected value changes.
  const JokerFrame({
    super.key,
    required this.joker,
    required this.selector,
    required this.builder,
  });

  /// Joker instance to observe.
  final Joker<T> joker;

  /// Selector function to extract the sub-state to monitor.
  final JokerFrameSelector<T, S> selector;

  /// Builder called when the selected value changes.
  final JokerFrameBuilder<S> builder;

  @override
  State<JokerFrame<T, S>> createState() => _JokerFrameState<T, S>();
}

/// Internal state class for [JokerFrame].
class _JokerFrameState<T, S> extends State<JokerFrame<T, S>> {
  /// The currently selected value.
  late S selected;

  /// Called by Joker when state changes. Updates the selected value
  /// and rebuilds if it changed.
  void _onChange() {
    final newSelected = widget.selector(widget.joker.state);
    if (newSelected != selected) {
      setState(() {
        selected = newSelected;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selected = widget.selector(widget.joker.state);
    widget.joker.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.joker.removeListener(_onChange);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, selected);
  }
}
