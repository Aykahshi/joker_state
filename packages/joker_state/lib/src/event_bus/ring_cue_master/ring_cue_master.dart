import 'dart:async';
import 'dart:developer';

import 'package:circus_ring/circus_ring.dart';

import 'cue_master.dart';

/// A Dart Stream-based implementation of [CueMaster].
///
/// This implementation uses a `StreamController.broadcast` for each event type,
/// allowing multiple listeners for each event stream.
/// It implements [Disposable] for automatic cleanup with CircusRing.
class RingCueMaster implements CueMaster, Disposable {
  // A map to hold StreamControllers for different event types.
  // The key is the Type of the cue, and the value is the StreamController for that cue.
  // We use `dynamic` for the StreamController's generic type here, but it's cast
  // to the correct type `T` in `_getController`.
  final Map<Type, StreamController<dynamic>> _controllers = {};

  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  /// Retrieves or creates a [StreamController] for the given type [T].
  StreamController<T> _getController<T>() {
    if (_isDisposed) {
      throw StateError('Cannot send cues after dispose');
    }
    // `putIfAbsent` ensures that if a controller for type T doesn't exist,
    // a new one is created and added to the map.
    // It's crucial to cast the result to `StreamController<T>` as the map
    // stores `StreamController<dynamic>`. This cast is safe because we always
    // create `StreamController<T>.broadcast()` for key `T`.
    return _controllers.putIfAbsent(T, () => StreamController<T>.broadcast())
        as StreamController<T>;
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