import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('Joker', () {
    group('Initialization & Basic Properties', () {
      test('Auto Joker should initialize with correct defaults', () {
        // Arrange
        final joker = Joker<int>(42, tag: 'test-tag');

        // Assert
        expect(joker.state, equals(42));
        expect(joker.previousState, equals(42));
        expect(joker.tag, equals('test-tag'));
        expect(joker.autoNotify, isTrue);
        expect(joker.keepAlive, isFalse); // Default keepAlive is false
        expect(joker.isDisposed, isFalse);
      });

      test('Manual Joker should initialize with correct settings', () {
        // Arrange
        final joker = Joker<int>(42, autoNotify: false, tag: 'manual');

        // Assert
        expect(joker.state, equals(42));
        expect(joker.previousState, equals(42));
        expect(joker.tag, equals('manual'));
        expect(joker.autoNotify, isFalse);
        expect(joker.keepAlive, isFalse);
        expect(joker.isDisposed, isFalse);
      });

      test('Joker with keepAlive should initialize correctly', () {
        // Arrange
        final joker = Joker<String>('persistent', keepAlive: true);

        // Assert
        expect(joker.keepAlive, isTrue);
        expect(joker.autoNotify, isTrue);
        expect(joker.isDisposed, isFalse);
      });
    });

    group('Auto Joker', () {
      test('should be initialized with correct values', () {
        // Arrange
        final joker = Joker<int>(42, tag: 'test-tag');

        // Assert
        expect(joker.state, equals(42));
        expect(joker.previousState, equals(42));
        expect(joker.tag, equals('test-tag'));
        expect(joker.autoNotify, isTrue);
      });

      test('should update value and notify listeners', () {
        // Arrange
        final joker = Joker<int>(0);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.trick(10);

        // Assert
        expect(joker.state, equals(10));
        expect(notificationCount, equals(1));
      });

      test('should update value with trick method', () {
        // Arrange
        final joker = Joker<int>(5);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.trick(15);

        // Assert
        expect(joker.state, equals(15));
        expect(joker.previousState, equals(5));
        expect(notificationCount, equals(1));
      });

      test('should update value with trickWith method', () {
        // Arrange
        final joker = Joker<int>(10);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.trickWith((val) => val * 2);

        // Assert
        expect(joker.state, equals(20));
        expect(joker.previousState, equals(10));
        expect(notificationCount, equals(1));
      });

      test('should update value asynchronously with trickAsync method',
          () async {
        // Arrange
        final joker = Joker<int>(5);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        await joker.trickAsync((val) async {
          await Future.delayed(Duration(milliseconds: 10));
          return val + 15;
        });

        // Assert
        expect(joker.state, equals(20));
        expect(joker.previousState, equals(5));
        expect(notificationCount, equals(1));
      });

      test('should throw exception when using manual methods on auto joker',
          () {
        // Arrange
        final joker = Joker<int>(42);

        // Assert
        expect(() => joker.whisper(10), throwsA(isA<JokerException>()));
        expect(() => joker.whisperWith((val) => val + 1),
            throwsA(isA<JokerException>()));
        expect(() => joker.yell(), returnsNormally);
      });

      test('should track previous value correctly', () {
        // Arrange
        final joker = Joker<int>(5);

        // Act
        joker.trick(10);

        // Assert
        expect(joker.previousState, equals(5));
        expect(joker.state, equals(10));

        // Act again
        joker.trick(15);

        // Assert
        expect(joker.previousState, equals(10));
        expect(joker.state, equals(15));
      });
    });

    group('Manual Joker', () {
      test('should be initialized with correct values', () {
        // Arrange
        final joker = Joker<int>(42, autoNotify: false, tag: 'manual');

        // Assert
        expect(joker.state, equals(42));
        expect(joker.previousState, equals(42));
        expect(joker.tag, equals('manual'));
        expect(joker.autoNotify, isFalse);
      });

      test('should update value without notification', () {
        // Arrange
        final joker = Joker<int>(0, autoNotify: false);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.whisper(10);

        // Assert
        expect(joker.state, equals(10));
        expect(notificationCount, equals(0));
      });

      test('should update value silently with whisper method', () {
        // Arrange
        final joker = Joker<int>(5, autoNotify: false);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.whisper(15);

        // Assert
        expect(joker.state, equals(15));
        expect(joker.previousState, equals(5));
        expect(notificationCount, equals(0));
      });

      test('should update value silently with whisperWith method', () {
        // Arrange
        final joker = Joker<int>(10, autoNotify: false);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act
        joker.whisperWith((val) => val * 2);

        // Assert
        expect(joker.state, equals(20));
        expect(joker.previousState, equals(10));
        expect(notificationCount, equals(0));
      });

      test('should notify listeners explicitly with yell method', () {
        // Arrange
        final joker = Joker<int>(5, autoNotify: false);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act - update without notification
        joker.whisper(15);
        expect(notificationCount, equals(0));

        // Act - notify explicitly
        joker.yell();

        // Assert
        expect(notificationCount, equals(1));
      });

      test('should throw exception when using auto methods on manual joker',
          () {
        // Arrange
        final joker = Joker<int>(42, autoNotify: false);

        // Assert
        expect(() => joker.trick(10), throwsA(isA<JokerException>()));
        expect(() => joker.trickWith((val) => val + 1),
            throwsA(isA<JokerException>()));
        expect(() => joker.trickAsync((val) async => val + 1),
            throwsA(isA<JokerException>()));
      });
    });

    group('Batch Operations', () {
      test('should batch update auto joker and notify only once', () {
        // Arrange
        final joker = Joker<int>(1);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act - perform multiple updates in batch
        joker
            .batch()
            .apply((val) => val + 5) // 1 -> 6
            .apply((val) => val * 2) // 6 -> 12
            .apply((val) => val - 2) // 12 -> 10
            .commit();

        // Assert
        expect(joker.state, equals(10));
        expect(notificationCount, equals(1)); // Only one notification
      });

      test('should batch update manual joker and notify only on commit', () {
        // Arrange
        final joker = Joker<int>(1, autoNotify: false);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act - perform multiple updates in batch
        joker
            .batch()
            .apply((val) => val + 5)
            .apply((val) => val * 2)
            .apply((val) => val - 2)
            .commit();

        // Assert
        expect(joker.state, equals(10));
        expect(notificationCount, equals(1)); // Notified on commit
      });

      test('should not notify if batch updates result in same value', () {
        // Arrange
        final joker = Joker<int>(10);
        int notificationCount = 0;
        joker.addListener(() => notificationCount++);

        // Act - perform operations that result in same value
        joker
            .batch()
            .apply((val) => val + 5) // 10 -> 15
            .apply((val) => val - 5) // 15 -> 10 (back to original)
            .commit();

        // Assert
        expect(joker.state, equals(10));
        expect(notificationCount, equals(0)); // No notification needed
      });

      test('should allow discarding batch changes', () {
        // Arrange
        final joker = Joker<int>(5);

        // Act - make changes but discard
        joker
            .batch()
            .apply((val) => val + 10)
            .apply((val) => val * 2)
            .discard();

        // Assert
        expect(joker.state, equals(5)); // Original value preserved
      });
    });

    group('Lifecycle Management (keepAlive & Auto-Dispose)', () {
      test(
          'Joker with keepAlive=false should dispose after listener removed (microtask)',
          () async {
        // Arrange
        final joker = Joker<int>(10, keepAlive: false);
        listener() {}
        joker.addListener(listener);
        expect(joker.isDisposed, isFalse);

        // Act - remove listener, schedules microtask
        joker.removeListener(listener);
        // Need just one event loop turn for microtask to run
        await Future.delayed(Duration.zero);

        // Assert
        expect(joker.isDisposed, isTrue);
      });

      test(
          'Joker with keepAlive=true should NOT dispose after listener removed (microtask)',
          () async {
        // Arrange
        final joker = Joker<int>(10, keepAlive: true);
        listener() {}
        joker.addListener(listener);
        expect(joker.isDisposed, isFalse);

        // Act - remove listener
        joker.removeListener(listener);
        await Future.delayed(Duration.zero); // Wait one event loop turn

        // Assert
        expect(joker.isDisposed, isFalse);
      });

      test('Adding listener should prevent microtask disposal', () async {
        // Arrange
        final joker = Joker<int>(10, keepAlive: false);
        listener1() {}
        listener2() {}
        joker.addListener(listener1);

        // Act - remove listener (schedules microtask), add listener back immediately
        joker.removeListener(listener1);
        joker.addListener(
            listener2); // This should set _isDisposalScheduled = false

        await Future.delayed(
            Duration.zero); // Wait for microtask queue to process

        // Assert - should not be disposed because flag was reset
        expect(joker.isDisposed, isFalse);
      });

      test('Explicit dispose() should dispose Joker regardless of keepAlive',
          () async {
        // Arrange
        final jokerKeepAlive = Joker<int>(10, keepAlive: true);
        final jokerNoKeepAlive = Joker<int>(20, keepAlive: false);
        listener() {}
        jokerKeepAlive.addListener(listener);
        jokerNoKeepAlive.addListener(listener);

        // Act
        jokerKeepAlive.dispose();
        jokerNoKeepAlive.dispose();
        // No need to wait for microtask here, explicit dispose is synchronous

        // Assert
        expect(jokerKeepAlive.isDisposed, isTrue);
        expect(jokerNoKeepAlive.isDisposed, isTrue);
      });

      test('Calling methods on disposed Joker should throw JokerException',
          () async {
        // Arrange
        final joker = Joker<int>(10);
        listener() {}
        joker.addListener(listener);
        joker.removeListener(listener);
        await Future.delayed(Duration.zero); // Wait for microtask disposal
        expect(joker.isDisposed, isTrue);

        // Assert
        expect(() => joker.trick(20), throwsA(isA<JokerException>()));
        expect(
            () => joker.trickWith((_) => 30), throwsA(isA<JokerException>()));
        expect(() => joker.trickAsync((_) async => 40),
            throwsA(isA<JokerException>()));
        expect(() => joker.whisper(50), throwsA(isA<JokerException>()));
        expect(
            () => joker.whisperWith((_) => 60), throwsA(isA<JokerException>()));
        expect(() => joker.batch(), throwsA(isA<JokerException>()));
        expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
        expect(() => joker.notifyListeners(), returnsNormally);
        expect(() => joker.yell(), returnsNormally);
        expect(() => joker.removeListener(() {}), returnsNormally);
      });

      test('Accessing state on disposed Joker should be allowed', () async {
        // Arrange
        final joker = Joker<int>(10);
        listener() {}
        joker.addListener(listener);
        joker.removeListener(listener);
        await Future.delayed(Duration.zero); // Wait for microtask disposal
        expect(joker.isDisposed, isTrue);

        // Assert
        expect(joker.state, equals(10)); // State is still accessible
        expect(joker.previousState, equals(10));
        expect(joker.tag, isNull);
        expect(joker.keepAlive, isFalse);
      });

      test('Batch operations should throw if Joker is disposed during apply',
          () async {
        // Arrange
        final joker = Joker<int>(10);
        final batch = joker.batch();

        // Dispose the joker after creating the batch but before applying
        joker.dispose();
        // No need to wait for microtask
        expect(joker.isDisposed, isTrue);

        // Assert
        expect(() => batch.apply((s) => s + 1), throwsA(isA<JokerException>()));
        expect(() => batch.commit(), returnsNormally);
        expect(() => batch.discard(), returnsNormally);
      });
    });
  });
}
