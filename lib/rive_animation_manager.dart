// lib/rive_animation_manager.dart

/// Rive Animation Manager - A comprehensive Flutter package for managing Rive animations
/// 
/// This library provides:
/// - Global animation state management via [RiveAnimationController]
/// - Reusable [RiveManager] widget for displaying animations
/// - Data binding property discovery and management
/// - Image replacement and caching
/// - Input handling (triggers, booleans, numbers)
/// - Text run management
/// - Event handling
/// - Performance monitoring and caching
/// 
/// ## Basic Usage
/// 
/// ```dart
/// import 'package:rive_animation_manager/rive_animation_manager.dart';
/// 
/// // Display an animation
/// RiveManager(
///   animationId: 'myAnimation',
///   riveFilePath: 'assets/animations/my_animation.riv',
///   animationType: RiveAnimationType.stateMachine,
///   onInit: (artboard) {
///     print('Animation loaded!');
///   },
/// )
/// 
/// // Control animations globally
/// final controller = RiveAnimationController.instance;
/// controller.updateBool('myAnimation', 'isHovered', true);
/// controller.triggerInput('myAnimation', 'playEffect');
/// ```
/// 
/// For more examples and documentation, see:
/// - [RiveAnimationController] - Global singleton controller
/// - [RiveManager] - Main animation widget
/// - [RiveAnimationType] - Animation type enum
/// - [LogManager] - Logging utility
library rive_animation_manager;

// Export the global animation controller
export '../src/controller/rive_animation_controller.dart';

// Export the main widget
export '../src/widgets/rive_manager.dart';

// Export models
export '../src/models/rive_animation_type.dart';

// Export helpers
export '../src/helpers/log_manager.dart';
