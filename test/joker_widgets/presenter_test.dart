// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:joker_state/joker_state.dart';
// import 'package:joker_state/src/state_management/presenter/presenter.dart';

// // --- Helper: Concrete Presenter Implementation ---

// class CounterPresenter extends Presenter<int> {
//   bool initCalled = false;
//   bool readyCalled = false;
//   bool doneCalled = false;

//   CounterPresenter(super.initial,
//       {super.autoNotify, super.keepAlive, super.tag});

//   @override
//   void onInit() {
//     super.onInit();
//     initCalled = true;
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     readyCalled = true;
//   }

//   @override
//   void onDone() {
//     super.onDone();
//     doneCalled = true;
//   }

//   void increment() => trickWith((s) => s + 1);
//   void decrement() => trickWith((s) => s - 1);
//   void reset(int value) => trick(value);
// }

// // Helper for complex state tests
// class UserProfile {
//   final String name;
//   final int age;
//   UserProfile(this.name, this.age);

//   UserProfile copyWith({String? name, int? age}) {
//     return UserProfile(name ?? this.name, age ?? this.age);
//   }

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is UserProfile &&
//           runtimeType == other.runtimeType &&
//           name == other.name &&
//           age == other.age;

//   @override
//   int get hashCode => name.hashCode ^ age.hashCode;
// }

// class UserPresenter extends Presenter<UserProfile> {
//   bool initCalled = false;
//   bool readyCalled = false;
//   bool doneCalled = false;

//   UserPresenter(super.initial, {super.keepAlive, super.tag});

//   @override
//   void onInit() {
//     super.onInit();
//     initCalled = true;
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     readyCalled = true;
//   }

//   @override
//   void onDone() {
//     super.onDone();
//     doneCalled = true;
//   }

//   void changeName(String newName) => trick(state.copyWith(name: newName));
//   void incrementAge() => trick(state.copyWith(age: state.age + 1));
// }

// // --- Test Suite ---

// void main() {
//   // Helper to pump widget within MaterialApp
//   Future<void> pumpWidgetWithMaterial(WidgetTester tester, Widget child) async {
//     await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
//     // Add pumpAndSettle to allow potential post-frame callbacks like onReady
//     await tester.pumpAndSettle();
//   }

//   // Clean CircusRing before each test if using DI tests
//   setUp(() async {
//     await Circus.fireAll();
//   });

//   group('Presenter Core & addListener', () {
//     testWidgets('initial state and lifecycle (onInit, onReady)',
//         (tester) async {
//       final presenter = CounterPresenter(10);

//       expect(presenter.state, 10);
//       expect(presenter.initCalled, isTrue); // onInit called in constructor
//       expect(presenter.readyCalled, isFalse); // onReady called after frame

//       // Simulate frame callback for onReady
//       await pumpWidgetWithMaterial(tester, Container()); // Need a frame

//       expect(presenter.readyCalled, isTrue);
//       presenter.dispose();
//     });

//     test('dispose calls onDone', () {
//       final presenter = CounterPresenter(10);
//       expect(presenter.doneCalled, isFalse);
//       presenter.dispose();
//       expect(presenter.doneCalled, isTrue);
//       expect(presenter.isDisposed, isTrue);
//     });

//     test('addListener is notified on state changes (trick, trickWith)', () {
//       final presenter = CounterPresenter(5);
//       int listenerCallCount = 0;
//       int? receivedState;

//       presenter.addListener(() {
//         listenerCallCount++;
//         receivedState = presenter.state;
//       });

//       // Test trick
//       presenter.reset(15);
//       expect(listenerCallCount, 1);
//       expect(receivedState, 15);

//       // Test trickWith
//       presenter.increment();
//       expect(listenerCallCount, 2);
//       expect(receivedState, 16);

//       presenter.dispose();
//     });

//     test('addListener is notified once on batch commit', () {
//       final presenter = CounterPresenter(100);
//       int listenerCallCount = 0;

//       presenter.addListener(() {
//         listenerCallCount++;
//       });

//       presenter.batch().apply((s) => s + 10).apply((s) => s - 5).commit();

//       expect(listenerCallCount, 1);
//       expect(presenter.state, 105);

//       presenter.dispose();
//     });

//     test('manual notification works correctly', () {
//       final manualPresenter =
//           CounterPresenter(0, autoNotify: false, tag: 'manual');
//       int notifications = 0;
//       manualPresenter.addListener(() => notifications++);

//       manualPresenter.whisper(10); // Silent update
//       expect(manualPresenter.state, 10);
//       expect(notifications, 0);

//       manualPresenter.yell(); // Manual notify
//       expect(notifications, 1);

//       manualPresenter.dispose();
//     });
//   });

//   group('Presenter with JokerStage (.perform)', () {
//     testWidgets('builds, updates, and calls lifecycle methods', (tester) async {
//       final presenter = CounterPresenter(0);

//       await pumpWidgetWithMaterial(
//         tester,
//         presenter.perform(
//           builder: (context, count) => Text('Count: $count'),
//         ),
//       );

//       // Check initial state and lifecycle
//       expect(find.text('Count: 0'), findsOneWidget);
//       expect(presenter.initCalled, isTrue);
//       expect(presenter.readyCalled,
//           isTrue); // Should be called after pumpAndSettle

//       // Trigger update
//       presenter.increment();
//       await tester.pump(); // Rebuild widget

//       // Check UI update
//       expect(find.text('Count: 1'), findsOneWidget);

//       // Remove widget
//       await tester.pumpWidget(Container());
//       await tester.pumpAndSettle(); // Allow microtasks/dispose logic

//       // Check cleanup (keepAlive = false by default)
//       expect(presenter.doneCalled, isTrue);
//       expect(presenter.isDisposed, isTrue);
//     });

//     testWidgets('keepAlive=true prevents disposal on widget removal',
//         (tester) async {
//       final presenter = CounterPresenter(5, keepAlive: true);

//       await pumpWidgetWithMaterial(
//         tester,
//         presenter.perform(
//           builder: (context, count) => Text('Count: $count'),
//         ),
//       );

//       expect(find.text('Count: 5'), findsOneWidget);
//       expect(presenter.readyCalled, isTrue);

//       // Remove widget
//       await tester.pumpWidget(Container());
//       await tester.pumpAndSettle();

//       // Check state (should NOT be disposed)
//       expect(presenter.doneCalled, isFalse);
//       expect(presenter.isDisposed, isFalse);

//       // Can still use it
//       presenter.increment();
//       expect(presenter.state, 6);

//       // Manual cleanup needed
//       presenter.dispose();
//       expect(presenter.doneCalled, isTrue);
//       expect(presenter.isDisposed, isTrue);
//     });
//   });

//   group('Presenter with JokerFrame (.focusOn)', () {
//     testWidgets('observes specific state part and rebuilds correctly',
//         (tester) async {
//       final presenter = UserPresenter(UserProfile("Alice", 30));
//       int buildCount = 0;

//       await pumpWidgetWithMaterial(
//         tester,
//         presenter.focusOn<String>(
//           selector: (profile) => profile.name,
//           builder: (context, name) {
//             buildCount++;
//             return Text('Name: $name');
//           },
//         ),
//       );

//       // Check initial state and build count
//       expect(find.text('Name: Alice'), findsOneWidget);
//       expect(buildCount, 1);
//       expect(presenter.readyCalled, isTrue);

//       // Change OBSERVED state (name)
//       presenter.changeName("Bob");
//       await tester.pump();
//       expect(find.text('Name: Bob'), findsOneWidget);
//       expect(buildCount, 2); // Rebuilt

//       // Change UNOBSERVED state (age)
//       presenter.incrementAge();
//       await tester.pump();
//       expect(find.text('Name: Bob'), findsOneWidget); // Still Bob
//       expect(buildCount, 2); // Should NOT rebuild

//       // Remove widget
//       await tester.pumpWidget(Container());
//       await tester.pumpAndSettle();

//       // Check cleanup (keepAlive = false)
//       expect(presenter.doneCalled, isTrue);
//       expect(presenter.isDisposed, isTrue);
//     });

//     testWidgets('keepAlive=true prevents disposal with focusOn',
//         (tester) async {
//       final presenter =
//           UserPresenter(UserProfile("Charlie", 25), keepAlive: true);

//       await pumpWidgetWithMaterial(
//         tester,
//         presenter.focusOn<int>(
//           selector: (profile) => profile.age,
//           builder: (context, age) => Text('Age: $age'),
//         ),
//       );

//       expect(find.text('Age: 25'), findsOneWidget);
//       expect(presenter.readyCalled, isTrue);

//       // Remove widget
//       await tester.pumpWidget(Container());
//       await tester.pumpAndSettle();

//       // Check state (should NOT be disposed)
//       expect(presenter.doneCalled, isFalse);
//       expect(presenter.isDisposed, isFalse);

//       // Manual cleanup
//       presenter.dispose();
//       expect(presenter.doneCalled, isTrue);
//       expect(presenter.isDisposed, isTrue);
//     });
//   });

//   group('Presenter with CircusRing', () {
//     testWidgets('register, spotlight, use with perform, and fire',
//         (tester) async {
//       // Arrange - Register presenter
//       final presenter = Circus.hire<CounterPresenter>(
//           CounterPresenter(100, tag: 'circus_counter', keepAlive: true),
//           tag: 'circus_counter');
//       expect(Circus.isHired<CounterPresenter>('circus_counter'), isTrue);
//       expect(presenter.initCalled, isTrue); // onInit during hire

//       // Act - Fire from CircusRing
//       final fired = Circus.fire<CounterPresenter>(tag: 'circus_counter');
//       expect(fired, isTrue);

//       // Assert disposal via fire
//       expect(Circus.isHired<CounterPresenter>('circus_counter'), isFalse);
//       expect(presenter.isDisposed, isFalse);
//       expect(presenter.doneCalled,
//           isFalse); // fire should NOT trigger dispose, because keepAlive=true
//     });
//   });
// }
