// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';
import 'package:joker_state/src/state_management/core/joker.dart';

void main() {
  group('Joker Core Functionality', () {
    test('Joker should initialize with correct state', () {
      final joker = Joker<int>(0);
      expect(joker.state, 0);
      expect(joker.value, 0);
      expect(joker.isDisposed, isFalse);
    });

    test('trick() should update state and notify listeners in autoNotify mode',
        () {
      final joker = Joker<int>(0);
      var listenerCalled = 0;
      joker.addListener(() => listenerCalled++);

      joker.trick(1);
      expect(joker.state, 1);
      expect(listenerCalled, 1);

      joker.trick(2);
      expect(joker.state, 2);
      expect(listenerCalled, 2);
    });

    test(
        'trickWith() should update state with function and notify listeners in autoNotify mode',
        () {
      final joker = Joker<int>(0);
      var listenerCalled = 0;
      joker.addListener(() => listenerCalled++);

      joker.trickWith((s) => s + 1);
      expect(joker.state, 1);
      expect(listenerCalled, 1);

      joker.trickWith((s) => s * 2);
      expect(joker.state, 2);
      expect(listenerCalled, 2);
    });

    test(
        'trickAsync() should update state asynchronously and notify listeners in autoNotify mode',
        () async {
      final joker = Joker<int>(0);
      var listenerCalled = 0;
      joker.addListener(() => listenerCalled++);

      await joker.trickAsync((s) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return s + 1;
      });
      expect(joker.state, 1);
      expect(listenerCalled, 1);

      await joker.trickAsync((s) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return s * 2;
      });
      expect(joker.state, 2);
      expect(listenerCalled, 2);
    });

    test('previousValue should be correct after state changes', () {
      final joker = Joker<int>(0);
      expect(joker.previousValue, null); // Initial previousValue is null

      joker.trick(1);
      expect(joker.previousValue, 0);
      expect(joker.state, 1);

      joker.trick(5);
      expect(joker.previousValue, 1);
      expect(joker.state, 5);

      joker.trickWith((s) => s + 1);
      expect(joker.previousValue, 5);
      expect(joker.state, 6);
    });

    group('Manual Notification Mode (autoNotify: false)', () {
      test('whisper() should update state without notifying', () {
        final joker = Joker<int>(0, autoNotify: false);
        var listenerCalled = 0;
        joker.addListener(() => listenerCalled++);

        joker.whisper(1);
        expect(joker.state, 1);
        expect(listenerCalled, 0);
      });

      test('whisperWith() should update state with function without notifying',
          () {
        final joker = Joker<int>(0, autoNotify: false);
        var listenerCalled = 0;
        joker.addListener(() => listenerCalled++);

        joker.whisperWith((s) => s + 1);
        expect(joker.state, 1);
        expect(listenerCalled, 0);
      });

      test('yell() should manually notify listeners', () {
        final joker = Joker<int>(0, autoNotify: false);
        var listenerCalled = 0;
        joker.addListener(() => listenerCalled++);

        joker.whisper(1);
        expect(listenerCalled, 0);

        joker.yell();
        expect(listenerCalled, 1);

        joker.yell(); // Calling yell again should notify again
        expect(listenerCalled, 2);
      });

      test('batch() should update state and notify once on commit', () {
        final joker = Joker<int>(0, autoNotify: false);
        var listenerCalled = 0;
        joker.addListener(() => listenerCalled++);

        var batch = joker.batch();

        batch
            .apply((s) => s + 1) // state becomes 1
            .apply((s) => s * 2); // state becomes 2

        expect(joker.state, 2);
        expect(listenerCalled, 0);

        joker.whisper(3);
        batch.commit(); // Change from 2 to 3, so notification
        expect(listenerCalled, 1);
      });

      test('batch().discard() should revert state', () {
        final joker = Joker<int>(0, autoNotify: false);
        var listenerCalled = 0;
        joker.addListener(() => listenerCalled++);

        final batch = joker.batch();
        batch.apply((s) => s + 10);
        expect(joker.state, 10);
        expect(listenerCalled, 0);

        batch.discard();
        expect(joker.state, 0);
        expect(listenerCalled, 0);
      });

      test('trick methods should throw JokerException in manual mode', () {
        final joker = Joker<int>(0, autoNotify: false);
        expect(() => joker.trick(1), throwsA(isA<JokerException>()));
        expect(() => joker.trickWith((s) => s + 1),
            throwsA(isA<JokerException>()));
        expect(() => joker.trickAsync((s) async => s + 1),
            throwsA(isA<JokerException>()));
      });

      test('whisper methods should throw JokerException in autoNotify mode',
          () {
        final joker = Joker<int>(0, autoNotify: true);
        expect(() => joker.whisper(1), throwsA(isA<JokerException>()));
        expect(() => joker.whisperWith((s) => s + 1),
            throwsA(isA<JokerException>()));
        expect(() => joker.batch(), throwsA(isA<JokerException>()));
      });
    });

    group('Joker Auto-Disposal', () {
      test('Joker should dispose itself when no listeners and not keepAlive',
          () async {
        final joker =
            Joker<int>(0, autoDisposeDelay: const Duration(milliseconds: 10));
        var listenerCalled = 0;
        listener() => listenerCalled++;

        joker.addListener(listener);
        expect(joker.hasListeners, isTrue);
        expect(joker.isDisposed, isFalse);

        joker.removeListener(listener);
        expect(joker.hasListeners, isFalse);

        await Future.delayed(
            const Duration(milliseconds: 50)); // Wait for dispose delay

        expect(joker.isDisposed, isTrue);
        expect(() => joker.state, throwsA(isA<JokerException>()));
        expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
      });

      test('Joker should not dispose if keepAlive is true', () async {
        final joker = Joker<int>(0,
            keepAlive: true,
            autoDisposeDelay: const Duration(milliseconds: 10));
        var listenerCalled = 0;
        listener() => listenerCalled++;

        joker.addListener(listener);
        joker.removeListener(listener);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(joker.isDisposed, isFalse);
        expect(joker.state, 0); // Should still be accessible
      });

      test('Joker should not dispose if listeners are re-added before delay',
          () async {
        final joker =
            Joker<int>(0, autoDisposeDelay: const Duration(milliseconds: 100));
        var listenerCalled = 0;
        listener() => listenerCalled++;

        joker.addListener(listener);
        joker.removeListener(listener);
        expect(joker.hasListeners, isFalse);

        await Future.delayed(
            const Duration(milliseconds: 50)); // Halfway through delay

        joker.addListener(listener); // Re-add listener
        expect(joker.hasListeners, isTrue);

        await Future.delayed(
            const Duration(milliseconds: 100)); // Wait past original delay

        expect(joker.isDisposed, isFalse);
        joker.removeListener(listener);
        await Future.delayed(
            const Duration(milliseconds: 150)); // Wait for new dispose cycle
        expect(joker.isDisposed, isTrue);
      });

      test('dispose() should make Joker unusable', () {
        final joker = Joker<int>(0);
        joker.dispose();

        expect(joker.isDisposed, isTrue);
        expect(() => joker.state, throwsA(isA<JokerException>()));
        expect(() => joker.value, throwsA(isA<JokerException>()));
        expect(() => joker.trick(1), throwsA(isA<JokerException>()));
        expect(() => joker.whisper(1), throwsA(isA<JokerException>()));
        expect(() => joker.yell(), throwsA(isA<JokerException>()));
        expect(() => joker.batch(), throwsA(isA<JokerException>()));
        expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
        expect(() => joker.removeListener(() {}),
            returnsNormally); // removeListener is safe on disposed
      });

      test('dispose() can be called multiple times safely', () {
        final joker = Joker<int>(0);
        joker.dispose();
        expect(() => joker.dispose(), returnsNormally);
        expect(joker.isDisposed, isTrue);
      });
    });
  });
}
