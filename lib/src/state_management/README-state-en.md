## 🚀 Basic Usage

### Creating a Joker or Presenter

- JokerState gives you a simple reactive container via `Joker`. When you want to implement BLoC, MVC, or MVVM patterns with clear separation of concerns, switch to `Presenter`. It extends `Joker` and adds handy lifecycle hooks—`onInit`, `onReady`, and `onDone`—so you can neatly organize setup, UI-ready logic, and cleanup without drowning in boilerplate.

```dart
// Simple reactive state (Joker)
final counterJoker = Joker<int>(0);

// Structured controller for BLoC/MVC/MVVM (Presenter)
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0);

  @override
  void onInit() { /* setup data or listeners */ }

  @override
  void onReady() { /* safe to use BuildContext or WidgetsBinding */ }

  @override
  void onDone() { /* clean up any resources */ }

  void increment() => trickWith((s) => s + 1);
}
final counterPresenter = CounterPresenter();

// Common usage:
counterJoker.trick(1);
counterPresenter.increment();

// Keep alive examples
final persistentJoker = Joker<String>("data", keepAlive: true);
final persistentPresenter = CounterPresenter(keepAlive: true);
```

### Using Joker/Presenter with Flutter

```dart
// Simplest way using perform()
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);

counterPresenter.perform(
  builder: (context, count) => Text('Presenter Count: $count'),
);

// Select just a part of the state using focusOn()
userPresenter.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

## 🎪 Core Concepts

### How to Update State

Joker gives you several ways to update state:

```dart
// Auto-notify (default)
counterJoker.trick(42);                      // Direct value assignment
counterJoker.trickWith((state) => state + 1); // Use a function to update
await counterJoker.trickAsync(fetchValue);    // Async update

// Manual mode
counterJoker.whisper(42);                     // Silent update
counterJoker.whisperWith((s) => s + 1);       // Silent transform
counterJoker.yell();                          // Notify when you want
```

### Batch Updates

Group multiple changes into a single notification:

```dart
userJoker.batch()
  .apply((u) => u.copyWith(name: 'Bob'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // Notifies listeners once
```

## 🌉 Widget Ecosystem

### JokerStage / Presenter.perform

Watch the whole state of a Joker or Presenter:

```dart
// With Joker
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
// With Presenter (using extension)
myPresenter.perform(
   builder: (context, state) => Text('State: $state'),
)
```

### JokerFrame / Presenter.focusOn

Watch just a part of the state to avoid unnecessary rebuilds:

```dart
// With Joker
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
// With Presenter (using extension)
userPresenter.focusOn<String>(
  selector: (userProfile) => userProfile.name,
  builder: (context, name) => Text('Name: $name'),
)
```

### JokerTroupe

Combine multiple Jokers into one widget using Dart Records:

```dart
// Define your combined state type
typedef UserProfile = (String name, int age, bool isActive);

JokerTroupe<UserProfile>(
  jokers: [nameJoker, ageJoker, activeJoker],
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool,
  ),
  builder: (context, profile) {
    final (name, age, active) = profile;
    return ListTile(
      title: Text(name),
      subtitle: Text('Age: $age'),
      trailing: Icon(active ? Icons.check : Icons.close),
    );
  },
)
```

### JokerPortal & JokerCast

Make Jokers available throughout your widget tree:

```dart
// Provide Joker at the top of your widget tree
JokerPortal<int>(
  tag: 'counter',
  joker: counterJoker,
  child: MaterialApp(...),
)

// Access Joker anywhere in the tree
JokerCast<int>(
  tag: 'counter',
  builder: (context, count) => Text('Count: $count'),
)

// Or use the extension
Text('Count: ${context.joker<int>(tag: 'counter').state}')
```

## 🎭 Side Effects and Listeners

React to state changes without rebuilding the UI:

```dart
// Listen to all changes
final cancel = counterJoker.listen((previous, current) {
  print('Counter changed from $previous to $current');
});

// Conditional listening
final cancel = counterJoker.listenWhen(
  listener: (prev, curr) => print('Counter increased!'),
  shouldListen: (prev, curr) => curr > (prev ?? 0),
);

// Stop listening when you want
cancel();
```

## 🎪 Dependency Injection with CircusRing

Joker and Presenter work seamlessly with CircusRing:

```dart
// Register a Joker (use summon)
Circus.summon<int>(0, tag: 'counter');

// Register a Presenter (use hire)
final presenter = MyPresenter(initialState, tag: 'myPresenter');
Circus.hire<MyPresenter>(presenter, tag: 'myPresenter');

// Access anywhere
final counterJoker = Circus.spotlight<int>(tag: 'counter');
final myPresenter = Circus.find<MyPresenter>(tag: 'myPresenter');

// Remove when done (CircusRing handles disposal based on keepAlive)
Circus.vanish<int>(tag: 'counter'); // Will dispose if keepAlive is false
Circus.fire<MyPresenter>(tag: 'myPresenter'); // Will dispose if keepAlive is false
```

## 📚 Extension Methods

These extensions make your code cleaner and easier to read:

```dart
// Create widgets directly from Joker/Presenter instances
counterJoker.perform(...);
counterPresenter.perform(...);

userPresenter.focusOn<String>(...);

// Combine multiple Jokers
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(...);
```

## 🧹 Lifecycle Management

- **Listener-based disposal**: By default (`keepAlive: false`), `Joker` and `Presenter` schedule disposal with a microtask when their last listener is removed.
- **Cancellation**: Adding a listener again cancels the scheduled disposal.
- **`keepAlive`**: Set `keepAlive: true` to prevent listener-based disposal. The instance remains until explicitly disposed or removed by CircusRing (see below).
- **Manual disposal**: You can always call `joker.dispose()` or `presenter.dispose()` yourself.
- **Widget integration**: Widgets like `JokerStage`, `JokerFrame` manage listeners. Removing the widget may trigger auto-disposal if `keepAlive` is false.
- **CircusRing Interaction (v3.0.0+)**: When removing a `Joker` or `Presenter` via `Circus.fire*` or `Circus.vanish`, CircusRing **WILL** call `dispose()` on the instance **IF `keepAlive` is `false`**. If `keepAlive` is `true`, CircusRing only removes it from the registry, and you need to manage disposal manually.

## 🧪 Best Practices

1. **Use selectors (`focusOn`)**: Minimize rebuilds by selecting only needed state parts.
2. **Batch updates**: Group related changes.
3. **Tag your instances**: Always use tags with CircusRing, especially for common types.
4. **`keepAlive`**: Use `keepAlive: true` for global/persistent state (Joker or Presenter). Remember manual disposal might be needed if CircusRing removes it.
5. **Explicit disposal**: Manually `dispose()` instances not managed by widgets or CircusRing (especially if `keepAlive` is true).