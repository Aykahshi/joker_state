import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// JokerPortal injects a [Joker<T>] into the widget tree.
///
/// Widgets below will be able to access the Joker using:
/// ```dart
/// JokerPortal.of<T>(context);
/// ```
class JokerPortal<T> extends InheritedNotifier<Joker<T>> {
  const JokerPortal({
    Key? key,
    required Joker<T> joker,
    required Widget child,
  }) : super(key: key, notifier: joker, child: child);

  /// Finds the nearest JokerPortal in the context.
  ///
  /// Note: this subscribes the widget to changes.
  static Joker<T> of<T>(BuildContext context) {
    final portal = context.dependOnInheritedWidgetOfExactType<JokerPortal<T>>();
    assert(portal != null, 'No JokerPortal<$T> found in context.');
    return portal!.notifier!;
  }

  /// Tries to find, but returns null if not found.
  static Joker<T>? maybeOf<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<JokerPortal<T>>()
        ?.notifier;
  }
}

extension JokerContextX on BuildContext {
  Joker<T> joker<T>() => JokerPortal.of<T>(this);
}
