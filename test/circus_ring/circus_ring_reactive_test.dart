import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/src/circus_ring.dart';
import 'package:joker_state/src/di/circus_ring/src/circus_ring_exception.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker/joker_trickx.dart';

void main() {
  group('CircusRing with Reactive Jokers', () {
    late CircusRing circus;

    setUp(() {
      circus = CircusRing();
      circus.fireAll(); // Clear all instances before each test
    });

    test('should maintain reactivity of registered Joker', () {
      // Arrange - create and register a Joker with a proper tag
      final joker = Joker<int>(42);
      circus.hire<Joker<int>>(joker, tag: 'counter');

      // Act - modify the joker value
      joker.trick(100);

      // Assert - retrieved joker should have updated value
      final retrievedJoker = circus.find<Joker<int>>('counter');
      expect(retrievedJoker.value, equals(100));
      expect(retrievedJoker, equals(joker)); // Same instance
    });

    test('should throw exception when registering Joker without tag', () {
      // Arrange
      final joker = Joker<int>(42);

      // Act & Assert
      expect(
          () => circus.hire<Joker<int>>(joker), // No tag provided
          throwsA(isA<CircusRingException>()));
    });

    test('should throw exception when registering Joker with empty tag', () {
      // Arrange
      final joker = Joker<int>(42);

      // Act & Assert
      expect(
          () => circus.hire<Joker<int>>(joker, tag: ''), // Empty tag
          throwsA(isA<CircusRingException>()));
    });

    test('should succeed when registering Joker with proper tag', () {
      // Arrange
      final joker = Joker<int>(42);

      // Act & Assert - should not throw
      expect(() => circus.hire<Joker<int>>(joker, tag: 'valid_tag'),
          returnsNormally);
    });

    test('should preserve listeners when accessing Joker multiple times', () {
      // Arrange - create a joker with a listener
      final joker = Joker<int>(0);
      int callCount = 0;

      joker.addListener(() {
        callCount++;
      });

      // Register the joker with a tag
      circus.hire<Joker<int>>(joker, tag: 'counter');

      // Act - retrieve the joker multiple times and update it
      final joker1 = circus.find<Joker<int>>('counter');
      final joker2 = circus.find<Joker<int>>('counter');

      // Each time we get the same instance
      expect(joker1, equals(joker2));
      expect(joker1, equals(joker));

      // Update through retrieved reference
      joker1.trick(10);

      // Assert - listener should be called
      expect(callCount, equals(1));

      // Update through another reference
      joker2.trick(20);

      // The listener should be called again
      expect(callCount, equals(2));
      expect(joker.value, equals(20));
    });

    test('should support Joker value changes through contract', () {
      // Arrange - register a factory for Joker
      int counter = 0;
      circus.contract<Joker<int>>(() {
        counter++;
        return Joker<int>(counter);
      });

      // Act - get instances and modify them
      final joker1 = circus.find<Joker<int>>();
      final joker2 = circus.find<Joker<int>>();

      // Assert - each factory call creates a new instance
      expect(joker1, isNot(equals(joker2)));
      expect(joker1.value, equals(1));
      expect(joker2.value, equals(2));

      // Changing one doesn't affect the other
      joker1.trick(100);
      expect(joker1.value, equals(100));
      expect(joker2.value, equals(2));
    });

    test('should create Joker through hireLazily only when accessed', () {
      // Arrange - track if factory was called
      bool factoryCalled = false;

      // Register lazy factory
      circus.hireLazily<Joker<String>>(() {
        factoryCalled = true;
        return Joker<String>('created');
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - access the lazy instance
      final joker = circus.find<Joker<String>>();

      // Assert - factory called and instance created
      expect(factoryCalled, isTrue);
      expect(joker.value, equals('created'));

      // Modify the instance
      joker.trick('modified');

      // Retrieve again - should be the same instance with updated value
      final joker2 = circus.find<Joker<String>>();
      expect(joker2.value, equals('modified'));
      expect(joker2, equals(joker));
    });

    test('should support complex objects with Joker', () {
      // Arrange - create a joker with a complex object
      final user = User('John', 30);
      final joker = Joker<User>(user);

      // Register the joker with a tag
      circus.hire<Joker<User>>(joker, tag: 'user_joker');

      // Act - retrieve and modify the object
      final retrievedJoker = circus.find<Joker<User>>('user_joker');
      retrievedJoker.trick(User('John', 31)); // Update age

      // Assert - object should be updated
      expect(retrievedJoker.value.age, equals(31));
      expect(retrievedJoker.value.name, equals('John'));

      // Original reference should reflect the change
      expect(joker.value.age, equals(31));
    });

    test('should handle Joker with collections', () {
      // Arrange - create a joker with a list
      final joker = Joker<List<String>>(['item1', 'item2']);
      circus.hire<Joker<List<String>>>(joker, tag: 'list_joker');

      // Act - retrieve and modify the list
      final retrievedJoker = circus.find<Joker<List<String>>>('list_joker');

      // Modify list (immutable way - recommended)
      retrievedJoker.trick([...retrievedJoker.value, 'item3']);

      // Assert
      expect(retrievedJoker.value.length, equals(3));
      expect(retrievedJoker.value, contains('item3'));

      // Original reference should reflect the change
      expect(joker.value.length, equals(3));
    });

    test('should support trickAsync with Joker', () async {
      // Arrange - create and register a joker
      final joker = Joker<int>(0);
      circus.hire<Joker<int>>(joker, tag: 'async_joker');

      // Act - perform async update
      await joker.trickAsync((value) async {
        await Future.delayed(Duration(milliseconds: 10));
        return value + 5;
      });

      // Assert - retrieved joker should have updated value
      final retrievedJoker = circus.find<Joker<int>>('async_joker');
      expect(retrievedJoker.value, equals(5));
    });

    test('should maintain stopped flag when registered in CircusRing', () {
      // Arrange - create a stopped joker
      final joker = Joker<int>(42, stopped: true);
      circus.hire<Joker<int>>(joker, tag: 'stopped_joker');

      // Add a listener to verify it's not called
      bool listenerCalled = false;
      joker.addListener(() {
        listenerCalled = true;
      });

      // Act - modify the joker
      joker.trick(100);

      // Assert - value should change but listener should not be called
      expect(joker.value, equals(100));
      expect(listenerCalled, isFalse);

      // Retrieved joker should also maintain the stopped flag
      final retrievedJoker = circus.find<Joker<int>>('stopped_joker');
      expect(retrievedJoker.stopped, isTrue);
    });

    test('should summon and spotlight Jokers through CircusRing extension', () {
      // Arrange & Act - summon a joker
      final joker = circus.summon<int>(42, tag: 'answer');

      // Assert - joker should be registered with the tag
      expect(circus.isHired<Joker<int>>('answer'), isTrue);

      // Modify the joker
      joker.trick(100);

      // Spotlight should retrieve the updated joker
      final spotlightedJoker = circus.spotlight<int>(tag: 'answer');
      expect(spotlightedJoker.value, equals(100));

      // Vanish should remove the joker
      circus.vanish<int>(tag: 'answer');
      expect(circus.isHired<Joker<int>>('answer'), isFalse);
    });

    test('should verify summon is the preferred way to register Jokers', () {
      // Arrange & Act - summon a joker
      // ignore: unused_local_variable
      final joker = circus.summon<String>('test', tag: 'message');

      // Assert - joker should be registered correctly
      expect(circus.isHired<Joker<String>>('message'), isTrue);
      expect(circus.spotlight<String>(tag: 'message').value, equals('test'));
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
