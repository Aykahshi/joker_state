import '../core/joker_exception.dart';
import 'joker_act.dart';
import 'joker_equals.dart';

/// A class to perform batch updates on a [JokerAct] instance.
///
/// This allows multiple state modifications to be grouped together, with a
/// single notification being sent only after all changes are applied.
///
/// This is only usable when the [JokerAct] is in manual notification mode
/// (`autoNotify = false`).
///
/// ### Example
/// ```dart
/// final userJoker = Joker<User>(User(name: 'initial', age: 0), autoNotify: false);
///
/// userJoker.batch()
///   .apply((user) => user.copyWith(name: 'John'))
///   .apply((user) => user.copyWith(age: 30))
///   .commit(); // Notifies listeners only once with the final state.
/// ```
class JokerSleight<T> {
  /// Creates a batch update session for a given [JokerAct] instance.
  JokerSleight(this._act) : _originalState = _act.value;

  final JokerAct<T> _act;
  final T _originalState;

  /// Applies a state modification function to the current state.
  ///
  /// The [updater] function receives the current state and should return the
  /// new, modified state. This can be called multiple times.
  ///
  /// Throws a [JokerException] if the underlying [JokerAct] has been disposed.
  JokerSleight<T> apply(T Function(T state) updater) {
    if (_act.isDisposed) {
      throw JokerException(
          'Cannot apply batch update to a disposed ${_act.runtimeType}');
    }
    // In a batch, we always use whisper to avoid notifications.
    _act.whisperWith(updater);
    return this;
  }

  /// Commits all the applied changes and notifies listeners if the state changed.
  ///
  /// Compares the final state with the state before the batch began.
  /// If they are different, a single notification is sent to all listeners.
  void commit() {
    if (_act.isDisposed) return;

    if (!isDeeplyEqual(_act.value, _originalState)) {
      _act.yell();
    }
  }

  /// Discards all changes made during the batch session.
  ///
  /// The state of the [JokerAct] is reverted to what it was before the
  /// batch began. No notification is sent.
  void discard() {
    if (_act.isDisposed) return;
    _act.whisper(_originalState);
  }
}
