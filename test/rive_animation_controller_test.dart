// RiveAnimationController's pure parts, which run without a GPU or a .riv:
// colour parsing and the registry's ownership. Each test names a defect fixed
// in 1.0.27, so it fails on 1.0.26.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_animation_manager/rive_animation_manager.dart';

void main() {
  final controller = RiveAnimationController.instance;

  group('colour parsing', () {
    test('the formats it documents give the colour', () {
      expect(controller.debugParseColor('#FF0000'), const Color(0xFFFF0000));
      expect(controller.debugParseColor('#80FF0000'), const Color(0x80FF0000));
      expect(controller.debugParseColor('#f00'), const Color(0xFFFF0000));
      expect(controller.debugParseColor('rgb(0, 128, 255)'),
          const Color.fromARGB(255, 0, 128, 255));
      expect(controller.debugParseColor([0, 128, 255]),
          const Color.fromARGB(255, 0, 128, 255));
      expect(controller.debugParseColor(0xFF112233), const Color(0xFF112233));
      expect(controller.debugParseColor('black'), Colors.black);
    });

    test('a 0-255 map without alpha is opaque, not 1/255', () {
      final c = controller.debugParseColor({'r': 255, 'g': 0, 'b': 0})!;
      expect((c.a * 255).round(), 255);
      expect((c.r * 255).round(), 255);
    });

    test('a 0.0-1.0 map without alpha is opaque too', () {
      final c = controller.debugParseColor({'r': 1.0, 'g': 0.5, 'b': 0.0})!;
      expect((c.a * 255).round(), 255);
    });

    test('what is not a colour is nothing, not white', () {
      for (final bad in <dynamic>[
        '#GGHHII',
        '#12345',
        'rgb(1, 2)',
        'not-a-colour',
        [1, 2],
        true,
        null,
      ]) {
        expect(controller.debugParseColor(bad), isNull, reason: '$bad');
      }
    });
  });

  group('the registry', () {
    RiveManagerState stateFor(String id) =>
        const RiveManager(animationId: 'unused').createState()
            as RiveManagerState;

    test('an old mount deregistering keeps the newer one', () {
      const id = 'registry_test_a';
      final older = stateFor(id);
      final newer = stateFor(id);
      controller.register(id, older);
      controller.register(id, newer);
      controller.deregister(id, owner: older);
      expect(identical(controller.getAnimationState(id), newer), isTrue);
      controller.deregister(id, owner: newer);
      expect(controller.getAnimationState(id), isNull);
    });

    test('deregistering without an owner still removes the id', () {
      const id = 'registry_test_b';
      controller.register(id, stateFor(id));
      controller.deregister(id);
      expect(controller.getAnimationState(id), isNull);
    });
  });
}
