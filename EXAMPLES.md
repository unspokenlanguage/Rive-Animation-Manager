# Rive Animation Manager - Example Usage (v1.0.15+)

This file demonstrates complete usage patterns for the Rive Animation Manager package.

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

  Future<void> _updateProperty(String name, dynamic value) async {
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
      body: RiveManager(
        animationId: 'databinding',
        riveFilePath: 'assets/animations/databinding.riv',
        onViewModelPropertiesDiscovered: (discoveredProps) {
          setState(() => properties = discoveredProps);
          print('Found ${discoveredProps.length} properties');
        },
        child: ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final prop = properties[index];
            return ListTile(
              title: Text(prop['name']),
              subtitle: Text('Type: ${prop['type']}'),
              trailing: ElevatedButton(
                onPressed: () => _updateProperty(
                  prop['name'],
                  'new_value',
                ),
                child: Text('Update'),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Example 4: Dynamic Image Updates (v1.0.9+)

### ✨ NEW: Type-Safe Image Property Handling

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

### ✨ NEW: FileLoader Support with Full Initialization

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
          // ✅ NOW WORKS! (Was broken in v1.0.9)
          print('FileLoader input: $name = $value');
        },
        onViewModelPropertiesDiscovered: (discoveredProps) {
          // ✅ NOW WORKS! (Was broken in v1.0.9)
          setState(() => properties = discoveredProps);
          print('FileLoader found ${discoveredProps.length} properties');
        },
        onDataBindingChange: (name, type, value) {
          // ✅ NOW WORKS! (Was broken in v1.0.9)
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
    // Could be from any source: database, network, etc.
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

**Before v1.0.10:** FileLoader worked but was missing discovery and registration  
**After v1.0.10:** FileLoader works identically to asset and external file loading

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
    controller.updateBool('animation1', 'isActive', true);
    controller.updateBool('animation2', 'isActive', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Multiple Animations')),
      body: Column(
        children: [
          Expanded(
            child: RiveManager(
              animationId: 'animation1',
              riveFilePath: 'assets/animations/anim1.riv',
            ),
          ),
          Expanded(
            child: RiveManager(
              animationId: 'animation2',
              riveFilePath: 'assets/animations/anim2.riv',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _syncAnimations,
              child: Text('Sync Animations'),
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
        // ✅ NEW in v1.0.11 - Auto-detected!
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
        // ✅ NEW in v1.0.11 - Auto-detected!
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
                      // String formats
                      _buildFormatButton('Hex'),
                      _buildFormatButton('Hex Short'),
                      _buildFormatButton('RGB'),
                      _buildFormatButton('RGBA'),

                      // Color objects
                      _buildFormatButton('Color Object'),
                      _buildFormatButton('Color.from'),

                      // Map formats
                      _buildFormatButton('Map Standard'),
                      _buildFormatButton('Map Normalized'),

                      // List formats
                      _buildFormatButton('List Standard'),
                      _buildFormatButton('List Normalized'),

                      // Named colors
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
## What's New in v1.0.11

### Flexible Multi-Format Color Support

Color properties now accept **8 different formats** with automatic detection:

✅ Hex Strings - `'#3EC293'`, `'#3EC'`, `'#FF3EC293'`  
✅ RGB/RGBA Strings - `'rgb(62, 194, 147)'`, `'rgba(62, 194, 147, 1.0)'`  
✅ Flutter Color Objects - `Color(0xFF3EC293)`, `Colors.teal`  
✅ Maps (Standard 0-255) - `{'r': 62, 'g': 194, 'b': 147}`  
✅ Maps (Normalized 0.0-1.0) - `{'r': 0.2431, 'g': 0.7608, 'b': 0.5764}` ⭐  
✅ Lists (Standard 0-255) - `[62, 194, 147]`  
✅ Lists (Normalized 0.0-1.0) - `[0.2431, 0.7608, 0.5764]` ⭐  
✅ Named Colors - `'red'`, `'blue'`, `'cyan'`, `'teal'`

**Auto-Detection:** Automatically detects standard vs normalized values!  
**Rive Compatible:** Direct support for Rive API normalized format!


## What's New in v1.0.10

### FileLoader Full Support (v1.0.10)

FileLoader loading method now has **complete feature parity** with other loading methods:

✅ Input discovery for async-loaded animations  
✅ Property discovery for dynamic binding  
✅ Event listener setup during async loading  
✅ Full registration with global controller  
✅ All callbacks work identically

### Advanced Image Property Handling (v1.0.9+)

The image property update system supports **4 different input types**:

1. **Local File Paths** - String paths to local files
2. **URLs** - HTTP/HTTPS URLs for remote images
3. **Raw Bytes** - Uint8List for custom image data
4. **Pre-Decoded RenderImage** - For maximum performance

### Benefits

✅ Flexible input handling  
✅ Automatic format detection  
✅ Full error validation  
✅ Performance optimization  
✅ Type-safe implementation

---

These examples cover all major features of the Rive Animation Manager package. Adapt them to your specific use cases!
