# Rive Animation Manager

A comprehensive Flutter package for managing Rive animations with data binding, image replacement, and global state management capabilities.

## Features

- **Global Animation Controller**: Centralized singleton for managing all Rive animations across your app
- **State Machine Management**: Handle inputs (triggers, booleans, numbers) and state transitions
- **Data Binding Support**: Full support for ViewModels with automatic property discovery
- **Flexible Color Support**: 8 color formats with automatic detection (hex, RGB, Maps, Lists, named colors)
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
  rive_animation_manager: ^1.0.12
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

## Logging - Corrected Section for QUICK_REFERENCE.md

## Logging (Corrected)

### Add Logs

```dart
import 'package:rive_animation_manager/rive_animation_manager.dart';

// Add a single log
LogManager.addLog('Animation loaded successfully');

// Add a log with error flag
LogManager.addLog('Failed to load animation', isExpected: false);

// Add multiple logs at once
LogManager.addMultipleLogs([
  'Log 1',
  'Log 2',
  'Log 3',
]);
```

### Retrieve Logs

```dart
// Get all logs as strings
List<String> allLogs = LogManager.logs;

// Get last N logs
final recentLogs = LogManager.getLastLogsAsStrings(10);
for (var log in recentLogs) {
  print(log);
}

// Get log counts
int totalLogs = LogManager.logCount;
int errorLogs = LogManager.errorCount;
int infoLogs = LogManager.infoCount;
```

### Filter & Search Logs

```dart
// Get only error logs
List<Map<String, dynamic>> errors = LogManager.getLogsByType(false);

// Get only info logs
List<Map<String, dynamic>> infos = LogManager.getLogsByType(true);

// Search logs by keyword
List<Map<String, dynamic>> results = LogManager.searchLogs('animation');
for (var log in results) {
  print('${log['timestamp']}: ${log['message']}');
}
```

### Export Logs

```dart
// Export all logs as formatted string
String formatted = LogManager.exportAsString();
print(formatted);

// Export all logs as JSON
String json = LogManager.exportAsJSON();
print(json);
```

### Clear Logs

```dart
// Clear all logs
LogManager.clearLogs();
```

### Reactive UI Updates

```dart
// Listen to log changes
LogManager.logMessages.addListener(() {
  print('Logs updated!');
});

// Use in ValueListenableBuilder for real-time UI updates
ValueListenableBuilder<List<Map<String, dynamic>>>(
  valueListenable: LogManager.logMessages,
  builder: (context, logs, _) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isError = log['type'] == 'error';
        
        return ListTile(
          leading: Icon(
            isError ? Icons.error : Icons.info,
            color: isError ? Colors.red : Colors.blue,
          ),
          title: Text(log['message']),
          subtitle: Text(log['timestamp']),
          trailing: Text(log['type']),
        );
      },
    );
  },
);
```

## Log Entry Structure

Each log is stored as a `Map<String, dynamic>` with the following structure:

```dart
{
  'message': 'The log message',    // String
  'text': 'The log message',       // String (same as message)
  'timestamp': '14:32:45',         // String in HH:MM:SS format
  'type': 'info',                  // String: 'info' or 'error'
  'isExpected': true,              // bool: true = info, false = error
}
```

## Complete LogManager API

### Methods

| Method | Purpose | Example |
|--------|---------|---------|
| `addLog()` | Add single log | `LogManager.addLog('message')` |
| `addMultipleLogs()` | Add multiple logs | `LogManager.addMultipleLogs(['log1', 'log2'])` |
| `clearLogs()` | Clear all logs | `LogManager.clearLogs()` |
| `getLastLogsAsStrings()` | Get last N logs | `LogManager.getLastLogsAsStrings(10)` |
| `getLogsByType()` | Filter by type | `LogManager.getLogsByType(true)` |
| `searchLogs()` | Search logs | `LogManager.searchLogs('keyword')` |
| `exportAsString()` | Export formatted | `LogManager.exportAsString()` |
| `exportAsJSON()` | Export as JSON | `LogManager.exportAsJSON()` |
| `dispose()` | Cleanup | `LogManager.dispose()` |

### Properties

| Property | Type | Purpose |
|----------|------|---------|
| `logs` | `List<String>` | All logs as strings |
| `logCount` | `int` | Total number of logs |
| `errorCount` | `int` | Number of error logs |
| `infoCount` | `int` | Number of info logs |
| `logMessages` | `ValueNotifier<List<Map>>` | For reactive UI updates |
| `mounted` | `bool` | Check if widget binding available |

## Logging Levels

LogManager uses a simple two-level logging system:

```dart
// Info level (default)
LogManager.addLog('Animation loaded', isExpected: true);  // ✅ Info

// Error level
LogManager.addLog('Failed to load', isExpected: false);   // ❌ Error
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

For issues, feature requests, or questions:

- **GitHub Repository:** https://github.com/unspokenlanguage/RiveAnimation-Manager
- **GitHub Issues:** https://github.com/unspokenlanguage/RiveAnimation-Manager/issues
- **pub.dev:** https://pub.dev/packages/rive_animation_manager

### Getting Help

1. **Check existing issues:** Search GitHub issues first
2. **Review documentation:** See README.md and EXAMPLES.md in the repository
3. **Create new issue:** If not found, create a detailed issue with:
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

## License

This package is licensed under the MIT License. See LICENSE file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

**Made with ❤️ for the Flutter community**
