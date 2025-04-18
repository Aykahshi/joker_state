# 🎪 CircusRing

A lightweight, flexible dependency injection container for Flutter applications.

## 🌟 Overview

CircusRing is a dependency management solution designed to simplify object creation, lifetime management, and component relations in Flutter applications. It provides an intuitive API for registering, finding, and managing dependencies with support for various instantiation strategies.

## ✨ Features

- **🧩 Multiple Registration Types**:
    - Singleton (eager and lazy)
    - Asynchronous singletons
    - Factories (new instance on each request)
    - Auto-rebinding with "fenix" mode

- **🔄 Dependency Management**:
    - Explicitly bind dependencies between components
    - Prevent removal of components that other components depend on
    - Clean disposal of resources when components are removed

- **🔍 Flexible Retrieval**:
    - Type-based lookup with optional tags
    - Synchronous and asynchronous dependency resolution
    - Tag-based lookup for finding components without knowing their type

- **♻️ Resource Management**:
    - Automatic disposal of resources implementing Disposable or ChangeNotifier
    - Asynchronous disposal support through AsyncDisposable

- **🧠 Integrated with State Management**:
    - Seamless integration with the Joker state management system
    - Special extensions for working with Joker instances

## 📝 Usage

### 🌐 Global Access

CircusRing follows the singleton pattern and can be accessed through the global `Circus` getter:

```dart
import 'package:your_package/circus_ring.dart';

// Access the global instance
final ring = Circus;
```

### 📥 Registering Dependencies

```dart
// Register a singleton instance
Circus.hire<UserRepository>(UserRepositoryImpl());

// Register with a tag for multiple instances of the same type
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// Register a lazy singleton
Circus.hireLazily<Database>(() => Database.connect());

// Register an async singleton
Circus.hireLazilyAsync<NetworkService>(() async => 
  await NetworkService.initialize()
);

// Register a factory (new instance each time)
Circus.contract<UserModel>(() => UserModel());
```

### 🔎 Finding Dependencies

```dart
// Get a singleton
final userRepo = Circus.find<UserRepository>();

// Get a tagged singleton
final apiClient = Circus.find<ApiClient>('prod');

// Get or create a lazy singleton
final db = Circus.find<Database>();

// Get an async singleton
final networkService = await Circus.findAsync<NetworkService>();

// Safe retrieval (returns null if not found)
final maybeRepo = Circus.tryFind<UserRepository>();
```

### 🔗 Dependency Binding

```dart
// Make UserRepository depend on ApiClient
Circus.bindDependency<UserRepository, ApiClient>();

// Now ApiClient can't be removed while UserRepository exists
```

### 🧹 Cleaning Up

```dart
// Remove a specific dependency
Circus.fire<UserRepository>();

// Remove asynchronously (for async disposables)
await Circus.fireAsync<NetworkService>();

// Remove all dependencies
Circus.fireAll();

// Remove all dependencies with async cleanup
await Circus.fireAllAsync();
```

### 🃏 Joker Integration

CircusRing integrates with the Joker state management system:

```dart
// Register a Joker state
Circus.summon<int>(0, tag: 'counter');

// Get a registered Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// Update state
counter.trick(1); 

// Remove Joker
Circus.vanish<int>(tag: 'counter');
```

## ⚙️ Logging (Previously Configuration)

CircusRing includes internal logging for registration, retrieval, and disposal events.

- **Automatic Logging**: Logging is automatically enabled when your application is run in debug mode (`kDebugMode` is true) and disabled in profile/release modes.
- **No Configuration Needed**: There is no need to manually configure logging anymore.

## 💡 Best Practices

1. **🏷️ Use Tags Consistently**: When using tags to differentiate instances, maintain a consistent naming convention.

2. **📊 Manage Dependencies Explicitly**: Use `bindDependency` to document and enforce dependencies between components.

3. **🗑️ Dispose Resources Properly**: Implement `Disposable` or `AsyncDisposable` for classes that need cleanup.

4. **🏭 Use Factories for Transient Objects**: For short-lived objects that shouldn't be shared, use `contract`.

5. **⏳ Prefer Lazy Loading**: Use `hireLazily` for resources that are expensive to create but might not be used.