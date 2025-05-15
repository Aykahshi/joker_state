part of 'circus_ring.dart';

/// Extension for registering dependencies in the CircusRing
extension CircusRingHirex on CircusRing {
  /// Register a synchronous singleton, optionally allowing replacement.
  ///
  /// Registers an instance that will be shared throughout the app.
  /// By default, if an instance/factory with the same key already exists,
  /// it returns the existing instance. Set [allowReplace] to true to
  /// delete the old registration and register the new instance.
  ///
  /// [instance]: The object to register.
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  /// [allowReplace]: If true, replaces any existing registration with the same key.
  ///
  /// Returns the registered or existing instance.
  T hire<T extends Object>(
    T instance, {
    String? tag,
    Type? alias,
    bool allowReplace = false,
  }) {
    _checkDisposed();

    // 1. Determine the key using alias if provided
    final key = _getKey(T, tag, alias);

    // 2. Check if registration exists.
    final bool keyExists = _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _factories.containsKey(key);

    // 3. Handle existing registration based on allowReplace.
    if (keyExists) {
      if (allowReplace) {
        _log(
            'Instance/Factory $key already exists. Replacing due to allowReplace=true.');
        _deleteSingle<T>(key: key, isReplacing: true); // Remove old one
      } else {
        _log(
            'Instance/Factory $key already exists. Returning existing instance (allowReplace=false).');
        // If instance exists, return it directly. Otherwise, use find<T> to handle lazy/factory instantiation.
        if (_instances.containsKey(key)) {
          return _instances[key] as T;
        }
        return find<T>(tag);
      }
    }

    // 4. No existing registration or replaced, proceed to register the new instance.
    _instances[key] = instance;
    _log('Instance $key registered (allowReplace: $allowReplace)');
    return instance;
  }

  /// Register an asynchronous singleton, optionally allowing replacement.
  ///
  /// Registers a dependency that will be created asynchronously.
  /// By default, if an instance/factory with the same key already exists,
  /// it returns the existing instance asynchronously. Set [allowReplace] to true to
  /// delete the old registration and register the new instance.
  ///
  /// [asyncBuilder]: Function that returns a Future of the instance to register.
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  /// [allowReplace]: If true, replaces any existing registration with the same key.
  ///
  /// Returns a Future of the registered or existing instance.
  Future<T> hireAsync<T extends Object>(
    AsyncFactoryFunc<T> asyncBuilder, {
    String? tag,
    Type? alias,
    bool allowReplace = false,
  }) async {
    _checkDisposed();
    final key = _getKey(T, tag, alias);

    // 1. Check if registration exists.
    final bool keyExists =
        _instances.containsKey(key) || _lazyAsyncSingleton.containsKey(key);

    // 2. Handle existing registration based on allowReplace.
    if (keyExists) {
      if (allowReplace) {
        _log(
            'Async instance/factory $key already exists. Replacing due to allowReplace=true.');
        await _deleteSingleAsync<T>(
            key: key, isReplacing: true); // Remove old one
        // Continue to registration below after deletion
      } else {
        _log(
            'Async instance/factory $key already exists. Returning existing instance (allowReplace=false).');
        return findAsync<T>(
            tag); // Use findAsync to handle potential async lazy instantiation
      }
    }

    // 3. No existing registration or replaced, proceed to register the new instance asynchronously.
    _log('Creating async instance: $key (allowReplace: $allowReplace)');
    final instance = await asyncBuilder();

    // 4. Check again after await, in case it was registered concurrently *while we were building*.
    //    Only replace if allowReplace is true AND the key still points to something else (or a factory).
    final bool keyExistsAfterBuild =
        _instances.containsKey(key) || _lazyAsyncSingleton.containsKey(key);
    if (keyExistsAfterBuild) {
      if (allowReplace) {
        // If replacement is allowed, AND the key still exists (meaning someone else registered *while we built*),
        // we need to delete that one before adding ours.
        _log(
            'Async instance/factory $key was registered concurrently. Replacing again due to allowReplace=true.');
        await _deleteSingleAsync<T>(key: key, isReplacing: true);
      } else {
        // If replacement is not allowed, and it got registered concurrently, return the concurrently registered one.
        _log(
            'Async instance/factory $key was registered concurrently. Returning existing instance (allowReplace=false).');
        return findAsync<T>(tag);
      }
    }

    // 5. Register the newly built instance.
    _instances[key] = instance;
    _log('Async instance $key registered (allowReplace: $allowReplace)');
    return instance;
  }

  /// Register a lazy-loaded singleton, optionally allowing replacement.
  ///
  /// Registers a dependency that will be created only when first requested.
  /// By default, if any registration with the same key already exists, this method does nothing.
  /// Set [allowReplace] to true to delete the old registration before registering the new lazy factory.
  ///
  /// [builder]: Function that creates the instance.
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  /// [fenix]: Whether to auto-rebind the instance if it was removed using `fire()`.
  /// [allowReplace]: If true, replaces any existing registration with the same key.
  void hireLazily<T extends Object>(
    FactoryFunc<T> builder, {
    String? tag,
    Type? alias,
    bool fenix = false,
    bool allowReplace = false,
  }) {
    _checkDisposed();
    final key = _getKey(T, tag, alias);

    // 1. Check if registration exists.
    final bool keyExists = _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _factories.containsKey(key) ||
        _fenixBuilders.containsKey(key);

    // 2. Handle existing registration based on allowReplace.
    if (keyExists) {
      if (allowReplace) {
        _log(
            'Instance/Factory/Lazy/Fenix $key already exists. Replacing due to allowReplace=true.');
        _deleteSingle<T>(key: key, isReplacing: true); // Remove old one
        // Continue to registration below
      } else {
        _log(
            'Instance/Factory/Lazy/Fenix $key already exists. Skipping registration (allowReplace=false).');
        return; // Do nothing if already registered and not replacing
      }
    }

    // 3. No existing registration or replaced, proceed to register the lazy factory.
    _lazyFactories[key] = builder;
    _log('Lazy instance $key registered (allowReplace: $allowReplace)');

    if (fenix) {
      // Also register fenix builder, potentially replacing an old one if allowReplace was true.
      // If allowReplace was false and a fenix builder already existed, we would have returned above.
      _fenixBuilders[key] = builder;
      _log(
          'Fenix (auto-rebind) registered for: $key (allowReplace: $allowReplace)');
    }
  }

  /// Register an async lazy-loaded singleton, optionally allowing replacement.
  ///
  /// Registers a dependency that will be created asynchronously when first requested.
  /// By default, if any async registration with the same key already exists, this method does nothing.
  /// Set [allowReplace] to true to delete the old registration before registering the new async lazy factory.
  ///
  /// [asyncBuilder]: Function that returns a Future of the instance.
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  /// [fenix]: Whether to auto-rebind the instance if it was removed.
  /// [allowReplace]: If true, replaces any existing registration with the same key.
  void hireLazilyAsync<T extends Object>(
    AsyncFactoryFunc<T> builder, {
    String? tag,
    Type? alias,
    bool fenix = false,
    bool allowReplace = false,
  }) {
    _checkDisposed();
    final key = _getKey(T, tag, alias);

    // 1. Check if registration exists.
    final bool keyExists = _instances.containsKey(key) ||
        _lazyAsyncSingleton.containsKey(key) ||
        _fenixAsyncBuilders.containsKey(key);

    // 2. Handle existing registration based on allowReplace.
    if (keyExists) {
      if (allowReplace) {
        _log(
            'Async Instance/Lazy/Fenix $key already registered. Replacing due to allowReplace=true.');
        // Use a fire-and-forget pattern for the async deletion, as this method is sync.
        // Or should this method be async? Let's make it sync for now.
        // We cannot await _deleteSingleAsync here. The deletion will happen later.
        // This means a subsequent *synchronous* find might still get the old instance briefly
        // before the async deletion completes. This is a trade-off.
        // Consider making this method async if guaranteed replacement before proceeding is needed.
        _deleteSingleAsync<T>(key: key, isReplacing: true);
        // Continue to registration below
      } else {
        _log(
            'Async Instance/Lazy/Fenix $key already registered. Skipping registration (allowReplace=false).');
        return; // Do nothing if already registered and not replacing
      }
    }

    // 3. No existing registration or replaced, proceed to register the async lazy factory.
    _lazyAsyncSingleton[key] = builder;
    _log('Async lazy instance registered: $key (allowReplace: $allowReplace)');

    if (fenix) {
      _fenixAsyncBuilders[key] = builder;
      _log(
          'Fenix (auto-rebind async) registered for: $key (allowReplace: $allowReplace)');
    }
  }

  /// Check if a type is properly registered
  ///
  /// Returns true if the instance exists or can be created
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  bool isHired<T extends Object>([String? tag, Type? alias]) {
    _checkDisposed();
    final key = _getKey(T, tag, alias);
    return _instances.containsKey(key) ||
        _lazyFactories.containsKey(key) ||
        _lazyAsyncSingleton.containsKey(key) ||
        _factories.containsKey(key) ||
        _fenixBuilders.containsKey(key) ||
        _fenixAsyncBuilders.containsKey(key);
  }

  /// Register a factory that creates a new instance on each call
  ///
  /// Instead of sharing a single instance, creates a new one each time it's requested
  /// [builder]: Function that creates the instance
  /// [tag]: Optional name to distinguish between factories of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  void contract<T extends Object>(FactoryFunc<T> builder,
      {String? tag, Type? alias}) {
    _checkDisposed();
    final key = _getKey(T, tag, alias);
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
  /// [tag]: Optional name to distinguish between instances of the same type.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  @Deprecated('This method is deprecated. Use hire instead')
  T appoint<T extends Object>(T instance, {String? tag, Type? alias}) =>
      hire<T>(instance, tag: tag, alias: alias);

  /// Create a new instance directly without storing it
  ///
  /// Creates an instance on demand without registering it in the container
  /// [builder]: Function that creates the instance
  /// [tag]: Optional tag for logging purposes.
  /// [alias]: Optional type to register the instance as, allowing interface implementation.
  T draft<T extends Object>(
      {required FactoryFunc<T> builder, String? tag, Type? alias}) {
    _checkDisposed();
    _log('Drafting new instance: ${_getKey(T, tag, alias)}');
    return builder();
  }
}
