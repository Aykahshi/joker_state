part of 'circus_ring.dart';

/// Extension for finding and retrieving dependencies from CircusRing
extension CircusRingFindx on CircusRing {
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
}

/// Extension for tag-based operations in CircusRing
extension CircusRingTagFindx on CircusRing {
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
}
