import 'dart:async';

import '../../di/circus_ring/src/circus_ring.dart';
import 'cue_master.dart';

/// Default implementation of [CueMaster].
///
/// Stores a controller per event type & broadcasts to listeners.
/// Can be reused across features or injected into widgets.
class RingCueMaster implements CueMaster {
  final _controllers = <Type, StreamController<dynamic>>{};

  @override
  Stream<T> on<T>() {
    return (_controllers[T] ??= StreamController<T>.broadcast()).stream
        as Stream<T>;
  }

  @override
  bool sendCue<T>(T cue) {
    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      controller.add(cue);
      return controller.hasListener;
    }
    return false;
  }

  @override
  StreamSubscription<T> listen<T>(void Function(T cue) callback) {
    return on<T>().listen(callback);
  }

  @override
  bool hasListeners<T>() {
    final controller = _controllers[T];
    return controller?.hasListener ?? false;
  }

  @override
  bool reset<T>() {
    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _controllers.remove(T);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }
}

/// 🎪 Extension to access the RingMaster — singleton cue controller for the entire app.
extension RingMasterExtension on CircusRing {
  /// Returns or initializes the global [CueMaster] implement as [RingCueMaster].
  /// if not found, it will be hired with the tag "ringMaster"
  /// it will be registered with key "CueMaster_$tag" in CircusRing
  /// you can implement your own, and pass the unique tag
  /// e.g. Circus.hire(CustomCueMaster(), tag: 'customMaster') or
  /// Circus.ringMaster(tag: 'customMaster')
  CueMaster ringMaster([String tag = 'ringMaster']) {
    final master = tryFind<CueMaster>(tag);
    if (master == null) {
      return hire<CueMaster>(RingCueMaster(), tag: tag);
    }
    return master;
  }

  /// Triggers a cue (typed signal) through the master.
  bool cue<T>(T cue, [String tag = 'ringMaster']) {
    return ringMaster(tag).sendCue(cue);
  }

  /// Listens for a specific cue type and returns subscription.
  StreamSubscription<T> onCue<T>(void Function(T cue) callback,
      [String tag = 'ringMaster']) {
    return ringMaster(tag).listen(callback);
  }
}
