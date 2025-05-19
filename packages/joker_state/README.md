[![Chinese](https://img.shields.io/badge/Language-Chinese-blueviolet?style=for-the-badge)](README-zh.md)

# 🃏 JokerState

**⚠️ Breaking Changes in v4.0.0:**
- `CircusRing` is now a standalone package. While still usable in JokerState, it no longer provides Joker-specific integration. Please use [circus_ring](https://pub.dev/packages/circus_ring).
- `RingCueMaster` now leverages `rx_dart` for a more robust Event Bus system.
- `JokerStage` and `JokerFrame` constructors are now private. Please use the `perform` and `focusOn` APIs instead.
- Both `Joker` and `Presenter` are now based on `RxInterface`, providing more flexible and efficient state management.
- `RxInterface` is built on `BehaviorSubject` and internally uses `Timer` for improved autoDispose handling.
- `JokerPortal` and `JokerCast` are deprecated. For context-free state management, use CircusRing API with `Presenter`.
- `JokerReveal` is deprecated. Use Dart's native language features for conditional rendering.
- `JokerTrap` is deprecated. Use `Presenter`'s `onDone` or `StatefulWidget`'s `dispose` for controller management.

JokerState is a lightweight, reactive Flutter state management toolkit based on `rx_dart`, with integrated dependency injection via [circus_ring](https://pub.dev/packages/circus_ring).  
With just the `Joker`, `Presenter`, and `CircusRing` APIs, you can flexibly manage state and dramatically reduce boilerplate.

[![pub package](https://img.shields.io/pub/v/joker_state.svg)](https://pub.dev/packages/joker_state)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🧠 **Reactive State Management**: Automatic widget rebuilds and side-effect execution.
- 💉 **Dependency Injection**: Simple DI with the CircusRing API.
- 🪄 **Selective Rebuilds**: Fine-grained control over what triggers UI updates.
- 🔄 **Batch Updates**: Combine multiple state changes into a single notification.
- 🏗️ **Record Support**: Combine multiple states using Dart Records.
- 🧩 **Modular Design**: Import only what you need, or use the full package.
- 📢 **Event Bus**: Type-safe event system via RingCueMaster.
- ⏱️ **Timing Controls**: Debounce, throttle, and more for smooth UX.

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

`Joker<T>` is a local reactive state container extending `ChangeNotifier`. Its lifecycle is managed by listeners and the `keepAlive` flag.

```dart
// Create a Joker (auto-notifies by default)
final counter = Joker<int>(0);

// Update state and notify all listeners
counter.trick(1);

// Update using a function
counter.trickWith((current) => current + 1);

// Batch multiple updates, notify once
counter.batch()
  .apply((s) => s * 2)
  .apply((s) => s + 10)
  .commit();

// Persistent Joker (remains alive even without listeners)
final persistentState = Joker<String>("initial", keepAlive: true);
```

For manual notification mode:

```dart
// Create with autoNotify off
final manualCounter = Joker<int>(0, autoNotify: false);

// Silent updates
manualCounter.whisper(5);
manualCounter.whisperWith((s) => s + 1);

// Notify listeners when ready
manualCounter.yell();
```

**Lifecycle:** By default (`keepAlive: false`), Joker schedules itself for disposal (via microtask) when its last listener is removed. Adding a listener cancels disposal. Set `keepAlive: true` to keep it alive until manually disposed.

### ✨ Presenter

`Presenter<T>` is built on `BehaviorSubject<T>` and provides `onInit`, `onReady`, and `onDone` lifecycle hooks—perfect for BLoC, MVC, or MVVM patterns.

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

### 🎪 CircusRing: Dependency Injection

CircusRing is a lightweight dependency container, now a standalone package ([circus_ring](https://pub.dev/packages/circus_ring)), but still usable within JokerState.

---

### 🎭 Simple Reactive UI Integration

JokerState provides various widgets for seamless state and UI integration:

#### The Simplest Usage

```dart
// Using Joker
final userJoker = Joker<User>(...);
userJoker.perform(
  builder: (context, user) => Text('Name: ${user.name}'),
)

// Using Presenter
final myPresenter = MyPresenter(...);
myPresenter.perform(
  builder: (context, state) => Text('State: $state'),
)
```

For more details, see [State Management](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/state_management/README-state-en.md).

### 📢 RingCueMaster: Event Bus System

Type-safe event bus for communication between components:

```dart
// Define event type
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

// Send event
Circus.sendCue(UserLoggedIn(currentUser));

// Cancel subscription when done
subscription.cancel();
```

For more details, see [Event Bus](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/event_bus/README-event-bus-en.md).

### ⏱️ CueGate: Timing Controls

Manage actions with debounce and throttle:

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

// In StatefulWidget, use the mixin for automatic cleanup
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

For more details, see [Timing Controls](https://github.com/Aykahshi/joker_state/blob/master/packages/joker_state/lib/src/timing_control/README-gate-en.md).

## Advanced Features

### 🔄 Side-Effects

Listen for state changes and execute side-effects:

```dart
final counter = Joker<int>(0);

counter.effect(
  child: Container(),
  effect: (context, state) {
    print('State changed: $state');
  },
  runOnInit: true,
  effectWhen: (prev, val) => (prev!.value ~/ 5) != (val.value ~/ 5),
);
```

## Additional Info

JokerState is designed to be lightweight, flexible, and powerful—offering reactive state management and dependency injection in one cohesive package.

### When should you use JokerState?

- You want something simpler than BLoC or other complex state solutions
- You need reactive UI updates with minimal boilerplate
- You want the flexibility to control things manually when needed
- You need integrated dependency management
- You prefer clear, direct state operations (not abstract concepts)
- You need a type-safe event bus for decoupled communication
- You want utility widgets that work well with your state management

## License

MIT