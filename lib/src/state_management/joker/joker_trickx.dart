import 'package:flutter/widgets.dart';

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
    Widget? child,
  }) {
    return JokerStage<T>(
      joker: this,
      builder: builder,
      autoDispose: autoDispose,
      child: child,
    );
  }
}

/// extension methods for cleaner usage
extension JokerTroupeExtension on List<Joker> {
  JokerTroupe assemble({
    required JokerTroupeBuilder builder,
    Widget? child,
  }) {
    return JokerTroupe(
      jokers: this,
      builder: builder,
      child: child,
    );
  }
}

/// Extension to get Jokers from CircusRing with auto-disposal
/// Tag is required to avoid conflicts if multiple cards are registered
extension JokerRingExtension on CircusRing {
  /// Summon a Joker to the CircusRing
  Joker<T> summon<T>(
    T initialValue, {
    required String tag,
    bool stopped = false,
  }) {
    if (tag.isEmpty) {
      throw CircusRingException(
        'To avoid conflicts, Jokers must be summoned with a unique tag.'
        'Use: Circus.summon<T>(tag: "unique_tag")',
      );
    }
    final joker = Joker<T>(initialValue, stopped: stopped);
    hire<Joker<T>>(joker, tag: tag);
    return joker;
  }

  /// Spotlight a Joker from the CircusRing
  Joker<T> spotlight<T>({required String tag}) {
    return find<Joker<T>>(tag);
  }

  /// Try Spotlight a Joker (nullable)
  Joker<T>? trySpotlight<T>({required String tag}) {
    return tryFind<Joker<T>>(tag);
  }

  /// Vanish a Joker from the CircusRing
  bool vanish<T>({required String tag}) {
    return fire<Joker<T>>(tag: tag);
  }
}
