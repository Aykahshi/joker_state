import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';

/// A builder that constructs a widget based on the [Joker]'s state.
typedef JokerRehearseBuilder<T> = Widget Function(
    BuildContext context, T state);

/// A callback to perform a side effect in response to a state change.
typedef JokerRehearseCallback<T> = void Function(BuildContext context, T state);

/// A condition that determines if a builder or callback should be executed.
typedef JokerRehearseCondition<T> = bool Function(T? previous, T current);

/// A widget that combines UI building and side effects in response to state changes.
///
/// [JokerRehearse] is analogous to `BlocConsumer` in the BLoC library. It listens
/// to a [JokerAct] and allows you to provide both a [builder] function to rebuild
/// the UI and an [onStateChange] callback to perform side effects.
///
/// This is useful for reducing boilerplate when you need to both update the UI
/// and trigger an action (like showing a snackbar or navigating) from the same
/// state change.
///
/// You can control when the builder and callback are executed independently using
/// the [performWhen] and [watchWhen] conditions, respectively.
///
/// {@tool snippet}
/// ### Direct Instantiation
///
/// ```dart
/// final counterAct = Joker<int>(0);
///
/// class CounterFeedback extends StatelessWidget {
///   const CounterFeedback({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return JokerRehearse<int>(
///       act: counterAct,
///       // Rebuild the Text widget on every state change.
///       builder: (context, count) => Text('Count: $count'),
///       // Show a snackbar only when the count is a multiple of 5.
///       watchWhen: (prev, curr) => (prev != curr) && (curr % 5 == 0),
///       onStateChange: (context, count) {
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(content: Text('Reached a multiple of 5: $count')),
///         );
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using the `.rehearse()` Extension
///
/// ```dart
/// // In your build method:
/// counterAct.rehearse(
///   builder: (context, count) => Text('Count: $count'),
///   onStateChange: (context, count) {
///     if (count % 10 == 0) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Count is a multiple of 10: $count')),
///       );
///     }
///   },
/// );
/// ```
/// {@end-tool}
class JokerRehearse<T> extends StatefulWidget {
  /// Creates a [JokerRehearse] widget.
  const JokerRehearse({
    super.key,
    required this.act,
    required this.builder,
    required this.onStateChange,
    this.performWhen,
    this.watchWhen,
    this.runOnBuild = false,
  });

  /// The [JokerAct] to listen to.
  final JokerAct<T> act;

  /// The builder function to create the widget.
  ///
  /// This is called when the widget is first built and whenever [performWhen]
  /// evaluates to `true`.
  final JokerRehearseBuilder<T> builder;

  /// The callback for side effects.
  ///
  /// This is called whenever [watchWhen] evaluates to `true`.
  final JokerRehearseCallback<T> onStateChange;

  /// An optional condition to control when the [builder] is called.
  /// If omitted, the widget rebuilds on every state change.
  final JokerRehearseCondition<T>? performWhen;

  /// An optional condition to control when [onStateChange] is called.
  /// If omitted, the callback is executed on every state change.
  final JokerRehearseCondition<T>? watchWhen;

  /// If `true`, runs the [onStateChange] callback once when the widget is first built.
  final bool runOnBuild;

  @override
  State<JokerRehearse<T>> createState() => _JokerRehearseState<T>();
}

class _JokerRehearseState<T> extends State<JokerRehearse<T>> {
  @override
  void initState() {
    super.initState();
    widget.act.addListener(_onStateChange);

    if (widget.runOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onStateChange(context, widget.act.value);
        }
      });
    }
  }

  @override
  void didUpdateWidget(JokerRehearse<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.act != oldWidget.act) {
      oldWidget.act.removeListener(_onStateChange);
      widget.act.addListener(_onStateChange);
    }
  }

  @override
  void dispose() {
    widget.act.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;

    // Handle the side effect (watch).
    if (widget.watchWhen?.call(widget.act.previousValue, widget.act.value) ??
        true) {
      widget.onStateChange(context, widget.act.value);
    }

    // Handle the UI rebuild (perform).
    if (widget.performWhen?.call(widget.act.previousValue, widget.act.value) ??
        true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.act.value);
  }
}
