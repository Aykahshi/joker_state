import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';

/// A builder that receives a selected slice of a [JokerAct]'s state.
typedef JokerFrameBuilder<S> = Widget Function(
  BuildContext context,
  S selected,
);

/// A function that selects a slice of state [S] from a full state [T].
typedef JokerFrameSelector<T, S> = S Function(T state);

/// A widget that observes a derived slice of a [JokerAct]'s state.
///
/// [JokerFrame] is an optimization tool. It listens to a [JokerAct] but only
/// rebuilds its UI when a specific part of the state, extracted by the
/// [selector], changes.
///
/// This is useful for preventing unnecessary rebuilds when a widget only cares
/// about a small portion of a larger state object.
///
/// {@tool snippet}
/// ### Direct Instantiation
///
/// ```dart
/// class User {
///   final String name;
///   final int age;
///   User({required this.name, required this.age});
/// }
///
/// final userAct = Joker<User>(User(name: 'Alice', age: 30));
///
/// class UserNameDisplay extends StatelessWidget {
///   const UserNameDisplay({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // This widget will only rebuild when the user's name changes.
///     return JokerFrame<User, String>(
///       act: userAct,
///       selector: (user) => user.name,
///       builder: (context, name) {
///         return Text('Name: $name');
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using the `.focusOn()` Extension
///
/// ```dart
/// // In your build method:
/// userAct.focusOn<String>(
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Name: $name'),
/// );
/// ```
/// {@end-tool}
class JokerFrame<T, S> extends StatefulWidget {
  /// Creates a [JokerFrame] that rebuilds only when the selected value changes.
  const JokerFrame({
    super.key,
    required this.act,
    required this.selector,
    required this.builder,
  });

  /// The [JokerAct] instance to observe.
  final JokerAct<T> act;

  /// A function to extract the slice of state to observe.
  /// The widget only rebuilds if the value returned by this function changes.
  final JokerFrameSelector<T, S> selector;

  /// The builder function that is called when the selected value changes.
  final JokerFrameBuilder<S> builder;

  @override
  State<JokerFrame<T, S>> createState() => _JokerFrameState<T, S>();
}

class _JokerFrameState<T, S> extends State<JokerFrame<T, S>> {
  late S _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selector(widget.act.value);
    widget.act.addListener(_onStateChange);
  }

  @override
  void didUpdateWidget(JokerFrame<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.act != oldWidget.act) {
      oldWidget.act.removeListener(_onStateChange);
      _selected = widget.selector(widget.act.value);
      widget.act.addListener(_onStateChange);
    }
  }

  @override
  void dispose() {
    widget.act.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    final newSelected = widget.selector(widget.act.value);
    if (_selected != newSelected) {
      setState(() {
        _selected = newSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selected);
  }
}


