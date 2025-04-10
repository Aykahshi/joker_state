import 'dart:developer';

import 'package:flutter/widgets.dart';

import '../../../state_management/joker/joker.dart';
import 'circus_ring_exception.dart';
import 'disposable.dart';

/// A function that creates an instance of type T
typedef FactoryFunc<T> = T Function();

/// A function that asynchronously creates an instance of type T
typedef AsyncFactoryFunc<T> = Future<T> Function();

/// Global access point for the CircusRing dependency injection container
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

  /// Whether to enable debug logs
  bool _enableLogs = false;

  /// Configure CircusRing
  ///
  /// [enableLogs]: Whether to enable debug logging
  void config({bool? enableLogs}) {
    if (enableLogs != null) _enableLogs = enableLogs;
  }

  /// Generate unique instance key
  ///
  /// Creates a unique identifier for each registered dependency
  /// based on its type and optional tag
  String _getKey(Type type, [String? tag]) =>
      tag != null ? '${type.toString()}_$tag' : type.toString();

  /// Log output
  ///
  /// Prints debug information if logging is enabled
  void _log(String message) {
    if (_enableLogs) {
      log('[🃏CircusRing] $message');
    }
  }
}

/// Extension for registering dependencies in the CircusRing
extension CircusRingHiring on CircusRing {
  /// Register a synchronous singleton
  ///
  /// Registers an instance that will be shared throughout the app.
  /// [instance]: The object to register
  /// [tag]: Optional name to distinguish between instances of the same type
  /// [permanent]: Whether this instance should persist until manually removed
  T hire<T>(T instance, {String? tag, bool permanent = true}) {
    // Verify that Joker instances must use summon or provide a tag
    if (instance is Joker && (tag == null || tag.isEmpty)) {
      throw CircusRingException(
        'Joker instances must be registered using summon() or provide a non-empty tag. ' +
            'Use: Circus.summon<T>(tag: "unique_tag") or Circus.hire<Joker<T>>(joker, tag: "unique_tag")',
      );
    }
    final key = _getKey(T, tag);
    if (_instances.containsKey(key)) {
      _log('Instance $key already exists, will be replaced');
      _deleteSingle<T>(key: key);
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
  /// [permanent]: Whether this instance should persist until manually removed
  Future<T> hireAsync<T>(AsyncFactoryFunc<T> asyncBuilder,
      {String? tag, bool permanent = true}) async {
    final key = _getKey(T, tag);
    if (_instances.containsKey(key)) {
      _log('Replacing existing async instance: $key');
      await _deleteSingleAsync<T>(key: key);
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
  /// [fenix]: Whether to recreate the instance if it was removed
  void hireLazily<T>(FactoryFunc<T> builder,
      {String? tag, bool fenix = false}) {
    final key = _getKey(T, tag);
    if (_lazyFactories.containsKey(key) || _instances.containsKey(key)) {
      _log('Instance $key already exists, will be replaced');
      _deleteSingle<T>(key: key);
    }
    _lazyFactories[key] = builder;
    _log('Lazy instance $key registered');
  }

  /// Register an async lazy-loaded singleton
  ///
  /// Registers a dependency that will be created asynchronously when first requested
  /// [asyncBuilder]: Function that returns a Future of the instance
  /// [tag]: Optional name to distinguish between instances of the same type
  /// [fenix]: Whether to recreate the instance if it was removed
  void hireLazilyAsync<T>(AsyncFactoryFunc<T> asyncBuilder,
      {String? tag, bool fenix = false}) {
    final key = _getKey(T, tag);
    if (_lazyAsyncSingleton.containsKey(key) || _instances.containsKey(key)) {
      _log('$key already registered, will be replaced');
      _deleteSingle<T>(key: key);
    }
    _lazyAsyncSingleton[key] = asyncBuilder;
    _log('Async lazy instance registered: $key');
  }

  /// Register a factory that creates a new instance on each call
  ///
  /// Instead of sharing a single instance, creates a new one each time it's requested
  /// [builder]: Function that creates the instance
  /// [tag]: Optional name to distinguish between factories of the same type
  void contract<T>(FactoryFunc<T> builder, {String? tag}) {
    final key = _getKey(T, tag);
    if (_factories.containsKey(key) || _instances.containsKey(key)) {
      _deleteSingle<T>(key: key);
    }
    _factories[key] = builder;
    _log('Factory instance $key registered');
  }

  /// Register a singleton instance (alias for hire)
  ///
  /// Alternative name for [hire] with identical functionality
  /// [instance]: The object to register
  /// [tag]: Optional name to distinguish between instances of the same type
  T appoint<T>(T instance, {String? tag}) => hire<T>(instance, tag: tag);

  /// Create a new instance directly without storing it
  ///
  /// Creates an instance on demand without registering it in the container
  /// [builder]: Function that creates the instance
  /// [tag]: Optional tag for logging purposes
  T draft<T>({required FactoryFunc<T> builder, String? tag}) {
    _log('Creating new instance: ${_getKey(T, tag)}');
    return builder();
  }

  /// Delete a single instance
  ///
  /// Internal method to remove an instance from the container
  /// and properly dispose of resources if necessary
  bool _deleteSingle<T>({required String key}) {
    if (_instances.containsKey(key)) {
      final instance = _instances[key];
      // Handle ChangeNotifier-based instances
      if (instance is ChangeNotifier) {
        instance.dispose();
      }
      if (instance is Disposable) {
        instance.dispose();
      }
      _instances.remove(key);
      _log('Instance deleted: $key');
      return true;
    }
    _factories.remove(key);
    _lazyFactories.remove(key);
    return false;
  }

  /// Asynchronously delete an instance
  ///
  /// Internal method to asynchronously remove an instance from the container
  /// and properly dispose of resources if necessary
  Future<bool> _deleteSingleAsync<T>({required String key}) async {
    if (_instances.containsKey(key)) {
      final instance = _instances[key];
      if (instance is AsyncDisposable) {
        await instance.dispose();
      } else if (instance is Disposable) {
        instance.dispose();
      }
      _instances.remove(key);
      _log('Instance deleted asynchronously: $key');
      return true;
    }
    _factories.remove(key);
    _lazyFactories.remove(key);
    _lazyAsyncSingleton.remove(key);
    return false;
  }
}

/// Extension for finding and retrieving dependencies from CircusRing
extension CircusRingFind on CircusRing {
  /// Find or create an instance
  ///
  /// Retrieves a registered instance or creates it if lazy loaded
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Throws [CircusRingException] if the dependency is not found
  T find<T>([String? tag]) {
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
      return instance;
    }

    // 3. Check if there's an async lazy factory, but warn this is a sync call
    if (_lazyAsyncSingleton.containsKey(key)) {
      throw CircusRingException(
          'Type $key is registered asynchronously, please use findAsync<$T>() to access it');
    }

    // 4. Check if there's a factory
    if (_factories.containsKey(key)) {
      _log('Creating from factory: $key');
      return _factories[key]!() as T;
    }

    throw CircusRingException(
        'Type not found: $key, please register it first using put, lazyPut, or factory');
  }

  /// Find or create an instance asynchronously
  ///
  /// Retrieves a registered instance or creates it if lazy loaded, with async support
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Throws [CircusRingException] if the dependency is not found
  Future<T> findAsync<T>([String? tag]) async {
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
      return instance;
    }

    // 3. Check if there's a regular lazy factory
    if (_lazyFactories.containsKey(key)) {
      final instance = _lazyFactories[key]!() as T;
      _instances[key] = instance;
      _log('Lazy instance instantiated: $key');
      return instance;
    }

    // 4. Check if there's a factory
    if (_factories.containsKey(key)) {
      _log('Creating from factory: $key');
      return _factories[key]!() as T;
    }

    throw CircusRingException(
        'Type not found: $key, please register it first using put, putAsync, lazyPut, or lazyPutAsync');
  }

  /// Try to find an instance, return null if not found
  ///
  /// Safe version of [find] that returns null instead of throwing an exception
  /// [tag]: Optional name to distinguish between instances of the same type
  T? tryFind<T>([String? tag]) {
    try {
      return find<T>(tag);
    } catch (_) {
      return null;
    }
  }

  /// Try to find an instance asynchronously, return null if not found
  ///
  /// Safe version of [findAsync] that returns null instead of throwing an exception
  /// [tag]: Optional name to distinguish between instances of the same type
  Future<T?> tryFindAsync<T>([String? tag]) async {
    try {
      return await findAsync<T>(tag);
    } catch (_) {
      return null;
    }
  }

  /// Check if a type is properly registered
  ///
  /// Returns true if the instance exists or can be created
  /// [tag]: Optional name to distinguish between instances of the same type
  bool isHired<T>([String? tag]) {
    final key = _getKey(T, tag);
    return _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _lazyAsyncSingleton.containsKey(key) ||
        _factories.containsKey(key);
  }

  /// Delete an instance
  ///
  /// Removes an instance from the container and disposes of resources if necessary
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Returns true if an instance was removed
  bool fire<T>({String? tag}) {
    final key = _getKey(T, tag);
    return _deleteSingle<T>(key: key);
  }

  /// Delete an instance asynchronously
  ///
  /// Asynchronously removes an instance from the container and disposes of resources
  /// [tag]: Optional name to distinguish between instances of the same type
  /// Returns true if an instance was removed
  Future<bool> fireAsync<T>({String? tag}) async {
    final key = _getKey(T, tag);
    return await _deleteSingleAsync<T>(key: key);
  }

  /// Delete all instances
  ///
  /// Removes all registered instances and factories from the container
  void fireAll() {
    for (final key in _instances.keys.toList()) {
      final instance = _instances[key];
      if (instance is ChangeNotifier) {
        instance.dispose();
      }
      if (instance is Disposable) {
        instance.dispose();
      }
    }
    _instances.clear();
    _factories.clear();
    _lazyFactories.clear();
    _lazyAsyncSingleton.clear();
    _log('Force deleted all instances and factories');
  }

  /// Delete all instances asynchronously
  ///
  /// Asynchronously removes all registered instances and factories from the container
  /// properly disposing of async resources
  Future<void> fireAllAsync() async {
    for (final key in _instances.keys) {
      final instance = _instances[key];
      if (instance is ChangeNotifier) {
        instance.dispose();
      }
      if (instance is AsyncDisposable) {
        await instance.dispose();
      } else if (instance is Disposable) {
        instance.dispose();
      }
    }
    _instances.clear();
    _factories.clear();
    _lazyFactories.clear();
    _lazyAsyncSingleton.clear();
    _log('Force deleted all instances and factories asynchronously');
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
    // Traverse all possible containers that may hold an instance
    // 1. Check already instantiate objects first
    for (final entry in _instances.entries) {
      if (entry.key.endsWith('_$tag')) {
        return entry.value;
      }
    }

    // 2. Check lazy factories
    for (final entry in _lazyFactories.entries) {
      if (entry.key.endsWith('_$tag')) {
        final instance = entry.value() as dynamic;
        _instances[entry.key] = instance;
        _log('Lazy instance instantiated by tag: $tag');
        return instance;
      }
    }

    // 3. Check asynchronous lazy factories (but do not invoke them)
    for (final entry in _lazyAsyncSingleton.entries) {
      if (entry.key.endsWith('_$tag')) {
        throw CircusRingException(
            'Instance with tag $tag is registered asynchronously, please use findAsyncByTag() to access it');
      }
    }

    // 4. Check factories
    for (final entry in _factories.entries) {
      if (entry.key.endsWith('_$tag')) {
        _log('Creating from factory by tag: $tag');
        return entry.value() as dynamic;
      }
    }

    return null; // Return null instead of throwing if instance not found
  }

  /// Try to find any instance by its tag, return null if not found
  ///
  /// Safe version of [findByTag] that returns null instead of throwing an exception
  /// [tag]: The tag to search for
  dynamic tryFindByTag(String tag) {
    try {
      return findByTag(tag);
    } catch (_) {
      return null;
    }
  }

  /// Delete any instance by its tag without specifying concrete type
  ///
  /// Removes all instances registered with the given tag across all types
  /// [tag]: The tag to search for
  /// Returns true if any instance was removed
  bool fireByTag(String tag) {
    // Find all instance keys that match the tag
    final keysToDelete = <String>[];
    for (final entry in _instances.entries) {
      if (entry.key.endsWith('_$tag')) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isEmpty) {
      return false;
    }

    // Delete all found instances
    bool anyDeleted = false;
    for (final key in keysToDelete) {
      final instance = _instances[key];
      if (instance is Disposable) {
        instance.dispose();
      } else if (instance is ChangeNotifier) {
        instance.dispose();
      }
      _instances.remove(key);
      anyDeleted = true;
      _log('Instance deleted by tag: $tag');
    }

    return anyDeleted;
  }
}
