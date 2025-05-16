import 'dart:async';

import 'package:flutter/widgets.dart';

import 'presenter.dart';

/// A side-effect callback triggered when Presenter state updates.
typedef PresenterListener<T> = void Function(T? previous, T current);

/// A predicate to determine whether to trigger a [PresenterListener].
typedef PresenterListenCondition<T> = bool Function(T? previous, T current);

/// Extension methods on Presenter to support side-effect listeners.
extension PresenterListenerExtension<T> on Presenter<T> {
  /// Runs side effects when the state changes instead of rebuilding UI.
  ///
  /// Similar to React useEffect or Flutter's didUpdateWidget, allows you
  /// to respond to state changes with side effects like analytics events,
  /// notifications, or navigation.
  ///
  /// Returns a StatefulWidget that handles the subscription lifecycle.
  Widget effect({
    required Widget child,
    required void Function(T state, BuildContext context) effect,
    bool Function(T previous, T current)? effectWhen,
    bool runOnInit = true,
  }) {
    return _PresenterEffect<T>(
      presenter: this,
      effect: effect,
      effectWhen: effectWhen,
      runOnInit: runOnInit,
      child: child,
    );
  }
}

/// An internal widget that runs side effects when presenter state changes
class _PresenterEffect<T> extends StatefulWidget {
  final Presenter<T> presenter;
  final Widget child;
  final void Function(T state, BuildContext context) effect;
  final bool Function(T previous, T current)? effectWhen;
  final bool runOnInit;

  const _PresenterEffect({
    super.key,
    required this.presenter,
    required this.child,
    required this.effect,
    this.effectWhen,
    required this.runOnInit,
  });

  @override
  State<_PresenterEffect<T>> createState() => _PresenterEffectState<T>();
}

class _PresenterEffectState<T> extends State<_PresenterEffect<T>> {
  late StreamSubscription<T> _subscription;
  late T _previousState;

  @override
  void initState() {
    super.initState();
    _previousState = widget.presenter.state;

    if (widget.runOnInit) {
      // Wait for the next frame to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.effect(widget.presenter.state, context);
        }
      });
    }

    _subscription = widget.presenter.stream.listen((state) {
      if (!mounted) return;

      if (widget.effectWhen == null ||
          widget.effectWhen!(_previousState, state)) {
        widget.effect(state, context);
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
