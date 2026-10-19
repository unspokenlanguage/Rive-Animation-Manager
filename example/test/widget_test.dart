// The example app needs a GPU to draw a .riv, so this checks only what runs
// without one: the package's public API is reachable from the example, and an
// unknown animation id is refused rather than crashing. (It was Flutter's
// stock counter test, which this app has no counter for.)

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_animation_manager/rive_animation_manager.dart';

void main() {
  test('an unknown animation id is refused, not a crash', () async {
    final controller = RiveAnimationController.instance;
    expect(controller.getAnimationState('no-such-animation'), isNull);
    expect(
      await controller.updateDataBindingProperty(
          'no-such-animation', 'name', 'value'),
      isFalse,
    );
    expect(controller.removeListItemAt('no-such-animation', 'items', 0),
        isFalse);
  });
}
