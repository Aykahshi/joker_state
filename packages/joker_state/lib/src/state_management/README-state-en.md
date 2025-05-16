## 🎪 Basic Usage

### Creating Joker or Presenter

- JokerState provides a simple `Joker` container, allowing you to easily manage local variables and achieve fine-grained rebuild control.
- `Presenter` is built on top of `BehaviorSubject` and introduces three major lifecycle hooks: `onInit`, `onReady`, and `onDone`. These make it easy to manage lifecycles and implement architectures like Clean Architecture.

```dart
// Simplest counter state (Joker)
final counterJoker = Joker<int>(0);

// Counter controller with lifecycle (Presenter)
class CounterPresenter extends Presenter<int> {
  CounterPresenter() : super(0);
  void increment() => trickWith((s) => s + 1);
  @override void onInit() { print('Presenter initialized!'); }
  @override void onDone() { print('Presenter cleaned up!'); }
}
final counterPresenter = CounterPresenter();

// Common operations for both:
counterJoker.trick(1);
counterPresenter.increment(); 

// keepAlive option
final persistentJoker = Joker<String>("data", keepAlive: true);
final persistentPresenter = CounterPresenter(keepAlive: true);
```

### Using Joker/Presenter in Flutter

```dart
// Simplest way: perform()
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);

counterPresenter.perform(
  builder: (context, count) => Text('Presenter Count: $count'),
);

// Use focusOn() to observe only part of the state
userPresenter.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

## 🎪 Core Concepts

### How to Update State

Joker provides various methods for updating state:

```dart
// Auto notification (default)
counterJoker.trick(42);                      // Direct assignment
counterJoker.trickWith((state) => state + 1); // Function transform
await counterJoker.trickAsync(fetchValue);    // Async update

// Manual notification
counterJoker.whisper(42);                     // Change value silently
counterJoker.whisperWith((s) => s + 1);       // Silent transform
counterJoker.yell();                          // Notify when needed
```

### Batch Updates

Multiple state changes can be merged into a single notification:

```dart
userJoker.batch()
  .apply((u) => u.copyWith(name: 'John'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // Notifies listeners only once
```

## 🌉 Widget Ecosystem

### Joker.perform / Presenter.perform

Observe the entire state of Joker or Presenter to rebuild widgets:

```dart
// Using Joker extension
userJoker.perform(
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
// Using Presenter extension
myPresenter.perform(
   builder: (context, state) => Text('State: $state'),
)
```

### Joker.focusOn / Presenter.focusOn

Observe only part of the state to avoid unnecessary rebuilds:

```dart
// Using Joker extension
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
// Using Presenter extension
userPresenter.focusOn<String>(
  selector: (userProfile) => userProfile.name,
  builder: (context, name) => Text('Name: $name'),
)
```

### JokerTroupe / PresenterTroupe

Combine multiple Joker/Presenter states using Dart Records:

```dart
// Define combined state type
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

PresenterTroupe<UserProfile>(
  presenters: [namePresenter, agePresenter, activePresenter],
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

// Using extension method
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
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

## 🎭 Side Effects and Listeners

You can listen to state changes without rebuilding the UI:

```dart
// Listen to all changes
final cancel = counterJoker.listen((previous, current) {
  print('Count changed from $previous to $current');
});

// Conditional listening
final cancel = counterJoker.listenWhen(
  listener: (prev, curr) => print('Count increased!'),
  shouldListen: (prev, curr) => curr > (prev ?? 0),
);

// Remember to cancel the listener when not needed
cancel();
```