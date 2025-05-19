import 'dart:async';

import 'package:flutter/widgets.dart';

import 'rx_interface.dart';

/// A side-effect callback triggered when RxInterface state updates.
typedef RxListener<T> = void Function(BuildContext context, T state);

/// A predicate to determine whether to trigger a [RxListener].
typedef RxListenCondition<T> = bool Function(T? previous, T current);

/// An internal widget that runs side effects when RxInterface state changes
class RxEffect<T> extends StatefulWidget {
  final RxInterface<T> rx;
  final Widget child;
  final RxListener<T> effect;
  final RxListenCondition<T>? effectWhen;
  final bool runOnInit;

  const RxEffect({
    super.key,
    required this.rx,
    required this.child,
    required this.effect,
    this.effectWhen,
    required this.runOnInit,
  });

  @override
  State<RxEffect<T>> createState() => _RxEffectState<T>();
}

class _RxEffectState<T> extends State<RxEffect<T>> {
  late StreamSubscription<T> _subscription;
  late T _previousState;

  @override
  void initState() {
    super.initState();
    _previousState = widget.rx.state;

    if (widget.runOnInit) {
      // Wait for the next frame to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.effect(context, widget.rx.state);
        }
      });
    }

    _subscription = widget.rx.stream.listen((state) {
      if (!mounted) return;

      if (widget.effectWhen == null ||
          widget.effectWhen!(_previousState, state)) {
        widget.effect(context, state);
      }
      _previousState = state;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
