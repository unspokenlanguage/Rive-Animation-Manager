# Rive Animation Manager

A comprehensive Flutter package for managing Rive animations with data binding, image replacement, and global state management capabilities.

## Features

- **Global Animation Controller**: Centralized singleton for managing all Rive animations across your app
- **State Machine Management**: Handle inputs (triggers, booleans, numbers) and state transitions
- **Data Binding Support**: Full support for ViewModels with automatic property discovery
- **Image Replacement**: Dynamically update images from assets, URLs, or raw bytes
- **Image Caching**: Preload and cache images for instant switching without decode overhead
- **Text Run Management**: Update and retrieve text values from animations
- **Input Callbacks**: Real-time callbacks for input changes, triggers, and hover actions
- **Event Handling**: Listen to Rive events with state context
- **Property Caching**: Optimized nested property path caching for performance
- **Comprehensive Logging**: Debug logging with configurable log manager

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rive_animation_manager: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';

RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my_animation.riv',
  animationType: RiveAnimationType.stateMachine,
  onInit: (artboard) {
    print('Animation loaded: $artboard');
  },
  onInputChange: (index, name, value) {
    print('Input changed: $name = $value');
  },
)
```

### Controlling Animations

Use the global controller to manipulate animations:

```dart
final controller = RiveAnimationController.instance;

// Update boolean input
controller.updateBool('myAnimation', 'isHovered', true);

// Update number input
controller.updateNumber('myAnimation', 'scrollPosition', 0.5);

// Trigger an input
controller.triggerInput('myAnimation', 'playAnimation');

// Update text
controller.setTextRunValue('myAnimation', 'myText', 'Hello World');

// Get current values
final value = controller.getDataBindingPropertyValue('myAnimation', 'propertyName');
```

### Data Binding

Discover and update data binding properties:

```dart
RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my_animation.riv',
  onViewModelPropertiesDiscovered: (properties) {
    for (var prop in properties) {
      print('Property: ${prop['name']} (${prop['type']})');
    }
  },
  onDataBindingChange: (propertyName, propertyType, value) {
    print('Property changed: $propertyName = $value');
  },
)
```

Update data binding properties:

```dart
final controller = RiveAnimationController.instance;

// Update various property types
await controller.updateDataBindingProperty('myAnimation', 'text', 'New Text');
await controller.updateDataBindingProperty('myAnimation', 'count', 42);
await controller.updateDataBindingProperty('myAnimation', 'isVisible', true);
await controller.updateDataBindingProperty('myAnimation', 'color', Color(0xFF00FF00));
```

### Image Replacement

Enable image replacement for dynamic image updates:

```dart
RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my_animation.riv',
  enableImageReplacement: true,
)
```

Update images programmatically:

```dart
final controller = RiveAnimationController.instance;
final state = controller.getAnimationState('myAnimation');

if (state != null) {
  // Update from asset
  await state.updateImageFromAsset('assets/images/new_image.png');
  
  // Update from URL
  await state.updateImageFromUrl('https://example.com/image.png');
  
  // Update from bytes
  await state.updateImageFromBytes(imageBytes);
  
  // Update from pre-decoded RenderImage (fastest)
  state.updateImageFromRenderedImage(renderImage);
}
```

### Image Caching

Preload images for instant switching:

```dart
final controller = RiveAnimationController.instance;

await controller.preloadImagesForAnimation(
  'myAnimation',
  [
    'https://example.com/image1.png',
    'https://example.com/image2.png',
    'https://example.com/image3.png',
  ],
  Factory.rive,
);

// Switch to cached image instantly
controller.updateImageFromCache('myAnimation', 0);
```

### Input Handling

Handle different input types:

```dart
RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my_animation.riv',
  onInputChange: (index, inputName, value) {
    print('Input changed: $inputName = $value');
  },
  onTriggerAction: (triggerName, value) {
    print('Trigger fired: $triggerName');
  },
  onHoverAction: (hoverName, value) {
    print('Hover state: $hoverName = $value');
  },
)
```

### Event Handling

Listen to Rive events:

```dart
RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my_animation.riv',
  onEventChange: (eventName, event, currentState) {
    print('Event: $eventName in state: $currentState');
  },
)
```

## Advanced Features

### Nested Property Updates

Update nested properties using path notation:

```dart
final controller = RiveAnimationController.instance;

// Using '/' separator
await controller.updateNestedProperty(
  'myAnimation',
  'parent/child',
  'newValue',
);

// Using '.' separator
await controller.updateNestedProperty(
  'myAnimation',
  'parent.child',
  'newValue',
);
```

### Cache Statistics

Monitor animation manager cache usage:

```dart
final controller = RiveAnimationController.instance;
final stats = controller.getCacheStats();

print('Active animations: ${stats['animations']}');
print('Cached images: ${stats['totalCachedImages']}');
print('Cached property paths: ${stats['totalCachedPropertyPaths']}');
```

### Logging

Configure logging behavior:

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';

// Enable/disable logging
LogManager.enabled = true;

// Clear logs
LogManager.clearLogs();

// Get last N logs
final recentLogs = LogManager.getLastLogs(10);
for (var log in recentLogs) {
  print(log);
}
```

## API Reference

### RiveAnimationController

Global singleton for managing all Rive animations.

**Key Methods:**
- `register(String id, RiveManagerState state)` - Register an animation
- `updateBool(String id, String name, bool value)` - Update boolean input
- `updateNumber(String id, String name, double value)` - Update number input
- `triggerInput(String id, String name)` - Fire a trigger
- `setTextRunValue(String id, String textRunName, String value)` - Update text
- `updateDataBindingProperty(String id, String name, dynamic value)` - Update data binding property
- `updateNestedProperty(String id, String path, dynamic value)` - Update nested property
- `preloadImagesForAnimation(String id, List<String> urls, Factory factory)` - Cache images
- `updateImageFromCache(String id, int index)` - Use cached image
- `getCacheStats()` - Get cache statistics

### RiveManager Widget

Flutter widget for displaying Rive animations.

**Constructor Parameters:**
- `animationId` - Unique identifier for this animation instance
- `riveFilePath` - Path to .riv file in assets
- `externalFile` - External Rive file (alternative to riveFilePath)
- `fileLoader` - Custom file loader
- `enableImageReplacement` - Enable dynamic image updates
- Various display properties: `fit`, `alignment`, `hitTestBehavior`, etc.

**Callbacks:**
- `onInit` - Called when animation is loaded
- `onInputChange` - Called when input value changes
- `onTriggerAction` - Called when trigger fires
- `onViewModelPropertiesDiscovered` - Called when data binding properties found
- `onDataBindingChange` - Called when data binding property changes

## Best Practices

1. **Use Unique Animation IDs**: Always provide unique identifiers for each animation instance
2. **Cache Images**: For animations with many image updates, preload and cache images
3. **Handle Errors**: Check return values and use logging to debug issues
4. **Dispose Properly**: The package handles cleanup automatically in dispose()
5. **Nested Properties**: Use path caching for frequently updated nested properties
6. **Enable Logging in Debug**: Use LogManager to debug issues during development

## Troubleshooting

**Animation not loading?**
- Check file path is correct
- Enable logging: `LogManager.enabled = true`
- Check logs for specific error messages

**Image replacement not working?**
- Ensure `enableImageReplacement: true` is set
- Check that animation actually has image assets
- Verify image format is supported (PNG, JPEG, etc.)

**Performance issues?**
- Use image caching for frequent updates
- Enable property path caching (automatic)
- Monitor cache stats with `getCacheStats()`

## License

This package is licensed under the MIT License. See LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues, feature requests, or questions, please open an issue on GitHub.
