import 'package:flutter/widgets.dart';

/// A conditional widget that reveals one of two widgets based on [condition].
///
/// Use [JokerReveal] for direct widgets and [JokerReveal.lazy] for deferred construction.
///
/// Usage:
/// ```
/// JokerReveal(
///   condition: someBoolean,
///   whenTrue: Text("True"),
///   whenFalse: Text("False"),
/// )
/// JokerReveal.lazy(
///   condition: someBoolean,
///   whenTrueBuilder: (context) => Text("True"),
///   whenFalseBuilder: (context) => Text("False"),
/// )
/// ```
///
class JokerReveal extends StatelessWidget {
  final bool condition;
  final WidgetBuilder? whenTrueBuilder;
  final WidgetBuilder? whenFalseBuilder;
  final Widget? whenTrue;
  final Widget? whenFalse;

  const JokerReveal({
    super.key,
    required this.condition,
    required this.whenTrue,
    required this.whenFalse,
  })  : whenTrueBuilder = null,
        whenFalseBuilder = null;

  const JokerReveal.lazy({
    super.key,
    required this.condition,
    required this.whenTrueBuilder,
    required this.whenFalseBuilder,
  })  : whenTrue = null,
        whenFalse = null;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      if (whenTrueBuilder != null) return whenTrueBuilder!(context);
      return whenTrue!;
    } else {
      if (whenFalseBuilder != null) return whenFalseBuilder!(context);
      return whenFalse!;
    }
  }
}

extension JokerRevealExtension on bool {
  /// Extension to select one of two widgets based on this boolean.
  Widget reveal({
    Key? key,
    required Widget whenTrue,
    required Widget whenFalse,
  }) {
    return JokerReveal(
      key: key,
      condition: this,
      whenTrue: whenTrue,
      whenFalse: whenFalse,
    );
  }

  Widget lazyReveal({
    Key? key,
    required WidgetBuilder whenTrueBuilder,
    required WidgetBuilder whenFalseBuilder,
  }) {
    return JokerReveal.lazy(
      key: key,
      condition: this,
      whenTrueBuilder: whenTrueBuilder,
      whenFalseBuilder: whenFalseBuilder,
    );
  }
}
