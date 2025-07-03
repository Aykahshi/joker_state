import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../foundation/joker_act.dart';

/// A widget that makes a [JokerAct] instance available to its descendants
/// using the `provider` package.
///
/// [JokerRing] simplifies dependency injection for [Joker] and [Presenter]
/// instances by placing them into the widget tree's context.
/// Descendant widgets can then easily access these instances using standard
/// `context.watch<JokerAct<T>>()` or `context.read<JokerAct<T>>()` methods,
/// or the convenient `context.watchAct<T>()`, `context.readAct<T>()` and
/// `context.selectAct<T, S>()` extensions.
///
/// This widget is designed to provide a single [JokerAct] instance of a given
/// type [T] to its subtree. If you need to provide multiple instances of the
/// same type, consider using `MultiProvider` with distinct types or a `Map<String, JokerAct<T>>`.
///
/// {@tool snippet}
/// ### Basic Usage
///
/// ```dart
/// final counterJoker = Joker<int>(0);
///
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return JokerRing<int>(
///       act: counterJoker,
///       child: MaterialApp(
///         home: Scaffold(
///           appBar: AppBar(title: const Text('Counter App')),
///           body: Center(
///             child: Builder(
///               builder: (context) {
///                 // Access the JokerAct instance from the context and listen for changes
///                 final counter = context.watch<JokerAct<int>>();
///                 return Text('Count: ${counter.value}');
///               },
///             ),
///           ),
///           floatingActionButton: FloatingActionButton(
///             onPressed: () => counterJoker.trick(counterJoker.value + 1),
///             child: const Icon(Icons.add),
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// ### Using Context Extensions
///
/// ```dart
/// // Inside a build method:
/// final counter = context.watchAct<int>(); // Watches for changes
/// final anotherCounter = context.readAct<int>(); // Reads without watching
///
/// // Select a specific part of the state:
/// final userName = context.selectAct<User, String>(
///   selector: (userAct) => userAct.value.name,
/// );
/// ```
/// {@end-tool}
class JokerRing<T> extends StatelessWidget {
  /// Creates a [JokerRing] to provide a [JokerAct] instance to its descendants.
  const JokerRing({
    super.key,
    required this.act,
    required this.child,
  });

  /// The [JokerAct] instance to be provided to the widget tree.
  final JokerAct<T> act;

  /// The widget subtree that will have access to the provided [JokerAct].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<JokerAct<T>>.value(
      value: act,
      child: child,
    );
  }
}

/// Extension on [BuildContext] for convenient access to [JokerAct] instances.
extension JokerActContextExtension on BuildContext {
  /// Retrieves the [JokerAct] of type [T] from the widget tree and listens to it.
  ///
  /// This is a shortcut for `Provider.of<JokerAct<T>>(this, listen: true)`
  /// and will cause the widget to rebuild when the [JokerAct] notifies changes.
  JokerAct<T> watchAct<T>() => watch<JokerAct<T>>();

  /// Retrieves the [JokerAct] of type [T] from the widget tree without listening.
  ///
  /// This is a shortcut for `Provider.of<JokerAct<T>>(this, listen: false)`
  /// and will NOT cause the widget to rebuild when the [JokerAct] notifies changes.
  JokerAct<T> readAct<T>() => read<JokerAct<T>>();
}
