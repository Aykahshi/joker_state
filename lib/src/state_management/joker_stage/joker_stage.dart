import 'package:flutter/widgets.dart';

import '../../di/circus_ring/circus_ring.dart';
import '../joker/joker.dart';
import '../joker/joker_trickx.dart';

/// Builder function for the JokerStage widget
///
/// Takes a BuildContext and the current value of the Joker, and returns a Widget
typedef JokerStageBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// A widget that observes a single Joker instance and rebuilds when its value changes
///
/// JokerStage is a reactive widget that automatically rebuilds its UI whenever
/// the observed Joker's value changes, making it easy to create reactive UIs.

/// JokerStage is a widget that observes a Joker and rebuilds when its value changes
///
/// Usage examples:
///
/// Basic usage:
/// ```dart
/// // Create a Joker
/// final counter = Joker<int>(0);
///
/// // Use JokerStage to build UI based on the Joker's value
/// @override
/// Widget build(BuildContext context) {
///   return JokerStage<int>(
///     joker: counter,
///     builder: (context, value) {
///       return Text('Count: $value');
///     },
///   );
/// }
///
/// // Later, update the Joker's value
/// counter.trick(counter.value + 1);
/// // The JokerStage will automatically rebuild with the new value
/// ```
///
/// Using extension method:
/// ```dart
/// // Create a Joker
/// final counter = Joker<int>(0);
///
/// // Use the perform extension for a cleaner API
/// @override
/// Widget build(BuildContext context) {
///   return counter.perform((context, value) {
///     return Text('Count: $value');
///   });
/// }
/// ```
///
/// With CircusRing integration:
/// ```dart
/// // In a setup or initialization method
/// Circus.summon<int>(0, tag: 'counter');
///
/// // In a widget build method
/// @override
/// Widget build(BuildContext context) {
///   final counter = Circus.spotlight<int>(tag: 'counter');
///   return counter.perform((context, value) {
///     return Column(
///       children: [
///         Text('Count: $value'),
///         ElevatedButton(
///           onPressed: () => counter.trick(value + 1),
///           child: Text('Increment'),
///         ),
///       ],
///     );
///   });
/// }
/// ```

class JokerStage<T> extends StatefulWidget {
  /// Creates a JokerStage widget
  ///
  /// [joker]: The Joker instance to observe
  /// [builder]: Function that builds UI based on the current value
  /// [autoDispose]: Whether to automatically dispose the Joker when this widget is disposed
  const JokerStage({
    super.key,
    required this.joker,
    this.autoDispose = true,
    required this.builder,
  });

  /// The Joker instance being observed
  ///
  /// Changes to this Joker's value will trigger rebuilds of the widget
  final Joker<T> joker;

  /// UI builder function that receives the current Joker value
  ///
  /// Called whenever the Joker's value changes
  final JokerStageBuilder<T> builder;

  /// Whether to automatically dispose the Joker when this widget is disposed
  ///
  /// When true, the Joker will be disposed or removed from CircusRing
  /// when this widget is removed from the widget tree
  final bool autoDispose;

  @override
  State<JokerStage<T>> createState() => _JokerStageState<T>();
}

/// State for JokerStage widget
class _JokerStageState<T> extends State<JokerStage<T>> {
  /// Current value of the observed Joker
  late T _value;

  @override
  void initState() {
    super.initState();
    // Initialize with current value
    _value = widget.joker.value;
    // Start listening for changes
    widget.joker.addListener(_updateState);
  }

  /// Update state when Joker value changes
  void _updateState() {
    if (mounted) {
      setState(() {
        _value = widget.joker.value;
      });
    }
  }

  @override
  void didUpdateWidget(JokerStage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the Joker instance changed, update listeners and values
    if (widget.joker != oldWidget.joker) {
      oldWidget.joker.removeListener(_updateState);
      _value = widget.joker.value;
      widget.joker.addListener(_updateState);
    }
  }

  @override
  void dispose() {
    // Stop listening for changes
    widget.joker.removeListener(_updateState);

    // If auto-dispose is enabled, clean up the Joker
    if (widget.autoDispose) {
      // Check if this Joker has a tag
      final tag = widget.joker.tag;
      if (tag != null && tag.isNotEmpty) {
        // Check if the Joker is registered in CircusRing
        try {
          final registeredJoker = Circus.spotlight<T>(tag: tag);
          // If the Joker is registered and the same instance, remove it from CircusRing
          if (identical(registeredJoker, widget.joker)) {
            Circus.vanish<T>(tag: tag);
          } else {
            // If the Joker is registered but not the same instance, dispose it directly
            widget.joker.dispose();
          }
        } catch (_) {
          // If the Joker is not registered, dispose it directly
          widget.joker.dispose();
        }
      } else {
        // If the Joker has no tag, dispose it directly
        widget.joker.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pass the current value to the builder function
    return widget.builder(context, _value);
  }
}
