import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';

void main() {
  late CircusRing ring;

  // reset CircusRing before each test
  setUp(() {
    ring = CircusRing();
    ring.deleteAll();
    ring.config(enableLogs: true);
  });

  group('CircusRing Basics', () {
    test('singleton instance should be the same', () {
      expect(Circus, equals(CircusRing.instance));
      expect(Circus, equals(CircusRing()));
      expect(CircusRing(), equals(CircusRing()));
    });
  });

  group('Registration', () {
    test('should register and retrieve instances', () {
      // Arrange
      final testString = 'Hello World';
      final testInt = 42;

      // Act
      ring.put<String>(testString);
      ring.put<int>(testInt, tag: 'answer');

      // Assert
      expect(ring.find<String>(), equals(testString));
      expect(ring.find<int>('answer'), equals(testInt));
    });

    test('should replace existing instances', () {
      // Arrange
      final firstString = 'First';
      final secondString = 'Second';

      // Act
      ring.put<String>(firstString);
      expect(ring.find<String>(), equals(firstString));
      ring.put<String>(secondString);

      // Assert
      expect(ring.find<String>(), equals(secondString));
    });

    test('should lazy register and instantiate', () {
      // Arrange
      var factoryCalled = false;

      // Act
      ring.lazyPut<String>(() {
        factoryCalled = true;
        return 'Lazy String';
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - trigger lazy instantiation
      final result = ring.find<String>();

      // Assert - factory was called and instance created
      expect(factoryCalled, isTrue);
      expect(result, equals('Lazy String'));

      // Check instance is now registered and factory not called again
      factoryCalled = false;
      final secondResult = ring.find<String>();
      expect(factoryCalled, isFalse); // Not called again
      expect(secondResult, equals('Lazy String'));
    });

    test('singleton method should register instance', () {
      // Arrange
      final service = TestService();

      // Act
      ring.singleton(service);

      // Assert
      expect(ring.find<TestService>(), equals(service));
    });

    test('factory should create new instance each time', () {
      // Arrange
      int counter = 0;

      // Act
      ring.factory<Counter>(() {
        counter++;
        return Counter(counter);
      });

      // Assert - each find should create new instance
      expect(ring.find<Counter>().count, equals(1));
      expect(ring.find<Counter>().count, equals(2));
      expect(ring.find<Counter>().count, equals(3));
    });
  });

  group('Async Registration', () {
    test('should register and retrieve async instances', () async {
      // Arrange
      var asyncInitCalled = false;

      // Act
      await ring.putAsync<String>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        asyncInitCalled = true;
        return 'Async String';
      });

      // Assert
      expect(asyncInitCalled, isTrue);
      expect(ring.find<String>(), equals('Async String'));
    });

    test('should lazy register and instantiate async', () async {
      // Arrange
      var factoryCalled = false;

      // Act - register
      ring.lazyPutAsync<String>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        factoryCalled = true;
        return 'Lazy Async String';
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - trigger lazy instantiation
      final result = await ring.findAsync<String>();

      // Assert - factory was called and instance created
      expect(factoryCalled, isTrue);
      expect(result, equals('Lazy Async String'));

      // Check instance is now registered and factory not called again
      factoryCalled = false;
      final secondResult = await ring.findAsync<String>();
      expect(factoryCalled, isFalse); // Not called again
      expect(secondResult, equals('Lazy Async String'));
    });

    test('should throw when accessing async registered instance synchronously',
        () {
      // Arrange
      ring.lazyPutAsync<String>(() async {
        return 'Lazy Async String';
      });

      // Act & Assert
      expect(() => ring.find<String>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('Find and TryFind', () {
    test('should throw when instance not found', () {
      // Act & Assert
      expect(() => ring.find<String>(), throwsA(isA<CircusRingException>()));
    });

    test('tryFind should return null when instance not found', () {
      // Act
      final result = ring.tryFind<String>();

      // Assert
      expect(result, isNull);
    });

    test('tryFindAsync should return null when instance not found', () async {
      // Act
      final result = await ring.tryFindAsync<String>();

      // Assert
      expect(result, isNull);
    });

    test('isRegistered should return correct status', () {
      // Arrange
      ring.put('Test');
      ring.lazyPut<int>(() => 42);

      // Assert
      expect(ring.isRegistered<String>(), isTrue);
      expect(ring.isRegistered<int>(), isTrue);
      expect(ring.isRegistered<bool>(), isFalse);
      expect(ring.isRegistered<String>('tagged'), isFalse);
    });
  });

  group('Resource Cleanup', () {
    test('should dispose resources when deleting', () {
      // Arrange
      final service = MockDisposable();
      ring.put(service);

      // Act
      ring.delete<MockDisposable>();

      // Assert
      expect(service.disposed, isTrue);
    });

    test('should dispose async resources when deleting async', () async {
      // Arrange
      final service = MockAsyncDisposable();
      ring.put(service);

      // Act
      await ring.deleteAsync<MockAsyncDisposable>();

      // Assert
      expect(service.disposed, isTrue);
    });

    test('should dispose ValueNotifier when deleting', () {
      // Arrange
      final notifier = ValueNotifier<int>(42);
      ring.put(notifier);

      // Keep a weak reference to check if it's garbage collected
      var listenerCalled = false;
      notifier.addListener(() {
        listenerCalled = true;
      });

      // Act
      ring.delete<ValueNotifier<int>>();

      // Try to use the notifier (should throw if properly disposed)
      expect(() => notifier.value = 43, throwsFlutterError);

      // Assert - listener shouldn't be called after disposal
      expect(listenerCalled, isFalse);
    });

    test('should dispose resources when calling deleteAll', () {
      // Arrange
      final service1 = MockDisposable();
      final service2 = MockDisposable();
      ring.put(service1, tag: '1');
      ring.put(service2, tag: '2');

      // Act
      ring.deleteAll();

      // Assert
      expect(service1.disposed, isTrue);
      expect(service2.disposed, isTrue);
    });
  });
}

// Helper classes for testing

class TestService {}

class Counter {
  final int count;

  Counter(this.count);
}

class MockDisposable implements Disposable {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}

class MockAsyncDisposable implements AsyncDisposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    await Future.delayed(Duration(milliseconds: 10));
    disposed = true;
  }
}
