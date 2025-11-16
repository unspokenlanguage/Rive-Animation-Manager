# Rive Animation Manager - Quick Reference (v1.0.11+)

## Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  rive_animation_manager: ^1.0.11
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

### Color Property Updates (v1.0.11+)

#### ✨ NEW: Flexible Multi-Format Color Support

```dart
final controller = RiveAnimationController.instance;

// Format 1: Hex string
await controller.updateDataBindingProperty('myAnimation', 'color', '#3EC293');
await controller.updateDataBindingProperty('myAnimation', 'color', '#06B6D4');
await controller.updateDataBindingProperty('myAnimation', 'color', '0xFF00FF00');

// Format 2: RGB/RGBA string
await controller.updateDataBindingProperty('myAnimation', 'color', 'rgb(62, 194, 147)');
await controller.updateDataBindingProperty('myAnimation', 'color', 'rgba(62, 194, 147, 1.0)');

// Format 3: Flutter Color object
await controller.updateDataBindingProperty('myAnimation', 'color', Color(0xFF00FF00));
await controller.updateDataBindingProperty('myAnimation', 'color', Colors.red);
await controller.updateDataBindingProperty('myAnimation', 'color', Color.fromARGB(255, 62, 194, 147));

// Format 4: Map (Standard 0-255)
await controller.updateDataBindingProperty('myAnimation', 'color', {'r': 62, 'g': 194, 'b': 147});

// Format 5: Map (Rive normalized 0.0-1.0)
await controller.updateDataBindingProperty('myAnimation', 'color', {'r': 0.2431, 'g': 0.7608, 'b': 0.5764});

// Format 6: List (Standard 0-255)
await controller.updateDataBindingProperty('myAnimation', 'color', [62, 194, 147]);
await controller.updateDataBindingProperty('myAnimation', 'color', [62, 194, 147, 255]);

// Format 7: List (Rive normalized 0.0-1.0)
await controller.updateDataBindingProperty('myAnimation', 'color', [0.2431, 0.7608, 0.5764]);
await controller.updateDataBindingProperty('myAnimation', 'color', [0.2431, 0.7608, 0.5764, 1.0]);

// Format 8: Named colors
await controller.updateDataBindingProperty('myAnimation', 'color', 'red');
await controller.updateDataBindingProperty('myAnimation', 'color', 'cyan');
await controller.updateDataBindingProperty('myAnimation', 'color', 'teal');
```

#### Supported Color Formats

| Format | Example | Notes |
|--------|---------|-------|
| Hex | `'#3EC293'` | 3, 6, or 8 digit hex |
| RGB | `'rgb(62, 194, 147)'` | Standard RGB string |
| RGBA | `'rgba(62, 194, 147, 1.0)'` | With alpha (0-1 or 0-255) |
| Color | `Color(0xFF00FF00)` | Flutter Color object |
| Map (Standard) | `{'r': 62, 'g': 194, 'b': 147}` | 0-255 values |
| Map (Normalized) | `{'r': 0.2431, 'g': 0.7608, 'b': 0.5764}` | 0.0-1.0 (Rive) |
| List (Standard) | `[62, 194, 147]` | 0-255 values |
| List (Normalized) | `[0.2431, 0.7608, 0.5764]` | 0.0-1.0 (Rive) |
| Named | `'red'`, `'blue'`, `'cyan'` | 17+ named colors |

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

### FileLoader (Custom Loading)
```dart
RiveManager(
  animationId: 'customAnimation',
  fileLoader: MyCustomFileLoader(),
)
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

### Update Nested Properties (v1.0.8+)
```dart
// Using '/' separator
await controller.updateNestedProperty(
  'animationId',
  'parent/child',
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

## Logging

### Add Logs
```dart
// Add single log
LogManager.addLog('Animation loaded');

// Add log with error flag
LogManager.addLog('Error occurred', isExpected: false);

// Add multiple logs
LogManager.addMultipleLogs(['Log 1', 'Log 2', 'Log 3']);
```

### Retrieve Logs
```dart
// All logs as strings
List<String> allLogs = LogManager.logs;

// Last N logs
List<String> recent = LogManager.getLastLogsAsStrings(10);

// Search logs
List<Map<String, dynamic>> results = LogManager.searchLogs('keyword');

// Log counts
int total = LogManager.logCount;
int errors = LogManager.errorCount;
int infos = LogManager.infoCount;
```

### Export Logs
```dart
// As formatted string
String formatted = LogManager.exportAsString();

// As JSON
String json = LogManager.exportAsJSON();
```

### Clear Logs
```dart
LogManager.clearLogs();
```

## Property Types

Supported data binding property types:

| Type | Description |
|------|-------------|
| `'string'` | Text value |
| `'number'` | Numeric value |
| `'boolean'` | True/false value |
| `'color'` | Color value (v1.0.11+: 8 formats!) |
| `'image'` | Image asset |
| `'enumType'` | Enum selection |
| `'trigger'` | Action trigger |
| `'viewModel'` | Nested ViewModel |

## Version History

| Version | Release | Key Features |
|---------|---------|-----------------|
| 1.0.11  | 2025-11-15 | Flexible color support ✨ |
| 1.0.10  | 2025-11-12 | FileLoader full support |
| 1.0.9   | 2025-11-11 | Advanced image handling |
| 1.0.8   | 2025-11-04 | Nested properties |
| 1.0.7   | 2025-11-04 | Data binding callbacks |
| 1.0.0   | 2025-11-01 | Initial release |

## What's New in v1.0.11

### Flexible Color Property Support

Color properties now support **8 different input formats** with automatic detection:

✅ Hex strings (#RGB, #RRGGBB, #AARRGGBB)  
✅ RGB/RGBA strings (rgb(...), rgba(...))  
✅ Flutter Color objects  
✅ Maps (standard 0-255 OR Rive normalized 0.0-1.0)  
✅ Lists (standard 0-255 OR Rive normalized 0.0-1.0)  
✅ Named colors (red, blue, cyan, etc.)

**Auto-detection:** The package automatically detects whether you're using standard (0-255) or normalized (0.0-1.0) values!

## Best Practices

1. **Use Unique IDs**: Always provide unique animation IDs
2. **Choose Loading Method**: Asset files for bundled, FileLoader for dynamic
3. **Cache Images**: Preload images for frequent updates
4. **Color Flexibility**: Use any color format - automatic conversion! (v1.0.11+)
5. **Check Nulls**: Always check if state/property exists
6. **Dispose**: Package handles automatic cleanup
7. **Log Issues**: Enable LogManager for debugging

---

For more details, see README.md and EXAMPLES.md
