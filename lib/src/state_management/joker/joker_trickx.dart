import 'package:flutter/widgets.dart';

import '../../di/circus_ring/src/circus_ring.dart';
import '../../di/circus_ring/src/circus_ring_exception.dart';
import '../joker_frame/joker_frame.dart';
import '../joker_stage/joker_stage.dart';
import '../joker_troupe/joker_troupe.dart';
import 'joker.dart';

/// Extension for Joker to easily create a [JokerStage] widget.
///
/// Provides a more fluent, builder-like API for creating [JokerStage]s
/// without explicitly wrapping it in widget constructors.
///
/// This is ideal when you want the entire Joker state to trigger the rebuild.
///
/// Example:
/// ```dart
/// final counter = Joker<int>(0);
///
/// // Wrap with perform
/// counter.perform(
///   builder: (context, count) => Text('$count'),
/// );
/// ```
extension JokerStageExtension<T> on Joker<T> {
  /// Creates a [JokerStage] that watches the entire state changes of this Joker.
  ///
  /// The [builder] will be rebuilt whenever this Joker calls notifyListeners().
  ///
  /// [autoDispose]: Whether to automatically remove/dispose the Joker when the widget is removed.
  ///
  /// Returns a [JokerStage] widget.
  JokerStage<T> perform({
    Key? key,
    required JokerStageBuilder<T> builder,
    bool autoDispose = true,
  }) {
    return JokerStage<T>(
      key: key,
      joker: this,
      builder: builder,
      autoDispose: autoDispose,
    );
  }
}

/// Extension for Joker to easily create a [JokerFrame] widget.
///
/// Similar to [perform], but allows selective listening using a [selector]
/// function. Only when the selector's return value changes (`==` comparison)
/// will the widget rebuild.
///
/// Useful for optimizing UI updates.
///
/// Example:
/// ```dart
/// final userJoker = Joker<User>(User(name: 'Alice', age: 20));
///
/// userJoker.observe<String>(
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Hi $name'),
/// );
/// ```
extension JokerFrameExtension<T> on Joker<T> {
  /// Creates a [JokerFrame] that observes a selected portion of the Joker state.
  ///
  /// [selector]: Function to extract the slice of state to observe.
  /// [builder]: Function called when the selected value changes.
  /// [autoDispose]: Whether to automatically dispose the Joker when removed.
  ///
  /// Returns a [JokerFrame] widget that only rebuilds when selector result changes.
  JokerFrame<T, S> observe<S>({
    Key? key,
    required JokerFrameSelector<T, S> selector,
    required JokerFrameBuilder<S> builder,
    bool autoDispose = true,
  }) {
    return JokerFrame<T, S>(
      key: key,
      joker: this,
      selector: selector,
      builder: builder,
      autoDispose: autoDispose,
    );
  }
}

/// Extension for List<Joker> to quickly create a [JokerTroupe] widget.
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
extension JokerTroupeExtension on List<Joker> {
  /// Creates a [JokerTroupe] widget from this list of Jokers.
  ///
  /// [converter]: Maps the dynamic list of Joker values into a Dart Record of type [T].
  /// [builder]: Receives the typed [T] and builds a widget based on combined state.
  /// [autoDispose]: Whether to automatically dispose Jokers on widget removal.
  ///
  /// Returns a [JokerTroupe] widget.
  JokerTroupe<T> assemble<T extends Record>({
    Key? key,
    required JokerTroupeConverter<T> converter,
    required JokerTroupeBuilder<T> builder,
    bool autoDispose = true,
  }) {
    return JokerTroupe<T>(
      key: key,
      jokers: this,
      converter: converter,
      builder: builder,
      autoDispose: autoDispose,
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
  ///
  /// Throws [CircusRingException] if the tag is empty.
  Joker<T> summon<T>(
    T initialValue, {
    required String tag,
  }) {
    final joker = Joker<T>(initialValue);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Registers a manual Joker (non-autoNotify) into the [CircusRing].
  ///
  /// Same as [summon] but requires manual [yell()] to trigger listeners.
  ///
  /// Throws [CircusRingException] if the tag is empty.
  Joker<T> recruit<T>(
    T initialValue, {
    required String tag,
  }) {
    final joker = Joker<T>(initialValue, autoNotify: false);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Finds a registered Joker by [tag] from [CircusRing].
  ///
  /// [tag]: Unique identifier used when [summon] or [recruit] was called.
  ///
  /// Throws [CircusRingException] if Joker not found or tag is empty.
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
  Joker<T>? trySpotlight<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'All Jokers must be registered with a unique tag.\n'
        'Please provide tag when calling Circus.trySpotlight<T>(tag: "...")',
      );
    }
    
    return tryFind<Joker<T>>(tag);
  }

  /// Removes and disposes the Joker tied to [tag].
  ///
  /// Returns true if successful, false if tag not found.
  ///
  /// Throws [CircusRingException] if tag is empty.
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
