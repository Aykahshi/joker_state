import 'package:flutter/widgets.dart';

import '../foundation/joker_act.dart';

/// A builder function that receives the full state from a [JokerAct].
typedef JokerStageBuilder<T> = Widget Function(
  BuildContext context,
  T state,
);

/// A widget that listens to a [JokerAct] and rebuilds whenever the state changes.
///
/// [JokerStage] is the most direct way to bind a state object's value to the UI.
/// It rebuilds on every notification, providing the entire state object to the
/// [builder].
///
/// For more optimized rebuilds based on a slice of the state, consider using
/// [JokerFrame].
///
/// {@tool snippet}
/// ### Direct Instantiation
///
/// ```dart
/// final counterAct = Joker<int>(0); // Can be a Joker or a Presenter
///
/// class CounterText extends StatelessWidget {
///   const CounterText({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return JokerStage<int>(
///       joker: counterAct,
///       builder: (context, count) {
///         return Text('Count: $count');
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using the `.perform()` Extension
///
/// For a more fluent syntax, you can use the [perform] extension method on any
/// [JokerAct] instance (like a [Joker] or [Presenter]) directly inside your
/// build method.
///
/// ```dart
/// final counterAct = Joker<int>(0);
///
/// // Inside a build method:
/// counterAct.perform(
///   builder: (context, count) => Text('Count: $count'),
/// );
/// ```
/// {@end-tool}
class JokerStage<T> extends StatelessWidget {
  /// Creates a [JokerStage] that rebuilds when the [act] notifies listeners.
  const JokerStage({
    super.key,
    required this.act,
    required this.builder,
  });

  /// The [JokerAct] instance to listen to.
  final JokerAct<T> act;

  /// The builder function that rebuilds when the state changes.
  final JokerStageBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: act,
      builder: (context, _) => builder(context, act.value),
    );
  }
}


