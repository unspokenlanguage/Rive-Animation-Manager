# Rive Animation Manager - Quick Reference (v1.0.10+)

## Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  rive_animation_manager: ^1.0.10
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

### Image Management (v1.0.9+)

#### Type-Safe Image Updates
```dart
// Type 1: Local file path
await controller.updateImageProperty(
  'animationId',
  'propertyName',
  '/path/to/image.png',
);

// Type 2: URL (http/https)
await controller.updateImageProperty(
  'animationId',
  'propertyName',
  'https://example.com/image.png',
);

// Type 3: Raw bytes (Uint8List)
final bytes = await File('path/to/image.png').readAsBytes();
await controller.updateImageProperty(
  'animationId',
  'propertyName',
  bytes,
);

// Type 4: Pre-decoded RenderImage (fastest)
final bytes = await File('path/to/image.png').readAsBytes();
final renderImage = await Factory.rive.decodeImage(bytes);
await controller.updateImageProperty(
  'animationId',
  'propertyName',
  renderImage,
);
```

#### Legacy Image Methods (Still Supported)
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

## File Loading Options (v1.0.10+)

### Asset File (Recommended)
```dart
RiveManager(
  animationId: 'assetAnimation',
  riveFilePath: 'assets/animations/my.riv',
)
```

### External File
```dart
RiveManager(
  animationId: 'externalAnimation',
  externalFile: File('/path/to/animation.riv'),
)
```

### FileLoader (Custom Loading - NEW in v1.0.10!)
```dart
RiveManager(
  animationId: 'customAnimation',
  fileLoader: MyCustomFileLoader(),
)
```

**What's New (v1.0.10):** FileLoader now fully works with input discovery, property discovery, and global registration!

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

### onDataBindingChange (v1.0.7+)
Called when data binding property changes.
```dart
onDataBindingChange: (String propertyName, String propertyType, dynamic value) {
  print('$propertyName changed to $value');
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
  List<Map<String, dynamic>> properties = state.properties;
}
```

### Update Nested Properties (v1.0.8+)
```dart
// Using '/' separator (parent/child/grandchild)
await controller.updateNestedProperty(
  'animationId',
  'parent/child',
  newValue,
);

// Recursive discovery works automatically!
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
LogManager.setDebugMode(true);
LogManager.clearLogs();
```

### Get Logs
```dart
// All logs
List<String> allLogs = LogManager.logs;

// Last N logs
List<String> recent = LogManager.getLastLogsAsStrings(10);

// Search logs
List<Map<String, dynamic>> results = LogManager.searchLogs('keyword');

// Export
String asString = LogManager.exportAsString();
String asJson = LogManager.exportAsJSON();
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
| `'viewModel'` | Nested ViewModel (v1.0.8+) |

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

### File Loading (v1.0.10+)
- `riveFilePath: String?` - Asset path (sync)
- `externalFile: File?` - External file (sync)
- `fileLoader: FileLoader?` - Custom loader (async) ← **Now fully supported!**

### Features
- `enableImageReplacement: bool` - Enable dynamic images
- `imageAssetReference: ImageAsset?` - Reference to image

## Best Practices

1. **Use Unique IDs**: Always provide unique animation IDs
2. **Choose Loading Method**: Asset files for bundled, FileLoader for dynamic
3. **Cache Images**: Preload images for frequent updates
4. **Check Nulls**: Always check if state/property exists
5. **Dispose**: Package handles automatic cleanup
6. **Log Issues**: Enable LogManager for debugging
7. **Error Handling**: Check return values of async operations

## Version History

| Version | Release | Key Features |
|---------|---------|--------------|
| 1.0.10  | 2025-11-12 | FileLoader full support ✨ |
| 1.0.9   | 2025-11-11 | Advanced image handling |
| 1.0.8   | 2025-11-04 | Nested properties |
| 1.0.7   | 2025-11-04 | Data binding callbacks |
| 1.0.0   | 2025-11-01 | Initial release |

## Common Errors

### Animation not loading
- ✓ Check file path is correct
- ✓ Enable logging to see errors
- ✓ Verify file exists in assets

### FileLoader animation not accessible (v1.0.10 Fixed!)
- ✓ Now properly registers with controller
- ✓ Use `RiveAnimationController.instance.getAnimationState('animationId')`

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
      onDataBindingChange: (name, type, value) {
        print('Property: $name = $value');
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
