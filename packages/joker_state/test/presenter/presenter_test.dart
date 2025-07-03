// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

class TestPresenter extends Presenter<int> {
  TestPresenter(
    super.initialState, {
    super.autoNotify,
    super.keepAlive,
    super.autoDisposeDelay,
    super.enableDebugLog,
  });

  int onInitCallCount = 0;
  int onReadyCallCount = 0;
  int onDoneCallCount = 0;

  @override
  void onInit() {
    super.onInit();
    onInitCallCount++;
  }

  @override
  void onReady() {
    super.onReady();
    onReadyCallCount++;
  }

  @override
  void onDone() {
    super.onDone();
    onDoneCallCount++;
  }
}

void main() {
  group('Presenter Core Functionality', () {
    test('Presenter should initialize with correct state and call onInit', () {
      final presenter = TestPresenter(10);
      expect(presenter.state, 10);
      expect(presenter.value, 10);
      expect(presenter.onInitCallCount, 1);
      expect(presenter.isDisposed, isFalse);
    });

    testWidgets('onReady should be called after the first frame',
        (WidgetTester tester) async {
      late TestPresenter presenter;

      // Create a simple widget that initializes the presenter
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              presenter = TestPresenter(10);
              return Container();
            },
          ),
        ),
      );

      expect(presenter.onInitCallCount, 1);
      expect(presenter.onReadyCallCount, 1);
    });

    test('onDone should be called on dispose', () {
      final presenter = TestPresenter(0);
      expect(presenter.onDoneCallCount, 0);

      presenter.dispose();
      expect(presenter.onDoneCallCount, 1);
      expect(presenter.isDisposed, isTrue);
    });

    test('trick() should update state and notify listeners in autoNotify mode',
        () {
      final presenter = TestPresenter(0);
      var listenerCalled = 0;
      presenter.addListener(() => listenerCalled++);

      presenter.trick(1);
      expect(presenter.state, 1);
      expect(listenerCalled, 1);
    });

    test('previousValue should be correct after state changes', () {
      final presenter = TestPresenter(0);
      expect(presenter.previousValue, null); // Initial previousValue is null

      presenter.trick(1);
      expect(presenter.previousValue, 0);
      expect(presenter.state, 1);

      presenter.trick(5);
      expect(presenter.previousValue, 1);
      expect(presenter.state, 5);
    });

    group('Presenter Auto-Disposal', () {
      test(
          'Presenter should dispose itself when no listeners and not keepAlive',
          () async {
        final presenter = TestPresenter(0,
            autoDisposeDelay: const Duration(milliseconds: 10));
        var listenerCalled = 0;
        listener() => listenerCalled++;

        presenter.addListener(listener);
        expect(presenter.hasListeners, isTrue);
        expect(presenter.isDisposed, isFalse);

        presenter.removeListener(listener);
        expect(presenter.hasListeners, isFalse);

        await Future.delayed(
            const Duration(milliseconds: 50)); // Wait for dispose delay

        expect(presenter.isDisposed, isTrue);
        expect(presenter.onDoneCallCount, 1);
        expect(() => presenter.state, throwsA(isA<JokerException>()));
      });

      test('Presenter should not dispose if keepAlive is true', () async {
        final presenter = TestPresenter(0,
            keepAlive: true,
            autoDisposeDelay: const Duration(milliseconds: 10));
        var listenerCalled = 0;
        listener() => listenerCalled++;

        presenter.addListener(listener);
        presenter.removeListener(listener);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(presenter.isDisposed, isFalse);
        expect(presenter.state, 0); // Should still be accessible
      });
    });

    group('Manual Notification Mode (autoNotify: false)', () {
      test('whisper() should update state without notifying', () {
        final presenter = TestPresenter(0, autoNotify: false);
        var listenerCalled = 0;
        presenter.addListener(() => listenerCalled++);

        presenter.whisper(1);
        expect(presenter.state, 1);
        expect(listenerCalled, 0);
      });

      test('yell() should manually notify listeners', () {
        final presenter = TestPresenter(0, autoNotify: false);
        var listenerCalled = 0;
        presenter.addListener(() => listenerCalled++);

        presenter.whisper(1);
        expect(listenerCalled, 0);

        presenter.yell();
        expect(listenerCalled, 1);
      });

      test('batch() should update state and notify once on commit', () {
        final presenter = TestPresenter(0, autoNotify: false);
        var listenerCalled = 0;
        presenter.addListener(() => listenerCalled++);

        var batch = presenter.batch();

        batch.apply((s) => s + 1).apply((s) => s * 2);

        expect(presenter.state, 2);
        expect(listenerCalled, 0);

        presenter.whisper(3);
        batch.commit(); // Change from 2 to 3, so notification
        expect(listenerCalled, 1);
      });

      test('trick methods should throw JokerException in manual mode', () {
        final presenter = TestPresenter(0, autoNotify: false);
        expect(() => presenter.trick(1), throwsA(isA<JokerException>()));
      });
    });
  });
}
