## 🚀 Basic Usage

### Creating a Joker

```dart
// The simplest counter state
final counter = Joker<int>(0);

// Auto-notify is on by default
counter.trick(1);  // Updates to 1 and notifies listeners

// Manual mode
final manualCounter = Joker<int>(0, autoNotify: false);
manualCounter.whisper(42);  // Silent update
manualCounter.yell();       // Notify when you want

// Keep Joker alive even with no listeners
final persistentJoker = Joker<String>("data", keepAlive: true);
```

### Using Joker with Flutter

```dart
// The simplest counter widget
counter.perform(
  builder: (context, count) => Text('Count: $count'),
);

// Select just a part of the state
userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);
```

## 🎪 Core Concepts

### How to Update State

Joker gives you several ways to update state:

```dart
// Auto-notify (default)
counter.trick(42);                      // Direct value assignment
counter.trickWith((state) => state + 1); // Use a function to update
await counter.trickAsync(fetchValue);    // Async update

// Manual mode
counter.whisper(42);                     // Silent update
counter.whisperWith((s) => s + 1);       // Silent transform
counter.yell();                          // Notify when you want
```

### Batch Updates

Group multiple changes into a single notification:

```dart
user.batch()
  .apply((u) => u.copyWith(name: 'Bob'))
  .apply((u) => u.copyWith(age: 30))
  .commit();  // Notifies listeners once
```

## 🌉 Widget Ecosystem

### JokerStage

Watch the whole state of a Joker:

```dart
JokerStage<User>(
  joker: userJoker,
  builder: (context, user) => Text('${user.name}: ${user.age}'),
)
```

### JokerFrame

Watch just a part of the state to avoid unnecessary rebuilds:

```dart
JokerFrame<User, String>(
  joker: userJoker,
  selector: (user) => user.name,
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

Joker works seamlessly with CircusRing for global state management:

```dart
// Register a Joker
Circus.summon<int>(0, tag: 'counter');
Circus.recruit<User>(User(), tag: 'user'); // Manual mode

// Access anywhere
final counterJoker = Circus.spotlight<int>(tag: 'counter');

// Safe access
final userJoker = Circus.trySpotlight<User>(tag: 'user');

// Remove when done
Circus.vanish<int>(tag: 'counter');
```

## 📚 Extension Methods

These extensions make your code cleaner and easier to read:

```dart
// Create widgets directly from Joker instances
counterJoker.perform(
  builder: (context, count) => Text('Count: $count'),
);

userJoker.observe<String>(
  selector: (user) => user.name,
  builder: (context, name) => Text('Name: $name'),
);

// Combine multiple Jokers
[nameJoker, ageJoker, activeJoker].assemble<UserProfile>(
  converter: (values) => (
    values[0] as String,
    values[1] as int,
    values[2] as bool
  ),
  builder: (context, profile) => ProfileCard(profile),
);
```

## 🧹 Lifecycle Management

- **Listener-based disposal**: By default (`keepAlive: false`), a Joker schedules itself for disposal with a microtask when its last listener is removed.
- **Cancellation**: If you add a listener again before the microtask runs, disposal is canceled.
- **keepAlive**: Set `keepAlive: true` to keep the Joker alive until you dispose it manually or remove it via CircusRing (if registered).
- **Manual disposal**: You can always call `joker.dispose()` yourself.
- **Widget integration**: Widgets like `JokerStage`, `JokerFrame`, etc. manage listeners for you. When the widget is removed, its listener is removed too, which may trigger auto-disposal if `keepAlive` is false.

## 🧪 Best Practices

1. **Use selectors**: Only select the state you need to minimize rebuilds
2. **Batch updates**: Group related changes to avoid multiple rebuilds
3. **Tag your Jokers**: Always use tags with CircusRing
4. **`keepAlive`**: Use `keepAlive: true` for Jokers that need to stick around (like global app state)
5. **Explicit disposal**: Manually `dispose()` Jokers not managed by widgets or CircusRing, especially if `keepAlive` is true

## 🏆 Comparison with Other Solutions

| Feature | Joker | Provider | BLoC | GetX |
|---------|-------|----------|------|------|
| Learning Curve | Low | Medium | High | Low |
| Boilerplate | Minimal | Low | High | Low |
| Testability | High | High | High | Medium |
| Performance | Good | Good | Great | Good |
| Complexity | Simple | Medium | Complex | Simple |