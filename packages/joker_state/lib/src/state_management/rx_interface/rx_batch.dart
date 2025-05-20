import 'package:collection/collection.dart';

import '../joker_exception.dart';
import 'rx_interface.dart';

/// Batch update session for RxInterface
///
/// Use [apply] to change state multiple times, then [commit] to notify listeners once
/// Use [discard] to cancel all changes
class RxBatch<T> {
  final RxInterface<T> _rx;
  final T _originalState;

  RxBatch(this._rx) : _originalState = _rx.state;

  /// Applies field-level state changes
  RxBatch<T> apply(T Function(T state) updater) {
    if (_rx.isDisposed) {
      throw JokerException(
          'Cannot apply batch update to a disposed $runtimeType');
    }
    final newState = updater(_rx.state);
    _rx.state = newState;
    return this;
  }

  /// Commits and triggers update if there are changes
  void commit() {
    if (_rx.isDisposed) return;
    final equality = DeepCollectionEquality();
    if (!equality.equals(_rx.state, _originalState)) {
      _rx.notifyListeners();
    }
  }

  /// Restores the original snapshot and discards all changes
  void discard() {
    if (_rx.isDisposed) return;
    _rx.state = _originalState;
  }
}
