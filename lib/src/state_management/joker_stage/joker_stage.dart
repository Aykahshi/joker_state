import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';
import '../joker/joker_trickx.dart';

typedef JokerStageBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

class JokerStage<T> extends StatefulWidget {
  const JokerStage({
    super.key,
    required this.joker,
    this.autoDispose = true,
    required this.builder,
  });

  final Joker<T> joker;
  final JokerStageBuilder<T> builder;
  final bool autoDispose;

  @override
  State<JokerStage<T>> createState() => _JokerStageState<T>();
}

class _JokerStageState<T> extends State<JokerStage<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.joker.value;
    widget.joker.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _value = widget.joker.value;
      });
    }
  }

  @override
  void didUpdateWidget(JokerStage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.joker != oldWidget.joker) {
      oldWidget.joker.removeListener(_updateState);
      _value = widget.joker.value;
      widget.joker.addListener(_updateState);
    }
  }

  @override
  void dispose() {
    widget.joker.removeListener(_updateState);

// 如果設置了自動釋放
    if (widget.autoDispose) {
      // 檢查這個 Joker 是否有標籤
      final tag = widget.joker.tag;

      if (tag != null && tag.isNotEmpty) {
        // Check if the Joker is registered in CircusRing
        try {
          final registeredJoker = Circus.spotlight<T>(tag: tag);

          // If the Joker is registered and the same instance, vanish it
          if (identical(registeredJoker, widget.joker)) {
            Circus.vanish<T>(tag: tag);
          } else {
            // If the Joker is registered but not the same instance, dispose it
            widget.joker.dispose();
          }
        } catch (_) {
          // If the Joker is not registered, dispose it
          widget.joker.dispose();
        }
      } else {
        // If the Joker has no tag, dispose it
        widget.joker.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _value);
  }
}
