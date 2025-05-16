import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../../../joker_state.dart';

final _engine = WidgetsFlutterBinding.ensureInitialized();

abstract class PresenterInterface<T> with PresenterLifeCycle {
  late final BehaviorSubject<T> _subject;

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
  /// when it has no listeners after waiting for the next frame.
  PresenterInterface(
    T initialState, {
    this.autoNotify = true,
    this.keepAlive = false,
  })  : _state = initialState,
        _previousState = initialState {
    _subject = BehaviorSubject<T>.seeded(
      initialState,
      onListen: _onAddListener,
      onCancel: _onLastListenerRemoved,
    );
  }

  /// When some listener is added.
  void _onAddListener() {
    // Cancel any pending auto-disposal
    _cancelScheduledDisposal();
  }

  /// When the last listener is removed.
  void _onLastListenerRemoved() {
    // If there are no listeners and keepAlive is false, schedule auto-disposal.
    if (!keepAlive && !_isDisposed) {
      _scheduleAutoDisposal();
    }
  }

  /// Schedule auto-disposal
  void _scheduleAutoDisposal() {
    _cancelScheduledDisposal();
    _isDisposalScheduled = true;
    _engine.addPostFrameCallback((_) => _checkAndDispose());
  }

  /// Check if conditions for disposal are still valid and dispose if they are
  void _checkAndDispose() {
    if (_isDisposalScheduled &&
        !_subject.hasListener &&
        !keepAlive &&
        !_isDisposed) {
      dispose();
    }
    _isDisposalScheduled = false;
  }

  /// Cancel any scheduled disposal
  void _cancelScheduledDisposal() {
    _isDisposalScheduled = false;
  }

  /// Returns the current state.
  T get state => _state;

  /// Returns the previous state.
  T? get previousState => _previousState;

  /// Returns whether this presenter has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns a ValueStream of state updates.
  ValueStream<T> get stream => _subject.stream;

  /// Adds a listener to the stream and returns a StreamSubscription.
  StreamSubscription<T> addListener(void Function(T state) listener) {
    if (_isDisposed) {
      throw JokerException('Cannot add listener to a disposed $runtimeType');
    }
    return _subject.stream.listen(listener);
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
    _subject.add(_state);
  }

  /// Updates state using a transform function and emits the new value.
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  void trickWith(T Function(T s) updater) {
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
    _subject.add(_state);
  }

  /// Async version of trickWith.
  ///
  /// Only usable in autoNotify mode.
  /// Throws [JokerException] if called on a disposed PresenterInterface.
  Future<void> trickAsync(Future<T> Function(T s) performer) async {
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
    _subject.add(_state);
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
  T whisperWith(T Function(T s) updater) {
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
      _subject.add(_state);
    }
  }

  /// Alias for [notifyListeners] specific to manual mode clarity.
  /// Does nothing if the PresenterInterface is disposed.
  void yell() {
    notifyListeners();
  }

  /// Whether the state has changed since the previous update.
  bool get isDifferent => _state != _previousState;

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
  bool get hasListeners => _subject.hasListener;

  /// Releases resources used by this presenter.
  @mustCallSuper
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _isDisposalScheduled = false;
      _subject.close();
      onDone(); // Lifecycle callback
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
