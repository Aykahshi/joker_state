## 🚀 Basic Usage

### Creating a Joker

```dart
// Simple counter state
final counter = Joker<int>(0);

// Auto-notify is enabled by default
counter.trick(1);  // Updates to 1 and notifies listeners

// Manual mode
final manualCounter = Joker<int>(0, autoNotify: false);
manualCounter.whisper(42);  // Silent update
manualCounter.yell();       // Manual notification
```

### Using Joker with Flutter

```dart
// Simple counter widget
counter.perform(
  builder: (context, count) => Text('Count: $count'), 
);

// Select a specific slice of state
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

## 🎪 Core Concepts

### State Modification

Joker offers different methods for updating state:

```dart
// Auto-notify mode (default)
counter.trick(42);                      // Direct value assignment
counter.trickWith((state) => state + 1); // Transform with function
await counter.trickAsync(fetchValue);    // Asynchronous update

// Manual mode
counter.whisper(42);                     // Silent update
counter.whisperWith((s) => s + 1);       // Silent transform
counter.yell();                          // Manual notification
```

### Batch Updates

Group multiple updates into a single notification:

```dart
user.batch()
  .apply((u) => u.copyWith(name: 'Bob'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // Notifies listeners once
```

## 🌉 Widget Ecosystem

### JokerStage

Observe the entire state of a Joker:

```dart
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
```

### JokerFrame

Observe a specific slice of state to avoid unnecessary rebuilds:

```dart
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
)
```

### JokerTroupe

Combine multiple Jokers into a single widget using Dart Records:

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

Make Jokers accessible throughout the widget tree:

```dart
// At the top of your widget tree
JokerPortal<int>(
  tag: 'counter',
  joker: counterJoker,
  child: MaterialApp(...),
)

// Anywhere in the widget tree
JokerCast<int>(
  tag: 'counter',
  builder: (context, count) => Text('Count: $count'),
)

// Alternatively use the extension
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

// Later: stop listening
cancel();
```

## 🎪 Dependency Injection with CircusRing

Joker integrates with CircusRing for global state management:

```dart
// Register a Joker
Circus.summon<int>(0, tag: 'counter');
Circus.recruit<User>(User(), tag: 'user'); // Manual mode

// Retrieve anywhere
final counterJoker = Circus.spotlight<int>(tag: 'counter');

// Safe retrieval
final userJoker = Circus.trySpotlight<User>(tag: 'user');

// Remove when done
Circus.vanish<int>(tag: 'counter');
```

## 📚 Extension Methods

Fluent extensions for more readable code:

```dart
// Create widgets directly from Joker instances
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);

userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);

// Create a JokerTroupe
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
  converter: (values) => (
    values[0] as String, 
    values[1] as int, 
    values[2] as bool,
  ),
  builder: (context, profile) => ProfileCard(profile),
);
```

## 🧪 Best Practices

1. **Use Selectors**: Minimize rebuilds by selecting only needed state slices
2. **Batch Updates**: Group related changes to avoid multiple rebuilds
3. **Tagged Jokers**: Always use tags when working with CircusRing
4. **Auto-Dispose**: Enable autoDispose (default) for automatic cleanup

## 🏆 Comparison with Other Solutions

| Feature | Joker | Provider | BLoC | GetX |
|---------|-------|----------|------|------|
| Learning Curve | Low | Medium | High | Low |
| Boilerplate | Minimal | Low | High | Low |
| Testability | High | High | High | Medium |
| Performance | Good | Good | Great | Good |
| Complexity | Simple | Medium | Complex | Simple |