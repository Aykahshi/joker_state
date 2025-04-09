import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card.dart';

void main() {
  group('JokerCard', () {
    test('should initialize with the given value', () {
      // Arrange & Act
      final card = JokerCard<int>(42);

      // Assert
      expect(card.value, equals(42));
    });

    test('should update value and notify listeners', () {
      // Arrange
      final card = JokerCard<int>(10);
      bool listenerCalled = false;

      card.addListener(() {
        listenerCalled = true;
      });

      // Act
      card.value = 20;

      // Assert
      expect(card.value, equals(20));
      expect(listenerCalled, isTrue);
    });

    test('should track previous value when updated', () {
      // Arrange
      final card = JokerCard<int>(10);

      // Act
      card.value = 20;

      // Assert
      expect(card.value, equals(20));
    });

    test('update() method should change value and notify listeners', () {
      // Arrange
      final card = JokerCard<String>('hello');
      bool listenerCalled = false;

      card.addListener(() {
        listenerCalled = true;
      });

      // Act
      card.update('world');

      // Assert
      expect(card.value, equals('world'));
      expect(listenerCalled, isTrue);
    });

    test('updateWith() should apply function and notify listeners', () {
      // Arrange
      final card = JokerCard<int>(5);
      bool listenerCalled = false;

      card.addListener(() {
        listenerCalled = true;
      });

      // Act
      card.updateWith((value) => value * 2);

      // Assert
      expect(card.value, equals(10));
      expect(listenerCalled, isTrue);
    });

    test('updateWithAsync() should apply async function and notify listeners',
        () async {
      // Arrange
      final card = JokerCard<int>(5);
      bool listenerCalled = false;

      card.addListener(() {
        listenerCalled = true;
      });

      // Act
      await card.updateWithAsync((value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value * 3;
      });

      // Assert
      expect(card.value, equals(15));
      expect(listenerCalled, isTrue);
    });

    test('hasChanged() should return true when value changed', () {
      // Arrange
      final card = JokerCard<int>(5);

      // Act
      card.value = 10;

      // Assert
      expect(card.hasChanged(), isTrue);
    });

    test('hasChanged() should return false when value is the same', () {
      // Arrange
      final card = JokerCard<int>(5);

      // Act
      card.value = 5;

      // Assert
      expect(card.hasChanged(), isFalse);
    });

    test('peek() should provide previous and current values', () {
      // Arrange
      final card = JokerCard<int>(5);
      int? oldValue;
      int newValue = 0;

      // Act
      card.value = 10;
      card.peek((previous, current) {
        oldValue = previous;
        newValue = current;
      });

      // Assert
      expect(oldValue, equals(5));
      expect(newValue, equals(10));
    });

    test('when stopped is true, should not notify listeners', () {
      // Arrange
      final card = JokerCard<int>(5, stopped: true);
      bool listenerCalled = false;

      card.addListener(() {
        listenerCalled = true;
      });

      // Act
      card.value = 10;

      // Assert
      expect(card.value, equals(10)); // Value should still update
      expect(listenerCalled, isFalse); // But listener should not be called
    });

    test('should maintain tag value', () {
      // Arrange & Act
      final card = JokerCard<int>(42, tag: 'score');

      // Assert
      expect(card.tag, equals('score'));
    });

    test('tag should be null by default', () {
      // Arrange & Act
      final card = JokerCard<int>(42);

      // Assert
      expect(card.tag, isNull);
    });

    group('with complex objects', () {
      test('should handle lists correctly', () {
        // Arrange
        final card = JokerCard<List<String>>(['a', 'b']);
        bool listenerCalled = false;

        card.addListener(() {
          listenerCalled = true;
        });

        // Act
        card.value = [...card.value, 'c'];

        // Assert
        expect(card.value, equals(['a', 'b', 'c']));
        expect(listenerCalled, isTrue);
      });

      test('should handle maps correctly', () {
        // Arrange
        final card = JokerCard<Map<String, int>>({'a': 1, 'b': 2});
        bool listenerCalled = false;

        card.addListener(() {
          listenerCalled = true;
        });

        // Act
        card.value = {...card.value, 'c': 3};

        // Assert
        expect(card.value, equals({'a': 1, 'b': 2, 'c': 3}));
        expect(listenerCalled, isTrue);
      });

      test('should handle custom objects correctly', () {
        // Arrange
        final user1 = User('John', 25);
        final card = JokerCard<User>(user1);
        bool listenerCalled = false;

        card.addListener(() {
          listenerCalled = true;
        });

        // Act
        final user2 = User('John', 26); // Only age changed
        card.value = user2;

        // Assert
        expect(card.value.name, equals('John'));
        expect(card.value.age, equals(26));
        expect(listenerCalled, isTrue);
      });
    });

    group('memory management', () {
      test('dispose() should remove all listeners', () {
        // Arrange
        final card = JokerCard<int>(5);
        bool listenerCalled = false;

        card.addListener(() {
          listenerCalled = true;
        });

        // Act
        card.dispose();
        try {
          card.value = 10; // This should not call any listeners
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
        final card = JokerCard<int>(5);
        int notificationCount = 0;

        card.addListener(() {
          notificationCount++;
        });

        // Act
        card.value = 5; //  Same value

        // Assert
        expect(notificationCount, equals(0));
      });

      test('updating with null for nullable types', () {
        // Arrange
        final card = JokerCard<int?>(5);
        bool listenerCalled = false;

        card.addListener(() {
          listenerCalled = true;
        });

        // Act
        card.value = null;

        // Assert
        expect(card.value, isNull);
        expect(listenerCalled, isTrue);
      });

      test('multiple updates should track the initial previous value', () {
        // Arrange
        final card = JokerCard<int>(5);

        // Act - multiple updates
        card.value = 10;
        card.value = 15;
        card.value = 20;

        // Assert
        expect(card.value, equals(20));
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
