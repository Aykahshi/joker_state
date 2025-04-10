import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';

void main() {
  group('Joker', () {
    test('should initialize with the given value', () {
      // Arrange & Act
      final joker = Joker<int>(42);

      // Assert
      expect(joker.value, equals(42));
    });

    test('should update value and notify listeners', () {
      // Arrange
      final joker = Joker<int>(10);
      bool listenerCalled = false;

      joker.addListener(() {
        listenerCalled = true;
      });

      // Act
      joker.value = 20;

      // Assert
      expect(joker.value, equals(20));
      expect(listenerCalled, isTrue);
    });

    test('should track previous value when updated', () {
      // Arrange
      final joker = Joker<int>(10);

      // Act
      joker.value = 20;

      // Assert
      expect(joker.value, equals(20));
    });

    test('trick() method should change value and notify listeners', () {
      // Arrange
      final joker = Joker<String>('hello');
      bool listenerCalled = false;

      joker.addListener(() {
        listenerCalled = true;
      });

      // Act
      joker.trick('world');

      // Assert
      expect(joker.value, equals('world'));
      expect(listenerCalled, isTrue);
    });

    test('trickWith() should apply function and notify listeners', () {
      // Arrange
      final joker = Joker<int>(5);
      bool listenerCalled = false;

      joker.addListener(() {
        listenerCalled = true;
      });

      // Act
      joker.trickWith((value) => value * 2);

      // Assert
      expect(joker.value, equals(10));
      expect(listenerCalled, isTrue);
    });

    test('trickAsync() should apply async function and notify listeners',
        () async {
      // Arrange
      final joker = Joker<int>(5);
      bool listenerCalled = false;

      joker.addListener(() {
        listenerCalled = true;
      });

      // Act
      await joker.trickAsync((value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value * 3;
      });

      // Assert
      expect(joker.value, equals(15));
      expect(listenerCalled, isTrue);
    });

    test('isDifferent() should return true when value changed', () {
      // Arrange
      final joker = Joker<int>(5);

      // Act
      joker.value = 10;

      // Assert
      expect(joker.isDifferent(), isTrue);
    });

    test('isDifferent() should return false when value is the same', () {
      // Arrange
      final joker = Joker<int>(5);

      // Act
      joker.value = 5;

      // Assert
      expect(joker.isDifferent(), isFalse);
    });

    test('peek() should provide previous and current values', () {
      // Arrange
      final joker = Joker<int>(5);
      int? oldValue;
      int newValue = 0;

      // Act
      joker.value = 10;
      joker.peek((previous, current) {
        oldValue = previous;
        newValue = current;
      });

      // Assert
      expect(oldValue, equals(5));
      expect(newValue, equals(10));
    });

    test('when stopped is true, should not notify listeners', () {
      // Arrange
      final joker = Joker<int>(5, stopped: true);
      bool listenerCalled = false;

      joker.addListener(() {
        listenerCalled = true;
      });

      // Act
      joker.value = 10;

      // Assert
      expect(joker.value, equals(10)); // Value should still update
      expect(listenerCalled, isFalse); // But listener should not be called
    });

    test('should maintain tag value', () {
      // Arrange & Act
      final joker = Joker<int>(42, tag: 'score');

      // Assert
      expect(joker.tag, equals('score'));
    });

    test('tag should be null by default', () {
      // Arrange & Act
      final joker = Joker<int>(42);

      // Assert
      expect(joker.tag, isNull);
    });

    group('with complex objects', () {
      test('should handle lists correctly', () {
        // Arrange
        final joker = Joker<List<String>>(['a', 'b']);
        bool listenerCalled = false;

        joker.addListener(() {
          listenerCalled = true;
        });

        // Act
        joker.value = [...joker.value, 'c'];

        // Assert
        expect(joker.value, equals(['a', 'b', 'c']));
        expect(listenerCalled, isTrue);
      });

      test('should handle maps correctly', () {
        // Arrange
        final joker = Joker<Map<String, int>>({'a': 1, 'b': 2});
        bool listenerCalled = false;

        joker.addListener(() {
          listenerCalled = true;
        });

        // Act
        joker.value = {...joker.value, 'c': 3};

        // Assert
        expect(joker.value, equals({'a': 1, 'b': 2, 'c': 3}));
        expect(listenerCalled, isTrue);
      });

      test('should handle custom objects correctly', () {
        // Arrange
        final user1 = User('John', 25);
        final joker = Joker<User>(user1);
        bool listenerCalled = false;

        joker.addListener(() {
          listenerCalled = true;
        });

        // Act
        final user2 = User('John', 26); // Only age changed
        joker.value = user2;

        // Assert
        expect(joker.value.name, equals('John'));
        expect(joker.value.age, equals(26));
        expect(listenerCalled, isTrue);
      });
    });

    group('memory management', () {
      test('dispose() should remove all listeners', () {
        // Arrange
        final joker = Joker<int>(5);
        bool listenerCalled = false;

        joker.addListener(() {
          listenerCalled = true;
        });

        // Act
        joker.dispose();
        try {
          joker.value = 10; // This should not call any listeners
        } catch (e) {
          // ValueNotifier might throw after dispose
        }

        // Assert
        expect(listenerCalled, isFalse);
      });
    });

    group('edge cases', () {
      test('setting the same value should not notify listeners', () {
        // Arrange
        final joker = Joker<int>(5);
        int notificationCount = 0;

        joker.addListener(() {
          notificationCount++;
        });

        // Act
        joker.value = 5; //  Same value

        // Assert
        expect(notificationCount, equals(0));
      });

      test('updating with null for nullable types', () {
        // Arrange
        final joker = Joker<int?>(5);
        bool listenerCalled = false;

        joker.addListener(() {
          listenerCalled = true;
        });

        // Act
        joker.value = null;

        // Assert
        expect(joker.value, isNull);
        expect(listenerCalled, isTrue);
      });

      test('multiple updates should track the initial previous value', () {
        // Arrange
        final joker = Joker<int>(5);

        // Act - multiple updates
        joker.value = 10;
        joker.value = 15;
        joker.value = 20;

        // Assert
        expect(joker.value, equals(20));
      });
    });
  });
}

// Helper class for testing complex objects
class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
