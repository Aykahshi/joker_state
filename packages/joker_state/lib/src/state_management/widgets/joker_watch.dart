import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';

/// A callback that performs a side effect in response to a state change.
typedef JokerWatchCallback<T> = void Function(BuildContext context, T state);

/// A condition that determines whether the [JokerWatchCallback] should be called.
typedef JokerWatchCondition<T> = bool Function(T? previous, T current);

/// A widget that listens to a [JokerAct] to perform side effects without rebuilding.
///
/// [JokerWatch] is used to trigger actions like showing dialogs, snackbars, or
/// navigating in response to state changes, without causing the widget tree
/// below it to rebuild.
///
/// The [onStateChange] callback is executed whenever the [act] notifies its
/// listeners, subject to the optional [watchWhen] condition.
///
/// {@tool snippet}
/// ### Direct Instantiation
///
/// ```dart
/// final errorAct = Joker<String?>(null);
///
/// class ErrorHandler extends StatelessWidget {
///   const ErrorHandler({super.key, required this.child});
///
///   final Widget child;
///
///   @override
///   Widget build(BuildContext context) {
///     return JokerWatch<String?>(
///       act: errorAct,
///       onStateChange: (context, errorMessage) {
///         if (errorMessage != null) {
///           ScaffoldMessenger.of(context).showSnackBar(
///             SnackBar(content: Text(errorMessage)),
///           );
///         }
///       },
///       child: child,
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using the `.watch()` Extension
///
/// ```dart
/// // In your build method:
/// messageAct.watch(
///   onStateChange: (context, message) {
///     if (message.isNotEmpty) {
///       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
///     }
///   },
///   child: YourPageContent(),
/// );
/// ```
/// {@end-tool}
class JokerWatch<T> extends StatefulWidget {
  /// Creates a [JokerWatch] widget.
  const JokerWatch({
    super.key,
    required this.act,
    required this.onStateChange,
    this.watchWhen,
    this.runOnBuild = false,
    required this.child,
  });

  /// The [JokerAct] to listen to.
  final JokerAct<T> act;

  /// The child widget that this widget will render.
  final Widget child;

  /// The callback to execute when the state changes.
  final JokerWatchCallback<T> onStateChange;

  /// An optional condition to control when [onStateChange] is called.
  final JokerWatchCondition<T>? watchWhen;

  /// If `true`, runs the [onStateChange] callback once when the widget is first built.
  final bool runOnBuild;

  @override
  State<JokerWatch<T>> createState() => _JokerWatchState<T>();
}

class _JokerWatchState<T> extends State<JokerWatch<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.runOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onStateChange(context, widget.act.value);
        }
      });
    }
    widget.act.addListener(_listener);
  }

  @override
  void didUpdateWidget(JokerWatch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.act != oldWidget.act) {
      oldWidget.act.removeListener(_listener);
      widget.act.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.act.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted &&
        (widget.watchWhen?.call(widget.act.previousValue, widget.act.value) ??
            true)) {
      widget.onStateChange(context, widget.act.value);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


