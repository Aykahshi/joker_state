import 'package:flutter/widgets.dart';

import '../mad_house/mad_house.dart';

/// MadHouseBuilder widget for building UI based on MadHouse state
class MadHouseBuilder<T> extends StatelessWidget {
  /// Creates a MadHouseBuilder
  ///
  /// [builder]: Function that builds UI based on the current state
  const MadHouseBuilder({
    super.key,
    required this.builder,
  });

  /// Builder function that receives the current state and builds a widget
  final Widget Function(BuildContext context, T state) builder;

  @override
  Widget build(BuildContext context) {
    final state = MadHouse.of<T>(context).state;
    return builder(context, state);
  }
}
