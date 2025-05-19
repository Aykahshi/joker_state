import 'package:flutter/widgets.dart';

import '../rx_interface/rx_effect.dart';
import 'joker.dart';

/// Extension methods on Joker to support side-effect listeners.
/// Usage:
/// ```dart
/// final joker = Joker<int>(0);
/// joker.effect(
///   child: Container(),
///   effect: (context, state) {
///     print('State changed: $state');
///   },
///   runOnInit: true,
///   effectWhen: (prev, val) => (prev!.value ~/ 5) != (val.value ~/ 5),
/// );
/// ```
extension JokerEffectExtension<T> on Joker<T> {
  /// Runs side effects when the state changes instead of rebuilding UI.
  /// Returns a StatefulWidget that handles the subscription lifecycle.
  Widget effect({
    required Widget child,
    required RxListener<T> effect,
    RxListenCondition<T>? effectWhen,
    bool runOnInit = true,
  }) {
    return RxEffect<T>(
      rx: this,
      effect: effect,
      effectWhen: effectWhen,
      runOnInit: runOnInit,
      child: child,
    );
  }
}
