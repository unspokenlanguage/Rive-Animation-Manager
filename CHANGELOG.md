# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Additional state machine utilities
- Performance profiling tools
- Extended animation event types


## [1.0.5] - 2025-11-03

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
- 
## [1.0.4] - 2025-11-03

### Fixed

- **Trigger Property Discovery**: Fixed missing trigger property discovery in data binding
  - Trigger properties are now properly discovered and stored in the properties list
  - Added trigger support in `_processViewModelInstance` method
  - Trigger properties can now be accessed via `updateDataBindingProperty` with type 'trigger'

### Improved

- **Property Disposal**: Enhanced cleanup to properly dispose trigger properties
  - Added `ViewModelInstanceTrigger` to the disposal logic
  - Prevents memory leaks when triggers are used in animations

## [1.0.2] - 2025-11-01

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

## [1.0.1] - 2025-11-01

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

- **Backward Compatibility**
  - Legacy `logs` list still accessible
  - `logsAsStrings` getter for string-based logs
  - All existing LogManager methods work unchanged

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

## [1.0.0] - 2025-11-01

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
  - Multiple image source support:
    - Asset bundle images
    - URL-based images
    - Raw byte data
    - Pre-decoded RenderImage (fastest)
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
  - Enable/disable logging functionality
  - Log history tracking (max 100 logs)

- **File Support**
  - Asset file loading via Flutter's asset system
  - External file support with File objects
  - Custom file loader interface for advanced use cases

- **Documentation**
  - Full Dart documentation on all public APIs
  - Comprehensive README with features and API reference
  - Quick start guide with code examples
  - Advanced usage patterns and best practices
  - Troubleshooting guide
  - 8+ complete working examples
  - QUICK_REFERENCE.md for fast lookup

### Features

- ✅ **Global animation state management** - Centralized controller for all animations
- ✅ **Real-time input callbacks** - Immediate response to input changes
- ✅ **Automatic property discovery** - Detect all available properties automatically
- ✅ **Dynamic image updates from multiple sources** - Asset, URL, bytes, or RenderImage
- ✅ **Performance-optimized caching** - Intelligent caching for properties and images
- ✅ **Debug logging with real-time monitoring** - Comprehensive logging system
- ✅ **Complete resource cleanup** - Proper disposal of animations and assets
- ✅ **Error handling and detailed logging** - Comprehensive error tracking
- ✅ **Nested property path support** - Access deeply nested properties easily
- ✅ **Event listener management** - Handle all animation events
- ✅ **Cache statistics** - Monitor cache usage and performance
- ✅ **Artboard selection** - Switch between artboards at runtime

### Supported Versions

- **Rive**: ^0.0.16
- **Flutter**: >=3.13.0
- **Dart**: >=3.0.0

### Technical Details

- Singleton pattern for global controller
- ValueNotifier-based state updates
- Performance-optimized property path caching
- Automatic memory management and cleanup
- Type-safe API with full null safety
- Backward compatible with previous Rive versions

## Version Compatibility

| Version | Release Date | Status     | Highlights                                        |
|---------|--------------|------------|---------------------------------------------------|
| 1.0.1   | 2025-11-01   | Latest     | Enhanced LogManager with ValueNotifier support    |
| 1.0.0   | 2025-11-01   | Stable     | Initial production release                        |

## Migration Guide

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

// New: Access detailed log information
final logs = LogManager.logs;
final message = logs[0]['message'];
final timestamp = logs[0]['timestamp'];
final isExpected = logs[0]['isExpected'];
```

## Future Roadmap

### Planned for v1.1.0

- StateManager integration for complex animations
- Animation timeline control (pause, resume, seek)
- Batch operations for multiple animations
- Performance profiling tools

### Planned for v2.0.0

- Breaking changes for enhanced stability (if needed)
- Extended Rive version support (>1.0)
- Advanced animation composition features

## Support

For issues, feature requests, or contributions:

- GitHub Issues: [rive_animation_manager/issues](https://github.com/yourusername/rive_animation_manager/issues)
- GitHub Discussions: [rive_animation_manager/discussions](https://github.com/yourusername/rive_animation_manager/discussions)

## Contributors

- Initial development and maintenance by the Flutter community

## License

MIT License - See LICENSE file for details
