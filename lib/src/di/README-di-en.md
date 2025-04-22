# 🎪 CircusRing

CircusRing is a lightweight and flexible dependency injection container for Flutter. It makes managing your app's objects, lifecycles, and dependencies straightforward and intuitive.

## 🌟 Overview

This solution is all about making dependency registration, lookup, and management in your Flutter project as easy as possible. The API is designed to be clear and practical, and you can choose from several ways to create and manage your dependencies.

## ✨ Features

- **🧩 Multiple ways to register**:
    - Singleton (eager or lazy)
    - Async singletons
    - Factories (get a new instance every time)
    - "Fenix" mode for auto-rebinding
- **🔄 Dependency management**:
    - Explicitly bind dependencies between components
    - Prevent removal of components that are still needed
    - Clean up resources automatically when components are removed
- **🔍 Flexible lookup**:
    - Find by type (optionally with a tag)
    - Supports both sync and async resolution
    - Lookup by tag if you don't know the type
- **♻️ Resource management**:
    - Automatically disposes resources that implement Disposable or ChangeNotifier
    - Supports async disposal with AsyncDisposable
- **🧠 State management integration**:
    - Works seamlessly with the Joker state management system
    - Special extensions for working with Joker instances

## 📝 How to Use

### 🌐 Global Access

CircusRing uses the singleton pattern, so you can always get the global instance with `Circus`:

```dart
import 'package:your_package/circus_ring.dart';

final ring = Circus;
```

### 📥 Registering Dependencies

```dart
// Register a singleton
Circus.hire<UserRepository>(UserRepositoryImpl());

// Register multiple instances of the same type with tags
Circus.hire<ApiClient>(ProductionApiClient(), tag: 'prod');
Circus.hire<ApiClient>(MockApiClient(), tag: 'test');

// Register a lazy singleton
Circus.hireLazily<Database>(() => Database.connect());

// Register an async singleton
Circus.hireLazilyAsync<NetworkService>(() async => await NetworkService.initialize());

// Register a factory (new instance every time)
Circus.contract<UserModel>(() => UserModel());
```

### 🔎 Finding Dependencies

Once you've registered your services or controllers, grabbing them is just as easy:

```dart
// Get a singleton
final userRepo = Circus.find<UserRepository>();

// Get a tagged singleton
final apiClient = Circus.find<ApiClient>('prod');

// Get a lazy singleton
final db = Circus.find<Database>();

// Get an async singleton
final networkService = await Circus.findAsync<NetworkService>();

// Safe lookup (returns null if not found)
final maybeRepo = Circus.tryFind<UserRepository>();
```

### 🔗 Binding Dependencies

```dart
// Make UserRepository depend on ApiClient
Circus.bindDependency<UserRepository, ApiClient>();
// ApiClient cannot be removed while UserRepository exists.
```

### 🧹 Cleaning Up

When you're done with a service, Presenter, or Joker, clean up in one line. CircusRing will handle disposal based on your `keepAlive` setting.

**🚨 Important Disposal Change (v3.0.0):**
`fire*` methods now **actively dispose** removed Jokers and Presenters (unless `keepAlive: true`).

```dart
// Remove a standard Disposable (triggers dispose)
Circus.fire<UserRepository>();

// Remove an AsyncDisposable asynchronously (triggers async dispose)
await Circus.fireAsync<NetworkService>();

// Remove a Joker or Presenter (keepAlive: false): dispose() is called
Circus.fire<MyPresenter>(tag: 'myTag');
Circus.vanish<int>(tag: 'counter');

// Remove a Joker or Presenter (keepAlive: true): only unregisters
Circus.fire<MyPresenter>(tag: 'myTagKeepAlive');

// Remove all (respects keepAlive, handles async cleanup)
await Circus.fireAll();
```

### 🃏 Joker Integration

CircusRing plays nicely with Joker for state management—register and retrieve seamlessly:

```dart
// Register a Joker state (keepAlive: false)
Circus.summon<int>(0, tag: 'counter');

// Keep a Joker state alive
Circus.summon<String>('sessionData', tag: 'session', keepAlive: true);

// Retrieve
final counter = Circus.spotlight<int>(tag: 'counter');
final session = Circus.spotlight<String>(tag: 'session');

// Update state
counter.trick(1);

// Clean up Jokers (dispose() if keepAlive is false)
Circus.vanish<int>(tag: 'counter');
Circus.vanish<String>(tag: 'session');

// Manual disposal for keepAlive Jokers
session.dispose();
```

## ⚙️ Logging

CircusRing automatically logs registration, lookup, and disposal events for you.
- **Automatic logging**: Enabled in debug mode, disabled in release/profile.
- **No setup needed**: You don't have to configure anything.

## 💡 Best Practices

1. **🏷️ Be consistent with tags**: If you use tags to differentiate instances, stick to a clear naming convention.
2. **📊 Manage dependencies explicitly**: Use `bindDependency` to document and enforce relationships between components.
3. **🗑️ Dispose resources properly**: Implement `Disposable` or `AsyncDisposable` for anything that needs cleanup.
4. **🏭 Use factories for short-lived objects**: If you don't need to share an object, use `contract`.
5. **⏳ Prefer lazy loading**: For expensive resources that might not always be used, go with `hireLazily`.