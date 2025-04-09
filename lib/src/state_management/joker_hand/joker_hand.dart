import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker_card/joker_card.dart';
import '../joker_card/joker_card_extension.dart';

typedef JokerHandBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Widget? child,
);

class JokerHand<T> extends StatefulWidget {
  const JokerHand({
    super.key,
    required this.joker,
    this.autoDispose = true,
    required this.builder,
    this.child,
  });

  final JokerCard<T> joker;
  final JokerHandBuilder<T> builder;
  final bool autoDispose;
  final Widget? child;

  @override
  State<JokerHand<T>> createState() => _JokerHandState<T>();
}

class _JokerHandState<T> extends State<JokerHand<T>> {
  @override
  void dispose() {
    if (widget.autoDispose) {
      var joker = Circus.tryDrawCard<T>(tag: widget.joker.tag ?? '');
      if (joker == null) {
        widget.joker.dispose();
      } else {
        Circus.discard<T>(tag: widget.joker.tag ?? '');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: widget.joker,
      builder: widget.builder,
      child: widget.child,
    );
  }
}
