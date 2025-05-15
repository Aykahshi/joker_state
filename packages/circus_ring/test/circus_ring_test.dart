// This file contains tests for the CircusRing dependency injection container
import 'package:circus_ring/circus_ring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Test classes
class TestClass {
  final String value;
  TestClass(this.value);
}

class AnotherTestClass {
  final int value;
  AnotherTestClass(this.value);
}

class DisposableTestClass implements Disposable {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}

class StateTestClass extends ChangeNotifier {
  int count = 0;

  void increment() {
    count++;
    notifyListeners();
  }
}

void main() {
  // Reset CircusRing before each test
  setUp(() async {
    await Ring.fireAll();
  });

  group('CircusRing Basic Functionality Tests', () {
    test('hire and find basic functionality test', () {
      // Register an object
      final testInstance = TestClass('test');
      Ring.hire(testInstance);

      // Find the registered object
      final foundInstance = Ring.find<TestClass>();

      // Verify the found object is correct
      expect(foundInstance, isA<TestClass>());
      expect(foundInstance.value, equals('test'));
      expect(identical(foundInstance, testInstance), isTrue);
    });

    test('hire multiple different type objects test', () {
      // Register multiple objects of different types
      final testInstance1 = TestClass('test1');
      final testInstance2 = AnotherTestClass(42);

      Ring.hire(testInstance1);
      Ring.hire(testInstance2);

      // Find the registered object
      final foundInstance1 = Ring.find<TestClass>();
      final foundInstance2 = Ring.find<AnotherTestClass>();

      // Verify the found object is correct
      expect(foundInstance1.value, equals('test1'));
      expect(foundInstance2.value, equals(42));
    });

    test('isHired functionality test', () {
      // Register an object
      final testInstance = TestClass('test');
      Ring.hire(testInstance);

      // Verify the isHired method
      expect(Ring.isHired<TestClass>(), isTrue);
      expect(Ring.isHired<AnotherTestClass>(), isFalse);
    });
  });

  group('CircusRing tag functionality tests', () {
    test('hire and find with tag test', () {
      // Register objects with tags
      final testInstance1 = TestClass('test1');
      final testInstance2 = TestClass('test2');

      Ring.hire(testInstance1, tag: 'tag1');
      Ring.hire(testInstance2, tag: 'tag2');

      // Find objects with tags
      final foundInstance1 = Ring.find<TestClass>('tag1');
      final foundInstance2 = Ring.find<TestClass>('tag2');

      // Verify the found object is correct
      expect(foundInstance1.value, equals('test1'));
      expect(foundInstance2.value, equals('test2'));
    });

    test('findByTag functionality test', () {
      // Register objects with tags
      final testInstance = TestClass('test');
      Ring.hire(testInstance, tag: 'myTag');

      // Use findByTag to find the object
      final foundInstance = Ring.findByTag('myTag');

      // Verify the found object is correct
      expect(foundInstance, isA<TestClass>());
      expect((foundInstance as TestClass).value, equals('test'));
    });

    test('same type with different tags test', () {
      // Register objects of the same type with different tags
      final testInstance1 = TestClass('test1');
      final testInstance2 = TestClass('test2');
      final testInstance3 = TestClass('test3');

      Ring.hire(testInstance1, tag: 'tag1');
      Ring.hire(testInstance2, tag: 'tag2');
      Ring.hire(testInstance3); // No tag

      // Find the objects
      final foundInstance1 = Ring.find<TestClass>('tag1');
      final foundInstance2 = Ring.find<TestClass>('tag2');
      final foundInstance3 = Ring.find<TestClass>(); // No tag

      // Verify the found object is correct
      expect(foundInstance1.value, equals('test1'));
      expect(foundInstance2.value, equals('test2'));
      expect(foundInstance3.value, equals('test3'));
    });
  });

  group('CircusRing fire functionality tests', () {
    test('fire basic functionality test', () {
      // Register an object
      final testInstance = TestClass('test');
      Ring.hire(testInstance);

      // Verify the object is registered
      expect(Ring.isHired<TestClass>(), isTrue);

      // Remove the object
      final result = Ring.fire<TestClass>();

      // Verify the removal result
      expect(result, isTrue);
      expect(Ring.isHired<TestClass>(), isFalse);

      // Attempting to find the removed object should throw an exception
      expect(() => Ring.find<TestClass>(), throwsA(isA<CircusRingException>()));
    });

    test('fire Disposable object test', () {
      // Register a Disposable object
      final disposableInstance = DisposableTestClass();
      Ring.hire(disposableInstance);

      // Remove the object
      Ring.fire<DisposableTestClass>();

      // Verify the dispose method was called
      expect(disposableInstance.disposed, isTrue);
    });

    test('fire ChangeNotifier object test', () {
      // Register a ChangeNotifier object
      final stateInstance = StateTestClass();
      Ring.hire(stateInstance);

      // Increment the counter
      stateInstance.increment();
      expect(stateInstance.count, equals(1));

      // Remove the object
      Ring.fire<StateTestClass>();

      // Verify the object has been removed
      expect(Ring.isHired<StateTestClass>(), isFalse);
    });

    test('fire object with tag test', () {
      // Register objects with tags
      final testInstance1 = TestClass('test1');
      final testInstance2 = TestClass('test2');

      Ring.hire(testInstance1, tag: 'tag1');
      Ring.hire(testInstance2, tag: 'tag2');

      // Remove one of the objects
      Ring.fire<TestClass>(tag: 'tag1');

      // Verify the results
      expect(Ring.isHired<TestClass>('tag1'), isFalse);
      expect(Ring.isHired<TestClass>('tag2'), isTrue);

      // Find the remaining object
      final foundInstance = Ring.find<TestClass>('tag2');
      expect(foundInstance.value, equals('test2'));
    });
  });

  group('CircusRing error handling tests', () {
    test('throws exception when object not found', () {
      // Attempt to find an unregistered object
      expect(() => Ring.find<TestClass>(), throwsA(isA<CircusRingException>()));
    });

    test('tryFind returns null when object not found', () {
      // Use tryFind to look for an unregistered object
      final result = Ring.tryFind<TestClass>();
      expect(result, isNull);
    });

    test('throws exception when object with tag not found', () {
      // Register an object with a tag
      final testInstance = TestClass('test');
      Ring.hire(testInstance, tag: 'tag1');

      // Attempt to find an object with the wrong tag
      expect(() => Ring.find<TestClass>('wrongTag'),
          throwsA(isA<CircusRingException>()));
    });
  });

  group('CircusRing advanced functionality tests', () {
    test('hireLazily functionality test', () {
      // Register a lazy-loaded object
      Ring.hireLazily<TestClass>(() => TestClass('lazy'));

      // Verify the object is registered but not yet instantiated
      expect(Ring.isHired<TestClass>(), isTrue);

      // Find the object, which should instantiate it now
      final foundInstance = Ring.find<TestClass>();

      // Verify the found object is correct
      expect(foundInstance, isA<TestClass>());
      expect(foundInstance.value, equals('lazy'));
    });

    test('contract functionality test', () {
      // Register a factory function
      var counter = 0;
      Ring.contract<TestClass>(() => TestClass('factory${counter++}'));

      // Find the object multiple times, should create new instances each time
      final instance1 = Ring.find<TestClass>();
      final instance2 = Ring.find<TestClass>();

      // Verify each found instance is a new one
      expect(instance1.value, equals('factory0'));
      expect(instance2.value, equals('factory1'));
      expect(identical(instance1, instance2), isFalse);
    });

    test('bindDependency functionality test', () {
      // Register interdependent objects
      final testInstance1 = TestClass('test1');
      final testInstance2 = AnotherTestClass(42);

      Ring.hire(testInstance1);
      Ring.hire(testInstance2);

      // Establish dependency relationship
      Ring.bindDependency<TestClass, AnotherTestClass>();

      // Attempt to remove the depended-upon object, should throw an exception
      expect(() => Ring.fire<AnotherTestClass>(),
          throwsA(isA<CircusRingException>()));

      // First remove the dependent, then remove the dependency
      Ring.fire<TestClass>();
      expect(Ring.fire<AnotherTestClass>(), isTrue);
    });
  });
}
