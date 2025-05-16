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
/// final userJoker = Joker<UserData>(UserData(name: 'Alice', age: 20));
///
/// userJoker.focusOn<String>(
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
/// ```
class JokerFrame<T, S> extends StatefulWidget {
  /// Creates a JokerFrame that only rebuilds when the selected value changes.
  ///
  /// The [selector] should return a derived value from the Joker state to watch.
  /// The [builder] will be run only when this selected value changes.
  const JokerFrame._({
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
    final newSelected = widget.selector(widget.joker.value);
    if (newSelected != selected) {
      setState(() {
        selected = newSelected;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selected = widget.selector(widget.joker.value);
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

/// Extension for Joker to easily create a [JokerFrame] widget.
///
/// Similar to [perform], but allows selective listening using a [selector]
/// function. Only when the selector's return value changes (`==` comparison)
/// will the widget rebuild.
///
/// Useful for optimizing UI updates.
///
/// Example:
/// ```dart
/// final userJoker = Joker<User>(User(name: 'Alice', age: 20));
///
/// userJoker.observe<String>(
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Hi $name'),
/// );
/// ```
///
/// Note: The `autoDispose` parameter has been removed as Joker now manages
/// its own lifecycle based on listeners and the `keepAlive` flag.
extension JokerFrameExtension<T> on Joker<T> {
  /// Creates a [JokerFrame] that focuses on a selected portion of the Joker state.
  ///
  /// [selector]: Function to extract the slice of state to observe.
  /// [builder]: Function called when the selected value changes.
  /// [autoDispose]: Whether to automatically dispose the Joker when removed.
  /// The Joker now manages its own lifecycle. This parameter is removed.
  ///
  /// Returns a [JokerFrame] widget that only rebuilds when selector result changes.
  JokerFrame<T, S> focusOn<S>({
    Key? key,
    required JokerFrameSelector<T, S> selector,
    required JokerFrameBuilder<S> builder,
  }) {
    return JokerFrame<T, S>._(
      key: key,
      joker: this,
      selector: selector,
      builder: builder,
    );
  }
}
