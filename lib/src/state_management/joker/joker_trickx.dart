import '../../di/circus_ring/src/circus_ring.dart';
import '../../di/circus_ring/src/circus_ring_exception.dart';
import '../joker_stage/joker_stage.dart';
import '../joker_troupe/joker_troupe.dart';
import 'joker.dart';

extension JokerStageExtension<T> on Joker<T> {
  /// Creates a JokerStage that watch the Joker changes
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

/// extension methods for cleaner usage
extension JokerTroupeExtension on List<Joker> {
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

/// Extension to get Jokers from CircusRing with auto-disposal
/// Tag is required to avoid conflicts if multiple cards are registered
extension JokerRingExtension on CircusRing {
  /// Summon a autoNotify Joker to the CircusRing
  Joker<T> summon<T>(
    T initialValue, {
    required String tag,
  }) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'To avoid conflicts, Jokers must be registered with a unique tag.'
        'Use: Circus.summon<T>(tag: "unique_tag")',
      );
    }
    final joker = Joker<T>(initialValue);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Register a Joker with manual notifications
  Joker<T> recruit<T>(
    T initialValue, {
    required String tag,
  }) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'To avoid conflicts, Jokers must be registered with a unique tag.'
        'Use: Circus.recruit<T>(tag: "unique_tag")',
      );
    }
    final joker = Joker<T>(initialValue, autoNotify: false);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Spotlight a Joker from the CircusRing
  Joker<T> spotlight<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException('All Jokers be registered with a unique tag.'
          'Please add tag to spotlight a Joker.');
    }
    return find<Joker<T>>(tag);
  }

  /// Try Spotlight a Joker (nullable)
  Joker<T>? trySpotlight<T>({required String tag}) {
    return tryFind<Joker<T>>(tag);
  }

  /// Vanish a Joker from the CircusRing
  bool vanish<T>({required String tag}) {
    if (tag.isEmpty) {
      throw CircusRingException('All Jokers be registered with a unique tag.'
          'Please add tag to vanish a Joker.');
    }
    return fire<Joker<T>>(tag: tag);
  }
}
