# 🎪 Ring Cue Master - Circus Event Bus

## 📚 Overview

Ring Cue Master is a lightweight, type-safe event bus system for Flutter that works hand-in-hand with the CircusRing dependency injection container. It lets different parts of your app talk to each other without direct dependencies, using a simple publish-subscribe pattern.

## ✨ Features

- 🔍 **Type-safe events**: Events are fully typed, so you get compile-time safety
- 🚀 **Easy integration**: Works directly with CircusRing dependency injection
- 🧩 **Decoupled architecture**: Components can communicate without direct references
- 🔄 **Multiple bus support**: Create separate event buses for different domains

## 🏁 Getting Started

### Basic Usage

```dart
import 'package:circus_framework/circus_framework.dart';

// Define an event (just a class)
class UserLoggedInEvent {
  final String userId;
  final String username;
  UserLoggedInEvent(this.userId, this.username);
}

// Use the default event bus via CircusRing
void main() {
  // Listen for events
  Circus.onCue<UserLoggedInEvent>((event) {
    print('User logged in: ${event.username}');
  });
  // Send an event
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### Optional: Extend the Cue Class

If you want better tracking or tooling, you can extend the `Cue` class:

```dart
import 'package:circus_framework/circus_framework.dart';

class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  UserLoggedInCue(this.userId, this.username);
}

// Now you get automatic timestamp tracking
void sendLoginEvent() {
  Circus.cue(UserLoggedInCue('123', 'john_doe'));
}
```

## 🎭 Advanced Usage

### Multiple Event Buses

You can create as many event buses as you want for different parts of your app:

```dart
// Create a dedicated event bus for authentication
final authBus = Circus.ringMaster(tag: 'auth');
// Create a dedicated event bus for payments
final paymentBus = Circus.ringMaster(tag: 'payment');

// Listen on a specific bus
authBus.listen<UserLoggedInCue>((event) {
  print('Auth event: User logged in at ${event.timestamp}');
});
// Send an event on a specific bus
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// Or use the CircusRing extension syntax
Circus.onCue<UserLoggedInCue>((event) {
  // Handle event
}, 'auth');
Circus.cue(UserLoggedInCue('123', 'john_doe'), 'auth');
```

### Manual Bus Management

You can also manage the event bus directly:

```dart
// Get the default bus
final cueMaster = Circus.ringMaster();

// Subscribe to events
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  updateNetworkStatus(event.isConnected);
});

// Check if there are listeners
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  cueMaster.sendCue(AppLifecycleCue.resumed);
}

// Don't forget to cancel subscriptions when done
subscription.cancel();

// Reset a specific event type (closes stream and removes listeners)
cueMaster.reset<NetworkStatusChangeCue>();

// Dispose the entire bus when you no longer need it
cueMaster.dispose();
```

## 🔧 Integration with CircusRing

RingCueMaster is built to work seamlessly with CircusRing:

```dart
// Register a custom event bus
class MyCustomCueMaster implements CueMaster {
  // ...your custom logic...
}
Circus.hire(MyCustomCueMaster(), tag: 'custom');
// Access it the same way
final customBus = Circus.ringMaster('custom');
```

## 📝 Best Practices

1. **Define clear event types**: Keep event classes focused on a single domain
2. **Cancel subscriptions**: Always cancel when widgets are disposed
3. **Use namespaced buses**: Separate buses for different domains
4. **Avoid circular dependencies**: Don't let events trigger each other in a loop
5. **Keep events lightweight**: Don't pass large objects through events