# Rive Animation Manager - Quick Reference

## Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  rive_animation_manager: ^1.0.0
```

## Basic Import

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';
```

## Core Classes

### 1. RiveManager (Widget)
Main widget for displaying Rive animations.

```dart
RiveManager(
  animationId: 'myAnimation',              // Unique ID
  riveFilePath: 'assets/animations/my.riv', // Asset path
  animationType: RiveAnimationType.stateMachine,
  onInit: (artboard) { },
  onInputChange: (index, name, value) { },
)
```

### 2. RiveAnimationController (Singleton)
Global controller for managing animations.

```dart
final controller = RiveAnimationController.instance;
```

## Common Operations

### Input Control
```dart
// Boolean input
controller.updateBool('animationId', 'inputName', true);

// Number input
controller.updateNumber('animationId', 'inputName', 0.5);

// Trigger input
controller.triggerInput('animationId', 'triggerName');
```

### Text Management
```dart
// Set text
controller.setTextRunValue('animationId', 'textName', 'Hello');

// Get text
String? text = controller.getTextRunValue('animationId', 'textName');
```

### Data Binding
```dart
// Update property
await controller.updateDataBindingProperty(
  'animationId',
  'propertyName',
  newValue,
);

// Get property value
dynamic value = controller.getDataBindingPropertyValue(
  'animationId',
  'propertyName',
);
```

### Image Management
```dart
// From asset
await state.updateImageFromAsset('assets/images/image.png');

// From URL
await state.updateImageFromUrl('https://example.com/image.png');

// From bytes
await state.updateImageFromBytes(bytes);

// From RenderImage (fastest)
state.updateImageFromRenderedImage(renderImage);
```

### Image Caching
```dart
// Preload images
await controller.preloadImagesForAnimation(
  'animationId',
  ['url1', 'url2', 'url3'],
  Factory.rive,
);

// Switch to cached image
controller.updateImageFromCache('animationId', 0);
```

## Callbacks

### onInit
Called when animation is loaded.
```dart
onInit: (Artboard artboard) {
  print('Ready!');
}
```

### onInputChange
Called when input value changes.
```dart
onInputChange: (int index, String name, dynamic value) {
  print('$name = $value');
}
```

### onTriggerAction
Called when trigger fires.
```dart
onTriggerAction: (String name, dynamic value) {
  print('Triggered: $name');
}
```

### onHoverAction
Called for boolean hover states.
```dart
onHoverAction: (String name, dynamic value) {
  print('Hover: $name');
}
```

### onViewModelPropertiesDiscovered
Called when data binding properties found.
```dart
onViewModelPropertiesDiscovered: (List<Map<String, dynamic>> props) {
  print('Found ${props.length} properties');
}
```

### onEventChange
Called when Rive event fires.
```dart
onEventChange: (String eventName, Event event, String currentState) {
  print('Event: $eventName in state: $currentState');
}
```

## Advanced Operations

### Get Animation State
```dart
RiveManagerState? state = controller.getAnimationState('animationId');
if (state != null) {
  List<Map> artboards = state.getArtboards();
  Map<String, Input> inputs = state.inputs;
}
```

### Update Nested Properties
```dart
// Using '/' separator
await controller.updateNestedProperty(
  'animationId',
  'parent/child',
  newValue,
);

// Using '.' separator
await controller.updateNestedProperty(
  'animationId',
  'parent.child',
  newValue,
);
```

### Cache Statistics
```dart
Map<String, dynamic> stats = controller.getCacheStats();
print('Animations: ${stats['animations']}');
print('Cached images: ${stats['totalCachedImages']}');
print('Cached paths: ${stats['totalCachedPropertyPaths']}');
```

### Clear Caches
```dart
// Clear one animation's property cache
controller.clearPropertyCache('animationId');

// Clear all caches
controller.clearAllPropertyCaches();
```

## Logging

### Configure
```dart
LogManager.enabled = true;  // Enable/disable
LogManager.clearLogs();     // Clear all logs
```

### Get Logs
```dart
// All logs
List<String> allLogs = LogManager.logs;

// Last N logs
List<String> recent = LogManager.getLastLogs(10);

for (var log in recent) {
  print(log);
}
```

## Property Types

Supported data binding property types:

| Type | Description |
|------|-------------|
| `'string'` | Text value |
| `'number'` | Numeric value |
| `'boolean'` | True/false value |
| `'color'` | Color value |
| `'image'` | Image asset |
| `'enumType'` | Enum selection |
| `'trigger'` | Action trigger |

## Animation Types

```dart
enum RiveAnimationType {
  oneShot,        // Single animation, plays once
  stateMachine,   // State machine with inputs
}
```

## Widget Properties

### Display
- `fit: Fit` - Image fit (default: contain)
- `alignment: Alignment` - Alignment (default: center)
- `hitTestBehavior: RiveHitTestBehavior` - Hit test behavior
- `cursor: MouseCursor` - Mouse cursor style
- `layoutScaleFactor: double` - Scale factor

### File Loading
- `riveFilePath: String?` - Asset path
- `externalFile: File?` - External file
- `fileLoader: FileLoader?` - Custom loader

### Features
- `enableImageReplacement: bool` - Enable dynamic images
- `imageAssetReference: ImageAsset?` - Reference to image

## Best Practices

1. **Use Unique IDs**: Always provide unique animation IDs
2. **Cache Images**: Preload images for frequent updates
3. **Check Nulls**: Always check if state/property exists
4. **Dispose**: Package handles automatic cleanup
5. **Log Issues**: Enable LogManager for debugging
6. **Error Handling**: Check return values of async operations

## Common Errors

### Animation not loading
- ✓ Check file path is correct
- ✓ Enable logging to see errors
- ✓ Verify file exists in assets

### Image replacement not working
- ✓ Set `enableImageReplacement: true`
- ✓ Verify animation has image assets
- ✓ Check image format support

### Performance issues
- ✓ Use image caching
- ✓ Monitor cache stats
- ✓ Check for memory leaks

## Example: Complete Integration

```dart
class MyAnimationWidget extends StatefulWidget {
  @override
  State<MyAnimationWidget> createState() => _MyAnimationWidgetState();
}

class _MyAnimationWidgetState extends State<MyAnimationWidget> {
  final controller = RiveAnimationController.instance;

  @override
  Widget build(BuildContext context) {
    return RiveManager(
      animationId: 'myApp',
      riveFilePath: 'assets/animations/app.riv',
      enableImageReplacement: true,
      onInit: (artboard) {
        print('Animation ready');
      },
      onInputChange: (index, name, value) {
        print('Input: $name = $value');
      },
      onViewModelPropertiesDiscovered: (props) {
        for (var prop in props) {
          print('Property: ${prop['name']}');
        }
      },
    );
  }

  void updateAnimation() {
    controller.updateBool('myApp', 'isActive', true);
    controller.updateNumber('myApp', 'progress', 0.7);
  }

  @override
  void dispose() {
    // Automatic cleanup by RiveManager
    super.dispose();
  }
}
```

---

For more details, see README.md and EXAMPLES.md
