// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:joker_state/src/special_widgets/joker_trap/joker_trap.dart';

// import '../../packages/circus_ring/src/disposable.dart';

// /// Mock implementation of a custom Disposable interface.
// class MockDisposable implements Disposable {
//   bool disposed = false;

//   @override
//   void dispose() => disposed = true;
// }

// /// Mock implementation of a custom AsyncDisposable interface.
// class MockAsyncDisposable implements AsyncDisposable {
//   bool disposed = false;

//   @override
//   Future<void> dispose() async => disposed = true;
// }

// void main() {
//   testWidgets('JokerTrap disposes TextEditingController', (tester) async {
//     final controller = TextEditingController();

//     await tester.pumpWidget(
//       MaterialApp(home: controller.trapeze(const SizedBox())),
//     );

//     // Verify controller is enabled before disposal
//     expect(controller.text, '');

//     // Remove the widget to dispose controller
//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     // use addListener which throws FlutterError if disposed
//     expect(() => controller.addListener(() {}), throwsFlutterError);
//   });

//   testWidgets('JokerTrap disposes ScrollController', (tester) async {
//     final scrollCtrl = ScrollController();

//     await tester.pumpWidget(
//       MaterialApp(home: scrollCtrl.trapeze(const SizedBox())),
//     );

//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     expect(() => scrollCtrl.position, throwsAssertionError);
//   });

//   testWidgets('JokerTrap disposes ChangeNotifier (ValueNotifier)',
//       (tester) async {
//     final notifier = ValueNotifier<int>(42);

//     await tester.pumpWidget(
//       MaterialApp(home: notifier.trapeze(const SizedBox())),
//     );

//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     // In general, using notifier after dispose should throw when addListener is called
//     expect(() => notifier.addListener(() {}), throwsA(isA<FlutterError>()));
//   });

//   testWidgets('JokerTrap disposes StreamSubscription', (tester) async {
//     final stream = Stream<int>.value(123);
//     bool cancelled = false;
//     final innerSubscription = stream.listen((event) {});
//     final tracked = _WrappedStreamSubscription(innerSubscription, onCancel: () {
//       cancelled = true;
//     });

//     await tester.pumpWidget(
//       MaterialApp(home: tracked.trapeze(const Text('stream'))),
//     );

//     // Remove the widget to trigger dispose
//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     // StreamSubscription.cancel() should have been called
//     expect(cancelled, isTrue);
//   });

//   testWidgets('JokerTrap disposes custom Disposable', (tester) async {
//     final disposable = MockDisposable();

//     await tester.pumpWidget(
//       MaterialApp(home: disposable.trapeze(const SizedBox())),
//     );

//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     expect(disposable.disposed, isTrue); // since we control class
//   });

//   testWidgets('JokerTrap disposes AsyncDisposable', (tester) async {
//     final asyncDisposable = MockAsyncDisposable();

//     await tester.pumpWidget(
//       MaterialApp(home: asyncDisposable.trapeze(const Text('Async'))),
//     );

//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     expect(asyncDisposable.disposed, isTrue);
//   });

//   testWidgets('JokerTrap properly disposes a list of mixed controllers',
//       (tester) async {
//     bool cancelled = false;

//     final textCtrl = TextEditingController();
//     final scrollCtrl = ScrollController();
//     final notifier = ValueNotifier<int>(0);
//     final mock = MockDisposable();

//     final subscription = _WrappedStreamSubscription(
//       Stream<int>.value(1).listen((_) {}),
//       onCancel: () => cancelled = true,
//     );

//     final asyncDisposable = MockAsyncDisposable();

//     final list = [
//       textCtrl,
//       scrollCtrl,
//       notifier,
//       mock,
//       subscription,
//       asyncDisposable
//     ];

//     await tester.pumpWidget(
//       MaterialApp(home: list.trapeze(const Text('Multi'))),
//     );

//     await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

//     // ✅ Use addListener to verify disposal instead of .text
//     expect(() => textCtrl.addListener(() {}), throwsFlutterError);
//     expect(() => notifier.addListener(() {}), throwsFlutterError);
//     expect(() => scrollCtrl.position, throwsAssertionError);

//     expect(mock.disposed, isTrue);
//     expect(cancelled, isTrue);
//     expect(asyncDisposable.disposed, isTrue);
//   });
// }

// /// Helper to simulate a stream subscription with side-effect on cancel.
// class _WrappedStreamSubscription implements StreamSubscription {
//   final StreamSubscription _inner;
//   final VoidCallback onCancel;

//   _WrappedStreamSubscription(this._inner, {required this.onCancel});

//   @override
//   Future<void> cancel() async {
//     onCancel();
//     return _inner.cancel();
//   }

//   @override
//   void onData(void Function(dynamic)? handleData) => _inner.onData(handleData);

//   @override
//   void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

//   @override
//   void onError(Function? handleError) => _inner.onError(handleError);

//   @override
//   void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

//   @override
//   void resume() => _inner.resume();

//   @override
//   bool get isPaused => _inner.isPaused;

//   @override
//   Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
// }
