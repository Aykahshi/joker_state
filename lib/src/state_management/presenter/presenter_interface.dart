import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../joker_state.dart';
import '../joker_exception.dart';
import 'presenter_life_cycle.dart';

/// PresenterInterface - a reactive state container based on Stream.
///
/// A lightweight state management solution that wraps any Dart object as a reactive
/// state unit using Stream-based architecture instead of ChangeNotifier.
///
/// Supports two notification modes:
/// - autoNotify = true (default): Automatically notify listeners of state changes
/// - autoNotify = false: Changes occur silently, requiring manual calls to [yell()]
abstract class PresenterInterface<T> with PresenterLifeCycle {
  /// Creates a stream controller for broadcasting state updates
  final StreamController<T> _controller = StreamController<T>.broadcast();

  /// The current state
  T _state;

  /// The previous state before the most recent update
  T? _previousState;

  /// Flag to track if dispose has been called
  bool _isDisposed = false;

  /// Flag to track if a disposal task has been scheduled
  bool _isDisposalScheduled = false;

  /// If true, prevents auto-disposal when listeners drop to zero
  final bool keepAlive;

  /// Controls whether [trick] and friends automatically call [notifyListeners].
  final bool autoNotify;

  /// Creates a PresenterInterface with the given [initialState].
  ///
  /// If [autoNotify] is true, all mutations will auto-emit to stream.
  /// If [keepAlive] is true, the presenter will not be automatically disposed
  /// when it has no listeners. Defaults to false.
  PresenterInterface(T initialState,
      {this.autoNotify = true, this.keepAlive = false})
      : _state = initialState,
        _previousState = initialState {
    // Emit initial state
    _controller.add(initialState);
  }

  /// Returns the current state.
  T get state => _state;

  /// Returns the previous state.
  T? get previousState => _previousState;

  /// Returns whether this presenter has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns a stream of state updates.
  Stream<T> get stream => _controller.stream;

  /// Adds a listener to the stream and returns a StreamSubscription.
  StreamSubscription<T> addListener(void Function(T state) listener) {
    if (_isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }
    // 取消任何待處理的釋放任務
    _isDisposalScheduled = false;

    // 建立訂閱
    final subscription = _controller.stream.listen(listener);

    // 使用 onDone 來檢測訂閱結束
    subscription.onDone(() {
      // 當訂閱結束時檢查是否需要自動釋放
      _checkForAutoDispose();
    });

    return subscription;
  }

  /// 檢查是否需要自動釋放資源
  void _checkForAutoDispose() {
    // 如果沒有活躍的監聽者、不需要保持活躍狀態，且尚未安排釋放
    if (!_controller.hasListener &&
        !keepAlive &&
        !_isDisposalScheduled &&
        !_isDisposed) {
      _scheduleDispose();
    }
  }

  /// 安排在下一個框架後釋放資源
  void _scheduleDispose() {
    // 設置標誌
    _isDisposalScheduled = true;

    // 等待下一個框架進行釋放
    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.addPostFrameCallback((_) {
      _disposeIfUnused();
    });
  }

  /// 如果仍然沒有使用，則釋放資源
  void _disposeIfUnused() {
    // 只有在安排了釋放任務且條件仍然成立時才釋放
    if (_isDisposalScheduled &&
        !_controller.hasListener &&
        !keepAlive &&
        !_isDisposed) {
      dispose();
    }
    // 無論是否釋放，都重置標誌
    _isDisposalScheduled = false;
  }

  /// Updates state and emits the new value to all listeners.
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  void trick(T newState) {
    if (_isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trick(): Use whisper() in manual mode.',
      );
    }
    _previousState = _state;
    _state = newState;
    _controller.add(_state);
  }

  /// Updates state using a transform function and emits the new value.
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  void trickWith(T Function(T currentState) updater) {
    if (_isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trickWith(): Use whisperWith() in manual mode.',
      );
    }
    _previousState = _state;
    _state = updater(_state);
    _controller.add(_state);
  }

  /// Async version of trickWith.
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  Future<void> trickAsync(Future<T> Function(T current) performer) async {
    if (_isDisposed) {
      throw JokerException(
          'Cannot update state asynchronously on a disposed $runtimeType');
    }
    if (!autoNotify) {
      throw JokerException(
        'trickAsync(): Use whisperWith() and yell() in manual mode.',
      );
    }
    _previousState = _state;
    _state = await performer(_state);
    _controller.add(_state);
  }

  // ------------- Manual-notify APIs -------------

  /// Updates state silently (no notify).
  ///
  /// Only usable when [autoNotify] is false.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  T whisper(T newState) {
    if (_isDisposed) {
      throw JokerException('Cannot call whisper() on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('whisper() is not allowed in autoNotify mode.');
    }
    _previousState = _state;
    _state = newState;
    return _state;
  }

  /// Functor version of [whisper].
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  T whisperWith(T Function(T currentState) updater) {
    if (_isDisposed) {
      throw JokerException(
          'Cannot call whisperWith() on a disposed $runtimeType');
    }
    if (autoNotify) {
      throw JokerException('whisperWith() is not allowed in autoNotify mode.');
    }
    _previousState = _state;
    _state = updater(_state);
    return _state;
  }

  /// Manually triggers all registered listeners.
  ///
  /// Used in manual mode after one or more silent updates ([whisper]).
  /// Does nothing if the PresenterInterface is disposed.
  void notifyListeners() {
    if (!_isDisposed) {
      _controller.add(_state);
    }
  }

  /// Alias for [notifyListeners] specific to manual mode clarity.
  /// Does nothing if the PresenterInterface is disposed.
  void yell() {
    notifyListeners();
  }

  /// Whether the state has changed since the previous update.
  bool isDifferent() => _state != _previousState;

  /// Begins a batch update session.
  ///
  /// Use [PresenterBatch.commit] to notify once after multiple updates.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  PresenterBatch<T> batch() {
    if (_isDisposed) {
      throw JokerException('Cannot start batch on a disposed $runtimeType');
    }
    return PresenterBatch<T>(this);
  }

  /// Returns whether this presenter has any active listeners.
  bool get hasListeners => _controller.hasListener;

  /// Releases resources used by this presenter.
  @protected
  @mustCallSuper
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _controller.close();
      onDone();
    }
  }
}

/// A batch update session for a [PresenterInterface].
///
/// Use [apply] multiple times to mutate state, and
/// notify listeners once via [commit]. Use [discard] to undo changes.
class PresenterBatch<T> {
  final PresenterInterface<T> _presenter;
  final T _originalState;
  final bool _isAutoNotify;

  PresenterBatch(this._presenter)
      : _originalState = _presenter.state,
        _isAutoNotify = _presenter.autoNotify;

  /// Applies a field-level change to the PresenterInterface state.
  PresenterBatch<T> apply(T Function(T state) updater) {
    if (_presenter.isDisposed) {
      throw JokerException(
          'Cannot apply batch update to a disposed $runtimeType');
    }
    if (_isAutoNotify) {
      final newState = updater(_presenter.state);
      (_presenter as dynamic)._state = newState;
    } else {
      _presenter.whisperWith(updater);
    }
    return this;
  }

  /// Commits and triggers force update if any change occurred.
  void commit() {
    if (_presenter.isDisposed) return; // Do nothing if disposed
    if (_presenter.state != _originalState) {
      _presenter.yell();
    }
  }

  /// Restores original snapshot and discards any changes.
  void discard() {
    if (_presenter.isDisposed) return; // Do nothing if disposed
    if (_isAutoNotify) {
      (_presenter as dynamic)._state = _originalState;
    } else {
      _presenter.whisper(_originalState);
    }
  }
}
