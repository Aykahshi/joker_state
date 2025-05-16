import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'presenter_interface.dart';

final _engine = WidgetsFlutterBinding.ensureInitialized();

/// Abstract base class providing a simple lifecycle (init -> ready -> done)
/// on top of a PresenterInterface, designed for Flutter integration.
///
/// Commonly used as a Controller or Presenter in UI patterns.
abstract class Presenter<T> extends PresenterInterface<T> {
  /// Optional tag for identification or debugging purposes
  final String? tag;

  /// Optional flag to enable debug logging
  final bool enableDebugLog;

  Presenter(
    super.initialState, {
    this.tag,
    this.enableDebugLog = kDebugMode,
    super.keepAlive = false,
    super.autoNotify = true,
  }) {
    _safeCall(this, onInit, 'onInit');

    // Schedule onReady after the first frame.
    // Ensure WidgetsBinding is initialized before scheduling the callback.
    _engine.addPostFrameCallback((_) {
      // Only call onReady if the instance hasn't been disposed in the meantime.
      if (!isDisposed) {
        // Use the getter from PresenterInterface
        _safeCall(this, onReady, 'onReady');
      }
    });
  }

  /// Called immediately after the Presenter instance is constructed.
  /// Ideal for basic setup and internal initializations.
  @override
  @protected
  @mustCallSuper
  void onInit() {
    if (enableDebugLog) {
      _log('onInit: $runtimeType tag: $tag');
    }
  }

  /// Called 1 frame after [onInit].
  /// Suitable for actions requiring the first frame to be built
  /// (e.g., showing dialogs, navigation, async calls based on initial UI).
  @override
  @protected
  @mustCallSuper
  void onReady() {
    if (enableDebugLog) {
      _log('onReady: $runtimeType tag: $tag');
    }
  }

  /// Called just before the Presenter instance is disposed.
  /// Use this for cleanup (canceling timers, closing streams, etc.).
  @override
  @protected
  @mustCallSuper
  void onDone() {
    if (enableDebugLog) {
      _log('onDone: $runtimeType tag: $tag');
    }
  }
}

void _log(String message) {
  log('--- $message ---', name: 'Presenter');
}

/// Safely calls a lifecycle method with error handling
void _safeCall(
    PresenterInterface presenter, void Function() callback, String methodName) {
  try {
    callback();
  } catch (e) {
    _log('Error during $methodName in ${presenter.runtimeType}');
  }
}
