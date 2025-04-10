import 'package:flutter/widgets.dart';

import '../mad_keeper/mad_keeper.dart';
import 'mad_house.dart';

/// Extension for more natural access to MadHouse state
extension MadHouseContextExtension on BuildContext {
  /// Get the global state from MadHouse
  T madState<T>() {
    return MadHouse.of<T>(this).state;
  }

  /// Get a MadHouseManager to update the global state
  MadManager<T> madManager<T>() {
    return MadManager<T>(this);
  }
}
