// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';

/// A widget that safely handles the disposal of controllers when removed from the tree.
@Deprecated('This widget is useless, handle dispose by Presenter\'s lifecycle')
class JokerTrap extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// List of controllers that should be disposed when this widget is disposed.
  final List<Object> _controllers;

  /// Creates a JokerTrap that will automatically dispose the given controllers.
  ///
  /// This widget is normally created by the [Trapeze] extension methods.
  const JokerTrap._({
    required this.child,
    required List<Object> controllers,
  }) : _controllers = controllers;

  @override
  State<JokerTrap> createState() => _JokerTrapState();
}

class _JokerTrapState extends State<JokerTrap> {
  @override
  void dispose() {
    for (final controller in widget._controllers) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      } else if (controller is TextEditingController) {
        controller.dispose();
      } else if (controller is ScrollController) {
        controller.dispose();
      } else if (controller is AnimationController) {
        controller.dispose();
      } else if (controller is StreamSubscription) {
        controller.cancel();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension that allows controllers to be auto-disposed.
extension Trapeze on Object {
  /// Registers this controller to be automatically disposed when the returned widget
  /// is removed from the widget tree.
  ///
  /// Use it like this:
  /// ```dart
  /// TextEditingController().trapeze(TextField(...))
  /// ```
  Widget trapeze(Widget child) {
    return JokerTrap._(
      controllers: [this],
      child: child,
    );
  }
}

/// Extension for combining multiple controllers to be disposed.
extension TrapezeArtist on List<Object> {
  /// Registers multiple controllers to be automatically disposed when the returned widget
  /// is removed from the widget tree.
  ///
  /// Use it like this:
  /// ```dart
  /// [controller1, controller2].trapeze(Column(...))
  /// ```
  Widget trapeze(Widget child) {
    return JokerTrap._(
      controllers: this,
      child: child,
    );
  }
}
