import 'dart:developer';

// Import foundation for kDebugMode
import 'package:flutter/foundation.dart';

import 'circus_ring_exception.dart';
import 'disposable.dart';

part 'circus_ring_findx.dart';
part 'circus_ring_firex.dart';
part 'circus_ring_hirex.dart';

/// A function that creates an instance of type T
typedef FactoryFunc<T> = T Function();

/// A function that asynchronously creates an instance of type T
typedef AsyncFactoryFunc<T> = Future<T> Function();

/// Global access point for the CircusRing dependency injection container
// ignore: non_constant_identifier_names
CircusRing get Circus => CircusRing.instance;

/// You can choose the alias you like to access the CircusRing instance
// ignore: non_constant_identifier_names
CircusRing get Ring => CircusRing.instance;

/// A lightweight dependency injection container for Flutter applications
///
/// CircusRing manages object creation and lifetime in your application
/// with support for singletons, factories, lazy-loading, and async dependencies.
class CircusRing {
  // Singleton pattern
  CircusRing._internal();

  static final CircusRing _instance = CircusRing._internal();

  factory CircusRing() => _instance;

  /// Direct access to instance shorthand
  static CircusRing get instance => _instance;

  /// Container for storing instances
  final _instances = <String, dynamic>{};

  /// Container for storing factory methods
  final _factories = <String, FactoryFunc>{};

  /// Container for storing lazy factory methods
  final _lazyFactories = <String, FactoryFunc>{};

  /// Container for storing lazy async factory methods
  final _lazyAsyncSingleton = <String, AsyncFactoryFunc>{};

  /// Container for storing dependents
  final _dependents = <String, Set<String>>{};

  /// Container for storing dependencies
  final _dependencies = <String, Set<String>>{};

  /// Stores fenix builders for auto-rebind after dispose.
  final _fenixBuilders = <String, FactoryFunc>{};

  /// Stores fenix async builders for auto-rebind after dispose.
  final _fenixAsyncBuilders = <String, AsyncFactoryFunc>{};

  /// Enable/Disable debug logging.
  bool _enableLogs = kDebugMode;

  /// Allow developer to enable/disable debug logging manually.
  set enableLogs(bool enable) => _enableLogs = enable;

  /// Log output
  /// Prints debug information if _enableLogs is true.
  void _log(String message) {
    if (_enableLogs) {
      log('--- $message ---', name: 'CircusRing');
    }
  }

  /// Flag to indicate if the CircusRing has been disposed.
  bool _isDisposed = false;

  /// Establishes a dependency relationship between two registered instances.
  ///
  /// Call this when one type (T) depends on another (D). This ensures the
  /// depended-on instance cannot be removed while its dependents are still registered.
  ///
  /// Example:
  /// ```dart
  /// Circus.bindDependency<UserRepo, ApiService>();
  /// ```
  ///
  /// [tagT]: Optional tag for dependent (type T)
  /// [tagD]: Optional tag for dependency (type D)
  void bindDependency<T, D>({String? tagT, String? tagD}) {
    final tKey = _getKey(T, tagT);
    final dKey = _getKey(D, tagD);

    _dependencies.putIfAbsent(tKey, () => {}).add(dKey);
    _dependents.putIfAbsent(dKey, () => {}).add(tKey);

    _log('Bound $tKey → $dKey successfully');
  }

  /// Generate unique instance key
  ///
  /// Creates a unique identifier for each registered dependency
  /// based on its type, optional tag, and optional alias
  String _getKey(Type type, [String? tag, Type? alias]) {
    final actualType = alias ?? type;
    return tag != null
        ? '${actualType.toString()}_$tag'
        : actualType.toString();
  }

  /// Disposes the CircusRing itself, making it unusable.
  /// Calls [fireAll] first to clear internal state asynchronously.
  Future<void> dispose() async {
    if (!_isDisposed) {
      await fireAll(); // Clear instances first
      _isDisposed = true;
      _log('CircusRing instance has been disposed');
    }
  }

  // --- Internal Helper for Replacing/Deleting Single Instance ---
  // This method is called internally when replacing an existing registration.
  // It should also apply the conditional dispose logic.
  bool _deleteSingle<T extends Object>(
      {required String key, bool isReplacing = false}) {
    final instance = _instances.remove(key);
    final factoryRemoved = _factories.remove(key) != null;
    final lazyFactoryRemoved = _lazyFactories.remove(key) != null;
    final fenixRemoved = _fenixBuilders.remove(key) != null;

    bool instanceRemoved = instance != null;
    bool didDispose = false; // Track if dispose was called

    if (instanceRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} instance: $key');

      if (instance is Disposable) {
        try {
          _log('Disposing Disposable during delete/replace: $key');
          instance.dispose();
          didDispose = true;
        } catch (e, s) {
          _log(
              'Error disposing Disposable during delete/replace $key: $e\\n$s');
        }
      } else if (instance is ChangeNotifier) {
        try {
          _log('Disposing ChangeNotifier during delete/replace: $key');
          instance.dispose();
          didDispose = true;
        } catch (e, s) {
          _log(
              'Error disposing ChangeNotifier during delete/replace $key: $e\\n$s');
        }
      }
    } else if (factoryRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} factory: $key');
    } else if (lazyFactoryRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} lazy factory: $key');
    } else if (fenixRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} fenix builder: $key');
    }

    // An instance or factory was removed
    bool bindingRemoved =
        instanceRemoved || factoryRemoved || lazyFactoryRemoved || fenixRemoved;

    // Clear dependencies if a binding was actually removed
    if (bindingRemoved) {
      _clearDependenciesFor(key);
    }

    // Return true if a binding was removed OR if dispose was successfully called
    // (Consider removal successful even if only dispose happened, though usually implies instance removal)
    return bindingRemoved || didDispose;
  }

  // Async version of _deleteSingle
  Future<bool> _deleteSingleAsync<T extends Object>(
      {required String key, bool isReplacing = false}) async {
    final instance = _instances.remove(key);
    final lazyAsyncRemoved = _lazyAsyncSingleton.remove(key) != null;
    final fenixAsyncRemoved = _fenixAsyncBuilders.remove(key) != null;

    bool instanceRemoved = instance != null;
    bool didDispose = false; // Track if dispose was called

    if (instanceRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} async instance: $key');

      if (instance is AsyncDisposable) {
        try {
          _log('Disposing AsyncDisposable during async delete/replace: $key');
          await instance.dispose();
          didDispose = true;
        } catch (e, s) {
          _log(
              'Error disposing AsyncDisposable during async delete/replace $key: $e\\n$s');
        }
      } else if (instance is Disposable) {
        try {
          _log('Disposing Disposable during async delete/replace: $key');
          instance.dispose();
          didDispose = true;
        } catch (e, s) {
          _log(
              'Error disposing Disposable during async delete/replace $key: $e\\n$s');
        }
      } else if (instance is ChangeNotifier) {
        try {
          _log('Disposing ChangeNotifier during async delete/replace: $key');
          instance.dispose();
          didDispose = true;
        } catch (e, s) {
          _log(
              'Error disposing ChangeNotifier during async delete/replace $key: $e\\n$s');
        }
      }
    } else if (lazyAsyncRemoved) {
      _log(
          '${isReplacing ? "Replacing" : "Deleting"} async lazy factory: $key');
    } else if (fenixAsyncRemoved) {
      _log(
          '${isReplacing ? "Replacing" : "Deleting"} async fenix builder: $key');
    }

    // An async instance or factory was removed
    bool bindingRemoved =
        instanceRemoved || lazyAsyncRemoved || fenixAsyncRemoved;

    // Clear dependencies if a binding was actually removed
    if (bindingRemoved) {
      _clearDependenciesFor(key);
    }

    // Return true if a binding was removed OR if dispose was successfully called
    return bindingRemoved || didDispose;
  }

  // Helper to clear dependencies AND dependents for a removed key
  void _clearDependenciesFor(String removedKey) {
    // Remove from dependency lists of others
    final dependents = _dependents.remove(removedKey) ?? {};
    for (final dependentKey in dependents) {
      _dependencies[dependentKey]?.remove(removedKey);
      if (_dependencies[dependentKey]?.isEmpty ?? false) {
        _dependencies.remove(dependentKey);
      }
    }

    // Remove its own dependencies from others' dependent lists
    final dependencies = _dependencies.remove(removedKey) ?? {};
    for (final dependencyKey in dependencies) {
      _dependents[dependencyKey]?.remove(removedKey);
      if (_dependents[dependencyKey]?.isEmpty ?? false) {
        _dependents.remove(dependencyKey);
      }
    }
    _log('Cleared dependencies for: $removedKey');
  }
}
