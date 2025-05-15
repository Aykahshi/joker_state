[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](https://github.com/Aykahshi/joker_state/blob/master/packages/circus_ring/README-zh.md)

# 🎪 CircusRing

**CircusRing** is a lightweight and flexible dependency injection container for Flutter, making object, lifecycle, and component relationship management intuitive.

## ✨ Features

- **🧩 Multiple Registration Methods:**
    - Singleton (immediate or lazy)
    - Asynchronous singleton
    - Factory mode (new instance each time)
    - "`fenix`" mode to automatically recreate instances
- **🔄 Dependency Management:**
    - Explicitly bind dependencies between components
    - Prevent removal of components that are still depended upon
    - Automatically clean up resources when components are removed
- **🔍 Flexible Lookup:**
    - Lookup by type (with optional tag)
    - Supports both synchronous and asynchronous lookup
    - Lookup by `Tag` only is also supported
- **♻️ Resource Management:**
    - Automatically handle `Disposable` or `ChangeNotifier`
    - Supports asynchronous release via `AsyncDisposable`

## 📝 How to Use

### 🌐 Global Access

CircusRing is a global singleton. You can easily access it via `Circus` or `Ring`:

```dart
import 'package:joker_state/circus_ring.dart';

final instance = Circus.find<T>();
final instance = Ring.find<T>();
```

### 📥 Register Dependencies

`CircusRing` provides multiple registration methods. You can even specify an `alias`, which is useful for architectural patterns.

```dart
// Simple singleton registration, returns the instance directly
// Yes, you can use it directly like this
// final repository = Circus.hire<UserRepository>();
Circus.hire(UserRepository());

// Register multiple instances of the same type with tags, suitable for multi-flavor development
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// Lazy singleton
Circus.hireLazily<Database>(() => Database.initialize());

// Asynchronous singleton
Circus.hireLazilyAsync<NetworkService>(() async => await NetworkService.initialize());

// Factory mode
Circus.contract<UserModel>(() => UserModel());

// "fenix" mode to automatically recreate instances
Circus.hireLazily<UserModel>(() => UserModel(), fenix: true);

// "alias" mode, pass the `Type` you want as an alias, CircusRing will handle everything for you
Circus.hire<UserRepository>(UserRepositoryImpl(), alias: UserRepository);
```

### 🔎 Lookup Dependencies

`CircusRing` makes it easy to find registered dependencies, all based on a `Map`, so it's extremely fast!

```dart
// Get a singleton directly
final userRepo = Circus.find<UserRepository>();

// Get a singleton with a tag
final apiClient = Circus.find<ApiClient>('prod');

// Lazy singleton
final db = Circus.find<Database>();

// Asynchronous singleton
final networkService = await Circus.findAsync<NetworkService>();

// Safe lookup (returns null if not found)
final maybeRepo = Circus.tryFind<UserRepository>();

// Lookup by Tag
final client = Circus.findByTag('mockClient');

// Safe Tag lookup, returns null if not found
final maybeClient = Circus.tryFindByTag('mockClient');
```

### 🔗 Bind Dependencies

`CircusRing` provides the `bindDependency` method to bind dependencies, ensuring that dependent objects are not accidentally removed.

```dart
// Make UserRepository depend on ApiClient
Circus.bindDependency<UserRepository, ApiClient>();
// As long as UserRepository exists, ApiClient will not be removed
```

### 🧹 Resource Cleanup

`CircusRing` provides various cleanup methods, including both synchronous and asynchronous cleanup, if you want your dependencies can be automatically disposed when removed, please let your dependencies implement `Disposable` or `AsyncDisposable`.

```dart
// Remove standard Disposable (triggers dispose)
Circus.fire<UserRepository>();

// Asynchronous removal of AsyncDisposable (triggers async dispose)
await Circus.fireAsync<NetworkService>();

// Remove all dependencies, including asynchronous cleanup
await Circus.fireAll();
```

## ⚙️ Friendly Debug Features

By default, `CircusRing` uses `kDebugMode` to control debug message output, but you can also control it via `enableLogs`.

```dart
Circus.enableLogs = true; // Enable debug messages
Circus.enableLogs = false; // Disable debug messages
```