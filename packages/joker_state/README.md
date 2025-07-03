[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](README-zh.md)

# 🃏 JokerState

**⚠️ Major Refactor Notice:**
- **No More RxDart**: The package has been completely refactored to remove the dependency on `rxdart`.
- **Built on ChangeNotifier**: The core is now built on Flutter's native `ChangeNotifier` for a simpler, more lightweight, and predictable API.
- **Simplified API**: `Joker` and `Presenter` now share a common base class, `JokerAct`, simplifying the overall architecture.
- **New DI Methods**: Dependency injection via `BuildContext` has been streamlined. Use `context.joker<T>()` to read a value and `context.watchJoker<T>()` to listen for changes.

JokerState is a lightweight, reactive Flutter state management toolkit built on `ChangeNotifier`, with integrated dependency injection.
With the `Joker`, `Presenter`, and UI binding widgets, you can flexibly manage state and dramatically reduce boilerplate.

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🧠 **Reactive State Management**: Automatic widget rebuilds and side-effect execution, powered by `ChangeNotifier`.
- 💉 **Simple Dependency Injection**: Easily provide `Joker` or `Presenter` instances to the widget tree.
- 🪄 **Selective Rebuilds**: Fine-grained control over what triggers UI updates to optimize performance.
- 🔄 **Batch Updates**: Combine multiple state changes into a single UI notification.
- 🏗️ **Record Support**: Combine multiple states into a single view using Dart Records with `JokerTroupe`.
- 🧩 **Modular Design**: A clear separation between state logic and UI widgets.
- 📢 **Event Bus**: A type-safe event system is available for decoupled communication.
- ⏱️ **Timing Controls**: Debounce and throttle utilities to manage frequent events.

## Quick Start

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

### 🎭 Joker: Local Reactive State Container

`Joker<T>` is a lightweight state container based on `ChangeNotifier`. It's perfect for managing simple, local state. Its lifecycle is managed by its listeners and the `keepAlive` parameter.

```dart
// Create a Joker (auto-notifies by default)
final counter = Joker<int>(0);

// Update state and notify all listeners
counter.trick(1);

// Or simply use the setter
counter.state = 2;

// Update using a function
counter.trickWith((current) => current + 1);
```

### ✨ Presenter: State Management with Lifecycle

`Presenter<T>` is an advanced version of `Joker`. It includes lifecycle hooks (`onInit`, `onReady`, `onDone`), making it ideal for complex business logic and implementing patterns like BLoC or MVVM.

```dart
class MyCounterPresenter extends Presenter<int> {
  MyCounterPresenter() : super(0);

  @override
  void onInit() { /* Initialization */ }

  @override
  void onReady() { /* Safe to interact with WidgetsBinding */ }

  @override
  void onDone() { /* Clean up resources */ }

  void increment() => trickWith((s) => s + 1);
}

// Usage:
final myPresenter = MyCounterPresenter();
myPresenter.increment();
// dispose() automatically calls onDone()
myPresenter.dispose();
```

### 🎪 JokerRing & CircusRing: Dependency Injection

#### Context-based DI with `JokerRing`
Use `JokerRing` to provide a `Joker` or `Presenter` to the widget tree. Descendants can then access the instance using context extensions.

```dart
// 1. Provide the Joker/Presenter
JokerRing<int>(
  act: myPresenter,
  child: MyScreen(),
);

// 2. Access it in a descendant widget
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use watchJoker to listen for changes and rebuild
    final count = context.watchJoker<int>().value;

    return Scaffold(
      body: Text('Count: $count'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use joker() to get the instance without listening
          // Cast it to the concrete type to access its methods
          final presenter = context.joker<int>() as MyCounterPresenter;
          presenter.increment();
        },
      ),
    );
  }
}
```

#### Context-less DI with `CircusRing`
For accessing dependencies from outside the widget tree (e.g., in a service or another `Presenter`), you can use `CircusRing` as a service locator.

```dart
// 1. Register a dependency (e.g., in main.dart)
Circus.hire<ApiService>(ApiService());

// 2. Find the dependency anywhere, without BuildContext
class AuthPresenter extends Presenter<AuthState> {
  final _apiService = Circus.find<ApiService>();

  Future<void> login(String user, String pass) async {
    final result = await _apiService.login(user, pass);
    // ... update state
  }
}
```

### 🎭 Simple Reactive UI Integration

JokerState provides extension methods on any `JokerAct` (`Joker` or `Presenter`) for seamless UI integration.

```dart
// Rebuild a widget when the state changes
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);

// Rebuild only when a specific part of the state changes
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

For more details, see [State Management](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/state_management/README-state-en.md).

### 📢 Event Bus & ⏱️ Timing Controls

The package also includes a robust, type-safe event bus (`RingCueMaster`) and timing control utilities (`CueGate`) for throttling and debouncing events. These tools are independent of the state management core but integrate well with it.

**Example: Debouncing search queries with `CueGate` and `RingCueMaster`**

```dart
// Define a search event
class SearchQueryChanged {
  final String query;
  SearchQueryChanged(this.query);
}

// Create a debounce gate
final searchGate = CueGate.debounce(delay: const Duration(milliseconds: 300));

// In your UI:
TextField(
  onChanged: (text) {
    // Trigger the gate. The action will only run after 300ms of inactivity.
    searchGate.trigger(() {
      // Send the event through the event bus
      Circus.cue(SearchQueryChanged(text));
    });
  },
);

// In your Presenter or another service, listen for the debounced event:
class SearchPresenter extends Presenter<List<String>> {
  SearchPresenter() : super([]) {
    // Listen for debounced search queries
    Circus.onCue<SearchQueryChanged>((event) {
      _performSearch(event.query);
    });
  }

  void _performSearch(String query) {
    // ... your search logic
  }
}
```

For more details, see their respective READMEs within the `lib` directory.

## When to use JokerState

- You want a simpler alternative to complex state management solutions.
- You need reactive UI updates with minimal boilerplate.
- You want the flexibility of both automatic and manual state notifications.
- You need a simple, integrated dependency injection solution.
- You prefer clear, direct state manipulation.

## License

MIT
