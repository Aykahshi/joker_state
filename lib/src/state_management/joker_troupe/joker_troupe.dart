import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';

typedef JokerTroupeBuilder<T> = Widget Function(
  BuildContext context,
  T values,
);

typedef JokerTroupeConverter<T> = T Function(List values);

/// JokerTroupe - Using Record to implement strong typing for Jokers
class JokerTroupe<T extends Record> extends StatefulWidget {
  /// Jokers
  final List<Joker> jokers;

  /// Converts a dynamic list of values to a strong type T
  final JokerTroupeConverter converter;

  /// Builder functions for building UI
  final JokerTroupeBuilder<T> builder;

  /// Whether to automatically release Joker when the component is destroyed
  final bool autoDispose;

  const JokerTroupe({
    super.key,
    required this.jokers,
    required this.converter,
    required this.builder,
    this.autoDispose = true,
  });

  @override
  _JokerTroupeState<T> createState() => _JokerTroupeState<T>();
}

class _JokerTroupeState<T extends Record> extends State<JokerTroupe<T>> {
  /// Store all Joker values
  late List<dynamic> _values;

  /// Store all Joker listeners
  final Map<Joker, VoidCallback> _listeners = {};

  @override
  void initState() {
    super.initState();
    _initValues();
    _addListeners();
  }

  void _initValues() {
    _values = List.from(widget.jokers.map((joker) => joker.value));
  }

  void _addListeners() {
    for (int i = 0; i < widget.jokers.length; i++) {
      final joker = widget.jokers[i];
      final index = i;

      final listener = () {
        if (mounted) {
          setState(() {
            if (index < _values.length) {
              _values[index] = joker.value;
            }
          });
        }
      };

      _listeners[joker] = listener;
      joker.addListener(listener);
    }
  }

  void _removeListeners() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
  }

  @override
  void didUpdateWidget(JokerTroupe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.jokers.length != oldWidget.jokers.length ||
        !_areJokersEqual(widget.jokers, oldWidget.jokers)) {
      _removeListeners();
      _initValues();
      _addListeners();
    }
  }

  bool _areJokersEqual(List<Joker> list1, List<Joker> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _removeListeners();

    if (widget.autoDispose) {
      for (final joker in widget.jokers) {
        final tag = joker.tag;
        if (tag != null && tag.isNotEmpty) {
          // If cannot fireByTag, dispose it
          if (!Circus.fireByTag(tag)) {
            joker.dispose();
          }
        } else {
          joker.dispose();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typedValues = widget.converter(_values);
    return widget.builder(context, typedValues);
  }
}
