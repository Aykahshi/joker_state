import '../../di/circus_ring/src/circus_ring.dart';
import '../../di/circus_ring/src/circus_ring_exception.dart';
import '../joker_stage/joker_stage.dart';
import '../joker_troupe/joker_troupe.dart';
import 'joker.dart';

/// Extension for Joker to easily create a JokerStage widget
///
/// Provides a more fluent, builder-like API for creating JokerStage widgets
extension JokerStageExtension<T> on Joker<T> {
  /// Creates a JokerStage that watches the Joker changes
  ///
  /// [builder]: Function that builds UI based on the current Joker value
  /// [autoDispose]: Whether to automatically dispose the Joker when the widget is disposed
  ///
  /// Returns a JokerStage widget that rebuilds when this Joker's value changes
  JokerStage<T> perform(
    JokerStageBuilder<T> builder, {
    bool autoDispose = true,
  }) {
    return JokerStage<T>(
      joker: this,
      builder: builder,
      autoDispose: autoDispose,
    );
  }
}

/// Extension for List<Joker> to easily create a JokerTroupe widget
///
/// Provides a more fluent, builder-like API for creating JokerTroupe widgets
extension JokerTroupeExtension on List<Joker> {
  /// Creates a JokerTroupe that watches multiple Jokers and combines their values
  ///
  /// [converter]: Function that converts raw Joker values to a Record type T
  /// [builder]: Function that builds UI based on the combined Record value
  /// [autoDispose]: Whether to automatically dispose Jokers when the widget is disposed
  ///
  /// Returns a JokerTroupe widget that rebuilds when any of the Jokers' values change
  JokerTroupe<T> assemble<T extends Record>({
    required JokerTroupeConverter<T> converter,
    required JokerTroupeBuilder<T> builder,
    bool autoDispose = true,
  }) {
    return JokerTroupe<T>(
      jokers: this,
      converter: converter,
      builder: builder,
      autoDispose: autoDispose,
    );
  }
}

/// Extension to integrate Jokers with the CircusRing dependency injection system
///
/// Provides methods to create, retrieve, and dispose of Jokers through CircusRing
extension JokerRingExtension on CircusRing {
  /// Creates and registers a new auto-notify Joker in the CircusRing
  ///
  /// [initialValue]: Starting value for the Joker
  /// [tag]: Unique identifier for this Joker (required)
  ///
  /// Returns the created Joker instance
  /// Throws [CircusRingException] if tag is empty
  Joker<T> summon<T>(
    T initialValue, {
    required String tag,
  }) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'To avoid conflicts, Jokers must be registered with a unique tag. '
        'Use: Circus.summon<T>(tag: "unique_tag")',
      );
    }
    final joker = Joker<T>(initialValue);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Creates and registers a manually-notifying Joker in the CircusRing
  ///
  /// [initialValue]: Starting value for the Joker
  /// [tag]: Unique identifier for this Joker (required)
  ///
  /// Returns the created Joker instance
  /// Throws [CircusRingException] if tag is empty
  Joker<T> recruit<T>(
    T initialValue, {
    required String tag,
  }) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'To avoid conflicts, Jokers must be registered with a unique tag. '
        'Use: Circus.recruit<T>(tag: "unique_tag")',
      );
    }
    final joker = Joker<T>(initialValue, autoNotify: false);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Retrieves a registered Joker from the CircusRing
  ///
  /// [tag]: Unique identifier for the Joker to retrieve
  ///
  /// Returns the Joker instance if found
  /// Throws [CircusRingException] if tag is empty or Joker not found
  Joker<T> spotlight<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
          'All Jokers must be registered with a unique tag. '
          'Please add tag to spotlight a Joker.');
    }
    return find<Joker<T>>(tag);
  }

  /// Attempts to retrieve a registered Joker from the CircusRing
  ///
  /// [tag]: Unique identifier for the Joker to retrieve
  ///
  /// Returns the Joker instance if found, or null if not found
  Joker<T>? trySpotlight<T>({required String tag}) {
    return tryFind<Joker<T>>(tag);
  }

  /// Removes and disposes a registered Joker from the CircusRing
  ///
  /// [tag]: Unique identifier for the Joker to remove
  ///
  /// Returns true if the Joker was found and removed, false otherwise
  /// Throws [CircusRingException] if tag is empty
  bool vanish<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException(
          'All Jokers must be registered with a unique tag. '
          'Please add tag to vanish a Joker.');
    }
    return fire<Joker<T>>(tag: tag);
  }
}
