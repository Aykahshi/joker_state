part of 'circus_ring.dart';

/// Extension for removing dependencies from CircusRing
extension CircusRingFirex on CircusRing {
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
      final factoryRemoved = _factories.remove(key) != null;
      final lazyFactoryRemoved = _lazyFactories.remove(key) != null;
      final fenixRemoved = _fenixBuilders.remove(key) != null;
      final lazyAsyncRemoved = _lazyAsyncSingleton.remove(key) != null;
      final fenixAsyncRemoved = _fenixAsyncBuilders.remove(key) != null;

      if (factoryRemoved ||
          lazyFactoryRemoved ||
          fenixRemoved ||
          lazyAsyncRemoved ||
          fenixAsyncRemoved) {
        _log('Binding removed (was not instantiated): $key');
        _clearDependenciesFor(key);
        return true;
      }
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

    if (instance is Disposable) {
      try {
        instance.dispose();
      } catch (e, s) {
        _log('Error disposing Disposable instance $key: $e\\n$s');
      }
    } else if (instance is ChangeNotifier) {
      // Dispose ChangeNotifier as a fallback if not Disposable
      try {
        instance.dispose();
      } catch (e, s) {
        _log('Error disposing ChangeNotifier instance $key: $e\\n$s');
      }
    }

    return true;
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

  /// Removes an instance by its tag (type is inferred or doesn't matter).
  /// Returns `true` if an instance with the tag was found and removed.
  /// Conditionally calls `dispose`.
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

    // Check for AsyncDisposable FIRST and throw
    if (instanceToRemove is AsyncDisposable) {
      throw CircusRingException(
        'Cannot synchronously dispose instance with tag "$tag" (key: $keyToRemove, Type: ${instanceToRemove.runtimeType}). '
        'It implements AsyncDisposable. Use fireAsyncByTag(tag: "$tag") or fireAsync<T>(tag: "$tag") instead.',
      );
    }

    if (instanceToRemove is Disposable) {
      try {
        instanceToRemove.dispose();
      } catch (e, s) {
        _log(
            'Error disposing Disposable instance (tag: $tag) $keyToRemove: $e\\n$s');
      }
    } else if (instanceToRemove is ChangeNotifier) {
      try {
        instanceToRemove.dispose();
      } catch (e, s) {
        _log(
            'Error disposing ChangeNotifier instance (tag: $tag) $keyToRemove: $e\\n$s');
      }
    }

    return true;
  }

  void _checkDisposed() {
    if (_isDisposed) {
      throw CircusRingException(
        'This CircusRing instance has been disposed and cannot be used anymore.',
      );
    }
  }

  /// Clears all registered instances and dependencies.
  /// Conditionally calls `dispose` on instances.
  /// Handles both [Disposable] and [AsyncDisposable] appropriately.
  Future<void> fireAll() async {
    _checkDisposed();
    final keys = _instances.keys.toList(); // Get keys before iterating
    for (final key in keys) {
      final instance = _instances.remove(key);
      if (instance != null) {
        if (instance is AsyncDisposable) {
          try {
            await instance.dispose();
          } catch (e, s) {
            _log('fireAll: Error disposing AsyncDisposable $key: $e\\n$s');
          }
        } else if (instance is Disposable) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log('fireAll: Error disposing Disposable $key: $e\\n$s');
          }
        } else if (instance is ChangeNotifier) {
          try {
            instance.dispose();
          } catch (e, s) {
            _log('fireAll: Error disposing ChangeNotifier $key: $e\\n$s');
          }
        }
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
    _log('Cleared all instances, factories, and dependencies successfully');
  }
}
