import '../../di/circus_ring/circus_ring.dart';
import 'joker_card.dart';

/// Extension to get JokerCards from CircusRing with auto-disposal
extension JokerCardExtension on CircusRing {
  /// Register a JokerCard that will be automatically disposed when CircusRing is cleared
  JokerCard<T> putCard<T>(T initialValue, {String? tag}) {
    final card = JokerCard<T>(initialValue);
    put<JokerCard<T>>(card, tag: tag);
    return card;
  }

  /// Find a JokerCard
  JokerCard<T> drawCard<T>([String? tag]) {
    return find<JokerCard<T>>(tag);
  }

  /// Try to find a JokerCard
  JokerCard<T>? tryDrawJoker<T>([String? tag]) {
    return tryFind<JokerCard<T>>(tag);
  }

  /// Delete a JokerCard
  bool discard<T>({String? tag}) {
    return delete<JokerCard<T>>(tag: tag);
  }
}
