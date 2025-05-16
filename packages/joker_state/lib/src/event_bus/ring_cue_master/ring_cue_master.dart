import 'dart:async';
import 'dart:developer';

import 'package:circus_ring/circus_ring.dart';
import 'package:rxdart/rxdart.dart';

import 'cue_master.dart';

/// An RxDart-based implementation of [CueMaster].
///
/// This implementation uses a `PublishSubject` for each event type.
/// `PublishSubject`s are suitable for event buses as they broadcast
/// events to all subscribers that subscribed *after* the event was emitted.
/// It implements [Disposable] for automatic cleanup with CircusRing.
class RingCueMaster implements CueMaster, Disposable {
  // A map to hold PublishSubjects for different event types.
  // The key is the Type of the cue, and the value is the PublishSubject for that cue.
  // We use `dynamic` for the PublishSubject's generic type here, but it's cast
  // to the correct type `T` in `_getController`.
  final Map<Type, PublishSubject<dynamic>> _controllers = {};

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  /// Retrieves or creates a [PublishSubject] for the given type [T].
  PublishSubject<T> _getController<T>() {
    if (_isDisposed) {
      throw StateError('Cannot send cues after dispose');
    }
    // `putIfAbsent` ensures that if a controller for type T doesn't exist,
    // a new one is created and added to the map.
    // It's crucial to cast the result to `PublishSubject<T>` as the map
    // stores `PublishSubject<dynamic>`. This cast is safe because we always
    // create `PublishSubject<T>` for key `T`.
    return _controllers.putIfAbsent(T, () => PublishSubject<T>())
        as PublishSubject<T>;
  }

  @override
  Stream<T> on<T>() {
    if (_isDisposed) {
      return Stream.empty();
    }
    return _getController<T>().stream;
  }

  // Extends Cue is optional, but recommended for better type safety and debuggability.
  @override
  bool sendCue<T>(T cue) {
    if (_isDisposed) {
      log(
        'Warning: Attempted to send cue on a disposed RingCueMaster: $cue',
        name: 'RingCueMaster',
      );
      return false;
    }
    // Get the controller for type T. This will create it if it doesn't exist.
    final controller = _getController<T>();
    // Only add the cue if the controller is not closed.
    if (!controller.isClosed) {
      controller.add(cue);
      return true;
    }
    // This case (controller.isClosed but !_isDisposed) would primarily happen if
    // reset<T>() was called for this specific T, but the bus itself isn't disposed.
    // _getController would have provided a fresh, open controller if reset<T> had removed it.
    // So, this path is less likely with PublishSubject unless a subject is closed externally
    // without being removed from _controllers.
    // However, if dispose() was called, _isDisposed is true, and we'd exit earlier.
    // If reset<T>() was called, the controller for T is removed. _getController would make a new one.
    // The main guard is _isDisposed.
    return false; // Controller was closed
  }

  @override
  StreamSubscription<T> listen<T>(void Function(T cue) fn) {
    return on<T>().listen(fn);
  }

  @override
  bool hasListeners<T>() {
    if (_isDisposed || !_controllers.containsKey(T)) {
      return false;
    }
    // The non-null assertion operator (!) is safe here because of `containsKey`.
    return _controllers[T]!.hasListener;
  }

  @override
  bool reset<T>() {
    if (_isDisposed) {
      return false;
    }
    if (_controllers.containsKey(T)) {
      final controller = _controllers.remove(T)!;
      controller.close();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _isDisposed = true;
    log(
      'RingCueMaster disposed successfully.',
      name: 'RingCueMaster',
    );
  }
}
