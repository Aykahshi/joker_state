// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';

import 'joker_portal.dart';

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
///   tag: 'counter',
///   builder: (context, count) => Text('$count'),
/// )
/// ```
@Deprecated(
    'Joker State is aim to be manage Presenter/Joker by CircusRing, not recommended to use through context.')
class JokerCast<T> extends StatelessWidget {
  final JokerCastBuilder<T> builder;
  final String? tag;

  const JokerCast({
    super.key,
    required this.builder,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final joker = JokerPortal.of<T>(context, tag: tag);

    return AnimatedBuilder(
      animation: joker,
      builder: (context, _) => builder(context, joker.state),
    );
  }
}
