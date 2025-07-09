import 'package:flutter/widgets.dart';

import '../widgets/index.dart';
import 'joker_act.dart';

/// Extension methods for [JokerAct] to provide fluent UI binding.
extension JokerActWidgetExtension<T> on JokerAct<T> {
  /// Creates a [JokerStage] widget that listens to this [JokerAct] instance.
  ///
  /// The [builder] is called whenever this instance notifies its listeners.
  /// This is a convenient alternative to instantiating [JokerStage] directly.
  JokerStage<T> perform({
    Key? key,
    required JokerStageBuilder<T> builder,
  }) {
    return JokerStage<T>(
      key: key,
      act: this,
      builder: builder,
    );
  }

  /// Creates a [JokerFrame] that focuses on a selected portion of this instance's state.
  ///
  /// The [builder] will only be called when the value returned by the [selector]
  /// changes. This is a convenient alternative to instantiating [JokerFrame] directly.
  JokerFrame<T, S> focusOn<S>({
    Key? key,
    required JokerFrameSelector<T, S> selector,
    required JokerFrameBuilder<S> builder,
  }) {
    return JokerFrame<T, S>(
      key: key,
      act: this,
      selector: selector,
      builder: builder,
    );
  }

  /// Creates a [JokerWatch] widget to perform side effects when this instance's state changes.
  ///
  /// This is a convenient alternative to instantiating [JokerWatch] directly.
  Widget watch({
    required JokerWatchCallback<T> onStateChange,
    required Widget child,
    JokerWatchCondition<T>? watchWhen,
    bool runOnBuild = false,
    Key? key,
  }) {
    return JokerWatch<T>(
      key: key,
      act: this,
      onStateChange: onStateChange,
      watchWhen: watchWhen,
      runOnBuild: runOnBuild,
      child: child,
    );
  }

  /// Creates a [JokerRehearse] widget that listens to this [JokerAct] instance.
  ///
  /// This is a convenient alternative to instantiating [JokerRehearse] directly.
  Widget rehearse({
    Key? key,
    required JokerRehearseBuilder<T> builder,
    required JokerRehearseCallback<T> onStateChange,
    JokerRehearseCondition<T>? performWhen,
    JokerRehearseCondition<T>? watchWhen,
    bool runOnBuild = false,
  }) {
    return JokerRehearse<T>(
      key: key,
      act: this,
      builder: builder,
      onStateChange: onStateChange,
      performWhen: performWhen,
      watchWhen: watchWhen,
      runOnBuild: runOnBuild,
    );
  }
}

/// Extension methods for [List<JokerAct>] to provide fluent UI binding for troupes.
extension JokerActListWidgetExtension on List<JokerAct> {
  /// Creates a [JokerTroupe] widget from this list of [JokerAct] instances.
  ///
  /// This is a convenient alternative to instantiating [JokerTroupe] directly.
  JokerTroupe<T> assemble<T extends Record>({
    Key? key,
    required JokerTroupeConverter<T> converter,
    required JokerTroupeBuilder<T> builder,
  }) {
    return JokerTroupe<T>(
      key: key,
      acts: this,
      converter: converter,
      builder: builder,
    );
  }
}
