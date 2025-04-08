import 'package:flutter/widgets.dart';

import '../joker_card/joker_card.dart';

typedef JokerDeckBuilder = Widget Function(
  BuildContext context,
  List<dynamic> values,
  Widget? child,
);

/// JokerDeck - A widget that listens to multiple JokerCards and rebuilds when any of them change
class JokerDeck extends StatefulWidget {
  final List<JokerCard> cards;
  final JokerDeckBuilder builder;
  final Widget? child;

  const JokerDeck({
    super.key,
    required this.cards,
    required this.builder,
    this.child,
  });

  @override
  _JokerDeckState createState() => _JokerDeckState();
}

class _JokerDeckState extends State<JokerDeck> {
  late List<dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = widget.cards.map((card) => card.value).toList();
    _addListeners();
  }

  void _addListeners() {
    for (int i = 0; i < widget.cards.length; i++) {
      final JokerCard card = widget.cards[i];
      card.addListener(() => _updateCard(i, card));
    }
  }

  void _updateCard(int index, JokerCard card) {
    setState(() {
      _values[index] = card.value;
    });
  }

  @override
  void didUpdateWidget(JokerDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.cards.length != oldWidget.cards.length ||
        !widget.cards.every((card) => oldWidget.cards.contains(card))) {
      // If the number of cards has changed or if any of the cards have been added or removed,
      // we need to update the listeners
      for (final JokerCard card in oldWidget.cards) {
        card.removeListener(() {});
      }

      _values = widget.cards.map((card) => card.value).toList();
      _addListeners();
    }
  }

  @override
  void dispose() {
    for (final card in widget.cards) {
      card.removeListener(() {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _values, widget.child);
  }
}
