import 'dart:async';

import 'package:circus_ring/circus_ring.dart';

import '../../../cue_master.dart';

// ignore_for_file: constant_identifier_names
const String _DEFAULT_RING_CUE_MASTER_TAG_INTERNAL =
    '__default_ring_cue_master_instance__';

extension CircusRingCueMasterExtension on CircusRing {
  /// Retrieves or lazily creates a [CueMaster] (implemented by [RingCueMaster])
  /// associated with the given [tag].
  ///
  /// If no [tag] is provided, it refers to the default [CueMaster].
  /// The [RingCueMaster] instances are registered as [Disposable] with CircusRing,
  /// so they will be automatically disposed when `CircusRing.fire()` or `CircusRing.fireAll()`
  /// is called on them.
  ///
  /// [tag]: Optional tag to identify a specific event bus.
  /// [allowReplace]: If a `CueMaster` with the same tag already exists,
  ///                 setting this to `true` will replace the old one.
  ///                 The old one will be disposed by `CircusRing.hire` if it's `Disposable`.
  CueMaster getCueMaster({String? tag, bool allowReplace = false}) {
    final effectiveTag = tag ?? _DEFAULT_RING_CUE_MASTER_TAG_INTERNAL;

    // Try to find an existing CueMaster
    try {
      // If allowReplace is false and it exists, find will return it.
      // If allowReplace is true, hire will handle replacement.
      if (!allowReplace && isHired<CueMaster>(effectiveTag)) {
        return find<CueMaster>(effectiveTag);
      }
      // If it doesn't exist, or if allowReplace is true, hire (or re-hire) it.
      // hireLazily ensures it's only created when first find is called.
      // However, for simplicity and to match the Facade approach more closely,
      // let's use hire directly. If lazy is strictly needed, hireLazily is an option.

      // Check if we need to hire or if find is enough (if !allowReplace and exists)
      if (isHired<CueMaster>(effectiveTag) && !allowReplace) {
        return find<CueMaster>(effectiveTag);
      }

      // If it doesn't exist, or if allowReplace is true:
      final newCueMaster = RingCueMaster();
      // Use `hire` which handles replacement and disposal of old if `allowReplace` is true.
      return hire<CueMaster>(
        newCueMaster,
        tag: effectiveTag,
        alias: CueMaster, // Explicitly register as CueMaster
        allowReplace: allowReplace,
      );
    } catch (e) {
      // This catch block might be redundant if hire/find logic is robust.
      // It was more relevant for a manual try-catch-create pattern.
      // For now, let's assume hire handles non-existence by creating.
      // If hire fails for other reasons, it will throw.

      // Fallback if tryFind was used or complex logic:
      // final newCueMaster = RingCueMaster();
      // return hire<CueMaster>(
      //   newCueMaster,
      //   tag: effectiveTag,
      //   alias: CueMaster,
      //   allowReplace: allowReplace, // This is important
      // );
      // Rethrow if it's not a "not found" scenario that hire should handle
      rethrow;
    }
  }

  /// Listens for cues/events of type [T] on a [CueMaster].
  ///
  /// [handler]: The function to call when a cue of type [T] is received.
  /// [tag]: Optional tag to identify a specific event bus. If null, uses the default bus.
  ///
  /// Returns a [StreamSubscription] that can be used to cancel the listening.
  StreamSubscription<T> onCue<T>(
    void Function(T cue) handler, {
    String? tag,
  }) {
    final bus = getCueMaster(tag: tag);
    return bus.listen<T>(handler);
  }

  /// Sends a cue/event of type [T] on a [CueMaster].
  ///
  /// [cue]: The cue/event object to send.
  /// [tag]: Optional tag to identify a specific event bus. If null, uses the default bus.
  ///
  /// Returns `true` if the cue was successfully sent (i.e., the bus is not disposed
  /// and had a controller for the cue type), `false` otherwise.
  bool sendCue<T>(T cue, {String? tag}) {
    final bus = getCueMaster(tag: tag);
    return bus.sendCue<T>(cue);
  }

  /// Disposes the [CueMaster] (event bus) associated with the given [tag].
  ///
  /// If no [tag] is provided, it disposes the default event bus.
  /// This internally calls `CircusRing.fire<CueMaster>()`, which will trigger
  /// the `dispose()` method on the [RingCueMaster] instance because it
  /// implements `Disposable`.
  ///
  /// [tag]: Optional tag of the event bus to dispose.
  /// Returns `true` if the bus was found and `fire` was called, `false` otherwise.
  bool disposeCueMaster({String? tag}) {
    final effectiveTag = tag ?? _DEFAULT_RING_CUE_MASTER_TAG_INTERNAL;
    if (isHired<CueMaster>(effectiveTag)) {
      return fire<CueMaster>(tag: effectiveTag);
    }
    return false; // Not hired, so nothing to fire.
  }

  /// A convenience getter for the default [CueMaster].
  /// Same as `Circus.getCueMaster()`.
  CueMaster get defaultCueMaster => getCueMaster();
}

// You can also provide global accessors similar to `Circus` or `Ring`
// if you prefer that style, but the extension methods on `CircusRing.instance`
// (or `Circus` / `Ring` aliases) are often cleaner.

// Example of global accessors (optional):
// CueMaster getCueMaster({String? tag}) => CircusRing.instance.getCueMaster(tag: tag);
// StreamSubscription<T> onCue<T>(void Function(T cue) handler, {String? tag}) =>
//    CircusRing.instance.onCue<T>(handler, tag: tag);
// bool sendCue<T>(T cue, {String? tag}) => CircusRing.instance.sendCue<T>(cue, tag: tag);
// bool disposeCueMaster({String? tag}) => CircusRing.instance.disposeCueMaster(tag: tag);
// CueMaster get defaultCueMaster => CircusRing.instance.defaultCueMaster;
