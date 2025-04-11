import 'package:flutter/widgets.dart';

import '../big_top/big_top.dart';

typedef ActPresenter<T> = Widget Function(
  BuildContext context,
  T state,
  void Function(T newState, {Set<Type> props}) present,
);

/// ShowMaster manages the state for a BigTop
///
/// This StatefulWidget wraps BigTop to provide mutable state capabilities
/// with support for selective rebuilds
class ShowMaster<T> extends StatefulWidget {
  /// Creates a ShowMaster widget with a builder function
  ///
  /// [initialAct]: The initial value of the global state
  /// [builder]: Function that builds UI with access to the state and update function
  /// [onChange]: Optional callback for when state changes
  const ShowMaster({
    super.key,
    required this.initialAct,
    required this.presenter,
    this.onChange,
  });

  /// Creates a ShowMaster widget with a child widget
  ///
  /// [initialAct]: The initial value of the global state
  /// [child]: Widget that will have access to this state
  /// [onChange]: Optional callback for when state changes
  factory ShowMaster.withChild({
    Key? key,
    required T initialAct,
    required Widget child,
    BigTopCallback<T>? onChange,
  }) {
    return ShowMaster<T>(
      key: key,
      initialAct: initialAct,
      onChange: onChange,
      presenter: (_, __, ___) => child,
    );
  }

  /// The initial state value
  final T initialAct;

  /// Function that builds UI with access to the state
  final ActPresenter<T> presenter;

  /// Optional callback for when state changes
  final BigTopCallback<T>? onChange;

  @override
  _ShowMasterState<T> createState() => _ShowMasterState<T>();
}

class _ShowMasterState<T> extends State<ShowMaster<T>> {
  /// Current state value
  late T _state;

  /// Current changed props
  Set<Type> _changedProps = {};

  @override
  void initState() {
    super.initState();
    _state = widget.initialAct;
  }

  /// Update the state with affected props
  void update(T newState, {Set<Type> props = const {}}) {
    if (_state != newState) {
      setState(() {
        _state = newState;
        _changedProps = props;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BigTop<T>(
      state: _state,
      changedProps: _changedProps,
      onChange: widget.onChange,
      child: Builder(
        builder: (context) => widget.presenter(context, _state, update),
      ),
    );
  }
}

/// ActManager - Controller to interact with ShowMaster state from outside the widget tree
class ActManager<T> {
  /// The BuildContext to find the ShowMaster
  final BuildContext context;

  /// Creates a ActManager
  ///
  /// [context]: The BuildContext that contains a BigTop of type T
  ActManager(this.context);

  /// Get the current state value
  T get state {
    return BigTop.of<T>(context).state;
  }

  /// Update the state with affected props
  void update(T newState, {Set<Type> props = const {}}) {
    final director = _findDirector();
    if (director != null) {
      director.update(newState, props: props);
    }
  }

  /// Update the state using a function with affected props
  void updateWith(T Function(T currentState) updater,
      {Set<Type> props = const {}}) {
    final director = _findDirector();
    if (director != null) {
      final newState = updater(director._state);
      director.update(newState, props: props);
    }
  }

  /// Find the nearest ShowMaster state
  _ShowMasterState<T>? _findDirector() {
    BuildContext? currentContext = context;
    _ShowMasterState<T>? director;

    if (currentContext is Element) {
      currentContext.visitAncestorElements((element) {
        if (element.widget is ShowMaster<T>) {
          final StatefulElement stateElement = element as StatefulElement;
          director = stateElement.state as _ShowMasterState<T>;
          return false;
        }
        return true;
      });
    }

    return director;
  }
}
