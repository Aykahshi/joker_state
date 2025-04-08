import 'package:flutter/widgets.dart';

import '../joker_deck/joker_deck.dart';
import '../joker_hand/joker_hand.dart';
import 'joker_card.dart';

extension JokerCardToBox<T> on JokerCard<T> {
  /// Creates a ValueListenableBuilder that rebuilds when the JokerCard changes
  JokerHand<T> reveal(
    JokerHandBuilder<T> builder, {
    Widget? child,
  }) {
    return JokerHand<T>(
      joker: this,
      builder: builder,
      child: child,
    );
  }
}

/// extension methods for cleaner usage
extension PokerTableExtension on List<JokerCard> {
  JokerDeck placeOnTable({
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
