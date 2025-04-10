import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';

void main() {
  late CircusRing circus;

  // reset CircusRing before each test
  setUp(() {
    circus = CircusRing();
    circus.fireAll();
    circus.config(enableLogs: true);
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
      circus.hire<String>(testString);
      circus.hire<int>(testInt, tag: 'answer');

      // Assert
      expect(circus.find<String>(), equals(testString));
      expect(circus.find<int>('answer'), equals(testInt));
    });

    test('should replace existing instances', () {
      // Arrange
      final firstString = 'First';
      final secondString = 'Second';

      // Act
      circus.hire<String>(firstString);
      expect(circus.find<String>(), equals(firstString));
      circus.hire<String>(secondString);

      // Assert
      expect(circus.find<String>(), equals(secondString));
    });

    test('should lazy register and instantiate', () {
      // Arrange
      var factoryCalled = false;

      // Act
      circus.hireLazily<String>(() {
        factoryCalled = true;
        return 'Lazy String';
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - trigger lazy instantiation
      final result = circus.find<String>();

      // Assert - factory was called and instance created
      expect(factoryCalled, isTrue);
      expect(result, equals('Lazy String'));

      // Check instance is now registered and factory not called again
      factoryCalled = false;
      final secondResult = circus.find<String>();
      expect(factoryCalled, isFalse); // Not called again
      expect(secondResult, equals('Lazy String'));
    });

    test('singleton method should register instance', () {
      // Arrange
      final service = TestService();

      // Act
      circus.appoint(service);

      // Assert
      expect(circus.find<TestService>(), equals(service));
    });

    test('factory should create new instance each time', () {
      // Arrange
      int counter = 0;

      // Act
      circus.contract<Counter>(() {
        counter++;
        return Counter(counter);
      });

      // Assert - each find should create new instance
      expect(circus.find<Counter>().count, equals(1));
      expect(circus.find<Counter>().count, equals(2));
      expect(circus.find<Counter>().count, equals(3));
    });
  });

  group('Async Registration', () {
    test('should register and retrieve async instances', () async {
      // Arrange
      var asyncInitCalled = false;

      // Act
      await circus.hireAsync<String>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        asyncInitCalled = true;
        return 'Async String';
      });

      // Assert
      expect(asyncInitCalled, isTrue);
      expect(circus.find<String>(), equals('Async String'));
    });

    test('should lazy register and instantiate async', () async {
      // Arrange
      var factoryCalled = false;

      // Act - register
      circus.hireLazilyAsync<String>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        factoryCalled = true;
        return 'Lazy Async String';
      });

      // Assert - factory not yet called
      expect(factoryCalled, isFalse);

      // Act - trigger lazy instantiation
      final result = await circus.findAsync<String>();

      // Assert - factory was called and instance created
      expect(factoryCalled, isTrue);
      expect(result, equals('Lazy Async String'));

      // Check instance is now registered and factory not called again
      factoryCalled = false;
      final secondResult = await circus.findAsync<String>();
      expect(factoryCalled, isFalse); // Not called again
      expect(secondResult, equals('Lazy Async String'));
    });

    test('should throw when accessing async registered instance synchronously',
        () {
      // Arrange
      circus.hireLazilyAsync<String>(() async {
        return 'Lazy Async String';
      });

      // Act & Assert
      expect(() => circus.find<String>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('Find and TryFind', () {
    test('should throw when instance not found', () {
      // Act & Assert
      expect(() => circus.find<String>(), throwsA(isA<CircusRingException>()));
    });

    test('tryFind should return null when instance not found', () {
      // Act
      final result = circus.tryFind<String>();

      // Assert
      expect(result, isNull);
    });

    test('tryFindAsync should return null when instance not found', () async {
      // Act
      final result = await circus.tryFindAsync<String>();

      // Assert
      expect(result, isNull);
    });

    test('isRegistered should return correct status', () {
      // Arrange
      circus.hire('Test');
      circus.hireLazily<int>(() => 42);

      // Assert
      expect(circus.isHired<String>(), isTrue);
      expect(circus.isHired<int>(), isTrue);
      expect(circus.isHired<bool>(), isFalse);
      expect(circus.isHired<String>('tagged'), isFalse);
    });
  });

  group('Resource Cleanup', () {
    test('should dispose resources when deleting', () {
      // Arrange
      final service = MockDisposable();
      circus.hire(service);

      // Act
      circus.fire<MockDisposable>();

      // Assert
      expect(service.disposed, isTrue);
    });

    test('should dispose async resources when deleting async', () async {
      // Arrange
      final service = MockAsyncDisposable();
      circus.hire(service);

      // Act
      await circus.fireAsync<MockAsyncDisposable>();

      // Assert
      expect(service.disposed, isTrue);
    });

    test('should dispose ValueNotifier when deleting', () {
      // Arrange
      final notifier = ValueNotifier<int>(42);
      circus.hire(notifier);

      // Keep a weak reference to check if it's garbage collected
      var listenerCalled = false;
      notifier.addListener(() {
        listenerCalled = true;
      });

      // Act
      circus.fire<ValueNotifier<int>>();

      // Try to use the notifier (should throw if properly disposed)
      expect(() => notifier.value = 43, throwsFlutterError);

      // Assert - listener shouldn't be called after disposal
      expect(listenerCalled, isFalse);
    });

    test('should dispose resources when calling deleteAll', () {
      // Arrange
      final service1 = MockDisposable();
      final service2 = MockDisposable();
      circus.hire(service1, tag: '1');
      circus.hire(service2, tag: '2');

      // Act
      circus.fireAll();

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
