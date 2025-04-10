import 'package:flutter/widgets.dart';

import '../mad_house/mad_house.dart';

/// MadKeeper manages the state for a MadHouse
///
/// This StatefulWidget wraps MadHouse to provide mutable state capabilities
class MadKeeper<T> extends StatefulWidget {
  /// Creates a MadKeeper widget
  ///
  /// [initialState]: The initial value of the global state
  /// [child]: Widget that will have access to this state
  /// [onChange]: Optional callback for when state changes
  const MadKeeper({
    super.key,
    required this.initialState,
    required this.child,
    this.onChange,
  });

  /// The initial state value
  final T initialState;

  /// Child widget that will have access to the global state
  final Widget child;

  /// Optional callback for when state changes
  final MadHouseStateChanged<T>? onChange;

  @override
  _MadKeeperState<T> createState() => _MadKeeperState<T>();
}

class _MadKeeperState<T> extends State<MadKeeper<T>> {
  /// Current state value
  late T _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  /// Update the state
  void updateState(T newState) {
    if (_state != newState) {
      setState(() {
        _state = newState;
      });
    }
  }

  /// Update the state using a function
  void updateStateWith(T Function(T currentState) updater) {
    final newState = updater(_state);
    updateState(newState);
  }

  @override
  Widget build(BuildContext context) {
    return MadHouse<T>(
      state: _state,
      onChange: widget.onChange,
      child: widget.child,
    );
  }
}

/// Controller to interact with MadKeeper state from outside the widget tree
class MadManager<T> {
  /// The BuildContext to find the MadKeeper
  final BuildContext context;

  /// Creates a MadManager
  ///
  /// [context]: The BuildContext that contains a MadHouse of the same type T
  MadManager(this.context);

  /// Get the current state value
  T get state {
    return MadHouse.of<T>(context).state;
  }

  /// Update the state
  void updateState(T newState) {
    final manager = _findKeeper();
    if (manager != null) {
      manager.updateState(newState);
    }
  }

  /// Update the state using a function
  void updateStateWith(T Function(T currentState) updater) {
    final keeper = _findKeeper();
    if (keeper != null) {
      keeper.updateStateWith(updater);
    }
  }

  /// Find the nearest MadKeeper state
  _MadKeeperState<T>? _findKeeper() {
    BuildContext? currentContext = context;
    _MadKeeperState<T>? keeper;

    // Define a visitor function to search the widget tree
    void visitor(Element element) {
      if (keeper != null) return;

      if (element.widget is MadKeeper<T>) {
        final StatefulElement stateElement = element as StatefulElement;
        keeper = stateElement.state as _MadKeeperState<T>;
      } else {
        element.visitChildren(visitor);
      }
    }

    // First try to find in ancestors (usually faster)
    if (currentContext is Element) {
      currentContext.visitAncestorElements((element) {
        if (element.widget is MadKeeper<T>) {
          final StatefulElement stateElement = element as StatefulElement;
          keeper = stateElement.state as _MadKeeperState<T>;
          return false;
        }
        return true;
      });

      // If not found in ancestors, search the entire tree from the root
      if (keeper == null) {
        Element? rootElement;
        currentContext.visitAncestorElements((element) {
          rootElement = element;
          return true;
        });

        if (rootElement != null) {
          visitor(rootElement!);
        }
      }
    }

    return keeper;
  }
}
