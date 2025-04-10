import 'dart:developer';

import 'package:flutter/widgets.dart';

import '../../../state_management/joker/joker.dart';
import 'circus_ring_exception.dart';
import 'disposable.dart';

typedef FactoryFunc<T> = T Function();
typedef AsyncFactoryFunc<T> = Future<T> Function();

CircusRing get Circus => CircusRing.instance;

class CircusRing {
  // Singleton pattern
  CircusRing._internal();

  static final CircusRing _instance = CircusRing._internal();

  factory CircusRing() => _instance;

  // Direct access to instance shorthand
  static CircusRing get instance => _instance;

  // Container for storing instances
  final _instances = <String, dynamic>{};

  // Container for storing factory methods
  final _factories = <String, FactoryFunc>{};

  // Container for storing lazy factory methods
  final _lazyFactories = <String, FactoryFunc>{};

  // Container for storing lazy async factory methods
  final _lazyAsyncSingleton = <String, AsyncFactoryFunc>{};

  // Whether to enable debug logs
  bool _enableLogs = false;

  /// Configure CircusRing
  void config({bool? enableLogs}) {
    if (enableLogs != null) _enableLogs = enableLogs;
  }

  /// Generate unique instance key
  String _getKey(Type type, [String? tag]) =>
      tag != null ? '${type.toString()}_$tag' : type.toString();

  /// Log output
  void _log(String message) {
    if (_enableLogs) {
      log('[🃏CircusRing] $message');
    }
  }
}

extension CircusRingHiring on CircusRing {
  /// Register a synchronous singleton
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
  void contract<T>(FactoryFunc<T> builder, {String? tag}) {
    final key = _getKey(T, tag);

    if (_factories.containsKey(key) || _instances.containsKey(key)) {
      _deleteSingle<T>(key: key);
    }

    _factories[key] = builder;
    _log('Factory instance $key registered');
  }

  /// Register a singleton instance
  T appoint<T>(T instance, {String? tag}) => hire<T>(instance, tag: tag);

  /// Create a new instance directly without storing it
  T draft<T>({required FactoryFunc<T> builder, String? tag}) {
    _log('Creating new instance: ${_getKey(T, tag)}');
    return builder();
  }

  /// Delete a single instance
  bool _deleteSingle<T>({required String key}) {
    if (_instances.containsKey(key)) {
      final instance = _instances[key];
      // Handle ValueNotifier-based instances
      if (instance is ValueNotifier) {
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

extension CircusRingFind on CircusRing {
  /// Find or create an instance
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
  T? tryFind<T>([String? tag]) {
    try {
      return find<T>(tag);
    } catch (_) {
      return null;
    }
  }

  /// Try to find an instance asynchronously, return null if not found
  Future<T?> tryFindAsync<T>([String? tag]) async {
    try {
      return await findAsync<T>(tag);
    } catch (_) {
      return null;
    }
  }

  /// Check if a type is properly registered
  bool isHired<T>([String? tag]) {
    final key = _getKey(T, tag);
    return _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _lazyAsyncSingleton.containsKey(key) ||
        _factories.containsKey(key);
  }

  /// Delete an instance
  bool fire<T>({String? tag}) {
    final key = _getKey(T, tag);

    return _deleteSingle<T>(key: key);
  }

  /// Delete an instance asynchronously
  Future<bool> fireAsync<T>({String? tag}) async {
    final key = _getKey(T, tag);

    return await _deleteSingleAsync<T>(key: key);
  }

  /// Delete all instances
  void fireAll() {
    for (final key in _instances.keys.toList()) {
      final instance = _instances[key];
      if (instance is ValueNotifier) {
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
  Future<void> fireAllAsync() async {
    for (final key in _instances.keys) {
      final instance = _instances[key];
      if (instance is ValueNotifier) {
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
