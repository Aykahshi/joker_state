import 'dart:async';

import 'ring_cue_master.dart';

/// The base interface for all cue controllers in the Circus runtime.
///
/// It dispatches typed cue signals (events), and listens for them through broadcast streams.
///
/// You may implement your own [CueMaster], or use [RingCueMaster] for default logic.
abstract class CueMaster {
  Stream<T> on<T>();

  bool sendCue<T>(T cue);

  StreamSubscription<T> listen<T>(void Function(T cue));
  bool hasListeners<T>();
  bool reset<T>();

  void dispose();
}
