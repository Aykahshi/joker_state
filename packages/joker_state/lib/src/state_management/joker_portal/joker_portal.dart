import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// JokerPortal injects a [Joker<T>] into the widget tree.
///
/// Makes the provided [joker] accessible to descendant widgets via
/// `JokerPortal.of<T>(context)` or the `context.joker<T>()` extension.
///
/// **⚠️ Important:** When using common types like `int`, `String`, or even
/// generic types like `List<String>`, multiple `JokerPortal` instances with the
/// same type `T` might exist in the widget tree. In such cases, you **MUST**
/// provide a unique [tag] to both the `JokerPortal` and when looking it up
/// (`JokerPortal.of<T>(context, tag: 'your_unique_tag')`) to ensure you
/// retrieve the correct instance.
///
/// If the type `T` is guaranteed to be unique within the relevant widget subtree
/// (e.g., a specific `UserProfile` class), the [tag] can be omitted.
///
/// Example:
/// ```dart
/// // Unique type - tag might be optional
/// final userJoker = Joker<UserProfile>(UserProfile());
/// JokerPortal<UserProfile>(joker: userJoker, child: ...);
/// // Access: JokerPortal.of<UserProfile>(context)
///
/// // Common type - tag is REQUIRED
/// final counterJoker = Joker<int>(0);
/// final timerJoker = Joker<int>(60);
///
/// Column(
///   children: [
///     JokerPortal<int>(
///       tag: 'counter', // Unique tag for counter
///       joker: counterJoker,
///       child: CounterDisplay(),
///     ),
///     JokerPortal<int>(
///       tag: 'timer', // Unique tag for timer
///       joker: timerJoker,
///       child: TimerDisplay(),
///     ),
///   ],
/// )
///
/// // Accessing counter:
/// // JokerPortal.of<int>(context, tag: 'counter')
/// // context.joker<int>(tag: 'counter')
///
/// // Accessing timer:
/// // JokerPortal.of<int>(context, tag: 'timer')
/// ```
@Deprecated(
    'Joker State is aim to be manage Presenter/Joker by CircusRing, not recommended to use through context.')
class JokerPortal<T> extends InheritedNotifier<Joker<T>> {
  /// An optional, unique tag used to differentiate `JokerPortal` instances
  /// with the same generic type `T` within the widget tree.
  /// See the class documentation for usage details.
  final String? tag;

  const JokerPortal({
    super.key,
    required Joker<T> joker,
    required super.child,
    this.tag,
  }) : super(notifier: joker);

  /// Finds the nearest ancestor `JokerPortal<T>` widget and returns its [Joker].
  ///
  /// - If [tag] is provided, it searches for a `JokerPortal<T>` whose `tag`
  ///   property matches the provided [tag]. This is **essential** when multiple
  ///   portals of the same type `T` exist.
  /// - If [tag] is `null`, it finds the nearest `JokerPortal<T>` regardless of tag.
  ///   **Warning:** Only use `tag: null` if you are certain that `T` is unique
  ///   in the relevant widget subtree, otherwise you might retrieve the wrong Joker.
  ///
  /// Throws an assertion error if no matching `JokerPortal` is found.
  /// For a non-throwing version, see [maybeOf].
  static Joker<T> of<T>(BuildContext context, {String? tag}) {
    Joker<T>? joker;
    String errorMessage;

    if (tag == null) {
      // --- Ambiguity Check --- Find ALL portals of type T
      final allPortals = _findAllPortalsOfType<T>(context);
      if (allPortals.length > 1) {
        // Ambiguous case: Multiple portals found without a tag
        errorMessage = 'Found multiple JokerPortal<$T> widgets in ancestors. ';
        errorMessage +=
            'You must provide a unique `tag` to JokerPortal.of<$T>() ';
        errorMessage += 'to identify which Joker instance you want.';
        assert(false, errorMessage);
        // The assert(false) will throw in debug mode.
        // In release mode, we might fall through, so throw explicitly.
        throw FlutterError(errorMessage);
      } else if (allPortals.isNotEmpty) {
        // Found exactly one portal, establish dependency on it
        final portal = allPortals.first;
        final element =
            context.getElementForInheritedWidgetOfExactType<JokerPortal<T>>();
        if (element != null) {
          context.dependOnInheritedElement(element);
        }
        joker = portal.notifier;
      }
      // If allPortals is empty, joker remains null, handled by assert below

      errorMessage = 'No JokerPortal<$T> found in context. ';
      // Add hint if type might be common
      if (T == int ||
          T == String ||
          T == bool ||
          T == double ||
          T.toString().startsWith('List<') ||
          T.toString().startsWith('Map<')) {
        errorMessage +=
            'Type $T is common. Did you forget to provide a unique `tag` when creating JokerPortal and calling JokerPortal.of?';
      } else {
        errorMessage +=
            'Ensure a JokerPortal<$T> exists above this widget in the tree.';
      }
    } else {
      // --- Tagged Lookup --- Find specific portal by tag
      final portal = _findPortalByTag<T>(context, tag);
      joker = portal?.notifier;
      errorMessage =
          'No JokerPortal<$T> with tag "$tag" found in context. Ensure a JokerPortal<$T> with this exact tag exists above this widget.';
    }

    // Final check: Ensure a joker was actually found (either tagged or unambiguous untagged)
    assert(joker != null, errorMessage);
    return joker!;
  }

  /// Finds the nearest ancestor `JokerPortal<T>` widget and returns its [Joker],
  /// or `null` if not found or if multiple untagged portals exist (ambiguity).
  ///
  /// Use this if the Joker might not be present or if ambiguity should result in null.
  /// See [of] for details on using the [tag].
  static Joker<T>? maybeOf<T>(BuildContext context, {String? tag}) {
    if (tag == null) {
      // --- Ambiguity Check --- Find ALL portals of type T
      final allPortals = _findAllPortalsOfType<T>(context);
      if (allPortals.length > 1) {
        // Ambiguous case: Return null
        return null;
      } else if (allPortals.isNotEmpty) {
        // Found exactly one portal, establish dependency and return notifier
        final element =
            context.getElementForInheritedWidgetOfExactType<JokerPortal<T>>();
        if (element != null) {
          context.dependOnInheritedElement(element);
        }
        return allPortals.first.notifier;
      }
      // No portals found
      return null;
    } else {
      // --- Tagged Lookup ---
      return _findPortalByTag<T>(context, tag)?.notifier;
    }
  }

  /// Helper method to find a portal by tag by walking up the element tree.
  /// Establishes a dependency on the found element.
  static JokerPortal<T>? _findPortalByTag<T>(BuildContext context, String tag) {
    JokerPortal<T>? result;
    // visitAncestorElements is the standard way to walk up the tree.
    // The return value ('found') is not needed here.
    context.visitAncestorElements((element) {
      // Check if the current element's widget is the type we're looking for.
      if (element.widget is JokerPortal<T>) {
        final portal = element.widget as JokerPortal<T>;
        if (portal.tag == tag) {
          // Found the portal, now establish dependency
          // Check if the element is an InheritedElement before depending on it
          if (element is InheritedElement) {
            context.dependOnInheritedElement(element);
          } else {
            // This case should technically not happen for InheritedNotifier based widgets,
            // but added for robustness. Fallback to type dependency.
            context.dependOnInheritedWidgetOfExactType<JokerPortal<T>>();
          }
          result = portal;
          return false; // Stop visiting
        }
      }
      return true; // Continue visiting
    });
    return result;
  }

  /// Helper function to find all ancestor portals of a specific type T
  static List<JokerPortal<T>> _findAllPortalsOfType<T>(BuildContext context) {
    final List<JokerPortal<T>> portals = [];
    context.visitAncestorElements((element) {
      if (element.widget is JokerPortal<T>) {
        portals.add(element.widget as JokerPortal<T>);
      }
      return true; // Continue visiting
    });
    return portals;
  }

  @override
  bool updateShouldNotify(covariant JokerPortal<T> oldWidget) {
    // Notify if the Joker instance itself changes OR if the tag changes
    // (though changing the tag on an existing portal is less common).
    return notifier != oldWidget.notifier || tag != oldWidget.tag;
  }
}

/// Extension on [BuildContext] for convenient access to Jokers via [JokerPortal].
extension JokerContextX on BuildContext {
  /// Shortcut for `JokerPortal.of<T>(context, tag: tag)`.
  ///
  /// **Warning:** Remember to provide the [tag] if multiple `JokerPortal`
  /// instances with the same type `T` might exist. See [JokerPortal.of].
  Joker<T> joker<T>({String? tag}) => JokerPortal.of<T>(this, tag: tag);

  /// Shortcut for `JokerPortal.maybeOf<T>(context, tag: tag)`.
  Joker<T>? maybeJoker<T>({String? tag}) =>
      JokerPortal.maybeOf<T>(this, tag: tag);
}
