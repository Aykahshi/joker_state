import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';
import '../joker/joker_trickx.dart';

typedef JokerTroupeBuilder = Widget Function(
  BuildContext context,
  List<dynamic> values,
  Widget? child,
);

/// JokerGroup - A widget that listens to multiple JokerCards and rebuilds when any of them change
class JokerTroupe extends StatefulWidget {
  const JokerTroupe({
    super.key,
    required this.jokers,
    required this.builder,
    this.autoDispose = true,
    this.child,
  });

  final List<Joker> jokers;
  final JokerTroupeBuilder builder;
  final bool autoDispose;
  final Widget? child;

  @override
  _JokerTroupeState createState() => _JokerTroupeState();
}

class _JokerTroupeState extends State<JokerTroupe> {
  late List<dynamic> _values;

  // Keep track of listener functions to correctly remove them
  final Map<Joker, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _values = List.from(widget.jokers.map((Joker card) => card.value));
    _addListeners();
  }

  void _addListeners() {
    for (int i = 0; i < widget.jokers.length; i++) {
      final card = widget.jokers[i];
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
  void didUpdateWidget(JokerTroupe oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the card list changed
    if (widget.jokers.length != oldWidget.jokers.length ||
        !widget.jokers.every((card) => oldWidget.jokers.contains(card))) {
      // Remove old listeners
      _removeListeners();

      // Update values and add new listeners
      _values = List.from(widget.jokers.map((card) => card.value));
      _addListeners();
    }
  }

  @override
  void dispose() {
    _removeListeners();

    // Handle auto disposal if needed
    if (widget.autoDispose) {
      for (final card in widget.jokers) {
        final tag = card.tag;
        if (tag != null && tag.isNotEmpty) {
          final joker = Circus.trySpotlight(tag: tag);
          if (joker == null) {
            card.dispose();
          } else {
            Circus.vanish(tag: tag);
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
