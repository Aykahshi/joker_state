import 'dart:async';

/// The base interface for event bus.
///
/// It dispatches typed cue signals (events), and listens for them through broadcast streams.
///
/// You may implement your own [CueMaster], or use [RingCueMaster] for default logic.
abstract class CueMaster {
  /// Returns a stream of cues of type T.
  Stream<T> on<T>();

  /// Sends a cue of type T to all listeners.
  bool sendCue<T>(T cue);

  /// Listens for cues of type T and returns a subscription.
  StreamSubscription<T> listen<T>(void Function(T cue) fn);

  /// Returns true if there are any listeners for cues of type T.
  bool hasListeners<T>();

  /// Resets the cue controller for type T, closing the stream and removing the controller.
  bool reset<T>();

  /// Disposes of all controllers and streams.
  void dispose();
}
