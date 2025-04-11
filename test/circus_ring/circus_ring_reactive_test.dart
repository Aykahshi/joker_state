import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker/joker_trickx.dart';
import 'package:joker_state/src/state_management/joker_exception.dart';

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
      expect(retrievedJoker.state, equals(100));
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

    test('should enforce method usage based on autoNotify mode', () {
      // Arrange - create jokers with different modes
      final autoJoker = Joker<int>(0, autoNotify: true);
      final manualJoker = Joker<int>(0, autoNotify: false);

      // Assert - methods restricted by mode
      expect(() => autoJoker.trick(10), returnsNormally);
      expect(() => manualJoker.trick(10), throwsA(isA<JokerException>()));

      expect(() => autoJoker.whisper(10), throwsA(isA<JokerException>()));
      expect(() => manualJoker.whisper(10), returnsNormally);

      expect(() => autoJoker.yell(), returnsNormally);
      expect(() => manualJoker.yell(), returnsNormally);
    });

    test('should preserve listeners when accessing Joker multiple times', () {
      // Arrange - create an auto joker with a listener
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
      expect(joker.state, equals(20));
    });

    test('should notify correctly with auto jokers', () {
      // Arrange - create an auto joker with listener
      final joker = Joker<int>(0, autoNotify: true);
      int countNotified = 0;
      joker.addListener(() => countNotified++);

      // Act - update with value
      joker.trick(10);

      // Assert - should have notified once
      expect(joker.state, equals(10));
      expect(countNotified, equals(1));

      // Act - update with function
      joker.trickWith((val) => val * 2);

      // Assert - should have notified again
      expect(joker.state, equals(20));
      expect(countNotified, equals(2));
    });

    test('should notify correctly with manual jokers', () {
      // Arrange - create a manual joker with listener
      final joker = Joker<int>(0, autoNotify: false);
      int countNotified = 0;
      joker.addListener(() => countNotified++);

      // Act - update value silently
      joker.whisper(10);

      // Assert - should not have notified
      expect(joker.state, equals(10));
      expect(countNotified, equals(0));

      // Act - call yell to notify
      joker.yell();

      // Assert - should notify now
      expect(countNotified, equals(1));
    });

    test('should batch update and notify only once', () {
      // Arrange
      final joker = Joker<int>(1);
      int countNotified = 0;
      joker.addListener(() => countNotified++);

      // Act - make batch updates
      joker
          .batch()
          .apply((val) => val + 1) // 1 -> 2
          .apply((val) => val * 3) // 2 -> 6
          .apply((val) => val - 1) // 6 -> 5
          .commit();

      // Assert
      expect(joker.state, equals(5)); // Final value
      expect(countNotified, equals(1)); // Only notified once at commit
    });

    test('should discard batch changes if needed', () {
      // Arrange
      final joker = Joker<int>(10);

      // Act - make batch updates but discard
      joker.batch().apply((val) => val * 2).apply((val) => val + 5).discard();

      // Assert - value should remain unchanged
      expect(joker.state, equals(10));
    });

    test('should summon and spotlight Jokers through CircusRing extension', () {
      // Arrange & Act - summon an auto-notify joker
      final joker = circus.summon<int>(42, tag: 'answer');

      // Assert - joker should be registered with the tag
      expect(circus.isHired<Joker<int>>('answer'), isTrue);
      expect(joker.autoNotify, isTrue);

      // Modify the joker
      joker.trick(100);

      // Spotlight should retrieve the updated joker
      final spotlightedJoker = circus.spotlight<int>(tag: 'answer');
      expect(spotlightedJoker.state, equals(100));

      // Vanish should remove the joker
      circus.vanish<int>(tag: 'answer');
      expect(circus.isHired<Joker<int>>('answer'), isFalse);
    });

    test('should recruit manual jokers through CircusRing extension', () {
      // Arrange & Act - recruit a manual joker
      final joker = circus.recruit<int>(42, tag: 'manual');

      // Assert - joker should be manual (autoNotify = false)
      expect(circus.isHired<Joker<int>>('manual'), isTrue);
      expect(joker.autoNotify, isFalse);

      int notifications = 0;
      joker.addListener(() => notifications++);

      // Modify using whisper (shouldn't notify)
      joker.whisper(100);
      expect(notifications, equals(0));

      // Yell to notify
      joker.yell();
      expect(notifications, equals(1));
    });
  });
}
