## 🎪 Basic Usage

### Creating Joker or Presenter

- JokerState provides a concise `Joker` container, allowing you to easily manage local variables much like Vue's `ref`.
- `Presenter` is built on top of `BehaviorSubject` and includes three major lifecycle hooks: `onInit`, `onReady`, and `onDone`. These facilitate easy lifecycle management and straightforward implementation of architectures like Clean Architecture.

```dart
// Simplest counter state (Joker)
final counterJoker = Joker<int>(0);

// Counter controller with lifecycle (Presenter)
class CounterPresenter extends Presenter<int> {
  CounterPresenter({super.initialState = 0, super.keepAlive}); // Pass initialState and keepAlive to super

  void increment() => trickWith((s) => s + 1);

  @override
  void onInit() {
    print('Presenter initialized!');
    super.onInit(); // It's good practice to call super.onInit()
  }

  @override
  void onDone() {
    print('Presenter cleaned up!');
    super.onDone(); // It's good practice to call super.onDone()
  }
}
final counterPresenter = CounterPresenter();

// Joker uses a setter directly
counterJoker.value = 1;

// Presenter uses trick
counterPresenter.trick(1);

// keepAlive option (for Presenter)
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

`Presenter` provides various methods for updating state:

```dart
// Auto notification (default)
counterPresenter.trick(42);                      // Direct assignment
counterPresenter.trickWith((state) => state + 1); // Function transform
await counterPresenter.trickAsync(fetchValue);    // Async update

// Manual notification
counterPresenter.whisper(42);                     // Change value silently
counterPresenter.whisperWith((s) => s + 1);       // Silent transform
counterPresenter.yell();                          // Notify when needed
```

### Batch Updates

Multiple state changes can be merged into a single notification:

```dart
// Assuming userJoker holds an object with copyWith, e.g., User class
// For Presenter, you would typically handle this within the Presenter's methods
// or use a similar batching mechanism if your state object supports it.
// Joker's batch update:
userJoker.batch()
  .apply((u) => u.copyWith(name: 'John Doe')) // Assuming User class has copyWith
  .apply((u) => u.copyWith(age: 30))
  .commit();  // Notifies listeners only once
```

## 🌉 Widget Ecosystem

### Joker.perform / Presenter.perform

Observe the entire state of `Joker` or `Presenter` to rebuild widgets:

```dart
// Using Joker extension
userJoker.perform(
  builder: (context, user) => Text('${user.name}: ${user.age}'),
);

// Using Presenter extension
myPresenter.perform(
   builder: (context, state) => Text('State: $state'),
);
```

### Joker.focusOn / Presenter.focusOn

Observe only part of the state to avoid unnecessary rebuilds:

```dart
// Using Joker extension
userJoker.focusOn<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);

// Using Presenter extension
userPresenter.focusOn<String>(
  selector: (userProfile) => userProfile.name, // Assuming userProfile has a name property
  builder: (context, name) => Text('Name: $name'),
);
```

### JokerTroupe / PresenterTroupe

Combine multiple `Joker`/`Presenter` states using Dart Records:

```dart
// Define combined state type
typedef UserProfile = (String name, int age, bool isActive);

// Using JokerTroupe for Jokers
JokerTroupe<UserProfile>(
  jokers: [nameJoker, ageJoker, activeJoker], // List of Jokers
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
);

// Using PresenterTroupe for Presenters
PresenterTroupe<UserProfile>(
  presenters: [namePresenter, agePresenter, activePresenter], // List of Presenters
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
);

// Using assemble extension for a list of Jokers
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
);

// Note: An assemble extension for Presenters might also exist or could be added.
// The example above is for Jokers based on the Chinese README.
```

## 🎭 Side Effects and Listeners

You can react to state changes to perform side effects without rebuilding the UI, typically using a `Presenter`:

```dart
// Listen to state changes to perform side effects with Presenter.effect
// (Assuming 'presenter' is an instance of a Presenter and 'log' is available)
presenter.effect(
  child: Container(), // Child widget, often not directly dependent on this effect
  effect: (stateSnapshot, context) { // stateSnapshot contains the current state
    log.add('effect:${stateSnapshot.value}');
    // Perform side effects here, e.g., show a snackbar, navigate, etc.
  },
  runOnInit: false, // Whether to run the effect when the widget is first built
  effectWhen: (previousStateSnapshot, currentStateSnapshot) {
    // Condition to run the effect
    // Example: run effect only if value divided by 5 changes category
    return (previousStateSnapshot.value ~/ 5) != (currentStateSnapshot.value ~/ 5);
  },
);