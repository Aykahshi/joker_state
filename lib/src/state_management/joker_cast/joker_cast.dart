import 'package:flutter/widgets.dart';

import '../joker_portal/joker_portal.dart';

/// Signature for a builder function inside a [JokerCast].
typedef JokerCastBuilder<T> = Widget Function(BuildContext context, T value);

/// A widget that listens to a provided [Joker<T>] from the widget tree
/// using [JokerPortal], and rebuilds when the state changes.
///
/// Similar to a Consumer in other systems.
///
/// Example:
/// ```dart
/// JokerCast<int>(
///   builder: (context, count) => Text('$count'),
/// )
/// ```
class JokerCast<T> extends StatelessWidget {
  final JokerCastBuilder<T> builder;

  const JokerCast({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final joker = JokerPortal.of<T>(context);

    return AnimatedBuilder(
      animation: joker,
      builder: (context, _) {
        return builder(context, joker.state);
      },
    );
  }
}
