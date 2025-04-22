import 'package:flutter/widgets.dart';

import '../joker_frame/joker_frame.dart';
import '../joker_stage/joker_stage.dart';
import 'presenter.dart';

/// Extension for Presenter to easily create a [JokerStage] widget.
///
/// Provides a builder-like API for "showing" the entire state managed by the Presenter.
///
/// Example:
/// ```dart
/// final counterPresenter = CounterPresenter(); // Extends Presenter<int>
///
/// // Use the extension to build UI based on the presenter's state
/// counterPresenter.show(
///   builder: (context, count) => Text('Count: $count'),
/// );
/// ```
extension PresenterStageExtension<T> on Presenter<T> {
  /// Creates a [JokerStage] that rebuilds whenever this Presenter's state changes.
  ///
  /// The [builder] is used to construct the UI based on the current state [T].
  ///
  /// Returns a [JokerStage] widget linked to this Presenter.
  JokerStage<T> perform({
    Key? key,
    required JokerStageBuilder<T> builder,
  }) {
    // Presenter already extends Joker, so we can pass `this` directly.
    return JokerStage<T>(
      key: key,
      joker: this,
      builder: builder,
    );
  }
}

/// Extension for Presenter to easily create a [JokerFrame] widget.
///
/// Allows "focusing" on a specific part of the Presenter's state via a [selector].
/// The UI only rebuilds when the selected value changes.
///
/// Example:
/// ```dart
/// final userPresenter = UserPresenter(); // Extends Presenter<User>
///
/// // Focus on the user's name for the Text widget
/// userPresenter.focusOn<String>(
///   selector: (user) => user.name,
///   builder: (context, name) => Text('Welcome, $name!'),
/// );
/// ```
extension PresenterFrameExtension<T> on Presenter<T> {
  /// Creates a [JokerFrame] that focuses on a selected portion ([S]) of this Presenter's state ([T]).
  ///
  /// [selector]: A function that extracts the specific piece of state to observe.
  /// [builder]: A function that builds the UI based on the selected state [S].
  ///
  /// Returns a [JokerFrame] widget linked to this Presenter, optimized for selective rebuilds.
  JokerFrame<T, S> focusOn<S>({
    Key? key,
    required JokerFrameSelector<T, S> selector,
    required JokerFrameBuilder<S> builder,
  }) {
    // Presenter extends Joker, so `this` works here too.
    return JokerFrame<T, S>(
      key: key,
      joker: this,
      selector: selector,
      builder: builder,
    );
  }
}
