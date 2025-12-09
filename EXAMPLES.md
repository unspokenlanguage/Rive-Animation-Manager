# Rive Animation Manager - Example Usage (v1.0.17)

This file demonstrates complete usage patterns for the Rive Animation Manager package.

---

## Table of Contents

1. [Basic Animation Display](#example-1-basic-animation-display)
2. [Interactive Input Handling](#example-2-interactive-input-handling)
3. [Data Binding Properties](#example-3-data-binding-properties)
4. [Dynamic Image Updates](#example-4-dynamic-image-updates-v109)
5. [Custom File Loading with FileLoader](#example-5-custom-file-loading-with-fileloader-v1010)
6. [Text Updates](#example-6-text-updates)
7. [Event Handling](#example-7-event-handling)
8. [Cache Management](#example-8-cache-management)
9. [Multiple Animations](#example-9-multiple-animations)
10. [Color Property Formats](#example-10-color)
11. [List Properties](#example-11-list-properties-v1017)
12. [Artboard Properties](#example-12-artboard-properties-v1017)
13. [Integer & SymbolListIndex Properties](#example-13-integer--symbollistindex-properties-v1017)
14. [Nested ViewModel Properties](#example-14-nested-viewmodel-properties)
15. [DataBind Strategies](#example-15-databind-strategies-v1017)
16. [Global Controller – Multi-Animation Orchestration](#example-16-global-controller--multi-animation-orchestration)
17. [Log Manager & Debugging](#example-17-log-manager--debugging)
18. [Complete Production Example](#example-18-complete-production-example)
19. [Dynamic Font Replacement](#example-19-dynamic-font-replacement-v1017)
20. [Thumbnail / Snapshot Capture](#example-20-thumbnail--snapshot-capture-v1017)
21. [Headless RenderTexture Mode](#example-21-headless-rendertexture-mode-v1017)

---

## Example 1: Basic Animation Display

```dart
import 'package:flutter/material.dart';
import 'package:rive_animation_manager/rive_animation_manager.dart';

class BasicAnimationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Basic Animation')),
      body: RiveManager(
        animationId: 'basicAnimation',
        riveFilePath: 'assets/animations/basic.riv',
        animationType: RiveAnimationType.stateMachine,
        onInit: (artboard) {
          print('Animation initialized with artboard: ${artboard.name}');
        },
      ),
    );
  }
}
```

## Example 2: Interactive Input Handling

```dart
class InteractiveAnimationScreen extends StatefulWidget {
  @override
  State<InteractiveAnimationScreen> createState() =>
      _InteractiveAnimationScreenState();
}

class _InteractiveAnimationScreenState
    extends State<InteractiveAnimationScreen> {
  final controller = RiveAnimationController.instance;

  void _toggleAnimation() {
    controller.updateBool('interactive', 'isActive', true);
  }

  void _updateProgress(double value) {
    controller.updateNumber('interactive', 'progress', value);
  }

  void _triggerAction() {
    controller.triggerInput('interactive', 'playEffect');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Interactive Animation')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'interactive',
              riveFilePath: 'assets/animations/interactive.riv',
              onInputChange: (index, name, value) {
                print('Input changed: $name = $value');
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _toggleAnimation,
                  child: Text('Toggle'),
                ),
                SizedBox(height: 16),
                Slider(
                  value: 0,
                  onChanged: _updateProgress,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerAction,
                  child: Text('Trigger Action'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Example 3: Data Binding Properties

```dart
class DataBindingScreen extends StatefulWidget {
  @override
  State<DataBindingScreen> createState() => _DataBindingScreenState();
}

class _DataBindingScreenState extends State<DataBindingScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];

  Future<void> _updateProperty(String name, String type, dynamic value) async {
    final success = await controller.updateDataBindingProperty(
      'databinding',
      name,
      value,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property updated: $name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Binding')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'databinding',
              riveFilePath: 'assets/animations/databinding.riv',
              onViewModelPropertiesDiscovered: (discoveredProps) {
                setState(() => properties = discoveredProps);
                // Properties contain: name, type, value, property instance
                for (final prop in discoveredProps) {
                  print('Found: ${prop['name']} (${prop['type']}) = ${prop['value']}');
                }
              },
              onDataBindingChange: (name, type, value) {
                print('Property changed: $name ($type) = $value');
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final prop = properties[index];
                final type = prop['type'] as String;
                return ListTile(
                  title: Text(prop['name']),
                  subtitle: Text('Type: $type | Value: ${prop['value']}'),
                  trailing: _buildQuickAction(prop),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(Map<String, dynamic> prop) {
    final name = prop['name'] as String;
    switch (prop['type']) {
      case 'string':
        return IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _updateProperty(name, 'string', 'Hello!'),
        );
      case 'boolean':
        return Switch(
          value: prop['value'] == true,
          onChanged: (v) => _updateProperty(name, 'boolean', v),
        );
      case 'trigger':
        return IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () => _updateProperty(name, 'trigger', true),
        );
      default:
        return SizedBox.shrink();
    }
  }
}
```

## Example 4: Dynamic Image Updates (v1.0.9+)

### ✨ Type-Safe Image Property Handling

```dart
class ImageReplacementScreen extends StatefulWidget {
  @override
  State<ImageReplacementScreen> createState() =>
      _ImageReplacementScreenState();
}

class _ImageReplacementScreenState extends State<ImageReplacementScreen> {
  final controller = RiveAnimationController.instance;
  int currentImageIndex = 0;
  bool isLoading = false;

  List<String> imageUrls = [
    'https://example.com/image1.png',
    'https://example.com/image2.png',
    'https://example.com/image3.png',
  ];

  /// Update image from local file path
  Future<void> _updateImageFromFile(String filePath) async {
    setState(() => isLoading = true);
    try {
      final success = await controller.updateDataBindingProperty(
        'imageReplacement',
        'displayImage',
        filePath, // Local file path
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image loaded from file')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Update image from URL
  Future<void> _updateImageFromUrl(String url) async {
    setState(() => isLoading = true);
    try {
      final success = await controller.updateImageProperty(
        'imageReplacement',
        'displayImage',
        url, // URL string
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image loaded from URL')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Update image from bytes
  Future<void> _updateImageFromBytes(Uint8List bytes) async {
    setState(() => isLoading = true);
    try {
      final success = await controller.updateImageProperty(
        'imageReplacement',
        'displayImage',
        bytes, // Raw bytes
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image loaded from bytes')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Update image from pre-decoded RenderImage (fastest)
  Future<void> _updateImageFromRenderImage(RenderImage renderImage) async {
    try {
      final success = await controller.updateImageProperty(
        'imageReplacement',
        'displayImage',
        renderImage, // Pre-decoded RenderImage
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image updated (pre-decoded)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Switch between different image sources
  void _switchImageSource() {
    currentImageIndex = (currentImageIndex + 1) % 4;
    switch (currentImageIndex) {
      case 0:
        _updateImageFromUrl(imageUrls[0]);
        break;
      case 1:
        _updateImageFromUrl(imageUrls[1]);
        break;
      case 2:
        _updateImageFromUrl(imageUrls[2]);
        break;
      case 3:
        // Example with file path
        _updateImageFromFile('/path/to/local/image.png');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Replacement (v1.0.9+)')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'imageReplacement',
              riveFilePath: 'assets/animations/image_replacement.riv',
              enableImageReplacement: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (isLoading)
                  CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => _switchImageSource(),
                        child: Text(
                          'Switch Image (${currentImageIndex + 1}/4)',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Supports: URLs, Local Files, Bytes, RenderImage',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Image Property Update Types

```dart
// Type 1: Local file path
await controller.updateDataBindingProperty(
  'animationId',
  'propertyName',
  '/path/to/image.png',
);

// Type 2: URL (http/https)
await controller.updateDataBindingProperty(
  'animationId',
  'propertyName',
  'https://example.com/image.png',
);

// Type 3: Raw bytes (Uint8List)
final bytes = await File('path/to/image.png').readAsBytes();
await controller.updateDataBindingProperty(
  'animationId',
  'propertyName',
  bytes,
);

// Type 4: Pre-decoded RenderImage (fastest)
final bytes = await File('path/to/image.png').readAsBytes();
final renderImage = await Factory.rive.decodeImage(bytes);
await controller.updateDataBindingProperty(
  'animationId',
  'propertyName',
  renderImage,
);
```

---

## Example 5: Custom File Loading with FileLoader (v1.0.10+)

### ✨ FileLoader Support with Full Initialization

```dart
class FileLoaderExampleScreen extends StatefulWidget {
  @override
  State<FileLoaderExampleScreen> createState() =>
      _FileLoaderExampleScreenState();
}

class _FileLoaderExampleScreenState extends State<FileLoaderExampleScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];
  Map<String, Input> inputs = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FileLoader Animation (v1.0.10+)')),
      body: RiveManager(
        animationId: 'fileLoaded',
        fileLoader: MyCustomFileLoader(), // ✅ Custom loader
        onInit: (artboard) {
          print('FileLoader animation ready!');
        },
        onInputChange: (index, name, value) {
          print('FileLoader input: $name = $value');
        },
        onViewModelPropertiesDiscovered: (discoveredProps) {
          setState(() => properties = discoveredProps);
          print('FileLoader found ${discoveredProps.length} properties');
        },
        onDataBindingChange: (name, type, value) {
          print('FileLoader property $name = $value');
        },
      ),
    );
  }
}

/// Custom FileLoader implementation
class MyCustomFileLoader extends FileLoader {
  @override
  Future<File> load(FileAssetLoader loader) async {
    // Your custom loading logic
    // Could load from database, network, cache, etc.
    final bytes = await _getFileBytes();
    return await loader.load(bytes);
  }

  Future<List<int>> _getFileBytes() async {
    // Example: load from custom source
    return [];
  }
}
```

### What's New in FileLoader Support (v1.0.10)

FileLoader animations now have **complete feature parity** with other loading methods:

✅ **Input Discovery** - All inputs are discovered automatically  
✅ **Property Discovery** - All ViewModel properties are discovered  
✅ **Event Listeners** - Event listeners properly attached  
✅ **Global Registration** - Animation accessible via `RiveAnimationController.instance`  
✅ **All Callbacks** - `onInit`, `onInputChange`, `onDataBindingChange`, `onEventChange` all work

---

## Example 6: Text Updates

```dart
class TextUpdateScreen extends StatefulWidget {
  @override
  State<TextUpdateScreen> createState() => _TextUpdateScreenState();
}

class _TextUpdateScreenState extends State<TextUpdateScreen> {
  final controller = RiveAnimationController.instance;
  final TextEditingController textController = TextEditingController();

  void _updateText() {
    final text = textController.text;
    controller.setTextRunValue('textUpdate', 'displayText', text);
  }

  String? _getText() {
    return controller.getTextRunValue('textUpdate', 'displayText');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Text Updates')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'textUpdate',
              riveFilePath: 'assets/animations/text_update.riv',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Enter text to update',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateText,
                  child: Text('Update Text'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final text = _getText();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Current text: $text')),
                    );
                  },
                  child: Text('Get Text'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
```

## Example 7: Event Handling

```dart
class EventHandlingScreen extends StatefulWidget {
  @override
  State<EventHandlingScreen> createState() => _EventHandlingScreenState();
}

class _EventHandlingScreenState extends State<EventHandlingScreen> {
  List<String> eventLog = [];

  void _addEventLog(String event) {
    setState(() {
      eventLog.insert(0, '[${DateTime.now().toIso8601String()}] $event');
      if (eventLog.length > 20) {
        eventLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event Handling')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: RiveManager(
              animationId: 'eventHandling',
              riveFilePath: 'assets/animations/events.riv',
              onEventChange: (eventName, event, currentState) {
                _addEventLog('Event: $eventName (State: $currentState)');
              },
              onInputChange: (index, name, value) {
                _addEventLog('Input: $name = $value');
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 1,
            child: ListView(
              children: eventLog
                  .map((log) => ListTile(title: Text(log)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Example 8: Cache Management

```dart
class CacheManagementScreen extends StatefulWidget {
  @override
  State<CacheManagementScreen> createState() =>
      _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  final controller = RiveAnimationController.instance;
  Map<String, dynamic> cacheStats = {};

  void _updateStats() {
    setState(() {
      cacheStats = controller.getCacheStats();
    });
  }

  void _clearCache() {
    controller.clearAllPropertyCaches();
    _updateStats();
  }

  @override
  void initState() {
    super.initState();
    _updateStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cache Management')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'cacheManagement',
              riveFilePath: 'assets/animations/cache.riv',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Statistics:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text('Active animations: ${cacheStats['animations'] ?? 0}'),
                Text('Cached images: ${cacheStats['totalCachedImages'] ?? 0}'),
                Text(
                  'Cached property paths: ${cacheStats['totalCachedPropertyPaths'] ?? 0}',
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _updateStats,
                      child: Text('Refresh'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _clearCache,
                      child: Text('Clear Cache'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Example 9: Multiple Animations

```dart
class MultipleAnimationsScreen extends StatelessWidget {
  final controller = RiveAnimationController.instance;

  void _syncAnimations() {
    // The animationId is the key — use it to target any registered animation
    controller.updateBool('animation1', 'isActive', true);
    controller.updateBool('animation2', 'isActive', true);
  }

  void _triggerOnlyFirst() {
    controller.triggerInput('animation1', 'playEffect');
  }

  void _updateSecondColor() {
    controller.updateDataBindingProperty('animation2', 'bgColor', '#FF5722');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Multiple Animations')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'animation1', // ← unique key
              riveFilePath: 'assets/animations/anim1.riv',
            ),
          ),
          Expanded(
            child: RiveManager(
              animationId: 'animation2', // ← unique key
              riveFilePath: 'assets/animations/anim2.riv',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _syncAnimations,
                  child: Text('Sync Both'),
                ),
                ElevatedButton(
                  onPressed: _triggerOnlyFirst,
                  child: Text('Trigger #1 Only'),
                ),
                ElevatedButton(
                  onPressed: _updateSecondColor,
                  child: Text('Color #2'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Example 10: Color

```dart
class ColorPropertiesScreen extends StatefulWidget {
  @override
  State<ColorPropertiesScreen> createState() => _ColorPropertiesScreenState();
}

class _ColorPropertiesScreenState extends State<ColorPropertiesScreen> {
  final controller = RiveAnimationController.instance;
  String currentFormat = 'Hex';
  bool isLoading = false;

  /// Update color using different formats
  Future<void> _updateColorFormat(String format) async {
    setState(() {
      isLoading = true;
      currentFormat = format;
    });

    try {
      bool success = false;

      switch (format) {
        case 'Hex':
        // Format 1: Hex string (#RRGGBB or #AARRGGBB)
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            '#3EC293',  // Teal color
          );
          break;

        case 'Hex Short':
        // Format 1b: Short hex (#RGB → #RRGGBB)
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            '#06B',  // Blue color → #0066BB
          );
          break;

        case 'RGB':
        // Format 2: RGB string
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            'rgb(62, 194, 147)',  // Teal color
          );
          break;

        case 'RGBA':
        // Format 2b: RGBA string with alpha
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            'rgba(62, 194, 147, 0.8)',  // Teal with 80% opacity
          );
          break;

        case 'Color Object':
        // Format 3: Flutter Color object
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            Color(0xFF00FF00),  // Green
          );
          break;

        case 'Color.from':
        // Format 3b: Color.fromARGB
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            Color.fromARGB(255, 62, 194, 147),  // Teal
          );
          break;

        case 'Map Standard':
        // Format 4: Map with standard 0-255 values
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            {'r': 62, 'g': 194, 'b': 147, 'a': 255},
          );
          break;

        case 'Map Normalized':
        // Format 5: Map with Rive normalized 0.0-1.0 values
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            {'r': 0.2431, 'g': 0.7608, 'b': 0.5764, 'a': 1.0},
          );
          break;

        case 'List Standard':
        // Format 6: List with standard 0-255 values
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            [62, 194, 147, 255],
          );
          break;

        case 'List Normalized':
        // Format 7: List with Rive normalized 0.0-1.0 values
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            [0.2431, 0.7608, 0.5764, 1.0],
          );
          break;

        case 'Named Color':
        // Format 8: Named color string
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            'teal',
          );
          break;

        case 'Colors.':
        // Format 8b: Material Colors
          success = await controller.updateDataBindingProperty(
            'colorDemo',
            'bgColor',
            Colors.teal,
          );
          break;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Updated using $format format')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Color Formats (v1.0.11+)')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'colorDemo',
              riveFilePath: 'assets/animations/color_demo.riv',
              onDataBindingChange: (name, type, value) {
                print('Color property $name changed');
              },
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color Format: $currentFormat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 16),
                if (isLoading)
                  Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFormatButton('Hex'),
                      _buildFormatButton('Hex Short'),
                      _buildFormatButton('RGB'),
                      _buildFormatButton('RGBA'),
                      _buildFormatButton('Color Object'),
                      _buildFormatButton('Color.from'),
                      _buildFormatButton('Map Standard'),
                      _buildFormatButton('Map Normalized'),
                      _buildFormatButton('List Standard'),
                      _buildFormatButton('List Normalized'),
                      _buildFormatButton('Named Color'),
                      _buildFormatButton('Colors.'),
                    ],
                  ),
                SizedBox(height: 16),
                Text(
                  '✨ All formats are automatically detected and converted!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton(String format) {
    return ElevatedButton(
      onPressed: () => _updateColorFormat(format),
      style: ElevatedButton.styleFrom(
        backgroundColor: currentFormat == format ? Colors.blue : null,
      ),
      child: Text(format),
    );
  }
}

```

---

## Example 11: List Properties (v1.0.17+)

### ✨ NEW: ViewModel List Discovery & Item Inspection

```dart
class ListPropertyScreen extends StatefulWidget {
  @override
  State<ListPropertyScreen> createState() => _ListPropertyScreenState();
}

class _ListPropertyScreenState extends State<ListPropertyScreen> {
  List<Map<String, dynamic>> properties = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('List Properties (v1.0.17+)')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: RiveManager(
              animationId: 'listDemo',
              riveFilePath: 'assets/animations/listwithViewModal.riv',
              onViewModelPropertiesDiscovered: (discoveredProps) {
                setState(() => properties = discoveredProps);
              },
              onDataBindingChange: (name, type, value) {
                print('Property changed: $name ($type) = $value');
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final prop = properties[index];
                final type = prop['type'] as String;

                if (type == 'list') {
                  return _buildListPropertyCard(prop);
                }

                return ListTile(
                  title: Text(prop['name']),
                  subtitle: Text('$type = ${prop['value']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Display a list property with its items and nested properties
  Widget _buildListPropertyCard(Map<String, dynamic> prop) {
    final listItems = prop['listItems'] as List<Map<String, dynamic>>? ?? [];
    final listLength = prop['value'] ?? 0;

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 ${prop['name']} (List: $listLength items)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            // Display each list item and its properties
            ...listItems.map((item) {
              final itemProps = item['properties'] as List<Map<String, dynamic>>? ?? [];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[${item['index']}] ${item['name']}',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ...itemProps.map((p) => Padding(
                      padding: EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        '${p['name']}: ${p['value']} (${p['type']})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
```

### List Property Data Structure

When a list property is discovered, it provides the following structure:

```dart
{
  'name': 'myList',              // Property name
  'type': 'list',                // Always 'list'
  'value': 3,                    // Number of items in the list
  'property': listProp,          // ViewModelInstanceList instance
  'listItems': [                 // Each item in the list
    {
      'index': 0,                // Item index
      'name': 'ItemViewModel',   // Item ViewModel name
      'properties': [            // Nested properties of this item
        {'name': 'title', 'type': 'string', 'value': 'Item 1', ...},
        {'name': 'count', 'type': 'number', 'value': 42.0, ...},
      ],
    },
    // ... more items
  ],
}
```

> **Note:** List properties are **read-only collections** in the current API. Items are managed via the `ViewModelInstanceList` API (`add`, `remove`, `insert`, `swap`).

---

## Example 12: Artboard Properties (v1.0.17+)

### ✨ NEW: BindableArtboard Support

```dart
class ArtboardPropertyScreen extends StatefulWidget {
  @override
  State<ArtboardPropertyScreen> createState() => _ArtboardPropertyScreenState();
}

class _ArtboardPropertyScreenState extends State<ArtboardPropertyScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];

  /// Update an artboard property with a different artboard from the same file
  Future<void> _switchArtboard(String artboardName) async {
    // Get the animation state to access the file
    final state = controller.getAnimationState('artboardDemo');
    if (state == null) return;

    // Create a BindableArtboard from the file
    final riveFile = state.riveFile;
    if (riveFile == null) return;

    final bindableArtboard = riveFile.artboardToBind(artboardName);
    if (bindableArtboard == null) return;

    // Update the artboard property
    await controller.updateDataBindingProperty(
      'artboardDemo',
      'displayArtboard',
      bindableArtboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Artboard Properties (v1.0.17+)')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'artboardDemo',
              riveFilePath: 'assets/animations/artboards.riv',
              onViewModelPropertiesDiscovered: (discoveredProps) {
                setState(() => properties = discoveredProps);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Switch embedded artboard:'),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _switchArtboard('ArtboardA'),
                      child: Text('Artboard A'),
                    ),
                    ElevatedButton(
                      onPressed: () => _switchArtboard('ArtboardB'),
                      child: Text('Artboard B'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Example 13: Integer & SymbolListIndex Properties (v1.0.17+)

### ✨ NEW: Dedicated Integer Handling

```dart
class IntegerPropertyScreen extends StatefulWidget {
  @override
  State<IntegerPropertyScreen> createState() => _IntegerPropertyScreenState();
}

class _IntegerPropertyScreenState extends State<IntegerPropertyScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Integer Properties (v1.0.17+)')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'integerDemo',
              riveFilePath: 'assets/animations/integers.riv',
              onViewModelPropertiesDiscovered: (props) {
                setState(() => properties = props);
              },
              onDataBindingChange: (name, type, value) {
                // Integer values are always returned as int
                if (type == 'integer') {
                  print('Integer changed: $name = $value (${value.runtimeType})');
                }
                // SymbolListIndex values are also integers
                if (type == 'symbolListIndex') {
                  print('SymbolListIndex changed: $name = $value');
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Update integer properties
                ElevatedButton(
                  onPressed: () {
                    controller.updateDataBindingProperty(
                      'integerDemo',
                      'itemCount',
                      5, // Automatically converted to int
                    );
                  },
                  child: Text('Set Count to 5'),
                ),
                SizedBox(height: 8),
                // Integer vs Number distinction
                Text(
                  'Integer: whole numbers (auto toInt())\n'
                  'Number: floating-point values (double)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Integer vs Number Quick Reference

```dart
// Integer property — value is always int
controller.updateDataBindingProperty('id', 'count', 42);     // ✅ int
controller.updateDataBindingProperty('id', 'count', 42.7);   // ✅ truncated to 42

// Number property — value is always double
controller.updateDataBindingProperty('id', 'progress', 0.75); // ✅ double
controller.updateDataBindingProperty('id', 'progress', 42);   // ✅ becomes 42.0
```

---

## Example 14: Nested ViewModel Properties

### Deep Property Access via Path Notation

```dart
class NestedViewModelScreen extends StatefulWidget {
  @override
  State<NestedViewModelScreen> createState() => _NestedViewModelScreenState();
}

class _NestedViewModelScreenState extends State<NestedViewModelScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nested ViewModels')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'nestedVM',
              riveFilePath: 'assets/animations/nested.riv',
              onViewModelPropertiesDiscovered: (props) {
                setState(() => properties = props);
                // Nested properties are automatically discovered
                for (final prop in props) {
                  if (prop['type'] == 'viewModel') {
                    final nested = prop['nestedProperties'] as List<Map<String, dynamic>>? ?? [];
                    print('Nested ViewModel "${prop['name']}" has ${nested.length} properties');
                    for (final n in nested) {
                      print('  - ${n['fullPath']}: ${n['type']} = ${n['value']}');
                    }
                  }
                }
              },
              onDataBindingChange: (name, type, value) {
                // Nested properties use path notation: "parent/child"
                print('Changed: $name ($type) = $value');
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Update a nested property using path notation
                ElevatedButton(
                  onPressed: () async {
                    await controller.updateNestedProperty(
                      'nestedVM',
                      'settings/theme/primaryColor',
                      Colors.blue,
                    );
                  },
                  child: Text('Update Nested Color'),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await controller.updateNestedProperty(
                      'nestedVM',
                      'settings/showBorder',
                      true,
                    );
                  },
                  child: Text('Toggle Nested Bool'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Nested Property Structure

```dart
// When onViewModelPropertiesDiscovered fires, nested VMs look like:
{
  'name': 'settings',
  'type': 'viewModel',
  'value': null,
  'property': viewModelInstance,
  'nestedProperties': [
    {
      'name': 'theme',
      'fullPath': 'settings/theme',      // ← use this path for updates
      'type': 'string',
      'value': 'dark',
      'property': stringProp,
    },
    {
      'name': 'volume',
      'fullPath': 'settings/volume',
      'type': 'number',
      'value': 0.75,
      'property': numberProp,
    },
    {
      'name': 'colors',                  // Deeply nested ViewModel
      'fullPath': 'settings/colors',
      'type': 'viewModel',
      'nestedProperties': [              // ← recursive!
        {
          'name': 'primary',
          'fullPath': 'settings/colors/primary',
          'type': 'color',
          'value': Color(0xFF2196F3),
        },
      ],
    },
  ],
}
```

---

## Example 15: DataBind Strategies (v1.0.17+)

### ✨ NEW: Choose How ViewModels Are Bound

```dart
// Strategy 1: Auto-discovery (default — same as before v1.0.17)
RiveManager(
  animationId: 'autoDemo',
  riveFilePath: 'assets/animations/demo.riv',
  // dataBind defaults to null → DataBind.auto()
);

// Strategy 2: Bind by ViewModel name
RiveManager(
  animationId: 'namedDemo',
  riveFilePath: 'assets/animations/demo.riv',
  dataBind: DataBind.byName('PlayerViewModel'),
);

// Strategy 3: Bind by ViewModel index
RiveManager(
  animationId: 'indexedDemo',
  riveFilePath: 'assets/animations/demo.riv',
  dataBind: DataBind.byIndex(0),
);

// Strategy 4: No data binding (skip ViewModel discovery)
RiveManager(
  animationId: 'noBind',
  riveFilePath: 'assets/animations/demo.riv',
  dataBind: DataBind.empty(),
);
```

### When to Use Each Strategy

| Strategy | Use Case |
|---|---|
| `DataBind.auto()` | Default — works for most .riv files with a single ViewModel |
| `DataBind.byName('...')` | When your .riv file has multiple ViewModels and you need a specific one |
| `DataBind.byIndex(n)` | When you know the ViewModel position but not its name |
| `DataBind.empty()` | When you only need inputs/triggers, not data binding |

---

## Example 16: Global Controller – Multi-Animation Orchestration

### The `animationId` Pattern

The `animationId` is the key to everything. Every animation registers with the global `RiveAnimationController` singleton using its `animationId`, making cross-animation communication effortless.

```dart
class AnimationOrchestrationScreen extends StatelessWidget {
  final controller = RiveAnimationController.instance;

  /// Broadcast a state change to all registered animations
  void _broadcastDarkMode(bool isDark) {
    // Update every registered animation that has a 'darkMode' property
    for (final id in ['header', 'sidebar', 'content', 'footer']) {
      controller.updateDataBindingProperty(id, 'darkMode', isDark);
    }
  }

  /// Query state from one animation and apply to another
  void _syncProgress() {
    final progress = controller.getDataBindingPropertyValue('player', 'progress');
    if (progress != null) {
      controller.updateDataBindingProperty('progressBar', 'value', progress);
    }
  }

  /// Get all property values from any animation
  void _inspectAnimation(String animationId) {
    final values = controller.getAllPropertyValues(animationId);
    values.forEach((name, value) {
      print('$name = $value');
    });
  }

  /// Get the current state machine state
  void _checkState(String animationId) {
    final state = controller.getCurrentStateName(animationId);
    print('Current state: $state');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Multiple animations, each with a unique ID
          Expanded(child: RiveManager(animationId: 'header', riveFilePath: 'assets/header.riv')),
          Expanded(child: RiveManager(animationId: 'content', riveFilePath: 'assets/content.riv')),
          Expanded(child: RiveManager(animationId: 'footer', riveFilePath: 'assets/footer.riv')),

          // Control panel
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _broadcastDarkMode(true),
                  child: Text('Dark Mode'),
                ),
                ElevatedButton(
                  onPressed: _syncProgress,
                  child: Text('Sync Progress'),
                ),
                ElevatedButton(
                  onPressed: () => _inspectAnimation('header'),
                  child: Text('Inspect Header'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Global Controller API Quick Reference

```dart
final c = RiveAnimationController.instance;

// ─── State Machine Inputs ───
c.triggerInput('animId', 'inputName');
c.updateBool('animId', 'inputName', true);
c.updateNumber('animId', 'inputName', 42.0);

// ─── Data Binding Properties ───
await c.updateDataBindingProperty('animId', 'propName', value);
c.getDataBindingPropertyValue('animId', 'propName');
c.getAllPropertyValues('animId');

// ─── Nested Properties ───
await c.updateNestedProperty('animId', 'parent/child/prop', value);

// ─── Text Runs ───
c.setTextRunValue('animId', 'textRunName', 'Hello');
c.getTextRunValue('animId', 'textRunName');

// ─── Image Properties ───
await c.updateImageProperty('animId', 'imageProp', urlOrBytesOrRenderImage);

// ─── State Queries ───
c.getCurrentStateName('animId');
c.getAnimationState('animId');

// ─── Cache ───
c.getCacheStats();
c.clearAllPropertyCaches();
```

---

## Example 17: Log Manager & Debugging

### Real-Time Log Monitoring

```dart
class DebugScreen extends StatefulWidget {
  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  @override
  void initState() {
    super.initState();
    // Enable verbose logging
    LogManager.enableLogging();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Console'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              LogManager.clearLogs();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: RiveManager(
              animationId: 'debugAnim',
              riveFilePath: 'assets/animations/debug.riv',
              onViewModelPropertiesDiscovered: (props) {
                print('Discovered ${props.length} properties');
              },
            ),
          ),
          Divider(),
          Expanded(
            flex: 3,
            // LogManager provides a reactive list of all library logs
            child: ValueListenableBuilder<List<String>>(
              valueListenable: LogManager.logsNotifier,
              builder: (context, logs, _) {
                return ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        logs[index],
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LogManager.disableLogging();
    super.dispose();
  }
}
```

---

## Example 18: Complete Production Example

### Full-Featured Animation with All Capabilities

```dart
class ProductionScreen extends StatefulWidget {
  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final controller = RiveAnimationController.instance;
  List<Map<String, dynamic>> properties = [];
  List<String> events = [];
  String currentState = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Production Example')),
      body: Row(
        children: [
          // ─── Animation Panel ───
          Expanded(
            flex: 3,
            child: RiveManager(
              animationId: 'production',
              riveFilePath: 'assets/animations/production.riv',
              animationType: RiveAnimationType.stateMachine,
              fit: Fit.contain,
              alignment: Alignment.center,
              hitTestBehavior: RiveHitTestBehavior.opaque,

              // Optional: choose a specific ViewModel
              // dataBind: DataBind.byName('MainViewModel'),

              // Initialization
              onInit: (artboard) {
                print('Ready: ${artboard.name}');
              },

              // State machine input changes
              onInputChange: (index, name, value) {
                setState(() => currentState = '$name=$value');
              },

              // ViewModel properties discovered
              onViewModelPropertiesDiscovered: (props) {
                setState(() => properties = props);
              },

              // Any property value changes (from animation or external)
              onDataBindingChange: (name, type, value) {
                setState(() {
                  events.insert(0, '[$type] $name = $value');
                  if (events.length > 50) events.removeLast();
                });
              },

              // Rive events fired from the state machine
              onEventChange: (eventName, event, state) {
                setState(() {
                  currentState = state;
                  events.insert(0, '🎯 Event: $eventName (state: $state)');
                });
              },
            ),
          ),

          // ─── Control Panel ───
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Current state
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  color: Colors.blue[50],
                  child: Text('State: $currentState',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                // Property controls
                Expanded(
                  child: ListView.builder(
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final prop = properties[index];
                      return _buildPropertyControl(prop);
                    },
                  ),
                ),

                // Event log
                Divider(),
                Text('Events:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView(
                    children: events.map((e) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      child: Text(e, style: TextStyle(fontSize: 11)),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyControl(Map<String, dynamic> prop) {
    final name = prop['name'] as String;
    final type = prop['type'] as String;
    final value = prop['value'];

    switch (type) {
      case 'string':
        return ListTile(
          title: Text(name),
          subtitle: TextField(
            controller: TextEditingController(text: value?.toString() ?? ''),
            onSubmitted: (v) =>
              controller.updateDataBindingProperty('production', name, v),
          ),
        );

      case 'number':
        return ListTile(
          title: Text('$name: ${(value as num?)?.toStringAsFixed(1) ?? '0'}'),
          subtitle: Slider(
            value: ((value as num?)?.toDouble() ?? 0).clamp(-100, 100),
            min: -100, max: 100,
            onChanged: (v) =>
              controller.updateDataBindingProperty('production', name, v),
          ),
        );

      case 'integer':
        return ListTile(
          title: Text('$name: ${value ?? 0}'),
          subtitle: Slider(
            value: ((value as num?)?.toDouble() ?? 0).clamp(-100, 100),
            min: -100, max: 100, divisions: 200,
            onChanged: (v) =>
              controller.updateDataBindingProperty('production', name, v.toInt()),
          ),
        );

      case 'boolean':
        return SwitchListTile(
          title: Text(name),
          value: value == true,
          onChanged: (v) =>
            controller.updateDataBindingProperty('production', name, v),
        );

      case 'trigger':
        return ListTile(
          title: Text(name),
          trailing: ElevatedButton(
            onPressed: () =>
              controller.updateDataBindingProperty('production', name, true),
            child: Text('Fire'),
          ),
        );

      case 'color':
        return ListTile(
          title: Text(name),
          trailing: Wrap(
            spacing: 4,
            children: [Colors.red, Colors.green, Colors.blue].map((c) =>
              GestureDetector(
                onTap: () =>
                  controller.updateDataBindingProperty('production', name, c),
                child: Container(width: 24, height: 24,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              ),
            ).toList(),
          ),
        );

      case 'list':
        final items = prop['listItems'] as List? ?? [];
        return ListTile(
          title: Text('$name (${items.length} items)'),
          subtitle: Text('List — read-only collection'),
        );

      case 'artboard':
        return ListTile(title: Text('$name (artboard)'));

      case 'viewModel':
        final nested = prop['nestedProperties'] as List? ?? [];
        return ExpansionTile(
          title: Text('$name (${nested.length} nested)'),
          children: nested.map<Widget>((n) =>
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('${n['name']}: ${n['type']} = ${n['value']}'),
            ),
          ).toList(),
        );

      default:
        return ListTile(title: Text('$name ($type)'));
    }
  }
}
```

---

## Supported Property Types Reference

| Type | Discovered As | Update Method | Value Type |
|---|---|---|---|
| `string` | `'string'` | `updateDataBindingProperty()` | `String` |
| `number` | `'number'` | `updateDataBindingProperty()` | `double` |
| `integer` | `'integer'` | `updateDataBindingProperty()` | `int` |
| `boolean` | `'boolean'` | `updateDataBindingProperty()` | `bool` |
| `color` | `'color'` | `updateDataBindingProperty()` | 8 formats (hex, rgb, Color, map, list, named) |
| `trigger` | `'trigger'` | `updateDataBindingProperty()` | `true` to fire |
| `enumType` | `'enumType'` | `updateDataBindingProperty()` | `String` |
| `image` | `'image'` | `updateImageProperty()` | URL, file path, bytes, RenderImage |
| `font` | `'font'` | `updateFontFrom{Bytes,Asset,Url}()` | URL, file path, bytes (.ttf/.otf) |
| `list` | `'list'` | Read-only collection | `int` (length) |
| `artboard` | `'artboard'` | `updateDataBindingProperty()` | `BindableArtboard` |
| `viewModel` | `'viewModel'` | `updateNestedProperty()` | Contains nested properties |
| `symbolListIndex` | `'symbolListIndex'` | `updateDataBindingProperty()` | `int` |

---

## What's New in v1.0.17

### Dynamic Font Replacement
Replace fonts in Rive animations at runtime using the same pattern as image replacement. Supports `.ttf` and `.otf` files from bytes, Flutter assets, or URLs.

### Thumbnail / Snapshot Capture
Capture any animation frame as a `ui.Image` or PNG bytes using GPU-direct `RenderTexture.toImage()`. Eliminates the need for `RepaintBoundary` workarounds.

### Headless RenderTexture Mode
Render Rive animations to a GPU texture without a visible widget — ideal for broadcast pipelines, compositors, and zero-copy IOSurface integration.

---

## Example 19: Dynamic Font Replacement (v1.0.17+)

### Purpose

Replace embedded fonts in Rive animations at runtime. This is useful for:
- **Branding** — Apply a client's custom font to a template lower-third
- **Localization** — Swap fonts for languages that require different character sets
- **User customization** — Let users pick their preferred font in a design tool

### Prerequisites

- The Rive file must contain at least one **embedded font asset** (added in the Rive editor)
- Set `enableImageReplacement: true` on `RiveManager` — this enables asset interception for **both** images and fonts

### Basic Usage

```dart
class FontReplacementScreen extends StatefulWidget {
  @override
  State<FontReplacementScreen> createState() => _FontReplacementScreenState();
}

class _FontReplacementScreenState extends State<FontReplacementScreen> {
  final controller = RiveAnimationController.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Font Replacement')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'lowerThird',
              riveFilePath: 'assets/animations/lower_third.riv',
              enableImageReplacement: true, // ✅ Required for font interception
              onViewModelPropertiesDiscovered: (props) {
                print('Properties ready — font can be swapped now');
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _loadFontFromAsset(),
                  child: Text('Load Bundled Font'),
                ),
                ElevatedButton(
                  onPressed: () => _loadFontFromUrl(),
                  child: Text('Load Google Font'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Load font from Flutter asset bundle
  Future<void> _loadFontFromAsset() async {
    await controller.updateFontFromAsset(
      'lowerThird',
      'assets/fonts/CustomBrand.ttf',
    );
  }

  /// Load font from URL
  Future<void> _loadFontFromUrl() async {
    await controller.updateFontFromUrl(
      'lowerThird',
      'https://fonts.gstatic.com/s/inter/v13/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuI6fMZ.ttf',
    );
  }
}
```

### Font Update Methods

```dart
// Method 1: From Flutter asset bundle (.ttf or .otf)
await controller.updateFontFromAsset(
  'animationId',
  'assets/fonts/MyFont.ttf',
);

// Method 2: From URL
await controller.updateFontFromUrl(
  'animationId',
  'https://example.com/fonts/CustomFont.ttf',
);

// Method 3: From raw bytes (Uint8List)
final fontBytes = await File('/path/to/font.otf').readAsBytes();
await controller.updateFontFromBytes('animationId', fontBytes);

// Method 4: Direct state access (for advanced use cases)
final state = controller.getAnimationState('animationId');
await state?.updateFontFromBytes(fontBytes);
```

### How It Works

1. When `enableImageReplacement: true`, the asset loader intercepts **both** `ImageAsset` and `FontAsset` references during Rive file loading
2. The `FontAsset` reference is stored on the `RiveManagerState` and registered with the global controller
3. When you call `updateFontFromBytes/Asset/Url`, the font bytes are decoded via `FontAsset.decode()` which uses Rive's native font decoder
4. The animation re-renders with the new font immediately

---

## Example 20: Thumbnail / Snapshot Capture (v1.0.17+)

### Purpose

Capture a static image of any animation frame. This is useful for:
- **Template galleries** — Generate preview thumbnails for Rive templates
- **Saving state** — Capture the current visual state after data binding changes
- **Export** — Save animation frames as images for sharing or printing

### Why Not RepaintBoundary?

The traditional Flutter approach (`RepaintBoundary.toImage()`) has several issues with Rive:
- Requires the widget to be in the visible widget tree
- `debugNeedsPaint` errors during active animation
- Recursive retry loops to wait for a stable frame
- Coupled to widget layout constraints

`captureSnapshot()` uses `RenderTexture.toImage()` instead — a GPU-direct capture that bypasses the widget tree entirely.

### Basic Usage

```dart
class ThumbnailCaptureScreen extends StatefulWidget {
  @override
  State<ThumbnailCaptureScreen> createState() => _ThumbnailCaptureScreenState();
}

class _ThumbnailCaptureScreenState extends State<ThumbnailCaptureScreen> {
  final controller = RiveAnimationController.instance;
  Uint8List? thumbnailBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thumbnail Capture')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'preview',
              riveFilePath: 'assets/animations/template.riv',
              onViewModelPropertiesDiscovered: (props) {
                // Trigger animation, then capture after it settles
                _triggerAndCapture(props);
              },
            ),
          ),
          if (thumbnailBytes != null)
            Container(
              height: 100,
              padding: EdgeInsets.all(8),
              child: Image.memory(thumbnailBytes!, fit: BoxFit.contain),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _captureNow,
              child: Text('Capture Current Frame'),
            ),
          ),
        ],
      ),
    );
  }

  /// Capture the current frame immediately
  Future<void> _captureNow() async {
    final pngBytes = await controller.captureAnimationThumbnail(
      'preview',
      width: 512,
      height: 512,
    );

    if (pngBytes != null) {
      setState(() => thumbnailBytes = pngBytes);
      print('Captured ${pngBytes.length} bytes');
    }
  }

  /// Trigger the first animation, wait for it to settle, then capture
  Future<void> _triggerAndCapture(List<dynamic> props) async {
    // Find first trigger
    String? triggerName;
    for (final prop in props) {
      if (prop is Map<String, dynamic> && prop['type'] == 'trigger') {
        triggerName = prop['name'];
        break;
      }
    }

    if (triggerName != null) {
      // Fire the trigger
      controller.updateDataBindingProperty('preview', triggerName, true);

      // Wait for animation to reach desired visual state
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Capture
    await _captureNow();
  }
}
```

### Capture Methods

```dart
// Via controller (recommended for most cases)
final pngBytes = await controller.captureAnimationThumbnail(
  'animationId',
  width: 512,   // Required — output image width
  height: 512,  // Required — output image height
);

// Via state (for advanced control)
final state = controller.getAnimationState('animationId');

// Get ui.Image (for further processing)
final image = await state?.captureSnapshot(width: 1920, height: 1080);

// Get PNG bytes directly
final bytes = await state?.captureSnapshotAsPng(width: 512, height: 512);
```

### How It Works

- **Widget mode:** Creates a temporary `RenderTexture`, draws the current artboard frame into it, captures via `toImage()`, then disposes the texture
- **Texture mode:** Uses the already-existing `RenderTexture` directly — instant capture, no allocation
- Both modes call the GPU-level `RenderTexture.toImage()` → `SceneBuilder.addTexture()` → snapshot

---

## Example 21: Headless RenderTexture Mode (v1.0.17+)

### Purpose

Render Rive animations directly to a GPU texture without displaying them in the widget tree. This is useful for:
- **Broadcast compositors** — Render overlays to a texture for GPU compositing
- **Zero-copy pipelines** — Pass the native `MTLTexture*` pointer to a broadcast engine via IOSurface
- **Off-screen rendering** — Generate animation frames without a visible window
- **Multi-output** — Render the same animation to multiple destinations simultaneously

### Basic Usage

```dart
class HeadlessTextureScreen extends StatefulWidget {
  @override
  State<HeadlessTextureScreen> createState() => _HeadlessTextureScreenState();
}

class _HeadlessTextureScreenState extends State<HeadlessTextureScreen> {
  int? nativePointer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Headless Texture Mode')),
      body: Stack(
        children: [
          // The RiveManager in texture mode renders to a GPU texture,
          // NOT to the screen. The widget is a 1x1 SizedBox.
          RiveManager(
            animationId: 'broadcast_overlay',
            riveFilePath: 'assets/animations/lower_third.riv',
            renderMode: RiveRenderMode.texture,  // ✅ GPU texture mode
            textureWidth: 1920,
            textureHeight: 1080,
            onTextureReady: (texture) {
              print('GPU texture ready: textureId=${texture.textureId}');
            },
            onNativeTexturePointer: (address) {
              // This is the MTLTexture* pointer on macOS
              setState(() => nativePointer = address);
              print('Native texture pointer: 0x${address.toRadixString(16)}');

              // Pass to your broadcast engine:
              // broadcastBus.attachRiveTexture(Pointer.fromAddress(address));
            },
            // All existing callbacks still work:
            onViewModelPropertiesDiscovered: (props) {
              print('Discovered ${props.length} properties (headless)');
            },
            onDataBindingChange: (name, type, value) {
              print('Data changed in headless mode: $name = $value');
            },
          ),

          // Your actual visible UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  nativePointer != null
                    ? 'GPU Texture Active\n0x${nativePointer!.toRadixString(16)}'
                    : 'Initializing texture...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Controller Access

```dart
// Get the native texture pointer for FFI integration
final pointer = RiveAnimationController.instance
    .getNativeTexturePointer('broadcast_overlay');

if (pointer != null) {
  // On macOS, this is the MTLTexture* address
  final mtlTexture = Pointer<Void>.fromAddress(pointer);
  // Pass to IOSurface bridge, broadcast engine, etc.
}
```

### Render Modes

| Mode | Widget Output | GPU Texture | Use Case |
|---|---|---|---|
| `RiveRenderMode.widget` | Visible `RiveWidget` | ❌ | Normal UI display |
| `RiveRenderMode.texture` | Hidden 1×1 `SizedBox` | ✅ | Broadcast, compositor, GPU pipeline |

---

These examples cover all major features of the Rive Animation Manager package. Adapt them to your specific use cases!
