import 'package:flutter/widgets.dart';

import '../../di/circus_ring/src/circus_ring.dart';
import '../joker_deck/joker_deck.dart';
import '../joker_hand/joker_hand.dart';
import 'joker_card.dart';

extension JokerCardToBox<T> on JokerCard<T> {
  /// Creates a ValueListenableBuilder that rebuilds when the JokerCard changes
  JokerHand<T> reveal(
    JokerHandBuilder<T> builder, {
    bool autoDispose = true,
    Widget? child,
  }) {
    return JokerHand<T>(
      joker: this,
      builder: builder,
      autoDispose: autoDispose,
      child: child,
    );
  }
}

/// extension methods for cleaner usage
extension PokerTableExtension on List<JokerCard> {
  JokerDeck onDeck({
    required JokerDeckBuilder builder,
    Widget? child,
  }) {
    return JokerDeck(
      cards: this,
      builder: builder,
      child: child,
    );
  }
}

/// Extension to get JokerCards from CircusRing with auto-disposal
/// Tag is required to avoid conflicts if multiple cards are registered
extension JokerCardExtension on CircusRing {
  /// Register a JokerCard that will be automatically disposed when CircusRing is cleared
  JokerCard<T> putCard<T>(
    T initialValue, {
    required String tag,
    bool stopped = false,
  }) {
    final card = JokerCard<T>(initialValue, stopped: stopped);
    put<JokerCard<T>>(card, tag: tag);
    return card;
  }

  /// Find a JokerCard
  JokerCard<T> drawCard<T>({required String tag}) {
    return find<JokerCard<T>>(tag);
  }

  /// Try to find a JokerCard
  JokerCard<T>? tryDrawCard<T>({required String tag}) {
    return tryFind<JokerCard<T>>(tag);
  }

  /// Delete a JokerCard
  bool discard<T>({required String tag}) {
    return delete<JokerCard<T>>(tag: tag);
  }
}
