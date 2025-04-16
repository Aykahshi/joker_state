# 🎪 Ring Cue Master - Circus Event Bus

## 📚 Overview

Ring Cue Master is a lightweight, type-safe event bus system for Flutter applications that works seamlessly with the CircusRing dependency injection container. It allows different parts of your application to communicate without direct dependencies, using a publish-subscribe pattern.

## ✨ Features

- 🔍 **Type-safe events**: Events are fully typed for compile-time safety
- 🚀 **Easy integration**: Works directly with CircusRing dependency injection
- 🧩 **Decoupled architecture**: Communicate between components without direct references
- 🔄 **Multiple bus support**: Create separate event buses for different domains

## 🏁 Getting Started

### Basic Usage

```dart
import 'package:circus_framework/circus_framework.dart';

// Define an event - can be any class
class UserLoggedInEvent {
  final String userId;
  final String username;
  
  UserLoggedInEvent(this.userId, this.username);
}

// Using the default event bus through CircusRing extension
void main() {
  // Listen for events
  Circus.onCue<UserLoggedInEvent>((event) {
    print('User logged in: ${event.username}');
  });
  
  // Send an event
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### Optional: Extend Base Cue Class

For better tracking and tooling support, you can extend the base `Cue` class:

```dart
import 'package:circus_framework/circus_framework.dart';

class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  
  UserLoggedInCue(this.userId, this.username);
}

// Now you can use it with automatic timestamp tracking
void sendLoginEvent() {
  Circus.cue(UserLoggedInCue('123', 'john_doe'));
}
```

## 🎭 Advanced Usage

### Creating Multiple Event Buses

You can create multiple event buses for different parts of your application:

```dart
// Create a dedicated event bus for authentication events
final authBus = Circus.ringMaster(tag: 'auth');

// Create a dedicated event bus for payment events
final paymentBus = Circus.ringMaster(tag: 'payment');

// Listen on specific bus
authBus.listen<UserLoggedInCue>((event) {
  print('Auth event: User logged in at ${event.timestamp}');
});

// Send event on specific bus
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// Alternative syntax with CircusRing extension
Circus.onCue<UserLoggedInCue>((event) {
  // Process event
}, 'auth');

Circus.cue(UserLoggedInCue('123', 'john_doe'), 'auth');
```

### Manual Bus Management

You can directly access and manage the event bus:

```dart
// Get reference to the default bus
final cueMaster = Circus.ringMaster();

// Subscribe to events
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  updateNetworkStatus(event.isConnected);
});

// Check if there are listeners
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  cueMaster.sendCue(AppLifecycleCue.resumed);
}

// Remember to cancel subscriptions when done
subscription.cancel();

// Reset a specific event type (closes stream and removes all listeners)
cueMaster.reset<NetworkStatusChangeCue>();

// Dispose the entire bus when no longer needed
cueMaster.dispose();
```

## 🔧 Integration with CircusRing

RingCueMaster is designed to work seamlessly with CircusRing dependency injection:

```dart
// Register a custom implementation
class MyCustomCueMaster implements CueMaster {
  // Custom implementation
}

// Register your custom implementation
Circus.hire(MyCustomCueMaster(), tag: 'custom');

// Access it using the same extension
final customBus = Circus.ringMaster('custom');
```

## 📝 Best Practices

1. **Define clear event types**: Keep event classes focused on specific domains
2. **Cancel subscriptions**: Always cancel subscriptions when widgets are disposed
3. **Use namespaced buses**: Create separate buses for different domains
4. **Avoid circular dependencies**: Don't create cyclic event chains
5. **Keep events lightweight**: Avoid passing large objects through events