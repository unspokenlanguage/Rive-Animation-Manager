# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.10]

### Added

- **FileLoader Support with Full Initialization**: Complete async file loading support
  - Implement full initialization pipeline in `onLoaded()` callback
  - Support for custom file loading via FileLoader interface
  - Async initialization for dynamically loaded animations

- **FileLoader Initialization Path**
  - Input discovery for async-loaded animations
  - Property discovery for dynamic binding
  - Event listener setup during async loading
  - Full registration with global controller

### Fixed

- **FileLoader Registration Issue**: Fixed critical bug where FileLoader-loaded animations weren't registered
  - Animations loaded via FileLoader now properly register with RiveAnimationController
  - Input discovery now works for async-loaded files
  - Data binding properties discovered correctly for FileLoader animations
  - Event listeners properly attached to async-loaded controllers

- **Async/Sync Loading Parity**: Unified initialization across all loading methods
  - All three loading paths (asset file, external file, FileLoader) now use identical initialization
  - Async loading in `onLoaded()` callback matches sync loading in `_initRive()`
  - Consistent behavior regardless of loading method

### Improved

- **Loading Architecture**: Cleaner separation of sync and async patterns
  - Synchronous loading: Initialize in `_initRive()` before render
  - Asynchronous loading: Initialize in `onLoaded()` after file loads
  - Same initialization, different timing

- **Error Handling**: Better error messages for async loading
  - Clear logging of async initialization steps
  - Detailed tracking of FileLoader animation lifecycle
  - Comprehensive debug information

- **Code Quality**
  - Reduced code duplication across loading methods
  - More maintainable initialization pipeline
  - Clearer async/await patterns

## Why This Fix Matters

**Before v1.0.10:** FileLoader animations worked but were never registered with the global controller, making them inaccessible via `RiveAnimationController.instance`.

**After v1.0.10:** All loading methods (asset, external, FileLoader) now behave identically with full initialization and registration.

### Impact

✅ FileLoader animations now accessible globally  
✅ All callbacks work with FileLoader (onInit, onInputChange, onEventChange, etc.)  
✅ Properties and inputs discoverable for FileLoader animations  
✅ Event listeners properly attached  
✅ Consistent API across all loading methods

---

## Technical Details

### What Changed

```dart
// Before: onLoaded() only called callback
onLoaded: (riveLoaded) {
  widget.onInit?.call(riveLoaded.controller.artboard);
}

// After: onLoaded() does full initialization
onLoaded: (riveLoaded) async {
  _controller = riveLoaded.controller;
  _file = riveLoaded.file;
  _controller?.stateMachine.addEventListener(_onRiveEvent);
  
  await Future.wait([
    _discoverInputs(),
    _discoverDataBindingProperties(),
  ]);
  
  RiveAnimationController.instance.register(widget.animationId, this);
  widget.onInit?.call(riveLoaded.controller.artboard);
}
```

### Three Loading Paths Now Unified

| Aspect | Asset File | External File | FileLoader |
|--------|---|---|---|
| Load timing | Sync in `_initRive()` | Sync in `loadExternalFile()` | Async in `onLoaded()` |
| Discovery | In load method | In load method | In `onLoaded()` |
| Registration | In load method | In load method | In `onLoaded()` |
| Initialization | Before `build()` | Before UI update | After file loads |
| **Behavior** | ✅ Identical | ✅ Identical | ✅ Now identical |

---

## Migration Guide

### From 1.0.9 to 1.0.10
No breaking changes! The FileLoader now works the same as other loading methods:

## [1.0.9]

### Added

- **Advanced Image Property Handling**: Type-safe image updates with multiple source support
  - Handle String paths (local files and URLs)
  - Handle pre-decoded RenderImage objects
  - Handle raw Uint8List bytes
  - Automatic format detection and decoding

- **Image Property Update Methods**
  - `updateImageProperty()` with full type support
  - Local file path support: `'path/to/image.png'`
  - URL support: `'https://example.com/image.png'`
  - Pre-decoded RenderImage support for performance
  - Raw Uint8List bytes support for custom decoding

### Fixed

- **Image Property Type Handling**: Fixed missing type-safe image property updates
  - Proper String path handling (local vs URL)
  - File existence validation before loading
  - HTTP status code validation for URL requests
  - Automatic Uint8List to RenderImage conversion
  - Error handling and logging for all image operations

- **Image Loading Errors**: Enhanced error messages and validation
  - File not found detection
  - HTTP error status detection
  - Decode failure handling
  - Invalid type parameter detection

### Improved

- **Image Property API**: More flexible and intuitive
  - Support for all common image source types
  - Automatic format detection
  - Better error messages for troubleshooting
  - Consistent with other property update methods

- **Performance**: Pre-decoded RenderImage support
  - Skip decoding for already-decoded images
  - Faster updates for cached images
  - Reduced memory usage with smart caching
  
## [1.0.8]

### Added
- **Complete Property Discovery System**
  - Flat properties fully supported (v1.0.7)
  - Nested ViewModels now fully supported (v1.0.8) ⚡
  - Together = complete Rive ViewModel coverage
  - Handles all property types at all nesting levels
  
## [1.0.7]

### Added

- **onDataBindingChange Callback Implementation**: Previously defined but unused callback now fully functional
  - Added property listeners in `_processViewModelInstance()` for real-time property value updates
  - Supports String, Number, Boolean, Color, and Enum property types
  - Fires immediately when property values change in the animation
  - Enables reactive UI updates based on animation state changes

- **Property Listener System**: Automatic property change detection
  - Type-safe listener signatures for each property type
  - String properties: `stringProp?.addListener((value) { ... })`
  - Number properties: `numberProp?.addListener((value) { ... })`
  - Boolean properties: `boolProp?.addListener((value) { ... })`
  - Color properties: `colorProp?.addListener((value) { ... })`
  - Enum properties: `enumProp?.addListener((value) { ... })`

### Fixed

- **Listener Type Signatures**: Fixed callback parameter type mismatches
  - Corrected signature from `void Function()` to `void Function(T value)`
  - Proper handling of typed listener parameters for each property type
  - Eliminated "argument type can't be assigned" compilation errors

- **Property Change Tracking**: Fixed issue where property changes weren't being reported
  - onDataBindingChange callback now invokes correctly when properties update
  - Value parameter properly passed to callback function
  - Multiple property types handled with correct type safety

### Improved

- **Complete Callback System**: All 8 callbacks now fully functional
  - onInit - Animation initialization
  - onInputChange - State machine input changes
  - onHoverAction - Hover/boolean action handling
  - onTriggerAction - Trigger event firing
  - onViewModelPropertiesDiscovered - Property discovery
  - **onDataBindingChange - Real-time property value updates** ⚡ (NEW)
  - onEventChange - Rive event handling
  - onAnimationComplete - Animation completion

- **Real-Time Data Binding**: Complete reactive data binding pipeline
  - Properties update instantly as animation state changes
  - User interactions trigger immediate property callbacks
  - UI can react to property changes in real-time
  - Full support for Rive's data binding system

- **Code Organization**: Enhanced property management
  - Clear separation of property initialization and listener setup
  - Type-safe listener implementations
  - Improved property disposal with proper listener cleanup

## [1.0.6]

### Fixed

- Missing type annotation in _paintShared callback: Added explicit Duration type to _paintShared parameter to resolve Dart linter warning and maintain strict type safety

## [1.0.5]

### Fixed

- **setState() During Build Phase**: Fixed critical Flutter error by wrapping all async/post-initialization `setState()` calls with `WidgetsBinding.instance.addPostFrameCallback()`
  - Fixed `_initRive()` setState calls during initialization
  - Fixed `_loadRiveFileStandard()` setState after file loading
  - Fixed `_loadRiveFileWithImageReplacement()` setState after async operations
  - Fixed `loadExternalFile()` setState in Future.then() callback
  - Prevents "setState() called during build" runtime errors

- **Trigger Property Discovery**: Added missing trigger property discovery in data binding
  - Trigger properties are now properly discovered and stored in the properties list
  - Added trigger support in `_processViewModelInstance` method
  - Trigger properties can now be accessed via `updateDataBindingProperty` with type 'trigger'

### Improved

- **Widget Lifecycle Safety**: All state updates now respect Flutter's widget lifecycle
  - Uses proper post-frame callbacks for safe UI updates
  - Maintains mounted state checks before setState calls
  - Prevents memory leaks and runtime errors

- **Property Disposal**: Enhanced cleanup to properly dispose trigger properties
  - Added `ViewModelInstanceTrigger` to the disposal logic
  - Prevents memory leaks when triggers are used in animations

- **Code Stability**: Overall stability improvements through proper async handling

## [1.0.4]

### Fixed

- **Trigger Property Discovery**: Fixed missing trigger property discovery in data binding
  - Trigger properties are now properly discovered and stored in the properties list
  - Added trigger support in `_processViewModelInstance` method
  - Trigger properties can now be accessed via `updateDataBindingProperty` with type 'trigger'

### Improved

- **Property Disposal**: Enhanced cleanup to properly dispose trigger properties
  - Added `ViewModelInstanceTrigger` to the disposal logic
  - Prevents memory leaks when triggers are used in animations

## [1.0.3]

### Fixed

- Code formatting compliance with Dart formatter (`dart format .`)
- Fixed pubspec.yaml URL format (removed markdown link syntax)
- Fixed empty `flutter:` section in pubspec.yaml (added empty object)
- Updated CHANGELOG.md formatting for pub.dev compliance
- Fixed issue_tracker URL to properly point to GitHub issues

### Improved

- Better pub.dev score and validation
- Improved documentation clarity
- Enhanced code style consistency

## [1.0.2]

### Fixed

- Code formatting compliance with Dart formatter (`dart format .`)
- Fixed pubspec.yaml URL format (removed markdown link syntax)
- Fixed empty `flutter:` section in pubspec.yaml (added empty object)
- Updated CHANGELOG.md formatting for pub.dev compliance
- Fixed issue_tracker URL to properly point to GitHub issues

### Improved

- Better pub.dev score and validation
- Improved documentation clarity
- Enhanced code style consistency

## [1.0.1]

### Added

- **Enhanced LogManager** with reactive UI support
  - `ValueNotifier<List<Map<String, dynamic>>> logMessages` for real-time log streaming
  - Detailed log entries with timestamps and event types
  - Log filtering capabilities (info vs warning/error)
  - Log search functionality
  - Export logs as string or JSON format
  - Log count statistics (total, info, error)
  - Multiple logs batch addition

- **New LogManager Methods**
  - `getLogsByType(bool isExpected)` - Filter logs by type
  - `searchLogs(String query)` - Search logs by text
  - `exportAsString()` - Export all logs as formatted string
  - `exportAsJSON()` - Export logs in JSON format
  - `getLastLogsAsStrings(int count)` - Get last N logs as strings (backward compatible)
  - `addMultipleLogs(List<String> messages)` - Add multiple logs at once
  - `logCount`, `errorCount`, `infoCount` - Get log statistics

### Changed

- **LogManager** now stores detailed log information
  - Each log entry contains: message, text, timestamp, type, isExpected
  - Improved timestamp formatting (HH:MM:SS)
  - Better structured logging data

### Fixed

- LogManager listeners now properly update UI
- Resolved issue where `LogManager.logs.addListener()` wasn't working (was `List<String>`, now supports `ValueNotifier`)

### Improved

- LogManager documentation with complete usage examples
- Better code organization in LogManager
- Enhanced error tracking and logging capabilities

## [1.0.0]

### Added

- Initial release of Rive Animation Manager
- **Global Animation Management**
  - Global singleton `RiveAnimationController` for centralized animation management
  - Per-animation state tracking and lifecycle management
  - Automatic resource cleanup and disposal

- **Core Widget**
  - `RiveManager` widget for displaying Rive animations with full input support
  - Support for both oneShot and stateMachine animation types
  - Multiple file loading options (asset, external, custom)
  - Responsive display with customizable fit and alignment

- **Input Handling**
  - State machine input handling (triggers, booleans, numbers)
  - Real-time input change callbacks
  - Input type detection and validation
  - Artboard selection by name

- **Data Binding & Properties**
  - Automatic property discovery from ViewModel instances
  - Data binding property management (number, boolean, string, color, enum, image, trigger)
  - Support for all Rive data types
  - Nested property updates with path caching for performance
  - Property value retrieval and bulk operations

- **Image Management**
  - Dynamic image replacement at runtime
  - Multiple image source support (asset, URL, bytes, RenderImage)
  - Image preloading and caching for instant swapping
  - Cache statistics and management

- **Text Management**
  - Text run value getting and setting
  - Path-based text targeting

- **Event Handling**
  - Rive event listening and callback handling
  - Event context with current state information
  - Animation completion callbacks

- **Logging & Debugging**
  - Comprehensive `LogManager` for debug logging
  - Cache statistics and performance monitoring
  - Detailed logging of animation lifecycle events

- **File Support**
  - Asset file loading via Flutter's asset system
  - External file support with File objects
  - Custom file loader interface for advanced use cases

### Features

- ✅ Global animation state management
- ✅ Real-time input callbacks
- ✅ Automatic property discovery
- ✅ Dynamic image updates from multiple sources
- ✅ Performance-optimized caching
- ✅ Debug logging with real-time monitoring
- ✅ Complete resource cleanup
- ✅ Nested property path support
- ✅ Event listener management
- ✅ Artboard selection

### Supported Versions

- **Rive**: ^0.0.16
- **Flutter**: >=3.13.0
- **Dart**: >=3.0.0

## Version Compatibility

| Version | Release Date | Status     | Highlights                                        |
|---------|--------------|------------|---------------------------------------------------|
| 1.0.8   | 2025-11-04   | Latest     | Nested properties + lint-free code ✅             |
| 1.0.7   | 2025-11-04   | Stable     | onDataBindingChange fully implemented ⚡         |
| 1.0.6   | 2025-11-01   | Stable     | Type annotation fixes                            |
| 1.0.5   | 2025-11-01   | Stable     | setState() lifecycle fixes + trigger support     |
| 1.0.4   | 2025-10-31   | Stable     | Trigger property discovery                       |
| 1.0.3   | 2025-10-31   | Stable     | Formatting and pub.dev compliance                |
| 1.0.2   | 2025-10-31   | Stable     | Formatting and pub.dev compliance                |
| 1.0.1   | 2025-11-01   | Stable     | Enhanced LogManager with ValueNotifier           |
| 1.0.0   | 2025-11-01   | Archived   | Initial production release                       |

## Migration Guide

### From 1.0.6 to 1.0.7

No breaking changes. To use the new onDataBindingChange callback:

```dart
RiveManager(
  animationId: 'myAnimation',
  riveFilePath: 'assets/animations/my.riv',
  // ✅ NEW: Callback now fires when properties change
  onDataBindingChange: (propertyName, propertyType, value) {
    print('Property $propertyName changed to $value');
    
    // Update your UI in real-time
    setState(() {
      _propertyValues[propertyName] = value;
    });
  },
)
```

### From 1.0.0 to 1.0.1

No breaking changes. To use new LogManager features:

```dart
// Old code still works
LogManager.addLog('Message', isExpected: true);

// New: Listen to log updates
LogManager.logMessages.addListener(() {
  print('Logs updated');
});

// New: Use ValueNotifier in UI
ValueListenableBuilder<List<Map<String, dynamic>>>(
  valueListenable: LogManager.logMessages,
  builder: (context, logs, _) {
    // Build UI with logs
  },
);
```

## Support

For issues, feature requests, or contributions:

- GitHub Issues: [rive_animation_manager/issues](https://github.com/unspokenlanguage/Rive-Animation-Manager/issues)
- GitHub Discussions: [rive_animation_manager/discussions](https://github.com/unspokenlanguage/rive_animation_manager/discussions)

## Contributors

- Initial development and maintenance by the Flutter community

## License

MIT License - See LICENSE file for details
