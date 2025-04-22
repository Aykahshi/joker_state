import 'package:flutter/widgets.dart';

import '../joker/joker.dart';

/// Abstract base class providing a simple lifecycle (init -> ready -> done)
/// on top of a Joker, designed for Flutter integration.
///
/// Commonly used as a Controller or Presenter in UI patterns.
abstract class Presenter<T> extends Joker<T> {
  Presenter(
    super.initialState, {
    super.autoNotify,
    super.keepAlive,
    super.tag,
  }) {
    try {
      onInit(); // Call initialization logic immediately.
    } catch (e, s) {
      debugPrint(
          '[Presenter] Error during onInit for ${tag ?? runtimeType}: $e\n$s');
    }

    // Schedule onReady after the first frame.
    try {
      // Ensure WidgetsBinding is initialized before scheduling the callback.
      final binding = WidgetsFlutterBinding.ensureInitialized();
      binding.addPostFrameCallback((_) {
        // Only call onReady if the instance hasn't been disposed in the meantime.
        if (!isDisposed) {
          // Use the getter from Joker
          try {
            onReady();
          } catch (e, s) {
            debugPrint(
                '[Presenter] Error during onReady for ${tag ?? runtimeType}: $e\n$s');
          }
        }
      });
    } catch (e, s) {
      debugPrint(
          '[Presenter] Error scheduling onReady for ${tag ?? runtimeType}: $e\n$s');
    }
  }

  /// Called immediately after the Presenter instance is constructed.
  /// Ideal for basic setup and internal initializations.
  @protected
  @mustCallSuper
  void onInit() {
    debugPrint('[Presenter] onInit: ${tag ?? runtimeType}');
  }

  /// Called 1 frame after [onInit].
  /// Suitable for actions requiring the first frame to be built
  /// (e.g., showing dialogs, navigation, async calls based on initial UI).
  @protected
  @mustCallSuper
  void onReady() {
    debugPrint('[Presenter] onReady: ${tag ?? runtimeType}');
  }

  /// Called just before the Presenter instance is disposed.
  /// Use this for cleanup (canceling timers, closing streams, etc.).
  @protected
  @mustCallSuper
  void onDone() {
    debugPrint('[Presenter] onDone: ${tag ?? runtimeType}');
  }

  /// Overrides Joker's dispose to incorporate the onDone lifecycle hook.
  @override
  @mustCallSuper
  void dispose() {
    // Use isDisposed getter from Joker base class
    if (!isDisposed) {
      try {
        onDone(); // Call the cleanup hook first.
      } catch (e, s) {
        debugPrint(
            '[Presenter] Error during onDone for ${tag ?? runtimeType}: $e\n$s');
      }
      // Call Joker's dispose method (which handles _isDisposed flag and ChangeNotifier disposal)
      super.dispose();
    }
  }
}
