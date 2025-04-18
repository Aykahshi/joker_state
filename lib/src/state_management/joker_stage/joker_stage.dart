import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';

/// Builder function for [JokerStage].
///
/// Provides the build context and the full state held by the Joker.
typedef JokerStageBuilder<T> = Widget Function(
  BuildContext context,
  T state,
);

/// JokerStage - A widget that observes a single Joker and rebuilds on full state changes.
///
/// This widget listens to an entire [Joker] instance and rebuilds whenever
/// the Joker notifies a change, using [Joker.notifyListeners()]. It provides
/// access to the full state object for straightforward UI updates.
///
/// This is ideal when you don't need partial/selective watching (use [JokerFrame] for that).
/// It also supports optional [autoDispose] that automatically removes the Joker from
/// [CircusRing] or calls .dispose() manually when this widget is removed from the tree.
///
/// Usage examples:
///
/// Basic usage:
/// ```dart
/// final counterJoker = Joker<int>(0);
///
/// JokerStage<int>(
///   joker: counterJoker,
///   builder: (context, count) => Text('Count: $count'),
/// );
/// ```
///
/// With internal Joker state updates:
/// ```dart
/// counterJoker.trick(1); // UI will rebuild automatically
/// ```
///
/// With CircusRing integration:
/// ```dart
/// // In setup/init
/// Circus.summon<int>(0, tag: 'counter');
///
/// // In your widget
/// final counterJoker = Circus.spotlight<int>(tag: 'counter');
///
/// JokerStage<int>(
///   joker: counterJoker,
///   builder: (context, count) => Text('Count: $count'),
/// );
/// ```
class JokerStage<T> extends StatefulWidget {
  /// Creates a JokerStage that rebuilds when the entire state of a Joker changes.
  ///
  /// The [builder] receives the current state and should return a widget.
  /// If [autoDispose] is true, the Joker is removed from the [CircusRing] or disposed when unmounted.
  /// The `autoDispose` parameter is removed, as Joker now manages its own lifecycle.
  const JokerStage({
    super.key,
    required this.joker,
    required this.builder,
  });

  /// The Joker instance to observe.
  final Joker<T> joker;

  /// The builder function that rebuilds on any state change.
  final JokerStageBuilder<T> builder;

  @override
  State<JokerStage<T>> createState() => _JokerStageState<T>();
}

/// Internal state object for [JokerStage].
class _JokerStageState<T> extends State<JokerStage<T>> {
  /// Current snapshot of the Joker's state.
  late T _state;

  /// Listener callback to update state and rebuild UI.
  void _updateState() {
    if (mounted) {
      setState(() {
        _state = widget.joker.state;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _state = widget.joker.state;
    widget.joker.addListener(_updateState);
  }

  @override
  void didUpdateWidget(JokerStage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.joker != oldWidget.joker) {
      oldWidget.joker.removeListener(_updateState);
      _state = widget.joker.state;
      widget.joker.addListener(_updateState);
    }
  }

  @override
  void dispose() {
    widget.joker.removeListener(_updateState);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}
