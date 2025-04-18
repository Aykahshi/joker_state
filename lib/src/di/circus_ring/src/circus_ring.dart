import 'dart:developer';

// Import foundation for kDebugMode
import 'package:flutter/foundation.dart';

import '../../../state_management/joker/joker.dart';
import 'circus_ring_exception.dart';
import 'disposable.dart';

/// A function that creates an instance of type T
typedef FactoryFunc<T> = T Function();

/// A function that asynchronously creates an instance of type T
typedef AsyncFactoryFunc<T> = Future<T> Function();

/// Global access point for the CircusRing dependency injection container
// ignore: non_constant_identifier_names
CircusRing get Circus => CircusRing.instance;

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

  /// Log output
  ///
  /// Prints debug information if kDebugMode is true.
  void _log(String message) {
    // Directly check kDebugMode instead of _enableLogs
    if (kDebugMode) {
      log('[🃏CircusRing] $message');
    }
  }

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

    _log('[🧷] Bound $tKey → $dKey');
  }

  /// Generate unique instance key
  ///
  /// Creates a unique identifier for each registered dependency
  /// based on its type and optional tag
  String _getKey(Type type, [String? tag]) {
    /// If CueMaster, just use CueMaster_$tag
    /// because there might be some class like CustomCueMaster
    /// and if we use CustomCueMaster_$tag, it will be conflict
    /// Circus.ringMaster() can not find the CustomCueMaster
    if (type.toString().contains('CueMaster')) {
      return 'CueMaster_$tag';
    }

    return tag != null ? '${type.toString()}_$tag' : type.toString();
  }

  /// Removes an instance of type [T] with the specified [tag] from the registry.
  /// Returns `true` if the instance was found and removed, `false` otherwise.
  /// Conditionally calls `dispose` on the removed instance if it implements
  /// `Disposable` or `ChangeNotifier`, **unless** it is a `Joker` instance.
  /// `Joker` instances manage their own lifecycle.
  /// Throws [CircusRingException] if trying to dispose an [AsyncDisposable] synchronously.
  bool fire<T extends Object>({String? tag}) {
    _checkDisposed();
    final key = _getKey(T, tag);

    final instance = _instances[key];
    if (instance == null) {
      // Also check factories etc. to allow removing non-instantiated bindings
      final factoryRemoved = _factories.remove(key) != null;
      final lazyFactoryRemoved = _lazyFactories.remove(key) != null;
      final fenixRemoved = _fenixBuilders.remove(key) != null;
      final lazyAsyncRemoved =
          _lazyAsyncSingleton.remove(key) != null; // Check async lazy too
      final fenixAsyncRemoved =
          _fenixAsyncBuilders.remove(key) != null; // Check async fenix too

      if (factoryRemoved ||
          lazyFactoryRemoved ||
          fenixRemoved ||
          lazyAsyncRemoved ||
          fenixAsyncRemoved) {
        _log('Binding removed (was not instantiated): $key');
        // Clear dependencies even if not instantiated
        _clearDependenciesFor(key);
        return true;
      }
      // If neither instance nor any factory/builder found
      return false;
    }

    // Prevent removal if this instance is depended on by others
    if (_dependents.containsKey(key) &&
        (_dependents[key]?.isNotEmpty ?? false)) {
      final activeDependents = _dependents[key]!
          .where((depKey) => _instances.containsKey(depKey))
          .toList();
      if (activeDependents.isNotEmpty) {
        throw CircusRingException(
          "Cannot remove $key. It is still depended on by: ${activeDependents.join(", ")}",
        );
      }
      // If dependents list exists but all are inactive, clean it up.
      _dependents.remove(key);
    }

    // Also clear its own dependencies from others dependents lists
    _clearDependenciesFor(key);

    // Remove the instance first
    _instances.remove(key);
    _log('Instance removed: $key');

    // --- Conditionally dispose ---
    // Check for AsyncDisposable FIRST and throw if found in sync fire()
    if (instance is AsyncDisposable) {
      throw CircusRingException(
        'Cannot synchronously dispose $key (Type: ${instance.runtimeType}). '
        'It implements AsyncDisposable. Use fireAsync<$T>(tag: "$tag") instead.',
      );
    }
    // Only dispose if it's NOT a Joker and implements Disposable or ChangeNotifier
    if (instance is! Joker) {
      if (instance is Disposable) {
        try {
          _log('Disposing Disposable: $key');
          instance.dispose();
        } catch (e, s) {
          _log('Error disposing Disposable instance $key: $e\n$s');
        }
      } else if (instance is ChangeNotifier) {
        // Dispose ChangeNotifier as a fallback if not Disposable
        try {
          _log('Disposing ChangeNotifier: $key');
          instance.dispose();
        } catch (e, s) {
          _log('Error disposing ChangeNotifier instance $key: $e\n$s');
        }
      }
    } else {
      _log('Skipping dispose for Joker instance: $key (manages own lifecycle)');
    }
    // --- End Conditionally dispose ---

    return true;
  }

  /// Removes an instance by its tag (type is inferred or doesn't matter).
  /// Returns `true` if an instance with the tag was found and removed.
  /// Conditionally calls `dispose` (excluding Jokers).
  /// Handles both [Disposable] and [AsyncDisposable] appropriately.
  bool fireByTag(String tag) {
    _checkDisposed();
    if (tag.isEmpty) {
      throw CircusRingException('Tag cannot be empty for fireByTag.');
    }

    String? keyToRemove;
    dynamic instanceToRemove;

    // Find the key and instance first
    for (final key in _instances.keys) {
      // Improved tag matching logic
      final typeAndTag = key.split('_');
      if (typeAndTag.length > 1 && typeAndTag.last == tag) {
        keyToRemove = key;
        instanceToRemove = _instances[key];
        break;
      } else if (typeAndTag.length == 1 && key == tag) {
        // Handle cases with no type prefix (less common)
        keyToRemove = key;
        instanceToRemove = _instances[key];
        break;
      }
    }

    if (keyToRemove == null || instanceToRemove == null) {
      _log('Instance with tag "$tag" not found for removal.');
      return false;
    }

    // Prevent removal if this instance is depended on by others
    if (_dependents.containsKey(keyToRemove) &&
        (_dependents[keyToRemove]?.isNotEmpty ?? false)) {
      final activeDependents = _dependents[keyToRemove]!
          .where((depKey) => _instances.containsKey(depKey))
          .toList();
      if (activeDependents.isNotEmpty) {
        throw CircusRingException(
          "Cannot remove $keyToRemove (tag: $tag). It is still depended on by: ${activeDependents.join(", ")}",
        );
      }
      // If dependents list exists but all are inactive, clean it up.
      _dependents.remove(keyToRemove);
    }

    // Also clear its own dependencies from others dependents lists
    _clearDependenciesFor(keyToRemove);

    // Remove the instance
    _instances.remove(keyToRemove);
    _log('Instance removed by tag: $tag (key: $keyToRemove)');

    // --- Conditionally dispose ---
    // Check for AsyncDisposable FIRST and throw
    if (instanceToRemove is AsyncDisposable) {
      throw CircusRingException(
        'Cannot synchronously dispose instance with tag "$tag" (key: $keyToRemove, Type: ${instanceToRemove.runtimeType}). '
        'It implements AsyncDisposable. Use fireAsyncByTag(tag: "$tag") or fireAsync<Type>(tag: "$tag") instead.',
      );
    }
    if (instanceToRemove is! Joker) {
      if (instanceToRemove is Disposable) {
        try {
          _log('Disposing Disposable by tag: $tag');
          instanceToRemove.dispose();
        } catch (e, s) {
          _log(
              'Error disposing Disposable instance (tag: $tag) $keyToRemove: $e\n$s');
        }
      } else if (instanceToRemove is ChangeNotifier) {
        try {
          _log('Disposing ChangeNotifier by tag: $tag');
          instanceToRemove.dispose();
        } catch (e, s) {
          _log(
              'Error disposing ChangeNotifier instance (tag: $tag) $keyToRemove: $e\n$s');
        }
      }
    } else {
      _log('Skipping dispose for Joker instance by tag: $tag');
    }
    // --- End Conditionally dispose ---

    return true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw StateError(
        'This CircusRing instance has been disposed and cannot be used anymore.',
      );
    }
  }

  /// Clears all registered instances and dependencies.
  /// Conditionally calls `dispose` on instances (excluding Jokers).
  /// Handles both [Disposable] and [AsyncDisposable] appropriately.
  Future<void> fireAll() async {
    _checkDisposed();
    final keys = _instances.keys.toList(); // Get keys before iterating
    for (final key in keys) {
      final instance = _instances.remove(key);
      if (instance != null) {
        // --- Conditionally dispose (Async first) ---
        if (instance is! Joker) {
          if (instance is AsyncDisposable) {
            try {
              _log('fireAll: Disposing AsyncDisposable: $key');
              await instance.dispose();
            } catch (e, s) {
              _log('fireAll: Error disposing AsyncDisposable $key: $e\n$s');
            }
          } else if (instance is Disposable) {
            try {
              _log('fireAll: Disposing Disposable: $key');
              instance.dispose();
            } catch (e, s) {
              _log('fireAll: Error disposing Disposable $key: $e\n$s');
            }
          } else if (instance is ChangeNotifier) {
            try {
              _log('fireAll: Disposing ChangeNotifier: $key');
              instance.dispose();
            } catch (e, s) {
              _log('fireAll: Error disposing ChangeNotifier $key: $e\n$s');
            }
          }
        } else {
          _log('fireAll: Skipping dispose for Joker: $key');
        }
        // --- End Conditionally dispose ---
      }
    }
    // Clear remaining containers
    _factories.clear();
    _lazyFactories.clear();
    _lazyAsyncSingleton.clear();
    _fenixBuilders.clear();
    _fenixAsyncBuilders.clear();
    _dependencies.clear();
    _dependents.clear(); // Clear dependents map as well
    _log('Cleared all instances, factories, and dependencies asynchronously.');
  }

  /// Disposes the CircusRing itself, making it unusable.
  /// Calls [fireAll] first to clear internal state asynchronously.
  Future<void> dispose() async {
    if (!_isDisposed) {
      await fireAll(); // Clear instances first (conditionally disposing non-Jokers)
      _isDisposed = true;
      _log('CircusRing disposed.');
    }
  }

  bool _isDisposed = false;

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

    if (instanceRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} instance: $key');
      // --- Conditionally dispose removed instance ---
      if (instance is! Joker) {
        if (instance is Disposable) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log(
                'Error disposing Disposable during delete/replace $key: $e\n$s');
          }
        } else if (instance is ChangeNotifier) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log(
                'Error disposing ChangeNotifier during delete/replace $key: $e\n$s');
          }
        }
      } else {
        _log('Skipping dispose for Joker during delete/replace: $key');
      }
      // --- End Conditionally dispose ---
    } else if (factoryRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} factory: $key');
    } else if (lazyFactoryRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} lazy factory: $key');
    } else if (fenixRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} fenix builder: $key');
    }

    // Clear dependencies only if actually deleting, not just replacing
    // if (!isReplacing && (instanceRemoved || factoryRemoved || lazyFactoryRemoved || fenixRemoved)) {
    //   _clearDependenciesFor(key);
    // }
    // Correction: Dependencies should be cleared regardless, as the old binding is gone.
    if (instanceRemoved ||
        factoryRemoved ||
        lazyFactoryRemoved ||
        fenixRemoved) {
      _clearDependenciesFor(key);
    }

    return instanceRemoved ||
        factoryRemoved ||
        lazyFactoryRemoved ||
        fenixRemoved;
  }

  // Async version of _deleteSingle
  Future<bool> _deleteSingleAsync<T extends Object>(
      {required String key, bool isReplacing = false}) async {
    final instance = _instances.remove(key);
    final lazyAsyncRemoved = _lazyAsyncSingleton.remove(key) != null;
    final fenixAsyncRemoved = _fenixAsyncBuilders.remove(key) != null;

    bool instanceRemoved = instance != null;

    if (instanceRemoved) {
      _log('${isReplacing ? "Replacing" : "Deleting"} async instance: $key');
      // --- Conditionally dispose removed instance (Async first) ---
      if (instance is! Joker) {
        if (instance is AsyncDisposable) {
          try {
            await instance.dispose();
          } catch (e, s) {
            _log(
                'Error disposing AsyncDisposable during async delete/replace $key: $e\n$s');
          }
        } else if (instance is Disposable) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log(
                'Error disposing Disposable during async delete/replace $key: $e\n$s');
          }
        } else if (instance is ChangeNotifier) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log(
                'Error disposing ChangeNotifier during async delete/replace $key: $e\n$s');
          }
        }
      } else {
        _log('Skipping dispose for Joker during async delete/replace: $key');
      }
      // --- End Conditionally dispose ---
    } else if (lazyAsyncRemoved) {
      _log(
          '${isReplacing ? "Replacing" : "Deleting"} async lazy factory: $key');
    } else if (fenixAsyncRemoved) {
      _log(
          '${isReplacing ? "Replacing" : "Deleting"} async fenix builder: $key');
    }

    // Clear dependencies only if actually deleting, not just replacing
    // if (!isReplacing && (instanceRemoved || lazyAsyncRemoved || fenixAsyncRemoved)) {
    //   _clearDependenciesFor(key);
    // }
    // Correction: Dependencies should be cleared regardless
    if (instanceRemoved || lazyAsyncRemoved || fenixAsyncRemoved) {
      _clearDependenciesFor(key);
    }

    return instanceRemoved || lazyAsyncRemoved || fenixAsyncRemoved;
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

/// Extension for registering dependencies in the CircusRing
extension CircusRingHiring on CircusRing {
  /// Register a synchronous singleton
  ///
  /// Registers an instance that will be shared throughout the app.
  /// [instance]: The object to register
  /// [tag]: Optional name to distinguish between instances of the same type
  T hire<T extends Object>(T instance, {String? tag}) {
    _checkDisposed();
    // Verify that Joker instances must use summon or provide a tag
    if (instance is Joker && (tag == null || tag.isEmpty)) {
      throw CircusRingException(
        'Joker instances must be registered using summon() or provide a non-empty tag. '
        'Use: Circus.summon<T>(tag: "unique_tag") or Circus.hire<Joker<T>>(joker, tag: "unique_tag")',
      );
    }
    final key = _getKey(T, tag);
    if (_instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _factories.containsKey(key)) {
      _log('Instance/Factory $key already exists, will be replaced');
      _deleteSingle<T>(key: key, isReplacing: true);
    }
    _instances[key] = instance;
    _log('Instance $key registered');
    return instance;
  }

  /// Register an asynchronous singleton
  ///
  /// Registers a dependency that will be created asynchronously
  /// [asyncBuilder]: Function that returns a Future of the instance
  /// [tag]: Optional name to distinguish between instances of the same type
  Future<T> hireAsync<T extends Object>(
    AsyncFactoryFunc<T> asyncBuilder, {
    String? tag,
  }) async {
    _checkDisposed();
    final key = _getKey(T, tag);
    if (_instances.containsKey(key) || _lazyAsyncSingleton.containsKey(key)) {
      _log('Replacing existing async instance/factory: $key');
      await _deleteSingleAsync<T>(key: key, isReplacing: true);
    }
    _log('Creating async instance: $key');
    final instance = await asyncBuilder();
    _instances[key] = instance;
    _log('Async instance registered: $key');
    return instance;
  }

  /// Register a lazy-loaded singleton
  ///
  /// Registers a dependency that will be created only when first requested
  /// [builder]: Function that creates the instance
  /// [tag]: Optional name to distinguish between instances of the same type
  /// [fenix]: Whether to fenix the instance if it was removed
  void hireLazily<T extends Object>(
    FactoryFunc<T> builder, {
    String? tag,
    bool fenix = false,
  }) {
    _checkDisposed();
    final key = _getKey(T, tag);

    if (_lazyFactories.containsKey(key) ||
        _instances.containsKey(key) ||
        _factories.containsKey(key) ||
        _fenixBuilders.containsKey(key)) {
      _log('Instance/Factory/Fenix $key already exists, will be replaced');
      _deleteSingle<T>(key: key, isReplacing: true);
    }

    _lazyFactories[key] = builder;

    if (fenix) {
      _fenixBuilders[key] = builder;
      _log('Fenix (auto-rebind) registered for: $key');
    }

    _log('Lazy instance $key registered');
  }

  /// Register an async lazy-loaded singleton
  ///
  /// Registers a dependency that will be created asynchronously when first requested
  /// [asyncBuilder]: Function that returns a Future of the instance
  /// [tag]: Optional name to distinguish between instances of the same type
  /// [fenix]: Whether to fenix the instance if it was removed
  void hireLazilyAsync<T extends Object>(
    AsyncFactoryFunc<T> builder, {
    String? tag,
    bool fenix = false,
  }) {
    _checkDisposed();
    final key = _getKey(T, tag);

    if (_lazyAsyncSingleton.containsKey(key) ||
        _instances.containsKey(key) ||
        _fenixAsyncBuilders.containsKey(key)) {
      _log(
          'Async Instance/Factory/Fenix $key already registered, will be replaced');
      _deleteSingleAsync<T>(key: key, isReplacing: true);
    }

    _lazyAsyncSingleton[key] = builder;

    if (fenix) {
      _fenixAsyncBuilders[key] = builder;
      _log('Fenix (auto-rebind async) registered for: $key');
    }

    _log('Async lazy instance registered: $key');
  }

  /// Register a factory that creates a new instance on each call
  ///
  /// Instead of sharing a single instance, creates a new one each time it's requested
  /// [builder]: Function that creates the instance
  /// [tag]: Optional name to distinguish between factories of the same type
  void contract<T extends Object>(FactoryFunc<T> builder, {String? tag}) {
    _checkDisposed();
    final key = _getKey(T, tag);
    if (_factories.containsKey(key) ||
        _instances.containsKey(key) ||
        _lazyFactories.containsKey(key)) {
      _log('Instance/LazyFactory $key already exists, will be replaced');
      _deleteSingle<T>(key: key, isReplacing: true);
    }
    _factories[key] = builder;
    _log('Factory instance $key registered');
  }

  /// Register a singleton instance (alias for hire)
  ///
  /// Alternative name for [hire] with identical functionality
  /// [instance]: The object to register
  /// [tag]: Optional name to distinguish between instances of the same type
  T appoint<T extends Object>(T instance, {String? tag}) =>
      hire<T>(instance, tag: tag);

  /// Create a new instance directly without storing it
  ///
  /// Creates an instance on demand without registering it in the container
  /// [builder]: Function that creates the instance
  /// [tag]: Optional tag for logging purposes
  T draft<T extends Object>({required FactoryFunc<T> builder, String? tag}) {
    _checkDisposed();
    _log('Drafting new instance: ${_getKey(T, tag)}');
    return builder();
  }
}

/// Extension for finding and retrieving dependencies from CircusRing
extension CircusRingFind on CircusRing {
  /// Find or create an instance
  ///
  /// Retrieves a registered instance or creates it if lazy loaded
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Throws [CircusRingException] if the dependency is not found
  T find<T extends Object>([String? tag]) {
    _checkDisposed();
    final key = _getKey(T, tag);

    // 1. Check if instance already exists
    if (_instances.containsKey(key)) {
      return _instances[key] as T;
    }

    // 2. Check if there's a lazy factory
    if (_lazyFactories.containsKey(key)) {
      final instance = _lazyFactories[key]!() as T;
      _instances[key] = instance;
      _log('Lazy instance instantiated: $key');
      // Remove the factory now that it's instantiated
      _lazyFactories.remove(key);
      return instance;
    }

    // 3. Check if there's a fenix builder (if instance was removed)
    if (_fenixBuilders.containsKey(key)) {
      _log('Fenix instance re-instantiating: $key');
      final instance = _fenixBuilders[key]!() as T;
      _instances[key] = instance; // Re-register the instance
      return instance;
    }

    // 4. Check if there's an async lazy factory, but warn this is a sync call
    if (_lazyAsyncSingleton.containsKey(key) ||
        _fenixAsyncBuilders.containsKey(key)) {
      throw CircusRingException(
          'Type $key is registered asynchronously, please use findAsync<$T>() to access it');
    }

    // 5. Check if there's a regular factory
    if (_factories.containsKey(key)) {
      _log('Creating from factory: $key');
      return _factories[key]!() as T;
    }

    throw CircusRingException(
        'Type not found: $key. Please register it first using hire, hireLazily, or contract.');
  }

  /// Find or create an instance asynchronously
  ///
  /// Retrieves a registered instance or creates it if lazy loaded, with async support
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Throws [CircusRingException] if the dependency is not found
  Future<T> findAsync<T extends Object>([String? tag]) async {
    _checkDisposed();
    final key = _getKey(T, tag);

    // 1. Check if instance already exists
    if (_instances.containsKey(key)) {
      return _instances[key] as T;
    }

    // 2. Check if there's an async lazy factory
    if (_lazyAsyncSingleton.containsKey(key)) {
      _log('Async lazy instance instantiating: $key');
      final instance = await _lazyAsyncSingleton[key]!() as T;
      _instances[key] = instance;
      // Remove the factory now that it's instantiated
      _lazyAsyncSingleton.remove(key);
      return instance;
    }

    // 3. Check if there's an async fenix builder
    if (_fenixAsyncBuilders.containsKey(key)) {
      _log('Async Fenix instance re-instantiating: $key');
      final instance = await _fenixAsyncBuilders[key]!() as T;
      _instances[key] = instance; // Re-register the instance
      return instance;
    }

    // 4. Check if there's a regular lazy factory (sync)
    if (_lazyFactories.containsKey(key)) {
      final instance = _lazyFactories[key]!() as T;
      _instances[key] = instance;
      _log('Lazy instance instantiated (via findAsync): $key');
      _lazyFactories.remove(key);
      return instance;
    }

    // 5. Check if there's a regular fenix builder (sync)
    if (_fenixBuilders.containsKey(key)) {
      _log('Fenix instance re-instantiating (via findAsync): $key');
      final instance = _fenixBuilders[key]!() as T;
      _instances[key] = instance; // Re-register the instance
      return instance;
    }

    // 6. Check if there's a regular factory (sync)
    if (_factories.containsKey(key)) {
      _log('Creating from factory (via findAsync): $key');
      return _factories[key]!() as T;
    }

    throw CircusRingException(
        'Type not found: $key. Please register it first using hire, hireAsync, hireLazily, hireLazilyAsync, or contract.');
  }

  /// Try to find an instance, return null if not found
  ///
  /// Safe version of [find] that returns null instead of throwing an exception
  /// [tag]: Optional name to distinguish between instances of the same type
  T? tryFind<T extends Object>([String? tag]) {
    _checkDisposed();
    try {
      return find<T>(tag);
    } on CircusRingException catch (e) {
      if (e.message.contains('Type not found')) {
        return null;
      } else {
        rethrow;
      }
    } catch (_) {
      return null;
    }
  }

  /// Try to find an instance asynchronously, return null if not found
  ///
  /// Safe version of [findAsync] that returns null instead of throwing an exception
  /// [tag]: Optional name to distinguish between instances of the same type
  Future<T?> tryFindAsync<T extends Object>([String? tag]) async {
    _checkDisposed();
    try {
      return await findAsync<T>(tag);
    } on CircusRingException catch (e) {
      if (e.message.contains('Type not found')) {
        return null;
      } else {
        rethrow;
      }
    } catch (_) {
      return null;
    }
  }

  /// Check if a type is properly registered
  ///
  /// Returns true if the instance exists or can be created
  /// [tag]: Optional name to distinguish between instances of the same type
  bool isHired<T extends Object>([String? tag]) {
    _checkDisposed();
    final key = _getKey(T, tag);
    return _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _lazyAsyncSingleton.containsKey(key) ||
        _factories.containsKey(key) ||
        _fenixBuilders.containsKey(key) ||
        _fenixAsyncBuilders.containsKey(key);
  }

  /// Delete an instance asynchronously, including dependency check.
  ///
  /// Removes an object registered in the container and invokes dispose / asyncDispose
  /// when appropriate (excluding Jokers). If the given instance is still required by other
  /// registered components (via [bindDependency]), this will throw [CircusRingException].
  ///
  /// [tag]: Optional name to distinguish between different instances of type T
  ///
  /// Returns true if successfully removed, false otherwise.
  Future<bool> fireAsync<T extends Object>({String? tag}) async {
    _checkDisposed();
    final key = _getKey(T, tag);

    if (_dependents.containsKey(key) &&
        (_dependents[key]?.isNotEmpty ?? false)) {
      throw CircusRingException(
        'Cannot asynchronously remove $key because it is still depended on by: ${_dependents[key]!.join(', ')}',
      );
    }

    final success = await _deleteSingleAsync<T>(key: key);
    // Dependencies are now cleared within _deleteSingleAsync
    // if (success) _clearDependenciesFor(key);
    return success;
  }
}

/// Extension for tag-based operations in CircusRing
extension CircusRingTagFind on CircusRing {
  /// Find any instance by its tag without specifying concrete type
  ///
  /// Searches for instances registered with the given tag across all types
  /// [tag]: The tag to search for
  /// Returns null if no matching instance is found
  dynamic findByTag(String tag) {
    _checkDisposed();
    // Traverse all possible containers that may hold an instance
    // 1. Check already instantiated objects first
    for (final entry in _instances.entries) {
      // Improved tag matching
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        return entry.value;
      } else if (keyParts.length == 1 && entry.key == tag) {
        return entry.value;
      }
    }

    // 2. Check lazy factories
    for (final entry in _lazyFactories.entries) {
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        final instance = entry.value() as dynamic;
        _instances[entry.key] = instance;
        _lazyFactories.remove(entry.key);
        _log('Lazy instance instantiated by tag: $tag');
        return instance;
      }
    }

    // 3. Check fenix builders
    for (final entry in _fenixBuilders.entries) {
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        _log('Fenix instance re-instantiating by tag: $tag');
        final instance = entry.value() as dynamic;
        _instances[entry.key] = instance; // Re-register
        return instance;
      }
    }

    // 4. Check asynchronous lazy factories (but do not invoke them)
    for (final entry in _lazyAsyncSingleton.entries) {
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        throw CircusRingException(
            'Instance with tag $tag is registered asynchronously, please use findAsyncByTag() to access it');
      }
    }
    // 5. Check async fenix builders (do not invoke)
    for (final entry in _fenixAsyncBuilders.entries) {
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        throw CircusRingException(
            'Instance with tag $tag is registered as async fenix, please use findAsyncByTag() to access it');
      }
    }

    // 6. Check factories
    for (final entry in _factories.entries) {
      final keyParts = entry.key.split('_');
      if (keyParts.length > 1 && keyParts.last == tag) {
        _log('Creating from factory by tag: $tag');
        return entry.value() as dynamic;
      }
    }

    _log('Instance with tag "$tag" not found.');
    return null; // Return null if not found
  }

  /// Try to find any instance by its tag, return null if not found
  ///
  /// Safe version of [findByTag] that returns null instead of throwing an exception
  /// [tag]: The tag to search for
  dynamic tryFindByTag(String tag) {
    _checkDisposed();
    try {
      return findByTag(tag);
    } on CircusRingException catch (e) {
      if (e.message.contains('registered asynchronously')) {
        // If it requires async access, return null in tryFind
        return null;
      }
      // We expect findByTag to return null if not found, so other exceptions are unexpected
      rethrow;
    } catch (_) {
      return null;
    }
  }

  // Note: fireByTag was already updated earlier to conditionally dispose and throw for AsyncDisposable
}
