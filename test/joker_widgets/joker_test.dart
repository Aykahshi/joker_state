import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker_exception.dart';

void main() {
  group('Joker', () {
    group('Auto Joker', () {
      test('should be initialized with correct values', () {
        // Arrange
        final joker = Joker<int>(42, tag: 'test-tag');

        // Assert
        expect(joker.value, equals(42));
        expect(joker.previousValue, equals(42));
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
        expect(joker.value, equals(10));
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
        expect(joker.value, equals(15));
        expect(joker.previousValue, equals(5));
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
        expect(joker.value, equals(20));
        expect(joker.previousValue, equals(10));
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
        expect(joker.value, equals(20));
        expect(joker.previousValue, equals(5));
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
        expect(() => joker.yell(), throwsA(isA<JokerException>()));
      });

      test('should track previous value correctly', () {
        // Arrange
        final joker = Joker<int>(5);

        // Act
        joker.trick(10);

        // Assert
        expect(joker.previousValue, equals(5));
        expect(joker.value, equals(10));

        // Act again
        joker.trick(15);

        // Assert
        expect(joker.previousValue, equals(10));
        expect(joker.value, equals(15));
      });
    });

    group('Manual Joker', () {
      test('should be initialized with correct values', () {
        // Arrange
        final joker = Joker<int>(42, autoNotify: false, tag: 'manual');

        // Assert
        expect(joker.value, equals(42));
        expect(joker.previousValue, equals(42));
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
        expect(joker.value, equals(10));
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
        expect(joker.value, equals(15));
        expect(joker.previousValue, equals(5));
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
        expect(joker.value, equals(20));
        expect(joker.previousValue, equals(10));
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
        expect(joker.value, equals(10));
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
        expect(joker.value, equals(10));
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
        expect(joker.value, equals(10));
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
        expect(joker.value, equals(5)); // Original value preserved
      });
    });
  });
}
