import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker_card/joker_card.dart';

void main() {
  group('CircusRing with Reactive Objects', () {
    late CircusRing ring;

    setUp(() {
      ring = CircusRing();
      ring.deleteAll();
    });

    test('should maintain reactivity of registered JokerCard', () {
      // Arrange - create and register a JokerCard
      final card = JokerCard<int>(42);
      ring.put<JokerCard<int>>(card, tag: 'counter');

      // Act - modify the card value
      card.update(100);

      // Assert - retrieved card should have updated value
      final retrievedCard = ring.find<JokerCard<int>>('counter');
      expect(retrievedCard.value, equals(100));
      expect(retrievedCard, equals(card)); // Same instance
    });

    test('should preserve listeners when accessing JokerCard multiple times',
        () {
      // Arrange - create a card with a listener
      final card = JokerCard<int>(0);
      int callCount = 0;

      card.addListener(() {
        callCount++;
      });

      // Register the card
      ring.put<JokerCard<int>>(card);

      // Act - retrieve the card multiple times and update it
      final card1 = ring.find<JokerCard<int>>();
      final card2 = ring.find<JokerCard<int>>();

      // Each time we get the same instance
      expect(card1, equals(card2));
      expect(card1, equals(card));

      // Update through retrieved reference
      card1.update(10);

      // Assert - listener should be called
      expect(callCount, equals(1));

      // Update through another reference
      card2.update(20);

      // The listener should be called again
      expect(callCount, equals(2));
      expect(card.value, equals(20));
    });

    test('should support JokerCard value changes through factory', () {
      // Arrange - register a factory for JokerCard
      int counter = 0;
      ring.factory<JokerCard<int>>(() {
        counter++;
        return JokerCard<int>(counter);
      });

      // Act - get instances and modify them
      final card1 = ring.find<JokerCard<int>>();
      final card2 = ring.find<JokerCard<int>>();

      // Assert - each factory call creates a new instance
      expect(card1, isNot(equals(card2)));
      expect(card1.value, equals(1));
      expect(card2.value, equals(2));

      // Changing one doesn't affect the other
      card1.update(100);
      expect(card1.value, equals(100));
      expect(card2.value, equals(2));
    });

    test('should create JokerCard through lazyPut only when accessed', () {
      // Arrange - track if factory was called
      bool factoryCalled = false;

      // Register lazy factory
      ring.lazyPut<JokerCard<String>>(() {
        factoryCalled = true;
        return JokerCard<String>('created');
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - access the lazy instance
      final card = ring.find<JokerCard<String>>();

      // Assert - factory called and instance created
      expect(factoryCalled, isTrue);
      expect(card.value, equals('created'));

      // Modify the instance
      card.update('modified');

      // Retrieve again - should be the same instance with updated value
      final card2 = ring.find<JokerCard<String>>();
      expect(card2.value, equals('modified'));
      expect(card2, equals(card));
    });

    test('should support complex objects with JokerCard', () {
      // Arrange - create a card with a complex object
      final user = User('John', 30);
      final card = JokerCard<User>(user);

      // Register the card
      ring.put<JokerCard<User>>(card);

      // Act - retrieve and modify the object
      final retrievedCard = ring.find<JokerCard<User>>();
      retrievedCard.update(User('John', 31)); // Update age

      // Assert - object should be updated
      expect(retrievedCard.value.age, equals(31));
      expect(retrievedCard.value.name, equals('John'));

      // Original reference should reflect the change
      expect(card.value.age, equals(31));
    });

    test('should handle JokerCard with collections', () {
      // Arrange - create a card with a list
      final card = JokerCard<List<String>>(['item1', 'item2']);
      ring.put<JokerCard<List<String>>>(card);

      // Act - retrieve and modify the list
      final retrievedCard = ring.find<JokerCard<List<String>>>();

      // Modify list (immutable way - recommended)
      retrievedCard.update([...retrievedCard.value, 'item3']);

      // Assert
      expect(retrievedCard.value.length, equals(3));
      expect(retrievedCard.value, contains('item3'));

      // Original reference should reflect the change
      expect(card.value.length, equals(3));
    });

    test('should maintain reactivity through delete and re-register', () {
      // Arrange - create and register a card
      final card = JokerCard<int>(5);
      ring.put<JokerCard<int>>(card, tag: 'counter');

      // Delete the card
      ring.delete<JokerCard<int>>(tag: 'counter');

      // Re-register the same card
      ring.put<JokerCard<int>>(card, tag: 'counter');

      // Modify the original card
      card.update(10);

      // Assert - retrieved card should have the updated value
      final retrievedCard = ring.find<JokerCard<int>>('counter');
      expect(retrievedCard.value, equals(10));
    });

    test('should support asyncUpdate with JokerCard', () async {
      // Arrange - create and register a card
      final card = JokerCard<int>(0);
      ring.put<JokerCard<int>>(card);

      // Act - perform async update
      await card.updateWithAsync((value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value + 5;
      });

      // Assert - retrieved card should have updated value
      final retrievedCard = ring.find<JokerCard<int>>();
      expect(retrievedCard.value, equals(5));
    });

    test('should persist tag information when registering JokerCard', () {
      // Arrange - create a card with a tag
      final card = JokerCard<int>(42, tag: 'answer');

      // Register without specifying tag in put
      ring.put<JokerCard<int>>(card);

      // Assert - retrieved card should have the original tag
      final retrievedCard = ring.find<JokerCard<int>>();
      expect(retrievedCard.tag, equals('answer'));
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
