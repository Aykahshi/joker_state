# 🎪 Ring Cue Master - Circus Event Bus

## 📚 Overview

Ring Cue Master is a lightweight, type-safe event bus system designed for Flutter applications, seamlessly integrating with CircusRing dependency injection. It enables different parts of an application to communicate without direct dependencies, following the publish-subscribe pattern.

It provides a default implementation `RingCueMaster` based on RxDart's `PublishSubject`, ensuring efficient and responsive event handling.

## ✨ Features

- 🔍 **Type-Safe Events**: Events are type-checked at compile-time.
- 🚀 **Easy Integration**: Works out of the box with CircusRing dependency injection, with `RingCueMaster` as the default event bus implementation.
- 🧩 **Decoupled Architecture**: Components can communicate without direct references to each other.
- 🔄 **Multiple Event Buses**: Create isolated `RingCueMaster` instances for different domains.
- 🎯 **RxDart-Powered**: Built on `PublishSubject` for powerful event stream handling.

## 🏁 Getting Started

### Basic Usage

```dart
import 'package:joker_state/cue_master.dart';

// 1. Define an event (can be a simple class)
class UserLoggedInEvent {
  final String userId;
  final String username;
  UserLoggedInEvent(this.userId, this.username);
}

// 2. Use the default event bus with CircusRing extensions
void main() {
  // Listen to an event
  // Circus.onCue uses the default RingCueMaster instance
  Circus.onCue<UserLoggedInEvent>((event) {
    print('User logged in: ${event.username} (ID: ${event.userId})');
  });

  // Send an event
  // Circus.cue also uses the default RingCueMaster instance
  Circus.cue(UserLoggedInEvent('123', 'john_doe'));
}
```

### Advanced: Extending the Cue Class

If you want events to automatically include timestamps or need additional common event metadata in the future, you can extend the base `Cue` class:

```dart
import 'package:joker_state/cue_master.dart';

// Events extending Cue automatically get a timestamp property
class UserLoggedInCue extends Cue {
  final String userId;
  final String username;
  UserLoggedInCue(this.userId, this.username);

  @override
  String toString() { // Recommended to override for debugging
    return 'UserLoggedInCue(userId: $userId, username: $username, timestamp: $timestamp)';
  }
}

void sendLoginEvent() {
  final event = UserLoggedInCue('456', 'jane_doe');
  print('Sending event: $event');
  Circus.cue(event); // Send event with timestamp
}

void setupListener() {
  Circus.onCue<UserLoggedInCue>((cue) {
    print('Login notification: ${cue.username} logged in at ${cue.timestamp}.');
  });
}
```

### Advanced: Multiple Event Buses
You can create multiple isolated event bus instances for different domains or modules in your application. Each instance is a `RingCueMaster`.

```dart
// Get or create tagged RingCueMaster instances with Circus.ringMaster
final authBus = Circus.ringMaster(tag: 'auth'); // Dedicated auth event bus
final paymentBus = Circus.ringMaster(tag: 'payment'); // Dedicated payment event bus

// Define domain-specific Cue
class PaymentCompletedCue extends Cue {
  final double amount;
  PaymentCompletedCue({required this.amount});
}

// Listen on specific bus
authBus.listen<UserLoggedInCue>((event) {
  print('[AuthBus] Auth event: User ${event.username} logged in at ${event.timestamp}');
});

// Send event on specific bus
paymentBus.sendCue(PaymentCompletedCue(amount: 99.99));

// Or use CircusRing's convenient syntax with tag
Circus.onCue<UserLoggedInCue>((event) {
  print('[CircusFacade-Auth] User ${event.username} logged in');
}, tag: 'auth'); // Listen on 'auth' bus

Circus.cue(UserLoggedInCue('789', 'another_user'), tag: 'auth'); // Send on 'auth' bus
```

### Manual Event Bus Management

```dart
// Get the default RingCueMaster instance
final cueMaster = Circus.ringMaster();

// Define some events
class NetworkStatusChangeCue extends Cue {
  final bool isConnected;
  NetworkStatusChangeCue(this.isConnected);
}

class AppLifecycleCue extends Cue {
  final String state; // e.g., "resumed", "paused"
  AppLifecycleCue(this.state);
}

// Subscribe to events
final subscription = cueMaster.listen<NetworkStatusChangeCue>((event) {
  // updateNetworkStatus(event.isConnected);
  print('Network status changed: ${event.isConnected ? "Connected" : "Disconnected"}');
});

// Send events
cueMaster.sendCue(NetworkStatusChangeCue(true));

// Check for listeners
if (cueMaster.hasListeners<AppLifecycleCue>()) {
  print('AppLifecycleCue has listeners.');
  cueMaster.sendCue(AppLifecycleCue("resumed"));
} else {
  print('AppLifecycleCue currently has no listeners.');
}

// Remember to cancel subscriptions when done to avoid memory leaks
subscription.cancel();
print('NetworkStatusChangeCue subscription cancelled.');

// Reset stream for a specific event type (closes the stream and removes all listeners)
cueMaster.reset<NetworkStatusChangeCue>();
print('NetworkStatusChangeCue stream reset.');

// When the event bus is no longer needed (e.g., in a Widget's dispose method, or when the app closes),
// dispose the entire bus to close all streams and clean up resources.
cueMaster.dispose();
print('Default RingCueMaster disposed.');
```

## 🔧 Integration with CircusRing (English Version)
RingCueMaster is designed to integrate seamlessly with the CircusRing dependency injection system. Because RingCueMaster implements the Disposable interface, CircusRing can automatically manage the creation and destruction of RingCueMaster instances within its lifecycle management.
You interact with the event bus primarily through extension methods on your CircusRing instance (typically accessed via the global Circus or Ring getter):

```dart
import 'package:circus_ring/circus_ring.dart'; // Assuming this is your CircusRing package
import 'package:your_project/ring_cue_master.dart'; // Your RingCueMaster and CueMaster
import 'package:your_project/circus_ring_cue_master_extension.dart'; // Your extension

// ... (Event definitions like NotificationReceivedCue) ...

void main() async {
  final circus = CircusRing.instance; // Or use Circus / Ring alias

  // 1. Get/create the default event bus (RingCueMaster instance)
  //    getCueMaster creates and registers it with CircusRing.hire<CueMaster> on first call.
  final CueMaster defaultBus = circus.getCueMaster();
  defaultBus.listen<NotificationReceivedCue>((cue) {
    print("Default Bus: ${cue.message}");
  });
  circus.sendCue(NotificationReceivedCue("Message from default bus!"));

  // 2. Get/create a tagged RingCueMaster instance
  final CueMaster notificationBus = circus.getCueMaster(tag: 'notifications');
  notificationBus.sendCue(NotificationReceivedCue("You have a new message from 'notifications' bus!"));

  // 3. Register and use a fully custom CueMaster implementation
  //    Ensure your custom implementation also implements Disposable if you want
  //    CircusRing to auto-dispose it.
  class MySpecializedCueMaster implements CueMaster, Disposable {
    final String id;
    MySpecializedCueMaster(this.id);
    // ... custom event handling logic ...
    @override
    Stream<T> on<T>() { print('$id: on<$T>()'); return Stream.empty(); }
    @override
    bool sendCue<T>(T cue) { print('$id: sendCue($cue)'); return true; }
    @override
    StreamSubscription<T> listen<T>(void Function(T cue) fn) { print('$id: listen<$T>()'); return Stream.empty().listen(fn); }
    @override
    bool hasListeners<T>() { print('$id: hasListeners<$T>()'); return false; }
    @override
    bool reset<T>() { print('$id: reset<$T>()'); return false; }
    @override
    void dispose() { print('$id: MySpecializedCueMaster disposing...'); }
  }

  final mySpecialBusInstance = MySpecializedCueMaster('special_bus_id');
  // Register the custom instance directly using CircusRing.hire
  circus.hire<CueMaster>(mySpecialBusInstance, tag: 'special_bus', alias: CueMaster);

  final CueMaster retrievedSpecialBus = circus.find<CueMaster>('special_bus'); // Or getCueMaster
  retrievedSpecialBus.sendCue(NotificationReceivedCue("Message from special bus!"));

  // Lifecycle Management:
  // When you call circus.fire<CueMaster>(tag: 'notifications') or circus.disposeCueMaster(tag: 'notifications'),
  // the dispose() method of the RingCueMaster instance for the 'notifications' bus will be called automatically.
  circus.disposeCueMaster(tag: 'notifications');
  print("'notifications' bus disposed: ${!circus.isHired<CueMaster>('notifications')}");

  // circus.fireAll() will dispose all registered Disposable instances, including all CueMasters.
  await circus.fireAll();
  print("All buses disposed after fireAll.");
}
```