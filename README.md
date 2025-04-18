[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](README-zh.md)

# 🃏 JokerState

**⚠️ Breaking Changes in v2.0.0:** Joker lifecycle and CircusRing disposal behavior have changed significantly. Please review the [Changelog](CHANGELOG.md) and updated documentation below before upgrading.

A lightweight, reactive state management solution for Flutter that integrates dependency injection seamlessly. JokerState provides flexible state containers with minimal boilerplate through its `Joker` API and companion widgets.

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🧠 **Reactive State Management** - Smart containers that notify listeners when state changes
- 💉 **Dependency Injection** - Intuitive service locator with the CircusRing API
- 🎭 **Flexible Widget Integration** - Multiple companion widgets for different UI patterns
- 🪄 **Selective Rebuilds** - Fine-grained control over what updates rebuild your UI
- 🔄 **Batch Updates** - Group multiple state changes into a single notification
- 🏗️ **Record Support** - Combine multiple states using Dart Records
- 🧩 **Modular Design** - Use just what you need or the entire ecosystem
- 📢 **Event Bus System** - Type-safe events with RingCueMaster
- 🎪 **Special Widgets** - Additional utility widgets like JokerReveal and JokerTrap
- ⏱️ **Timing Controls** - Debounce and throttle mechanisms for controlling action execution

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

`Joker<T>` is a reactive state container that extends `ChangeNotifier`. Its lifecycle is now primarily managed by its listeners and the `keepAlive` flag.

```dart
// Create a Joker with auto-notification (default)
final counter = Joker<int>(0);

// Update state and notify all listeners
counter.trick(1);

// Update using a transform function
counter.trickWith((current) => current + 1);

// Batch multiple updates with a single notification
counter.batch()
  .apply((s) => s * 2)
  .apply((s) => s + 10)
  .commit();

// Create a Joker that stays alive even without listeners
final persistentState = Joker<String>("initial", keepAlive: true);
```

For granular control, use manual notification mode:

```dart
// Create with auto-notify disabled
final manualCounter = Joker<int>(0, autoNotify: false);

// Update silently
manualCounter.whisper(5);
manualCounter.whisperWith((s) => s + 1);

// Trigger listeners manually when ready
manualCounter.yell();
```

**Lifecycle:** By default (`keepAlive: false`), a Joker automatically schedules itself for disposal via `Future.microtask` when its last listener is removed. Adding a listener again cancels this. Set `keepAlive: true` to disable this auto-disposal.

### 🎪 CircusRing: Dependency Injection

CircusRing is a lightweight dependency container. Its `fire*` methods now perform **conditional disposal**.

```dart
// Global singleton accessor
final ring = Circus;

// Register a singleton (Disposable example)
ring.hire(MyDisposableService());

// Register a lazy-loaded singleton
ring.hireLazily(() => NetworkService());

// Register a factory (new instance per request)
ring.contract(() => ApiClient());

// Find instances later
final service = Circus.find<MyDisposableService>();
```

For Joker integration with CircusRing:

```dart
// Register a Joker (requires a tag)
Circus.summon<int>(0, tag: 'counter');

// Find registered Joker
final counter = Circus.spotlight<int>(tag: 'counter');

// Remove a Joker (ONLY removes from ring, does NOT dispose the Joker)
Circus.vanish<int>(tag: 'counter'); 

// Joker's own lifecycle (listeners/keepAlive) determines when it disposes.
```

**Disposal:** `Circus.fire*` methods will **only** dispose non-Joker instances that implement `Disposable`, `AsyncDisposable`, or `ChangeNotifier`. `Joker` instances are **never** disposed by CircusRing; they manage their own lifecycle.

### 🎭 UI Integration

JokerState provides multiple widget types to integrate with your UI:

#### JokerStage

Rebuilds when any part of the state changes:

```dart
final userJoker = Joker<User>(User(name: 'Alice', age: 30));

JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

Or with a more fluent API:

```dart
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}, Age: ${user.age}'),
)
```

#### JokerFrame

For selective rebuilds based on a specific part of your state:

```dart
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
```

#### JokerTroupe

Combine multiple Jokers with Dart Records:

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

Provide and access Jokers through the widget tree. **Remember to use `tag` when providing/accessing common types like `int` or `String` to avoid ambiguity.**

```dart
// Insert Joker into widget tree
JokerPortal<int>(
  joker: counterJoker,
  tag: 'counter', // Tag is crucial here!
  child: MyApp(),
)

// Later, access it from any descendant
JokerCast<int>(
  tag: 'counter', // Use the same tag!
  builder: (context, count) => Text('Count: $count'),
)

// Or access directly with extension
Text('Count: ${context.joker<int>(tag: 'counter').state}')
```

### 🎪 Special Widgets

#### JokerReveal

Conditionally display widgets based on a boolean expression:

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

// Or use the extension method on boolean
isLoggedIn.reveal(
  whenTrue: ProfileScreen(),
  whenFalse: LoginScreen(),
)
```

#### JokerTrap

Automatically dispose controllers when a widget is removed from the tree:

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

A type-safe event bus for communication between components:

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

Manage the timing of actions with debounce and throttle mechanisms:

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

Listen for state changes with side-effects:

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

Establish relationships between dependencies:

```dart
// Record that UserRepository depends on ApiService
Circus.bindDependency<UserRepository, ApiService>();

// Now ApiService can't be removed while UserRepository is registered
```

### 🧹 Resource Management

- **Joker**: Manages its own lifecycle based on listeners and `keepAlive`.
- **CircusRing**: Conditionally disposes non-Joker resources upon removal.
- **Manual Cleanup**: Always manually `dispose()` Jokers or other resources not managed elsewhere (especially `keepAlive: true` Jokers).

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

Complete counter example:

```dart
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  // Register Joker globally
  Circus.summon<int>(0, tag: 'counter');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Find the registered Joker
    final counter = Circus.spotlight<int>(tag: 'counter');
    
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

## Additional Information

JokerState is designed to be lightweight, flexible, and powerful - providing reactive state management with dependency injection in one cohesive package.

### When to use JokerState

- You want a simpler alternative to BLoC or other complex state solutions
- You need reactive UI updates with minimal boilerplate
- You want the flexibility of manual control when needed
- You need integrated dependency management
- You prefer clear, direct state manipulation without abstract concepts
- You want a type-safe event bus for decoupled communication
- You need utility widgets that work well with your state management

## License

MIT
