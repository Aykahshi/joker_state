import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';
import '../joker/joker_trickx.dart';

typedef JokerStageBuilder<T> = Widget Function(
  BuildContext context,
  T value,
  Widget? child,
);

class JokerStage<T> extends StatefulWidget {
  const JokerStage({
    super.key,
    required this.joker,
    this.autoDispose = true,
    required this.builder,
    this.child,
  });

  final Joker<T> joker;
  final JokerStageBuilder<T> builder;
  final bool autoDispose;
  final Widget? child;

  @override
  State<JokerStage<T>> createState() => _JokerStageState<T>();
}

class _JokerStageState<T> extends State<JokerStage<T>> {
  @override
  void dispose() {
    if (widget.autoDispose) {
      var joker = Circus.trySpotlight<T>(tag: widget.joker.tag ?? '');
      if (joker == null) {
        widget.joker.dispose();
      } else {
        Circus.vanish<T>(tag: widget.joker.tag ?? '');
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
