// import 'package:clean_architecture_example/domain/entity/counter.dart';
// // Import the necessary parts of the app
// import 'package:clean_architecture_example/main.dart'; // Need MyApp
// import 'package:clean_architecture_example/presentation/presenter/counter_presenter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:joker_state/joker_state.dart';

// // A fake presenter to control behavior during tests.
// class FakeCounterPresenter implements CounterPresenter {
//   final Joker<Counter> _counterState;
//   bool initialized = false;
//   int incrementCallCount = 0;

//   FakeCounterPresenter(this._counterState);

//   @override
//   Future<void> initialize() async {
//     initialized = true;
//     // Simulate initial state loading
//     await Future.delayed(const Duration(milliseconds: 10));
//     _counterState.trick(const Counter(value: 0));
//   }

//   @override
//   Future<void> increment() async {
//     incrementCallCount++;
//     // Simulate increment logic and state update
//     await Future.delayed(const Duration(milliseconds: 10));
//     final currentValue = _counterState.state.value;
//     _counterState.trick(Counter(value: currentValue + 1));
//     // Simulate sending cues (not verified in this test)
//     Circus.logger.info('Fake increment called, new value: ${currentValue + 1}');
//   }

//   @override
//   void dispose() {
//     // Fake dispose
//     Circus.logger.info('FakeCounterPresenter disposed.');
//   }
// }

// // A fake logger
// class FakeLogger implements Logger {
//   final List<String> logs = [];
//   @override
//   void severe(String message) => logs.add('[SEVERE] $message');
//   @override
//   void warning(String message) => logs.add('[WARNING] $message');
//   @override
//   void info(String message) => logs.add('[INFO] $message');
// }

// void main() {
//   // Test-specific Joker instance for state.
//   late Joker<Counter> testCounterState;
//   // Fake presenter instance.
//   late FakeCounterPresenter fakePresenter;
//   // Fake logger instance.
//   late FakeLogger fakeLogger;

//   setUp(() {
//     // Reset CircusRing before each test.
//     // Circus.fireAll(); // REMOVED: tearDown should handle cleanup.

//     // Create and register fakes/test doubles.
//     fakeLogger = FakeLogger();
//     Circus.hire<Logger>(fakeLogger);

//     // Create and register the *real* Joker for state.
//     testCounterState = Joker<Counter>(
//         const Counter(value: -99)); // Start with distinct initial
//     Circus.hire<Joker<Counter>>(testCounterState, tag: COUNTER_JOKER_TAG);

//     // Create and register the *fake* presenter.
//     fakePresenter = FakeCounterPresenter(testCounterState);
//     Circus.hire<CounterPresenter>(fakePresenter);

//     // Ensure RingCueMaster is ready (important if testing cues/listeners)
//     Circus.ringMaster();
//   });

//   tearDown(() async {
//     // Clean up CircusRing after each test.
//     await Circus.fireAll();
//   });

//   testWidgets('Counter starts at 0 after initialization',
//       (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());

//     // Allow time for the presenter's initialize() and state update.
//     await tester.pumpAndSettle();

//     // Verify that the presenter was initialized.
//     expect(fakePresenter.initialized, isTrue);

//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//     expect(find.text('Error loading counter!'), findsNothing);
//   });

//   testWidgets('Counter increments when FloatingActionButton is tapped',
//       (WidgetTester tester) async {
//     await tester.pumpWidget(const MyApp());
//     await tester.pumpAndSettle(); // Wait for initial state

//     // Verify initial state
//     expect(find.text('0'), findsOneWidget);
//     expect(fakePresenter.incrementCallCount, 0);

//     // Find the FAB.
//     final fab = find.byType(FloatingActionButton);
//     expect(fab, findsOneWidget);

//     // Tap the FAB.
//     await tester.tap(fab);
//     // Wait for debounce and async operations in presenter/joker.
//     await tester.pumpAndSettle(
//         const Duration(milliseconds: 350)); // Duration > debounce

//     // Verify the presenter's increment was called.
//     expect(fakePresenter.incrementCallCount, 1);

//     // Verify that the counter displays 1.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);

//     // Tap again.
//     await tester.tap(fab);
//     await tester.pumpAndSettle(const Duration(milliseconds: 350));

//     // Verify state and count.
//     expect(fakePresenter.incrementCallCount, 2);
//     expect(find.text('1'), findsNothing);
//     expect(find.text('2'), findsOneWidget);
//   });

//   testWidgets('Milestone message appears at count 10',
//       (WidgetTester tester) async {
//     // 1. Build the app and wait for presenter initialization to complete.
//     await tester.pumpWidget(const MyApp());
//     await tester.pumpAndSettle(); // State should now be 0

//     // Verify initial state after initialization is 0
//     expect(find.text('0'), findsOneWidget);
//     expect(testCounterState.state.value, 0);

//     // 2. Now, set the specific state needed for this test case.
//     testCounterState.trick(const Counter(value: 9));
//     // Pump a frame to reflect this change in the UI.
//     await tester.pump();

//     // 3. Verify UI is now showing 9 and no milestone message.
//     expect(find.text('9'), findsOneWidget);
//     expect(find.textContaining('Milestone'), findsNothing);

//     // 4. Tap the FAB.
//     await tester.tap(find.byType(FloatingActionButton));

//     // 5. Advance time and pump frames (presenter reads 9, tricks 10).
//     await tester.pump(const Duration(milliseconds: 320));
//     await tester.pump();

//     // 6. Verify state is 10 and UI shows 10 + milestone message.
//     expect(testCounterState.state.value, 10);
//     expect(find.text('10'), findsOneWidget);
//     expect(find.text('🎉 Milestone 10 reached! 🎉'), findsOneWidget);

//     // 7. Tap again.
//     await tester.tap(find.byType(FloatingActionButton));

//     // 8. Advance time and pump frames (presenter reads 10, tricks 11).
//     await tester.pump(const Duration(milliseconds: 320));
//     await tester.pump();

//     // 9. Verify state is 11 and UI shows 11, milestone message gone.
//     expect(testCounterState.state.value, 11);
//     expect(find.text('11'), findsOneWidget);
//     expect(find.textContaining('Milestone'), findsNothing);
//   });

//   // Note: Testing SnackBar appearances driven by JokerListener or RingCueMaster
//   // is more complex in widget tests. It often requires mocking ScaffoldMessenger
//   // or relying on integration tests for full verification.
//   // This example focuses on UI state verification based on Joker updates.
// }
