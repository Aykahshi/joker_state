import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// JokerPortal injects a [Joker<T>] into the widget tree.
///
/// Widgets below will be able to access the Joker using:
/// ```dart
/// JokerPortal.of<T>(context, tag: 'counter');
/// ```
///
/// This is useful for accessing a Joker from multiple places in the widget tree.
///
/// Example:
/// ```dart
/// final counterJoker = Joker<int>(0, tag: 'counter');
///
/// JokerPortal<int>(
///   tag: 'counter', //provide and unique tag
///   joker: counterJoker,
///   child: MaterialApp(
///     home: Scaffold(
///       body: JokerCast<int>(
///         tag: 'counter',
///         builder: (context, count) => Text('$count'),
///       ),
///     ),
///   ),
/// );
/// ```
class JokerPortal<T> extends InheritedNotifier<Joker<T>> {
  final String? tag;

  const JokerPortal({
    Key? key,
    required Joker<T> joker,
    required Widget child,
    this.tag,
  }) : super(key: key, notifier: joker, child: child);

  /// Find a Joker with a specific type and optional tag
  static Joker<T> of<T>(BuildContext context, {String? tag}) {
    if (tag == null) {
      /// find JokerPortal by type only, need to ensure you can get the correct Joker
      /// if you have multiple JokerPortals with the same type
      /// only use this if you know the type is unique
      /// e.g. JokerPortal<User> and JokerPortal<Product>
      final portal =
          context.dependOnInheritedWidgetOfExactType<JokerPortal<T>>();
      assert(portal != null, 'No JokerPortal<$T> found in context.');
      return portal!.notifier!;
    } else {
      /// find by both type and tag, correspond to Joker.tag
      /// you need to provide the same tag to both Joker and JokerPortal
      /// use this if Joker type is not unique
      /// e.g. JokerPortal<int> and JokerPortal<String>
      final portal = _findPortalByTag<T>(context, tag);
      assert(portal != null,
          'No JokerPortal<$T> with tag "$tag" found in context.');
      return portal!.notifier!;
    }
  }

  /// Try to find a Joker with specific type and optional tag
  static Joker<T>? maybeOf<T>(BuildContext context, {String? tag}) {
    if (tag == null) {
      return context
          .dependOnInheritedWidgetOfExactType<JokerPortal<T>>()
          ?.notifier;
    } else {
      return _findPortalByTag<T>(context, tag)?.notifier;
    }
  }

  /// Helper method to find a portal by tag
  static JokerPortal<T>? _findPortalByTag<T>(BuildContext context, String tag) {
    JokerPortal<T>? result;
    context.visitAncestorElements((element) {
      if (element.widget is JokerPortal<T>) {
        final portal = element.widget as JokerPortal<T>;
        if (portal.tag == tag) {
          result = portal;
          return false;
        }
      }
      return true;
    });
    return result;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! JokerPortal<T> || oldWidget.tag != tag;
  }
}

extension JokerContextX on BuildContext {
  Joker<T> joker<T>({String? tag}) => JokerPortal.of<T>(this, tag: tag);
}
