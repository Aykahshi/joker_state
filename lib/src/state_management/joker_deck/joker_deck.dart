import 'package:flutter/widgets.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card_extension.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker_card/joker_card.dart';

typedef JokerDeckBuilder = Widget Function(
  BuildContext context,
  List<dynamic> values,
  Widget? child,
);

/// JokerDeck - A widget that listens to multiple JokerCards and rebuilds when any of them change
class JokerDeck extends StatefulWidget {
  const JokerDeck({
    super.key,
    required this.cards,
    required this.builder,
    this.autoDispose = true,
    this.child,
  });

  final List<JokerCard> cards;
  final JokerDeckBuilder builder;
  final bool autoDispose;
  final Widget? child;

  @override
  _JokerDeckState createState() => _JokerDeckState();
}

class _JokerDeckState extends State<JokerDeck> {
  late List<dynamic> _values;

  // Keep track of listener functions to correctly remove them
  final Map<JokerCard, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.cards.map((JokerCard card) => card.value));
    _addListeners();
  }

  void _addListeners() {
    for (int i = 0; i < widget.cards.length; i++) {
      final card = widget.cards[i];
      final int index = i; // Capture the current index

      // Create and store the listener function
      final listener = () {
        if (mounted) {
          setState(() {
            if (index < _values.length) {
              _values[index] = card.value;
            }
          });
        }
      };

      // Store reference to the listener
      _listeners[card] = listener;
      card.addListener(listener);
    }
  }

  void _removeListeners() {
    // Remove using the stored references
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
  }

  @override
  void didUpdateWidget(JokerDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the card list changed
    if (widget.cards.length != oldWidget.cards.length ||
        !widget.cards.every((card) => oldWidget.cards.contains(card))) {
      // Remove old listeners
      _removeListeners();

      // Update values and add new listeners
      _values = List.from(widget.cards.map((card) => card.value));
      _addListeners();
    }
  }

  @override
  void dispose() {
    _removeListeners();

    // Handle auto disposal if needed
    if (widget.autoDispose) {
      for (final card in widget.cards) {
        final tag = card.tag;
        if (tag != null && tag.isNotEmpty) {
          final joker = Circus.tryDrawCard(tag: tag);
          if (joker == null) {
            card.dispose();
          } else {
            Circus.discard(tag: tag);
          }
        } else {
          card.dispose();
        }
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values, widget.child);
  }
}
