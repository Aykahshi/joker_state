import 'package:circus_ring/circus_ring.dart';
import 'package:flutter/widgets.dart';

import '../joker_troupe/joker_troupe.dart';
import 'joker.dart';

/// Extension for List of Jokers to quickly create a [JokerTroupe] widget.
///
/// Allows merging multiple Jokers into a single Record via [converter] and
/// building UI accordingly.
///
/// This encourages strong-typed scoped state selection using Dart Records.
///
/// Example:
/// ```dart
/// final name = Joker<String>('Alice');
/// final age = Joker<int>(20);
/// final active = Joker<bool>(true);
///
/// typedef UserRecord = (String, int, bool);
///
/// [name, age, active].assemble<UserRecord>(
///   converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
///   builder: (context, user) {
///     final (name, age, active) = user;
///     return Text('$name | $age | $active');
///   },
/// );
/// ```
///
/// Note: The `autoDispose` parameter has been removed as Joker now manages
/// its own lifecycle based on listeners and the `keepAlive` flag.
extension JokerTroupeExtension on List<Joker> {
  /// Creates a [JokerTroupe] widget from this list of Jokers.
  ///
  /// [converter]: Maps the dynamic list of Joker values into a Dart Record of type [T].
  /// [builder]: Receives the typed [T] and builds a widget based on combined state.
  /// [autoDispose]: Whether to automatically dispose Jokers on widget removal.
  /// The Joker now manages its own lifecycle. This parameter is removed.
  ///
  /// Returns a [JokerTroupe] widget.
  JokerTroupe<T> assemble<T extends Record>({
    Key? key,
    required JokerTroupeConverter<T> converter,
    required JokerTroupeBuilder<T> builder,
  }) {
    return JokerTroupe<T>(
      key: key,
      jokers: this,
      converter: converter,
      builder: builder,
    );
  }
}

/// Extension methods to integrate Jokers with [CircusRing] for dependency injection.
///
/// Provides easy summon/recruit/spotlight/vanish operation for Jokers
/// using tags (string keys) registered within the global CircusRing.
///
/// This design allows runtime Joker registration and central management without
/// passing around instances manually.
///
/// Example:
/// ```dart
/// Circus.summon<int>(0, tag: 'counter');
/// final counter = Circus.spotlight<int>(tag: 'counter');
/// counter.trick(1);
/// ```
extension JokerRingExtension on CircusRing {
  /// Registers a new auto-notify Joker in the [CircusRing].
  ///
  /// [initialValue]: Starting value for the Joker.
  /// [tag]: Globally unique tag used to identify this Joker.
  /// [keepAlive]: If true, prevents automatic disposal when listeners drop to zero.
  ///
  /// Throws [CircusRingException] if the tag is empty.
  @Deprecated(
      'CircusRing is split package now, and Joker should only be used for local variables.')
  Joker<T> summon<T>(
    T initialValue, {
    required String tag,
    bool keepAlive = false,
  }) {
    final existingJoker = trySpotlight<T>(tag: tag);
    if (existingJoker != null) {
      return existingJoker;
    }

    final joker = Joker<T>(initialValue, keepAlive: keepAlive, tag: tag);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Registers a manual Joker (non-autoNotify) into the [CircusRing].
  ///
  /// Same as [summon] but requires manual [Joker.yell] to trigger listeners.
  /// [keepAlive]: If true, prevents automatic disposal when listeners drop to zero.
  ///
  /// Throws [CircusRingException] if the tag is empty.
  @Deprecated(
      'CircusRing is split package now, and Joker should only be used for local variables.')
  Joker<T> recruit<T>(
    T initialValue, {
    required String tag,
    bool keepAlive = false,
  }) {
    final existingJoker = trySpotlight<T>(tag: tag);
    if (existingJoker != null) {
      return existingJoker;
    }

    final joker = Joker<T>(initialValue,
        autoNotify: false, keepAlive: keepAlive, tag: tag);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Finds a registered Joker by [tag] from [CircusRing].
  ///
  /// [tag]: Unique identifier used when [summon] or [recruit] was called.
  ///
  /// Throws [CircusRingException] if Joker not found or tag is empty.
  @Deprecated(
      'CircusRing is split package now, and Joker should only be used for local variables.')
  Joker<T> spotlight<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'All Jokers must be registered with a unique tag.\n'
        'Please provide tag when calling Circus.spotlight<T>(tag: "...")',
      );
    }

    return find<Joker<T>>(tag);
  }

  /// Tries to find a registered Joker safely by [tag].
  ///
  /// Returns null if not found instead of throwing exception.
  @Deprecated(
      'CircusRing is split package now, and Joker should only be used for local variables.')
  Joker<T>? trySpotlight<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'All Jokers must be registered with a unique tag.\n'
        'Please provide tag when calling Circus.trySpotlight<T>(tag: "...")',
      );
    }

    return tryFind<Joker<T>>(tag);
  }

  /// Removes and potentially disposes the Joker tied to [tag].
  ///
  /// This method removes the Joker instance from the CircusRing registry.
  /// If the Joker has `keepAlive` set to false and no other listeners exist
  /// (after being removed from the registry which might hold the last reference indirectly),
  /// it might trigger its auto-dispose logic.
  ///
  /// Returns true if the Joker was found and removed from the registry, false otherwise.
  ///
  /// Throws [CircusRingException] if tag is empty.
  @Deprecated(
      'CircusRing is split package now, and Joker should only be used for local variables.')
  bool vanish<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'All Jokers must be registered with a unique tag to be vanished.\n'
        'Please provide a tag for vanish<T>(tag: "...")',
      );
    }

    return fire<Joker<T>>(tag: tag);
  }
}
