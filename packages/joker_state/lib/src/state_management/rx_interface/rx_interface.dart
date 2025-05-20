import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../../../joker_state.dart';

/// RxInterface - Base reactive state management interface
///
/// Provides basic state synchronization, subscription, and lifecycle management.
/// Does not include business logic or complex state operations, which are provided by Presenter.
abstract class RxInterface<T> with LifeCycleMixin {
  late final BehaviorSubject<T> _subject;

  /// Current state value
  T _state;

  /// Flag to track if dispose has been called
  bool _isDisposed = false;

  /// Flag to track if a disposal task has been scheduled
  bool _isDisposalScheduled = false;

  /// If true, prevents auto-disposal when listeners drop to zero
  final bool keepAlive;

  /// If true, auto notify listeners when state changes
  final bool autoNotify;

  /// Timer for auto-disposal
  Timer? _disposeTimer;

  /// Auto-disposal delay in milliseconds, default is 500ms
  final Duration? autoDisposeDelay;

  /// Creates an RxInterface instance with the given initial state
  ///
  /// If [keepAlive] is true, resources will not be automatically released when there are no listeners
  RxInterface(
    T initialState, {
    this.keepAlive = false,
    this.autoNotify = true,
    this.autoDisposeDelay,
  }) : _state = initialState {
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
    if (!keepAlive && !_isDisposed && !_subject.hasListener) {
      _scheduleAutoDisposal();
    }
  }

  /// Schedule auto-disposal
  void _scheduleAutoDisposal() {
    _cancelScheduledDisposal();
    _isDisposalScheduled = true;
    _disposeTimer =
        Timer(autoDisposeDelay ?? const Duration(milliseconds: 500), () {
      _checkAndDispose();
    });
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
    _disposeTimer?.cancel();
    _disposeTimer = null;
  }

  /// Gets the current state value
  T get state {
    if (_isDisposed) {
      throw JokerException('Cannot get state from a disposed $runtimeType');
    }
    return _state;
  }

  /// Sets a new state value and notifies all listeners
  set state(T newValue) {
    if (_isDisposed) {
      throw JokerException('Cannot update state on a disposed $runtimeType');
    }
    _state = newValue;
    if (autoNotify) _subject.add(_state);
  }

  /// Returns whether this instance has been disposed
  bool get isDisposed => _isDisposed;

  /// Gets the ValueStream of state updates
  ValueStream<T> get stream => _subject.stream;

  /// Subscribes to state changes and returns a subscription object
  StreamSubscription<T> subscribe(void Function(T state) listener) {
    if (_isDisposed) {
      throw JokerException('Cannot subscribe to a disposed $runtimeType');
    }
    return _subject.stream.listen(listener);
  }

  /// Notifies all listeners of the current state value
  ///
  /// Use this method when the state has been updated but not automatically notified
  void notifyListeners() {
    if (!_isDisposed) {
      _subject.add(_state);
    }
  }

  /// Returns whether this instance has any active listeners
  bool get hasListeners => _subject.hasListener;

  /// Releases resources used by this instance
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
