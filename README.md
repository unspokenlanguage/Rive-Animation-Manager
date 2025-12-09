# Rive Animation Manager

A comprehensive Flutter package for managing Rive animations with bidirectional data binding, interactive controls, image replacement, and global state management capabilities.
## What's New in v1.0.16

- Updated to the latest stable Rive runtimes:
   - `rive_native: ^0.1.0`
   - `rive: ^0.14.0`
- Confirmed full compatibility of data binding, image replacement, interactive example, and logging with these versions.


## What's New in v1.0.15

**Enhanced Interactive Example** ✨
- Complete side-by-side responsive layout (desktop/mobile)
- Type-specific interactive controls for all property types
- **Real-time bidirectional updates**: UI ↔ Rive animation
- Automatic ViewModel property discovery and UI generation
- Production-ready example code with comprehensive documentation
- Event logging system for debugging and monitoring

> **See the enhanced example:** Run `dart pub unpack rive_animation_manager` and check the `/example` folder for fully documented, production-ready code demonstrating all features.

## Why This Library Matters

Managing Rive animations in Flutter can be complex when you need to:

- ❌ **Manually track** dozens of state machine inputs across multiple animations
- ❌ **Manually define** every property, input, and callback for each animation instance
- ❌ **Duplicate code** when managing multiple Rive files with similar interactions
- ❌ **Handle image replacements** without built-in caching or optimization
- ❌ **Debug issues** without visibility into animation state and property values

**This library solves all of this with:**

✅ **Global Controller** - One centralized singleton manages all animations app-wide  
✅ **Automatic Discovery** - ViewModel properties are automatically detected and exposed  
✅ **Type-Safe Updates** - Update any property (string, number, boolean, color, trigger) with one method  
✅ **Animation ID System** - Unique IDs let you control multiple `.riv` files independently  
✅ **Built-in Caching** - Image and property path caching for optimal performance  
✅ **Comprehensive Logging** - Debug with full visibility into all animation interactions

### The Power of `animationId`

The `animationId` is the **key differentiator** that makes this library powerful for complex apps:

```dart
// ✅ Load multiple animations independently
RiveManager(
  animationId: 'heroAnimation',      // Unique ID
  riveFilePath: 'assets/hero.riv',
)

RiveManager(
  animationId: 'backgroundAnimation', // Different ID
  riveFilePath: 'assets/background.riv',
)

// ✅ Control them independently from anywhere
final controller = RiveAnimationController.instance;

// Update hero animation
await controller.updateDataBindingProperty('heroAnimation', 'progress', 0.75);

// Update background animation
await controller.updateDataBindingProperty('backgroundAnimation', 'opacity', 0.5);
```

**Without this library**, you'd need to:
- Store separate references to each animation's state
- Manually expose each property update method
- Track all state machine inputs yourself
- Handle image replacements manually for each instance

**With this library**, you get:
- One global controller for all animations
- Access any animation by its ID from anywhere
- Automatic property discovery and type handling
- Built-in caching and optimization

## Features

- **Global Animation Controller**: Centralized singleton for managing all Rive animations across your app
- **State Machine Management**: Handle inputs (triggers, booleans, numbers) and state transitions
- **Data Binding Support**: Full support for ViewModels with automatic property discovery
- **Interactive Controls**: Automatic generation of type-specific UI controls (string, number, boolean, color, trigger, enum)
- **Bidirectional Updates**: Real-time sync between UI controls and animation properties
- **Flexible Color Support**: 8 color formats with automatic detection (hex, RGB, Maps, Lists, named colors)
- **Image Replacement**: Dynamically update images from assets, URLs, or raw bytes
- **Image Caching**: Preload and cache images for instant switching without decode overhead
- **Text Run Management**: Update and retrieve text values from animations
- **Input Callbacks**: Real-time callbacks for input changes, triggers, and hover actions
- **Event Handling**: Listen to Rive events with state context
- **Property Caching**: Optimized nested property path caching for performance
- **Responsive Layouts**: Automatic layout adaptation for desktop and mobile screens
- **Comprehensive Logging**: Debug logging with configurable log manager

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rive_animation_manager: ^1.0.16
```

Then run:

```bash
flutter pub get
```

## Getting Started Locally

To unpack the package source code and run the enhanced interactive example:

```bash
# Unpack the package source code and example app
dart pub unpack rive_animation_manager

# Navigate to the example folder
cd rive_animation_manager/example

# Create the platform folders (if not already created)
flutter create .

# Fetch dependencies
flutter pub get

# Run the example app
flutter run
```

This will launch the interactive example showcasing:
- **Desktop View**: Side-by-side layout with Rive animation on left and controls on right
- **Mobile View**: Stacked layout optimized for smaller screens
- **Property Controls**: Auto-generated controls based on your Rive file's ViewModel properties
- **Event Logging**: Real-time event tracking and debugging

## Quick Start

### Basic Usage

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';

RiveManager(
  animationId: 'myAnimation',  // 🔑 Unique ID to control this animation
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
RiveAnimationController controller = RiveAnimationController.instance;

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

### Color Property Updates (v1.0.11+)

Update colors with 8 different formats - all automatically detected!

```dart
final controller = RiveAnimationController.instance;

// Hex format
await controller.updateDataBindingProperty('myAnimation', 'color', '#3EC293');

// RGB/RGBA strings
await controller.updateDataBindingProperty('myAnimation', 'color', 'rgb(62, 194, 147)');
await controller.updateDataBindingProperty('myAnimation', 'color', 'rgba(62, 194, 147, 0.8)');

// Flutter Color objects
await controller.updateDataBindingProperty('myAnimation', 'color', Colors.teal);
await controller.updateDataBindingProperty('myAnimation', 'color', Color(0xFF3EC293));

// Maps (standard 0-255)
await controller.updateDataBindingProperty('myAnimation', 'color', {'r': 62, 'g': 194, 'b': 147});

// Maps (Rive normalized 0.0-1.0) - Auto-detected!
await controller.updateDataBindingProperty('myAnimation', 'color', {'r': 0.2431, 'g': 0.7608, 'b': 0.5764});

// Lists (standard 0-255)
await controller.updateDataBindingProperty('myAnimation', 'color', [62, 194, 147]);

// Lists (Rive normalized 0.0-1.0) - Auto-detected!
await controller.updateDataBindingProperty('myAnimation', 'color', [0.2431, 0.7608, 0.5764]);

// Named colors
await controller.updateDataBindingProperty('myAnimation', 'color', 'teal');
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

Add and retrieve logs for debugging:

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';

// Add a single log
LogManager.addLog('Animation loaded successfully');

// Add a log with error flag
LogManager.addLog('Failed to load animation', isExpected: false);

// Get all logs as strings
List<String> allLogs = LogManager.logs;

// Get last N logs
final recentLogs = LogManager.getLastLogsAsStrings(10);

// Search logs by keyword
List<Map<String, dynamic>> results = LogManager.searchLogs('animation');
for (var log in results) {
  print('${log['timestamp']}: ${log['message']}');
}

// Export logs as JSON
String json = LogManager.exportAsJSON();
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
- `animationId` - **Unique identifier** for this animation instance (enables global control)
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

## Support

For issues, feature requests, or questions:

- **GitHub Repository:** [https://github.com/unspokenlanguage/RiveAnimation-Manager](https://github.com/unspokenlanguage/RiveAnimation-Manager)
- **GitHub Issues:** [https://github.com/unspokenlanguage/RiveAnimation-Manager/issues](https://github.com/unspokenlanguage/RiveAnimation-Manager/issues)
- **pub.dev:** [https://pub.dev/packages/rive_animation_manager](https://pub.dev/packages/rive_animation_manager)

### Getting Help

1. **Check existing issues:** Search GitHub issues first
2. **Review documentation:** See README.md, EXAMPLES.md, and QUICK_REFERENCE.md in the repository
3. **Run the example:** Use `dart pub unpack rive_animation_manager` to explore the fully documented example
4. **Create new issue:** If not found, create a detailed issue with:
   - Flutter version (`flutter --version`)
   - Package version
   - Error logs or stack trace
   - Minimal reproducible example (MRE)

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with clear commit messages
4. Add tests for new functionality
5. Update documentation as needed
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request with detailed description

## Requirements

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- rive_native package dependency

## License

This package is licensed under the MIT License. See LICENSE file for details.

## Changelog

### v1.0.15 (Current)
- **Enhanced Interactive Example** with side-by-side responsive layout
- **Automatic UI control generation** from ViewModel properties
- **Bidirectional data binding** demonstrations
- **Type-specific controls** for string, number, boolean, color, trigger, and enum properties
- **Comprehensive documentation** in example code
- Added "Getting Started Locally" section to README
- Added "Why This Library Matters" section explaining benefits over manual implementation
- Clarified `animationId` role and importance for multi-animation management


---

**Made with ❤️ for the Flutter community**
