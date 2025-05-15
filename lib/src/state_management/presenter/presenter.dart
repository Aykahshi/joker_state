import 'dart:developer';

import 'package:flutter/widgets.dart';

import 'presenter_interface.dart';

/// Abstract base class providing a simple lifecycle (init -> ready -> done)
/// on top of a PresenterInterface, designed for Flutter integration.
///
/// Commonly used as a Controller or Presenter in UI patterns.
abstract class Presenter<T> extends PresenterInterface<T> {
  /// Optional tag for identification or debugging purposes
  final String? tag;

  Presenter(
    super.initialState, {
    this.tag = '',
    super.keepAlive = false,
    super.autoNotify,
  }) {
    try {
      onInit(); // Call initialization logic immediately.
    } catch (e, s) {
      _log('Error during onInit for ${tag ?? runtimeType}: $e\n$s');
    }

    // Schedule onReady after the first frame.
    try {
      // Ensure WidgetsBinding is initialized before scheduling the callback.
      final binding = WidgetsFlutterBinding.ensureInitialized();
      binding.addPostFrameCallback((_) {
        // Only call onReady if the instance hasn't been disposed in the meantime.
        if (!isDisposed) {
          // Use the getter from PresenterInterface
          try {
            onReady();
          } catch (e, s) {
            _log('Error during onReady for ${tag ?? runtimeType}: $e\n$s');
          }
        }
      });
    } catch (e, s) {
      _log('Error scheduling onReady for ${tag ?? runtimeType}: $e\n$s');
    }
  }

  /// Called immediately after the Presenter instance is constructed.
  /// Ideal for basic setup and internal initializations.
  @override
  void onInit() {
    super.onInit();
    _log('onInit: $runtimeType tag: $tag');
  }

  /// Called 1 frame after [onInit].
  /// Suitable for actions requiring the first frame to be built
  /// (e.g., showing dialogs, navigation, async calls based on initial UI).
  @override
  void onReady() {
    super.onReady();
    _log('onReady: $runtimeType tag: $tag');
  }

  /// Called just before the Presenter instance is disposed.
  /// Use this for cleanup (canceling timers, closing streams, etc.).
  @override
  void onDone() {
    _log('onDone: $runtimeType tag: $tag');
    super.onDone();
  }

  /// Overrides PresenterInterface's dispose method.
  @override
  void dispose() {
    if (!isDisposed) {
      super.dispose();
    }
  }
}

void _log(String message) {
  log('--- $message ---', name: 'Presenter');
}
