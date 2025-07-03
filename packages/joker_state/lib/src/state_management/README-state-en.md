## 🃏 State Management with JokerState

This document details the state management features of JokerState, which are now built on Flutter's `ChangeNotifier`.

### Creating a State Holder: Joker vs. Presenter

- **`Joker<T>`**: A simple, lightweight state container, perfect for local state. It's analogous to a `ValueNotifier` but with more features.
- **`Presenter<T>`**: An advanced state holder with a defined lifecycle (`onInit`, `onReady`, `onDone`). It's designed for complex business logic where you need to manage resources or perform setup/teardown operations.

Both `Joker` and `Presenter` extend a common base class, `JokerAct<T>`.

```dart
// Simple counter state using Joker
final counterJoker = Joker<int>(0, keepAlive: true);

// Counter controller with lifecycle using Presenter
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0, keepAlive: true);

  void increment() => trickWith((s) => s + 1);

  @override
  void onInit() {
    print('Presenter initialized!');
    super.onInit();
  }

  @override
  void onDone() {
    print('Presenter cleaned up!');
    super.onDone();
  }
}
final counterPresenter = CounterPresenter();
```

### Updating State

State can be updated in several ways, depending on whether `autoNotify` is enabled (which it is by default).

```dart
// --- Automatic Notifications (autoNotify: true) ---

// Direct assignment (Joker only)
counterJoker.state = 1;

// Using trick() - works for both Joker and Presenter
counterPresenter.trick(1);

// Update with a function
counterPresenter.trickWith((state) => state + 1);

// Async update
await counterPresenter.trickAsync(fetchValue);

// --- Manual Notifications (autoNotify: false) ---
final manualJoker = Joker(0, autoNotify: false);

manualJoker.whisper(42);              // Change value silently
manualJoker.whisperWith((s) => s + 1); // Silent transform
manualJoker.yell();                   // Manually notify listeners
```

### Batch Updates

For manual notification mode, you can group multiple changes into a single update.

```dart
final userJoker = Joker<User>(User(name: 'initial'), autoNotify: false);

userJoker.batch()
  .apply((u) => u.copyWith(name: 'John Doe'))
  .apply((u) => u.copyWith(age: 30))
  .commit(); // Notifies listeners only once
```

## 🌉 UI Integration

### Dependency Injection with `JokerRing`

Provide a `Joker` or `Presenter` to the widget tree using `JokerRing`.

```dart
JokerRing<int>(
  act: counterPresenter,
  child: YourWidgetTree(),
);
```

### Accessing State in Widgets

Use the `BuildContext` extensions to access the provided state holders.

- `context.watchJoker<T>()`: Listens for changes and rebuilds the widget. Returns the `JokerAct<T>` instance.
- `context.joker<T>()`: Reads the instance without listening. Useful for calling methods in event handlers like `onPressed`.

```dart
// In a build method:

// To display the value (rebuilds on change)
final count = context.watchJoker<int>().value;
Text('Count: $count');

// To call a method (does not cause rebuilds)
onPressed: () {
  final presenter = context.joker<int>() as CounterPresenter;
  presenter.increment();
}
```

### Context-less Access with `CircusRing`

For accessing dependencies from outside the widget tree (e.g., within a `Presenter` or a service layer), you can use `CircusRing` directly. This follows the Service Locator pattern.

1.  **Hire (Register) a dependency**:
    You can using it anywhere you want in your app.

    ```dart
    // Register a singleton instance of CounterPresnter
    CircusRing.hire(CounterPresnter());
    ```

2.  **Find (Locate) a dependency**:
    Access the instance anywhere in your app without `BuildContext`.

    ```dart
    final counter = Circus.find<CounterPresnter>();

    // Use the instance
    Button(
      onPressed: () {
        counter.increment();
      },
    )
    ```

### Binding State to Widgets

Use the convenient extension methods on any `JokerAct` instance to bind it to your UI.

#### `perform()`
Rebuilds the widget whenever the state changes.

```dart
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);
```

#### `focusOn()`
Rebuilds the widget only when a selected part of the state changes. This is crucial for performance optimization.

```dart
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

#### `watch()`
Performs a side effect (like showing a `SnackBar` or navigating) in response to a state change, without rebuilding the child widget.

```dart
messageJoker.watch(
  onStateChange: (context, message) {
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  },
  child: YourPageContent(), // This child does not rebuild
);
```

#### `rehearse()`
A combination of `perform` and `watch`. It rebuilds the UI *and* performs a side effect from a single state stream.

```dart
counterJoker.rehearse(
  builder: (context, count) => Text('Count: $count'),
  onStateChange: (context, count) {
    if (count % 10 == 0) {
      print('Reached a multiple of 10!');
    }
  },
);
```

#### `assemble()`
Combines multiple `JokerAct` instances into a single builder using Dart Records. The widget rebuilds if any of the source `JokerAct`s change.

```dart
typedef UserProfile = (String name, int age);

[nameJoker, ageJoker].assemble<UserProfile>(
  converter: (values) => (values[0] as String, values[1] as int),
  builder: (context, profile) {
    final (name, age) = profile;
    return Text('$name is $age years old.');
  },
);
```
