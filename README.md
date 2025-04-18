[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](README-zh.md)

# 🃏 JokerState

**⚠️ Breaking Changes in v2.0.0:** Joker's lifecycle and CircusRing's disposal logic have changed a lot. Before upgrading, check out the [Changelog](CHANGELOG.md) and the updated docs below.

JokerState is a lightweight, reactive state management package for Flutter that makes dependency injection super easy. With its `Joker` API and handy widgets, you get flexible state containers and barely any boilerplate.

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🧠 **Reactive State Management** – Smart containers that notify listeners when your state changes
- 💉 **Dependency Injection** – Intuitive service locator with the CircusRing API
- 🎭 **Flexible Widget Integration** – Widgets for all kinds of UI patterns
- 🪄 **Selective Rebuilds** – Fine control over what triggers a UI rebuild
- 🔄 **Batch Updates** – Group multiple state changes into a single notification
- 🏗️ **Record Support** – Combine multiple states using Dart Records
- 🧩 **Modular Design** – Use just what you need, or the whole ecosystem
- 📢 **Event Bus System** – Type-safe events with RingCueMaster
- 🎪 **Special Widgets** – Extra utilities like JokerReveal and JokerTrap
- ⏱️ **Timing Controls** – Debounce and throttle for smoother actions

## Getting Started

Add JokerState to your `pubspec.yaml`:

```yaml
dependencies:
  joker_state: ^latest_version
```

Then import the package:

```dart
import 'package:joker_state/joker_state.dart';
```

## Core Concepts

### 🎭 Joker: The Reactive State Container

`Joker<T>` is a reactive state container (extends `ChangeNotifier`). Its lifecycle is mostly managed by its listeners and the `keepAlive` flag.

```dart
// Create a Joker (auto-notifies by default)
final counter = Joker<int>(0);

// Update state and notify listeners
counter.trick(1);

// Update using a function
counter.trickWith((current) => current + 1);

// Batch multiple updates, notify once
counter.batch()
  .apply((s) => s * 2)
  .apply((s) => s + 10)
  .commit();

// Keep alive even with no listeners
final persistentState = Joker<String>("initial", keepAlive: true);
```

Want more control? Use manual notification mode:

```dart
// Create with auto-notify off
final manualCounter = Joker<int>(0, autoNotify: false);

// Update silently
manualCounter.whisper(5);
manualCounter.whisperWith((s) => s + 1);

// Notify listeners when you're ready
manualCounter.yell();
```

**Lifecycle:** By default (`keepAlive: false`), a Joker schedules itself for disposal (via `Future.microtask`) when its last listener is removed. If you add a listener again, disposal is canceled. Set `keepAlive: true` to keep it alive until you dispose it manually.

### 🎪 CircusRing: Dependency Injection

CircusRing is a lightweight dependency container. Its `fire*` methods now do **conditional disposal**.

```dart
// Global singleton accessor
final ring = Circus;

// Register a singleton (Disposable example)
ring.hire(MyDisposableService());

// Register a lazy singleton
ring.hireLazily(() => NetworkService());

// Register a factory (new instance each time)
ring.contract(() => ApiClient());

// Find your instance later
final service = Circus.find<MyDisposableService>();
```

Joker and CircusRing work great together:

```dart
// Register a Joker (needs a tag)
Circus.summon<int>(0, tag: 'counter');

// Find your Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// Remove Joker (just from the registry, not disposed)
Circus.vanish<int>(tag: 'counter');

// Joker disposes itself based on listeners/keepAlive.
```

**Disposal:** `Circus.fire*` only disposes non-Joker instances that implement `Disposable`, `AsyncDisposable`, or `ChangeNotifier`. Jokers manage their own lifecycle.

### 🎭 UI Integration

JokerState gives you several widgets to connect state and UI:

#### JokerStage

Rebuilds whenever any part of the state changes:

```dart
final userJoker = Joker<User>(User(name: 'Alice', age: 30));

JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

Or use the fluent API:

```dart
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

#### JokerFrame

Rebuild only for a specific part of your state:

```dart
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
```

#### JokerTroupe

Combine multiple Jokers using Dart Records:

```dart
final name = Joker<String>('Alice');
final age = Joker<int>(30);
final active = Joker<bool>(true);

typedef UserRecord = (String name, int age, bool active);

[name, age, active].assemble<UserRecord>(
  converter: (values) => (values[0] as String, values[1] as int, values[2] as bool),
  builder: (context, user) {
    final (name, age, active) = user;
    return Column(
      children: [
        Text('Name: $name'),
        Text('Age: $age'),
        Icon(active ? Icons.check : Icons.close),
      ],
    );
  },
)
```

#### JokerPortal & JokerCast

Provide and access Jokers through the widget tree. **If you're using common types like `int` or `String`, always use a `tag` to avoid confusion.**

```dart
// Provide Joker in the widget tree
JokerPortal<int>(
  joker: counterJoker,
  tag: 'counter', // Tag is important!
  child: MyApp(),
)

// Access it from any descendant
JokerCast<int>(
  tag: 'counter', // Use the same tag!
  builder: (context, count) => Text('Count: $count'),
)

// Or use the extension
Text('Count: ${context.joker<int>(tag: 'counter').state}')
```

### 🎪 Special Widgets

#### JokerReveal

Show widgets conditionally based on a boolean:

```dart
// Direct widgets
JokerReveal(
  condition: isLoggedIn,
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)

// Lazy construction
JokerReveal.lazy(
  condition: isLoading,
  whenTrueBuilder: (context) => LoadingIndicator(),
  whenFalseBuilder: (context) => ContentView(),
)

// Or use the extension on boolean
isLoggedIn.reveal(
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)
```

#### JokerTrap

Automatically dispose controllers when a widget is removed:

```dart
// Single controller
textController.trapeze(
  TextField(controller: textController),
)

// Multiple controllers
[textController, scrollController, animationController].trapeze(
  ComplexWidget(),
)
```

### 📢 RingCueMaster: Event Bus System

A type-safe event bus for communication between parts of your app:

```dart
// Define event types
class UserLoggedIn extends Cue {
  final User user;
  UserLoggedIn(this.user);
}

// Access the global event bus
final cueMaster = Circus.ringMaster();

// Listen for events
final subscription = Circus.onCue<UserLoggedIn>((event) {
  print('User ${event.user.name} logged in at ${event.timestamp}');
});

// Send events
Circus.cue(UserLoggedIn(currentUser));

// Cancel subscription when done
subscription.cancel();
```

### ⏱️ CueGate: Timing Controls

Debounce and throttle actions easily:

```dart
// Create a debounce gate
final debouncer = CueGate.debounce(delay: Duration(milliseconds: 300));

// Use in event handlers
TextField(
  onChanged: (value) {
    debouncer.trigger(() => performSearch(value));
  },
),

// Create a throttle gate
final throttler = CueGate.throttle(interval: Duration(seconds: 1));

// Limit UI updates
scrollController.addListener(() {
  throttler.trigger(() => updatePositionIndicator());
});

// In StatefulWidgets, use the mixin for automatic cleanup
class SearchView extends StatefulWidget {
// ...
}

class _SearchViewState extends State<SearchView> with CueGateMixin {
  void _handleSearchInput(String query) {
    debounceTrigger(
      () => _performSearch(query),
      Duration(milliseconds: 300),
    );
  }

  void _handleScroll() {
    throttleTrigger(
      () => _updateScrollPosition(),
      Duration(milliseconds: 100),
  );
}

// Cleanup handled automatically by mixin
}
```

## Advanced Features

### 🔄 Side-Effects

Listen for state changes and run side-effects:

```dart
// Listen to all changes
final cancel = counter.listen((previous, current) {
  print('Changed from $previous to $current');
});

// Listen conditionally
counter.listenWhen(
  listener: (prev, curr) => showToast('Milestone reached!'), 
  shouldListen: (prev, curr) => curr > 100 && (prev ?? 0) <= 100,
);

// Cancel when done
cancel();
```

### 💉 CircusRing Dependencies

Set up relationships between dependencies:

```dart
// Make UserRepository depend on ApiService
Circus.bindDependency<UserRepository, ApiService>();

// Now ApiService can't be removed while UserRepository is registered
```

### 🧹 Resource Management

- **Joker**: Manages its own lifecycle based on listeners and `keepAlive`.
- **CircusRing**: Disposes non-Joker resources when removed.
- **Manual Cleanup**: Always call `dispose()` on Jokers or other resources not managed elsewhere (especially `keepAlive: true` Jokers).

```dart
// Joker example
final persistentJoker = Joker<int>(0, keepAlive: true);
// ... use joker ...
persistentJoker.dispose(); // Manual disposal needed

// CircusRing example (Disposable)
Circus.hire(MyDisposableService());
// ... use service ...
Circus.fire<MyDisposableService>(); // Service will be disposed by fire()

// CircusRing example (Joker)
final managedJoker = Circus.summon<int>(0, tag: 'temp');
// ... use joker ...
Circus.vanish<int>(tag: 'temp'); // Removes from ring ONLY
// managedJoker will dispose itself if no listeners remain (default keepAlive: false)
```

## Example

Here's a full counter example:

```dart
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Find the registered Joker
    final counter = Circus.summon<int>(tag: 'counter');
    
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('JokerState Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              // Rebuild only when the state changes
              counter.perform(
                builder: (context, count) => Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          // Update the state
          onPressed: () => counter.trickWith((state) => state + 1),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

## Additional Info

JokerState is designed to be lightweight, flexible, and powerful—giving you reactive state management and dependency injection in one package.

### When should you use JokerState?

- You want something simpler than BLoC or other complex state solutions
- You need reactive UI updates with minimal boilerplate
- You want the flexibility to control things manually when needed
- You want built-in dependency management
- You prefer clear, direct state operations (not abstract concepts)
- You want a type-safe event bus for decoupled communication
- You want utility widgets that work well with your state management

## License

MIT
