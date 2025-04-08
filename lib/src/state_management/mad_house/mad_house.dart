import 'package:flutter/widgets.dart';
import 'package:joker_state/src/state_management/mad_house/mad_house_manager.dart';

/// MadHouse - An InheritedWidget that provides state to the widget tree
class MadHouse<T> extends InheritedWidget {
  /// The state being provided
  final MadHouseState<T> state;

  /// Creates a MadHouse with a state
  const MadHouse({
    Key? key,
    required this.state,
    required Widget child,
  }) : super(key: key, child: child);

  /// Get the state from the closest MadHouse ancestor, and rebuild when it changes
  static MadHouseState<T> of<T>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<MadHouse<T>>();
    assert(provider != null, 'No MadHouse<$T> found in context');
    return provider!.state;
  }

  /// Get the state without creating a rebuild dependency
  static MadHouseState<T>? maybeOf<T>(BuildContext context) {
    final provider = context
        .getElementForInheritedWidgetOfExactType<MadHouse<T>>()
        ?.widget as MadHouse<T>?;
    return provider?.state;
  }

  @override
  bool updateShouldNotify(MadHouse<T> oldWidget) {
    return state != oldWidget.state;
  }
}
