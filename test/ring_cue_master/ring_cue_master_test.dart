import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/src/circus_ring.dart';
import 'package:joker_state/src/event_bus/ring_cue_master/cue_master.dart';
import 'package:joker_state/src/event_bus/ring_cue_master/ring_cue_master.dart';

void main() {
  group('CircusRing & RingCueMaster integration', () {
    late CircusRing circus;

    setUp(() {
      circus = CircusRing();
    });

    tearDown(() {
      circus.fireAll();
    });

    test(
        'ringMaster() creates and returns a RingCueMaster instance with default tag',
        () {
      // First access should create a new instance
      final ringMaster = circus.ringMaster();
      expect(ringMaster, isA<RingCueMaster>());
      expect(circus.isHired<CueMaster>('ringMaster'), isTrue);
    });

    test(
        'ringMaster() returns the same instance on subsequent calls with same tag',
        () {
      final ringMaster1 = circus.ringMaster();
      final ringMaster2 = circus.ringMaster();

      expect(identical(ringMaster1, ringMaster2), isTrue);
    });

    test('ringMaster() can create multiple instances with different tags', () {
      // Create two ring masters with different tags
      final defaultMaster = circus.ringMaster();
      final customMaster = circus.ringMaster('customMaster');

      // Should be different instances
      expect(identical(defaultMaster, customMaster), isFalse);

      // Both should be registered with correct tags
      expect(circus.isHired<CueMaster>('ringMaster'), isTrue);
      expect(circus.isHired<CueMaster>('customMaster'), isTrue);
    });

    test('cue() method works with ringMaster to send events', () async {
      final completer = Completer<String>();

      // Listen for events
      circus.onCue<_TestCue>((cue) => completer.complete(cue.value));

      // Send event via CircusRing extension
      final sent = circus.cue(_TestCue('Hello from CircusRing'));

      // Should return true if there's a listener
      expect(sent, isTrue);

      // Verify the message is received
      final received = await completer.future;
      expect(received, 'Hello from CircusRing');
    });

    test('cue() returns false when there are no listeners', () {
      // Send event with no listeners
      final sent = circus.cue(_TestCue('No listeners'));

      // Should return false
      expect(sent, isFalse);
    });

    test('onCue() subscribes to events correctly', () async {
      final receivedMessages = <String>[];

      // Set up listener
      final subscription = circus.onCue<_TestCue>((cue) {
        receivedMessages.add(cue.value);
      });

      // Send multiple events
      circus.cue(_TestCue('Message 1'));
      circus.cue(_TestCue('Message 2'));

      // Wait for events to process
      await Future.delayed(Duration.zero);

      // Check that messages were received
      expect(receivedMessages, ['Message 1', 'Message 2']);

      // Clean up
      await subscription.cancel();
    });

    test('multiple tags have separate event streams', () async {
      final defaultMessages = <String>[];
      final customMessages = <String>[];

      // Set up listeners on different channels
      final defaultSub = circus.onCue<_TestCue>((cue) {
        defaultMessages.add(cue.value);
      });

      final customSub = circus.onCue<_TestCue>((cue) {
        customMessages.add(cue.value);
      }, 'customMaster');

      // Send events to different channels
      circus.cue(_TestCue('Default channel'));
      circus.cue(_TestCue('Custom channel'), 'customMaster');

      // Wait for events to process
      await Future.delayed(Duration.zero);

      // Verify messages went to correct channels
      expect(defaultMessages, ['Default channel']);
      expect(customMessages, ['Custom channel']);

      // Clean up
      await defaultSub.cancel();
      await customSub.cancel();
    });
  });
}

class _TestCue {
  final String value;

  _TestCue(this.value);
}
