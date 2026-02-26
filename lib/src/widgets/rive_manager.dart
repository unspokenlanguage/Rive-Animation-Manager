// lib/src/widgets/rive_manager.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rive_native/rive_native.dart' as rive_native;

import '../controller/rive_animation_controller.dart';
import '../helpers/log_manager.dart';
import '../models/rive_animation_type.dart';
import '../models/rive_render_mode.dart';
import '../painters/headless_rive_painter.dart';
import 'package:rive/rive.dart';

/// Modern RiveManager widget with full rive_native support
///
/// Provides a complete animation widget with input handling, data binding,
/// and image replacement capabilities.
///
/// Usage:
/// ```dart
/// RiveManager(
///   animationId: 'myAnimation',
///   riveFilePath: 'assets/animations/my_animation.riv',
///   animationType: RiveAnimationType.stateMachine,
///   onInputChange: (index, name, value) {
///     print('Input changed: $name = $value');
///   },
/// )
/// ```
class RiveManager extends StatefulWidget {
  final String animationId;
  final String? riveFilePath;
  final File? externalFile;
  final FileLoader? fileLoader;
  final RiveAnimationType animationType;

  // Data binding strategy (optional, defaults to auto-discovery)
  final DataBind? dataBind;

  // Display properties
  final Fit fit;
  final Alignment alignment;
  final RiveHitTestBehavior hitTestBehavior;
  final MouseCursor cursor;
  final double layoutScaleFactor;

  // Image replacement
  final bool enableImageReplacement;
  final ImageAsset? imageAssetReference;

  // === RenderTexture Mode (Approach B — Zero-Copy GPU Pipeline) ===
  /// Rendering mode: [RiveRenderMode.widget] (default) or
  /// [RiveRenderMode.texture] for headless GPU rendering.
  final RiveRenderMode renderMode;

  /// Width of the GPU texture in pixels. Required when [renderMode] is
  /// [RiveRenderMode.texture]. Defaults to 1920.
  final int textureWidth;

  /// Height of the GPU texture in pixels. Required when [renderMode] is
  /// [RiveRenderMode.texture]. Defaults to 1080.
  final int textureHeight;

  /// Called when the GPU [RenderTexture] is created and ready for use.
  /// Use this to access the texture for compositing or broadcast pipelines.
  final void Function(rive_native.RenderTexture texture)? onTextureReady;

  /// Convenience callback that fires with the native GPU texture pointer
  /// address (e.g., MTLTexture* on macOS). Use for FFI-based IOSurface
  /// integration.
  final void Function(int nativePointerAddress)? onNativeTexturePointer;

  /// Callback that fires with the MetalTextureRenderer* pointer address.
  /// Used by the GPU pipeline to register a dynamic texture provider that
  /// resolves the current texture from Rive's triple-buffer ring each frame.
  final void Function(int rendererPointerAddress)? onRendererPointer;

  // Callbacks
  final void Function(Artboard artboard)? onInit;
  final void Function(int inputIndex, String inputName, dynamic value)?
      onInputChange;
  final void Function(String inputName, dynamic value)? onHoverAction;
  final void Function(String inputName, dynamic value)? onTriggerAction;
  final void Function(List<Map<String, dynamic>> properties)?
      onViewModelPropertiesDiscovered;
  final void Function(String eventName, Event event, String currentState)?
      onEventChange;
  final void Function(String propertyName, String propertyType, dynamic value)?
      onDataBindingChange;

  final VoidCallback? onAnimationComplete;

  const RiveManager({
    Key? key,
    required this.animationId,
    this.riveFilePath,
    this.externalFile,
    this.fileLoader,
    this.animationType = RiveAnimationType.stateMachine,
    this.dataBind,
    this.fit = Fit.contain,
    this.alignment = Alignment.center,
    this.hitTestBehavior = RiveHitTestBehavior.opaque,
    this.cursor = MouseCursor.defer,
    this.layoutScaleFactor = 1.0,
    this.enableImageReplacement = false,
    this.imageAssetReference,
    this.renderMode = RiveRenderMode.widget,
    this.textureWidth = 1920,
    this.textureHeight = 1080,
    this.onTextureReady,
    this.onNativeTexturePointer,
    this.onRendererPointer,
    this.onInit,
    this.onInputChange,
    this.onHoverAction,
    this.onTriggerAction,
    this.onViewModelPropertiesDiscovered,
    this.onDataBindingChange,
    this.onEventChange,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<RiveManager> createState() => RiveManagerState();
}

/// State for RiveManager widget
class RiveManagerState extends State<RiveManager> {
  File? _file;
  RiveWidgetController? _controller;
  ViewModelInstance? _viewModelInstance;
  CallbackHandler? _inputChangedHandler;
  bool _isInitializing = false;
  final Map<String, Map<String, dynamic>> _propertyCache = {};

  // === RenderTexture Mode State ===
  rive_native.RenderTexture? _renderTexture;
  HeadlessRivePainter? _headlessPainter;

  /// The underlying GPU [RenderTexture] when in texture mode, or null.
  /// Access the native pointer via [renderTexture?.nativeTexture].
  rive_native.RenderTexture? get renderTexture => _renderTexture;

  String _currentStateName = '';
  bool _isInitialized = false;

  // State machine inputs
  final Map<String, Input> inputs = {};

  // Data binding properties
  final List<Map<String, dynamic>> _properties = [];

  // Image asset reference
  ImageAsset? _imageAssetReference;

  // Font asset reference
  FontAsset? _fontAssetReference;

  // ========== PUBLIC GETTERS FOR CONTROLLER ACCESS ==========

  /// Get the internal properties list
  List<Map<String, dynamic>> get properties => _properties;

  /// Get the ViewModel instance
  ViewModelInstance? get viewModelInstance => _viewModelInstance;

  /// Get the Rive widget controller
  RiveWidgetController? get controller => _controller;

  /// Get the current state name
  String get currentStateName => _currentStateName;

  /// Get the image asset reference
  ImageAsset? get imageAssetReference => _imageAssetReference;

  /// Get the font asset reference
  FontAsset? get fontAssetReference => _fontAssetReference;

  // ========== END PUBLIC GETTERS ==========

  /// Safe setState that defers to post-frame callback.
  /// Prevents !_dirty assertions when Rive runtime listeners fire
  /// synchronously during the widget's own build phase.
  bool _setStatePending = false;

  void _safeSetState(VoidCallback fn) {
    fn(); // Apply the state mutation immediately
    if (!mounted) return;
    if (_setStatePending) return; // Already scheduled
    _setStatePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setStatePending = false;
      if (mounted) {
        setState(() {}); // Trigger a single rebuild
      }
    });
  }

  @override
  void initState() {
    super.initState();
    LogManager.addLog(
      'Initializing RiveManager for: ${widget.animationId}',
      isExpected: true,
    );
    _initRive();
  }

  @override
  void didUpdateWidget(RiveManager oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.externalFile != oldWidget.externalFile &&
        widget.externalFile != null) {
      LogManager.addLog(
        'External file changed for: ${widget.animationId}',
        isExpected: true,
      );
      loadExternalFile(widget.externalFile!);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      try {
        _controller!.stateMachine.removeEventListener(_onRiveEvent);
      } catch (e) {
        LogManager.addLog(
          'Error removing event listener: $e',
          isExpected: false,
        );
      }
    }

    RiveAnimationController.instance.deregister(widget.animationId);

    _inputChangedHandler?.dispose();

    for (var propInfo in _properties) {
      _disposeProperty(propInfo);

      if (propInfo['nestedProperties'] != null) {
        for (var nested in propInfo['nestedProperties']) {
          _disposePropertyRecursive(nested);
        }
      }
    }

    _propertyCache.clear();

    // Clean up headless texture resources
    _headlessPainter?.dispose();
    _headlessPainter = null;
    _renderTexture?.onTextureChanged = null;
    _renderTexture?.dispose();
    _renderTexture = null;

    _viewModelInstance?.dispose();
    _controller?.dispose();
    _file?.dispose();

    super.dispose();
  }

  /// Public API: Get all artboards from the current file
  List<Map<String, dynamic>> getArtboards() {
    if (_file == null) {
      LogManager.addLog(
        'Cannot get artboards: File is null for ${widget.animationId}',
        isExpected: false,
      );
      return [];
    }

    final List<Map<String, dynamic>> artboardList = [];
    int index = 0;

    while (true) {
      try {
        final artboard = _file!.artboardAt(index);
        if (artboard == null) break;

        artboardList.add({
          'name': artboard.name,
          'index': index,
          'artboard': artboard,
        });

        index++;
      } catch (_) {
        break;
      }
    }

    LogManager.addLog(
      'Retrieved ${artboardList.length} artboards for ${widget.animationId}',
      isExpected: true,
    );

    return artboardList;
  }

  /// Public API: Get the ImageAsset reference for this animation
  ImageAsset? getImageAsset() {
    if (_imageAssetReference == null) {
      LogManager.addLog(
        'No ImageAsset reference available for ${widget.animationId}',
        isExpected: false,
      );
    }
    return _imageAssetReference;
  }

  /// Public API: Get the FontAsset reference for this animation
  FontAsset? getFontAsset() {
    if (_fontAssetReference == null) {
      LogManager.addLog(
        'No FontAsset reference available for ${widget.animationId}',
        isExpected: false,
      );
    }
    return _fontAssetReference;
  }

  /// Public API: Update image from URL
  Future<void> updateImageFromUrl(String url) async {
    if (_imageAssetReference == null) {
      LogManager.addLog(
        'Cannot update image from URL: No image asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      LogManager.addLog(
        'Fetching image from URL for ${widget.animationId}: $url',
        isExpected: true,
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        LogManager.addLog(
          'HTTP error fetching image for ${widget.animationId}: ${response.statusCode}',
          isExpected: false,
        );
        return;
      }

      await _imageAssetReference!.decode(
        Uint8List.view(response.bodyBytes.buffer),
      );

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully loaded image from URL for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e, stack) {
      LogManager.addLog(
        'Failed to load image from URL for ${widget.animationId}: $e\n$stack',
        isExpected: false,
      );
    }
  }

  Future<void> _initRive() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    LogManager.markBuildPhaseStart();

    if (_isInitialized) {
      LogManager.addLog(
        'RiveManager already initialized for: ${widget.animationId}',
        isExpected: true,
      );
      LogManager.markBuildPhaseEnd();
      return;
    }

    try {
      LogManager.addLog(
        'Starting Rive initialization for: ${widget.animationId}',
        isExpected: true,
      );

      if (widget.fileLoader != null) {
        LogManager.addLog('Loading via FileLoader for ${widget.animationId}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
          }
        });
        LogManager.markBuildPhaseEnd();
        return;
      }

      if (widget.externalFile != null) {
        LogManager.addLog(
          'Loading external file for: ${widget.animationId}',
          isExpected: true,
        );
        loadExternalFile(widget.externalFile!);
        LogManager.markBuildPhaseEnd();
        return;
      }

      if (widget.riveFilePath != null) {
        if (widget.enableImageReplacement) {
          LogManager.addLog(
            'Loading Rive file with image replacement for: ${widget.animationId}',
            isExpected: true,
          );
          await _loadRiveFileWithImageReplacement();
        } else {
          LogManager.addLog(
            'Loading standard Rive file for: ${widget.animationId}',
            isExpected: true,
          );
          await _loadRiveFileStandard();
        }
      } else {
        LogManager.addLog(
          'No Rive file path or external file provided for: ${widget.animationId}',
          isExpected: false,
        );
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
          }
        });
      }

      LogManager.markBuildPhaseEnd();
    } catch (e) {
      LogManager.addLog(
        'RiveManager init failed for ${widget.animationId}: $e',
        isExpected: false,
      );
      LogManager.markBuildPhaseEnd();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadRiveFileStandard() async {
    try {
      _file = await File.asset(widget.riveFilePath!, riveFactory: Factory.rive);

      LogManager.addLog(
        'Rive file loaded from: ${widget.riveFilePath}',
        isExpected: true,
      );

      _controller = RiveWidgetController(_file!);
      _controller?.stateMachine.addEventListener(_onRiveEvent);

      await _discoverArtboards();
      await _discoverInputs();
      await _discoverDataBindingProperties();

      // Setup headless texture if in texture mode
      if (widget.renderMode == RiveRenderMode.texture) {
        await _setupHeadlessTexture();
      }

      RiveAnimationController.instance.register(widget.animationId, this);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
          }
          // Fire user callbacks AFTER setState so any parent setState
          // they trigger schedules on the next frame, not during this build.
          if (widget.onInit != null) {
            widget.onInit!(_controller!.artboard);
            LogManager.addLog(
              'onInit callback executed for: ${widget.animationId}',
              isExpected: true,
            );
          }
        });
      }

      LogManager.addLog(
        'Standard Rive file initialization complete for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to load standard Rive file for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  Future<void> _loadRiveFileWithImageReplacement() async {
    try {
      _file = await File.asset(
        widget.riveFilePath!,
        riveFactory: Factory.rive,
        assetLoader: (asset, bytes) {
          if (asset is ImageAsset && bytes == null) {
            _imageAssetReference = asset;
            RiveAnimationController.instance.registerImageAsset(
              widget.animationId,
              asset,
            );

            LogManager.addLog(
              'Image asset intercepted for: ${widget.animationId}',
              isExpected: true,
            );

            return true;
          }

          if (asset is FontAsset && bytes == null) {
            _fontAssetReference = asset;
            RiveAnimationController.instance.registerFontAsset(
              widget.animationId,
              asset,
            );

            LogManager.addLog(
              'Font asset intercepted for: ${widget.animationId}',
              isExpected: true,
            );

            return true;
          }

          return false;
        },
      );

      LogManager.addLog(
        'Rive file with image replacement loaded from: ${widget.riveFilePath}',
        isExpected: true,
      );

      _controller = RiveWidgetController(_file!);

      _controller?.stateMachine.addEventListener(_onRiveEvent);

      await _discoverInputs();
      await _discoverDataBindingProperties();
      await _discoverArtboards();

      // Setup headless texture if in texture mode
      if (widget.renderMode == RiveRenderMode.texture) {
        await _setupHeadlessTexture();
      }

      RiveAnimationController.instance.register(widget.animationId, this);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
          }
          // Fire user callbacks AFTER setState so any parent setState
          // they trigger schedules on the next frame, not during this build.
          if (widget.onInit != null) {
            widget.onInit!(_controller!.artboard);
          }
        });
      }

      LogManager.addLog(
        'Image replacement Rive file initialization complete for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to load Rive file with image replacement for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  /// Public API: Decode image from bytes
  Future<void> updateImageFromBytes(Uint8List bytes) async {
    if (_imageAssetReference == null) {
      LogManager.addLog(
        'Cannot update image from bytes: No image asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      await _imageAssetReference!.decode(bytes);

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully decoded and updated image for: ${widget.animationId} (${bytes.length} bytes)',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to decode image for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  /// Public API: Update image from pre-decoded RenderImage
  void updateImageFromRenderedImage(RenderImage renderImage) {
    if (_imageAssetReference == null) {
      LogManager.addLog(
        'Cannot update image from RenderImage: No image asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    setState(() {
      _imageAssetReference!.renderImage(renderImage);
    });

    LogManager.addLog(
      'Updated image from RenderImage for: ${widget.animationId}',
      isExpected: true,
    );
  }

  /// Public API: Load image from asset bundle
  Future<void> updateImageFromAsset(String assetPath) async {
    if (_imageAssetReference == null) {
      LogManager.addLog(
        'Cannot update image from asset: No image asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      LogManager.addLog(
        'Loading image from asset for ${widget.animationId}: $assetPath',
        isExpected: true,
      );

      final bytes = await rootBundle.load(assetPath);
      await _imageAssetReference!.decode(bytes.buffer.asUint8List());

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully loaded image from asset for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to load image from asset for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  // ========== FONT REPLACEMENT API ==========

  /// Public API: Update font from raw bytes (.ttf, .otf)
  Future<void> updateFontFromBytes(Uint8List bytes) async {
    if (_fontAssetReference == null) {
      LogManager.addLog(
        'Cannot update font from bytes: No font asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      await _fontAssetReference!.decode(bytes);

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully decoded and updated font for: ${widget.animationId} (${bytes.length} bytes)',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to decode font for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  /// Public API: Load font from asset bundle
  Future<void> updateFontFromAsset(String assetPath) async {
    if (_fontAssetReference == null) {
      LogManager.addLog(
        'Cannot update font from asset: No font asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      LogManager.addLog(
        'Loading font from asset for ${widget.animationId}: $assetPath',
        isExpected: true,
      );

      final bytes = await rootBundle.load(assetPath);
      await _fontAssetReference!.decode(bytes.buffer.asUint8List());

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully loaded font from asset for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Failed to load font from asset for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  /// Public API: Load font from URL
  Future<void> updateFontFromUrl(String url) async {
    if (_fontAssetReference == null) {
      LogManager.addLog(
        'Cannot update font from URL: No font asset for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    try {
      LogManager.addLog(
        'Fetching font from URL for ${widget.animationId}: $url',
        isExpected: true,
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        LogManager.addLog(
          'HTTP error fetching font for ${widget.animationId}: ${response.statusCode}',
          isExpected: false,
        );
        return;
      }

      await _fontAssetReference!.decode(
        Uint8List.view(response.bodyBytes.buffer),
      );

      if (mounted) {
        setState(() {});
      }

      LogManager.addLog(
        'Successfully loaded font from URL for: ${widget.animationId}',
        isExpected: true,
      );
    } catch (e, stack) {
      LogManager.addLog(
        'Failed to load font from URL for ${widget.animationId}: $e\n$stack',
        isExpected: false,
      );
    }
  }

  // ========== THUMBNAIL / SNAPSHOT API ==========

  /// Captures a snapshot of the current animation frame as a [ui.Image].
  ///
  /// In texture mode: uses `RenderTexture.toImage()` (GPU-direct, instant).
  /// In widget mode: creates a temporary RenderTexture, draws one frame,
  /// captures, then disposes.
  ///
  /// Returns null if the animation is not initialized.
  Future<ui.Image?> captureSnapshot({
    required int width,
    required int height,
  }) async {
    if (_controller == null) {
      LogManager.addLog(
        'Cannot capture snapshot: controller not initialized for ${widget.animationId}',
        isExpected: false,
      );
      return null;
    }

    try {
      // If we already have a render texture (texture mode), use it directly
      if (_renderTexture != null && _renderTexture!.isReady) {
        LogManager.addLog(
          'Capturing snapshot from existing RenderTexture for ${widget.animationId}',
          isExpected: true,
        );
        return await _renderTexture!.toImage();
      }

      // Widget mode: create a temporary texture, render one frame, capture
      final tempTexture = rive_native.RiveNative.instance.makeRenderTexture();
      await tempTexture.makeRenderTexture(width, height);

      // Draw one frame into the temp texture
      tempTexture.clear(const Color(0x00000000));
      final renderer = tempTexture.renderer;
      renderer.save();

      final artboard = _controller!.artboard;
      renderer.align(
        widget.fit,
        widget.alignment,
        AABB.fromValues(0, 0, width.toDouble(), height.toDouble()),
        artboard.bounds,
        widget.layoutScaleFactor,
      );
      artboard.draw(renderer);
      renderer.restore();
      tempTexture.flush(1.0);

      // Wait for the GPU to finish rendering before capturing.
      // rive_native ^0.1.0 pipelines rendering async — toImage() called
      // immediately after flush() may return a blank frame.
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture
      final image = await tempTexture.toImage();

      // Cleanup
      tempTexture.dispose();

      LogManager.addLog(
        'Captured snapshot from temp RenderTexture for ${widget.animationId} (${width}x$height)',
        isExpected: true,
      );

      return image;
    } catch (e) {
      LogManager.addLog(
        'Failed to capture snapshot for ${widget.animationId}: $e',
        isExpected: false,
      );
      return null;
    }
  }

  /// Convenience: captures a snapshot and returns PNG bytes directly.
  ///
  /// Returns null if the animation is not initialized or capture fails.
  Future<Uint8List?> captureSnapshotAsPng({
    required int width,
    required int height,
  }) async {
    final image = await captureSnapshot(width: width, height: height);
    if (image == null) return null;

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      LogManager.addLog(
        'Failed to encode snapshot as PNG for ${widget.animationId}: $e',
        isExpected: false,
      );
      return null;
    }
  }

  void loadExternalFile(File file) {
    try {
      _file = file;

      if (_file == null) {
        return;
      }

      LogManager.markBuildPhaseStart();
      _controller = RiveWidgetController(_file!);
      _isInitialized = false;
      inputs.clear();

      _controller?.stateMachine.addEventListener(_onRiveEvent);

      Future.wait([_discoverInputs(), _discoverDataBindingProperties()]).then((
        _,
      ) async {
        // Setup headless texture if in texture mode (GPU pipeline)
        if (widget.renderMode == RiveRenderMode.texture) {
          await _setupHeadlessTexture();
        }

        RiveAnimationController.instance.register(widget.animationId, this);

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
            // Fire user callbacks AFTER setState so any parent setState
            // they trigger schedules on the next frame, not during this build.
            if (widget.onInit != null) {
              widget.onInit!(_controller!.artboard);
            }
          });
        }

        LogManager.addLog(
          'External file loaded successfully for ${widget.animationId}',
          isExpected: true,
        );

        LogManager.markBuildPhaseEnd();
      }).catchError((e, stack) {
        LogManager.markBuildPhaseEnd();
      });
    } catch (e) {
      LogManager.addLog(
        'Failed to load external file for ${widget.animationId}: $e',
        isExpected: false,
      );
      LogManager.markBuildPhaseEnd();
    }
  }

  Future<void> _discoverArtboards() async {
    if (_file == null) {
      LogManager.addLog(
        'Cannot discover artboards: File is null for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    int index = 0;
    try {
      while (true) {
        final artboard = _file!.artboardAt(index);
        if (artboard == null) break;

        LogManager.addLog(
          'Discovered artboard $index for ${widget.animationId}: ${artboard.name}',
          isExpected: true,
        );
        index++;
      }

      LogManager.addLog(
        'Artboard discovery complete for ${widget.animationId}: Found $index artboard(s)',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Error during artboard discovery for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  Future<void> _discoverInputs() async {
    if (_controller == null) {
      LogManager.addLog(
        'Cannot discover inputs: Controller is null for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    LogManager.markBuildPhaseStart();

    int index = 0;
    try {
      while (true) {
        final input = _controller?.stateMachine.inputAt(index);
        if (input == null) break;

        inputs[input.name] = input;
        LogManager.addLog(
          'Discovered input $index for ${widget.animationId}: ${input.name} (${input.runtimeType})',
          isExpected: true,
        );
        index++;
      }

      if (inputs.isNotEmpty) {
        _inputChangedHandler = _controller?.stateMachine.onInputChanged(
          _onInputChanged,
        );
        LogManager.addLog(
          'Input change listener registered for: ${widget.animationId}',
          isExpected: true,
        );
      }

      LogManager.addLog(
        'Input discovery complete for ${widget.animationId}: Found ${inputs.length} input(s)',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Error during input discovery for ${widget.animationId}: $e',
        isExpected: false,
      );
    } finally {
      LogManager.markBuildPhaseEnd();
    }
  }

  void _onInputChanged(int index) {
    final input = _controller?.stateMachine.inputAt(index);
    if (input == null) return;

    if (input is TriggerInput) {
      LogManager.addLog(
        'Trigger input fired for ${widget.animationId}: ${input.name}',
        isExpected: true,
      );
      widget.onTriggerAction?.call(input.name, true);
    } else if (input is BooleanInput) {
      LogManager.addLog(
        'Boolean input changed for ${widget.animationId}: ${input.name} = ${input.value}',
        isExpected: true,
      );
      widget.onInputChange?.call(index, input.name, input.value);
      widget.onHoverAction?.call(input.name, input.value);
    } else if (input is NumberInput) {
      LogManager.addLog(
        'Number input changed for ${widget.animationId}: ${input.name} = ${input.value}',
        isExpected: true,
      );
      widget.onInputChange?.call(index, input.name, input.value);
    }

    if (_controller?.stateMachine.isDone == false) {
      LogManager.addLog(
        'Animation complete for: ${widget.animationId}',
        isExpected: true,
      );
      widget.onAnimationComplete?.call();
    }
  }

  void _onRiveEvent(Event event) {
    LogManager.addLog(
      'Event fired for ${widget.animationId}: ${event.name} (state: $_currentStateName)',
      isExpected: true,
    );
    widget.onEventChange?.call(event.name, event, _currentStateName);
  }

  Future<void> _discoverDataBindingProperties() async {
    if (_controller == null) {
      LogManager.addLog(
        'Cannot discover data binding: Controller is null for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    LogManager.markBuildPhaseStart();

    try {
      LogManager.addLog(
        'DEBUG: File state for ${widget.animationId}: '
        'file=${_file != null}, '
        'viewModelCount=${_file?.viewModelCount ?? "null"}',
        isExpected: true,
      );

      if (_file == null || _file!.viewModelCount == 0) {
        LogManager.addLog(
          'No ViewModels in file for ${widget.animationId} - skipping data binding',
          isExpected: true,
        );
        return;
      }

      LogManager.addLog(
        'Found ${_file!.viewModelCount} ViewModels in file for ${widget.animationId}',
        isExpected: true,
      );

      try {
        final bindStrategy = widget.dataBind ?? DataBind.auto();
        _viewModelInstance = _controller?.dataBind(bindStrategy);

        if (_viewModelInstance != null &&
            _viewModelInstance!.properties.isNotEmpty) {
          LogManager.addLog(
            'Discovered ViewModel for ${widget.animationId} with ${_viewModelInstance!.properties.length} properties (strategy: ${bindStrategy.runtimeType})',
            isExpected: true,
          );
          _processViewModelInstance(_viewModelInstance!);
        } else {
          LogManager.addLog(
            'Auto-discovery returned no ViewModel for ${widget.animationId}',
            isExpected: true,
          );
        }
      } catch (autoDiscoveryError) {
        LogManager.addLog(
          'Discovery failed for ${widget.animationId}: $autoDiscoveryError',
          isExpected: false,
        );
      }

      if (_viewModelInstance == null) {
        for (int i = 0; i < _file!.viewModelCount; i++) {
          try {
            final viewModel = _file!.viewModelByIndex(i);
            if (viewModel != null) {
              final vmInstance = viewModel.createDefaultInstance();
              if (vmInstance != null && vmInstance.properties.isNotEmpty) {
                _viewModelInstance = _controller?.dataBind(
                  DataBind.byInstance(vmInstance),
                );

                if (_viewModelInstance != null) {
                  LogManager.addLog(
                    'Bound ViewModel $i for ${widget.animationId} with ${vmInstance.properties.length} properties',
                    isExpected: true,
                  );
                  _processViewModelInstance(_viewModelInstance!);
                  break;
                }
              }
            }
          } catch (vmError) {
            LogManager.addLog(
              'Failed to bind ViewModel $i for ${widget.animationId}: $vmError',
              isExpected: false,
            );
          }
        }
      }

      if (_properties.isNotEmpty) {
        // Defer the callback to a post-frame callback so any parent setState
        // it triggers doesn't overlap with the current build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onViewModelPropertiesDiscovered?.call(_properties);
          }
        });
        LogManager.addLog(
          'Discovered ${_properties.length} properties for ${widget.animationId}',
          isExpected: true,
        );
      }
    } catch (e) {
      LogManager.addLog(
        'Error discovering data binding for ${widget.animationId}: $e',
        isExpected: false,
      );
    } finally {
      LogManager.markBuildPhaseEnd();
    }
  }

  void _processViewModelInstance(ViewModelInstance vmInstance) {
    for (final property in vmInstance.properties) {
      final name = property.name;
      final type = property.type;

      if (type == DataType.string) {
        final stringProp = vmInstance.string(name);
        _properties.add({
          'name': name,
          'type': 'string',
          'value': stringProp?.value ?? '',
          'property': stringProp,
        });

        stringProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'string', value);
        });
      } else if (type == DataType.trigger) {
        final triggerProp = vmInstance.trigger(name);
        _properties.add({
          'name': name,
          'type': 'trigger',
          'value': null,
          'property': triggerProp,
        });

        // ✅ Add the boolean parameter (usually true when fired)
        triggerProp?.addListener((bool triggered) {
          if (triggered) {
            widget.onDataBindingChange?.call(name, 'trigger', true);
          }
        });

        LogManager.addLog(
          'Discovered trigger property: $name',
          isExpected: true,
        );
      } else if (type == DataType.number) {
        final numberProp = vmInstance.number(name);
        _properties.add({
          'name': name,
          'type': 'number',
          'value': numberProp?.value ?? 0.0,
          'property': numberProp,
        });

        numberProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'number', value);
        });
      } else if (type == DataType.boolean) {
        final boolProp = vmInstance.boolean(name);
        _properties.add({
          'name': name,
          'type': 'boolean',
          'value': boolProp?.value ?? false,
          'property': boolProp,
        });

        boolProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'boolean', value);
        });
      } else if (type == DataType.color) {
        final colorProp = vmInstance.color(name);
        _properties.add({
          'name': name,
          'type': 'color',
          'value': colorProp?.value ?? Colors.transparent,
          'property': colorProp,
        });

        colorProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'color', value);
        });
      } else if (type == DataType.image) {
        final imageProp = vmInstance.image(name);
        _properties.add({
          'name': name,
          'type': 'image',
          'value': null,
          'property': imageProp,
        });
      } else if (type == DataType.enumType) {
        final enumProp = vmInstance.enumerator(name);
        _properties.add({
          'name': name,
          'type': 'enumType',
          'value': enumProp?.value ?? '',
          'enumTypeName': enumProp?.enumType ?? '',
          'property': enumProp,
        });

        enumProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'enumType', value);
        });
      } else if (type == DataType.viewModel) {
        final nestedVM = vmInstance.viewModel(name);
        if (nestedVM != null) {
          _properties.add({
            'name': name,
            'type': 'viewModel',
            'value': null,
            'property': nestedVM,
            'nestedProperties': _discoverNestedProperties(
              nestedVM,
              name,
            ),
          });

          LogManager.addLog(
            'Discovered nested ViewModel property: $name',
            isExpected: true,
          );
        }
      } else if (type == DataType.integer) {
        // Integer uses the same ViewModelInstanceNumber API
        final numberProp = vmInstance.number(name);
        _properties.add({
          'name': name,
          'type': 'integer',
          'value': numberProp?.value.toInt() ?? 0,
          'property': numberProp,
        });

        numberProp?.addListener((value) {
          widget.onDataBindingChange?.call(name, 'integer', value.toInt());
        });
      } else if (type == DataType.list) {
        final listProp = vmInstance.list(name);
        if (listProp != null) {
          // Discover list items as nested ViewModelInstances
          final List<Map<String, dynamic>> listItems = [];
          for (int i = 0; i < listProp.length; i++) {
            try {
              final itemVM = listProp.instanceAt(i);
              listItems.add({
                'index': i,
                'name': itemVM.name,
                'properties': _discoverNestedProperties(itemVM, '$name[$i]'),
              });
            } catch (e) {
              LogManager.addLog(
                'Error accessing list item $i for $name in ${widget.animationId}: $e',
                isExpected: false,
              );
            }
          }

          _properties.add({
            'name': name,
            'type': 'list',
            'value': listProp.length,
            'property': listProp,
            'listItems': listItems,
          });

          LogManager.addLog(
            'Discovered list property: $name with ${listProp.length} items',
            isExpected: true,
          );
        }
      } else if (type == DataType.artboard) {
        final artboardProp = vmInstance.artboard(name);
        _properties.add({
          'name': name,
          'type': 'artboard',
          'value': null,
          'property': artboardProp,
        });

        LogManager.addLog(
          'Discovered artboard property: $name',
          isExpected: true,
        );
      } else if (type == DataType.symbolListIndex) {
        // SymbolListIndex is an observable integer property
        final prop = vmInstance.number(name);
        _properties.add({
          'name': name,
          'type': 'symbolListIndex',
          'value': prop?.value.toInt() ?? 0,
          'property': prop,
        });

        prop?.addListener((value) {
          widget.onDataBindingChange
              ?.call(name, 'symbolListIndex', value.toInt());
        });
      } else if (type == DataType.none) {
        LogManager.addLog(
          'Skipping DataType.none property: $name in ${widget.animationId}',
          isExpected: true,
        );
      } else {
        LogManager.addLog(
          'Unsupported property type for ${widget.animationId}: $name (${type.name})',
          isExpected: false,
        );
      }
    }

    LogManager.addLog(
      'ViewModel processing complete for ${widget.animationId}: '
      'Processed ${_properties.length}/${vmInstance.properties.length} properties',
      isExpected: true,
    );
  }

  /// Discover nested ViewModel properties recursively
  List<Map<String, dynamic>> _discoverNestedProperties(
    ViewModelInstance nestedVM,
    String parentName,
  ) {
    List<Map<String, dynamic>> nestedProps = [];
    int processedCount = 0;

    for (var propDesc in nestedVM.properties) {
      final propType = propDesc.type;
      final propName = propDesc.name;
      final fullPath = '$parentName/$propName';

      Map<String, dynamic> nestedInfo = {
        'name': propName,
        'fullPath': fullPath,
        'type': propType.name,
        'dataType': propType,
      };

      try {
        switch (propType) {
          case DataType.number:
            final prop = nestedVM.number(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value;
              prop.addListener((newValue) {
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue);
                }
              });
              processedCount++;
            }
            break;

          case DataType.boolean:
            final prop = nestedVM.boolean(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value;
              prop.addListener((newValue) {
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue);
                }
              });
              processedCount++;
            }
            break;

          case DataType.string:
            final prop = nestedVM.string(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value;
              prop.addListener((newValue) {
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue);
                }
              });
              processedCount++;
            }
            break;
          case DataType.trigger:
            final prop = nestedVM.trigger(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = null;

              prop.addListener((bool fired) {
                // We pass 'true' to your callback to notify Flutter the trigger happened
                widget.onDataBindingChange?.call(fullPath, 'trigger', true);
                if (mounted) {
                  _safeSetState(() {});
                }
              });
              processedCount++;
            }
            break;
          case DataType.viewModel:
            final deepNestedVM = nestedVM.viewModel(propName);
            if (deepNestedVM != null) {
              nestedInfo['property'] = deepNestedVM;
              nestedInfo['nestedProperties'] = _discoverNestedProperties(
                deepNestedVM,
                fullPath,
              );
              processedCount++;
            }
            break;

          case DataType.color:
            final prop = nestedVM.color(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value;
              prop.addListener((newValue) {
                widget.onDataBindingChange?.call(fullPath, 'color', newValue);
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue);
                }
              });
              processedCount++;
            }
            break;

          case DataType.image:
            final prop = nestedVM.image(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = null;
              processedCount++;
            }
            break;

          case DataType.enumType:
            final prop = nestedVM.enumerator(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value;
              nestedInfo['enumTypeName'] = prop.enumType;
              prop.addListener((newValue) {
                widget.onDataBindingChange
                    ?.call(fullPath, 'enumType', newValue);
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue);
                }
              });
              processedCount++;
            }
            break;

          case DataType.integer:
            final prop = nestedVM.number(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value.toInt();
              prop.addListener((newValue) {
                widget.onDataBindingChange
                    ?.call(fullPath, 'integer', newValue.toInt());
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue.toInt());
                }
              });
              processedCount++;
            }
            break;

          case DataType.list:
            final listProp = nestedVM.list(propName);
            if (listProp != null) {
              nestedInfo['property'] = listProp;
              nestedInfo['value'] = listProp.length;
              final List<Map<String, dynamic>> listItems = [];
              for (int i = 0; i < listProp.length; i++) {
                try {
                  final itemVM = listProp.instanceAt(i);
                  listItems.add({
                    'index': i,
                    'name': itemVM.name,
                    'properties':
                        _discoverNestedProperties(itemVM, '$fullPath[$i]'),
                  });
                } catch (e) {
                  LogManager.addLog(
                    'Error accessing nested list item $i for $fullPath: $e',
                    isExpected: false,
                  );
                }
              }
              nestedInfo['listItems'] = listItems;
              processedCount++;
            }
            break;

          case DataType.artboard:
            final prop = nestedVM.artboard(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = null;
              processedCount++;
            }
            break;

          case DataType.symbolListIndex:
            final prop = nestedVM.number(propName);
            if (prop != null) {
              nestedInfo['property'] = prop;
              nestedInfo['value'] = prop.value.toInt();
              prop.addListener((newValue) {
                widget.onDataBindingChange
                    ?.call(fullPath, 'symbolListIndex', newValue.toInt());
                if (mounted) {
                  _safeSetState(() => nestedInfo['value'] = newValue.toInt());
                }
              });
              processedCount++;
            }
            break;

          case DataType.none:
            // Skip none type properties
            break;
        }

        nestedProps.add(nestedInfo);
      } catch (e) {
        LogManager.addLog(
          'Error processing nested property "$fullPath" for ${widget.animationId}: $e',
          isExpected: false,
        );
      }
    }

    LogManager.addLog(
      'Nested property discovery complete for $parentName in ${widget.animationId}: $processedCount properties',
      isExpected: true,
    );

    return nestedProps;
  }

  /// Public API: Select artboard by name
  void selectArtboardByName(String artboardName) {
    if (_file == null) {
      LogManager.addLog(
        'Cannot select artboard "$artboardName": File is null for ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    final chosenArtboard = _file!.artboard(artboardName);
    if (chosenArtboard == null) {
      LogManager.addLog(
        'Artboard "$artboardName" not found in ${widget.animationId}',
        isExpected: false,
      );
      return;
    }

    LogManager.addLog(
      'Selecting artboard "$artboardName" for: ${widget.animationId}',
      isExpected: true,
    );

    setState(() {
      _controller = RiveWidgetController(
        _file!,
        artboardSelector: ArtboardSelector.byName(artboardName),
      );
      _isInitialized = false;
      inputs.clear();
    });

    _controller?.stateMachine.addEventListener(_onRiveEvent);

    _discoverInputs();
    _discoverDataBindingProperties();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
      // Fire user callback AFTER setState
      if (widget.onInit != null) {
        widget.onInit!(_controller!.artboard);
      }
    });

    LogManager.addLog(
      'Artboard selection complete for ${widget.animationId}: "$artboardName"',
      isExpected: true,
    );
  }

  void _disposeProperty(Map<String, dynamic> propInfo) {
    final prop = propInfo['property'];
    if (prop is ViewModelInstanceNumber ||
        prop is ViewModelInstanceBoolean ||
        prop is ViewModelInstanceString ||
        prop is ViewModelInstanceColor ||
        prop is ViewModelInstanceEnum ||
        prop is ViewModelInstanceTrigger) {
      (prop as dynamic).clearListeners();
      (prop as dynamic).dispose();
    } else if (prop is ViewModelInstance) {
      prop.dispose();
    }
  }

  void _disposePropertyRecursive(Map<String, dynamic> propInfo) {
    _disposeProperty(propInfo);
    if (propInfo['nestedProperties'] != null) {
      for (var deepNested in propInfo['nestedProperties']) {
        _disposePropertyRecursive(deepNested);
      }
    }
  }

  // === RenderTexture Setup (Approach B) ===

  /// Creates the headless GPU texture and painter for texture render mode.
  /// Called after _controller is set up and data binding is discovered.
  Future<void> _setupHeadlessTexture() async {
    if (_controller == null) {
      return;
    }

    try {
      // Create the GPU texture
      _renderTexture = rive_native.RiveNative.instance.makeRenderTexture();
      await _renderTexture!.makeRenderTexture(
        widget.textureWidth,
        widget.textureHeight,
      );

      // Create the headless painter that drives the render loop
      _headlessPainter = HeadlessRivePainter(
        controller: _controller!,
        fit: widget.fit,
        alignment: widget.alignment,
        layoutScaleFactor: widget.layoutScaleFactor,
      );

      LogManager.addLog(
        'Headless RenderTexture created: ${widget.textureWidth}x${widget.textureHeight} '
        'for ${widget.animationId}',
        isExpected: true,
      );

      // Fire callbacks
      widget.onTextureReady?.call(_renderTexture!);

      if (_renderTexture!.nativeTexture != null) {
        final address = _renderTexture!.nativeTexture.address;
        widget.onNativeTexturePointer?.call(address);
        LogManager.addLog(
          'Native texture pointer: 0x${address.toRadixString(16)} '
          'for ${widget.animationId}',
          isExpected: true,
        );
      }

      // Fire renderer pointer callback for dynamic texture resolution
      // NOTE: nativeRendererPointer may not be available in all rive_native versions
      try {
        final rendererPtr = (_renderTexture as dynamic).nativeRendererPointer;
        if (rendererPtr != null) {
          final rendererAddress = rendererPtr.address as int;
          if (rendererAddress != 0) {
            widget.onRendererPointer?.call(rendererAddress);
            LogManager.addLog(
              'Renderer pointer: 0x${rendererAddress.toRadixString(16)} '
              'for ${widget.animationId}',
              isExpected: true,
            );
          }
        }
      } catch (_) {
        // nativeRendererPointer not available in this rive_native version
      }

      // Wire re-registration: when rive_native's performLayout() recreates
      // the MTLTexture (e.g. due to devicePixelRatio scaling), the bus
      // must be updated with the new pointer.
      _renderTexture!.onTextureChanged = () {
        if (!mounted) return;
        final tex = _renderTexture;
        if (tex == null || tex.isDisposed) return;
        try {
          final ptr = tex.nativeTexture;
          if (ptr != null) {
            final address = ptr.address;
            widget.onNativeTexturePointer?.call(address);
            LogManager.addLog(
              'Texture re-created, new pointer: 0x${address.toRadixString(16)} '
              'for ${widget.animationId}',
              isExpected: true,
            );
          }
          // Also re-register the renderer pointer for dynamic texture resolution
          try {
            final rendererPtr = (tex as dynamic).nativeRendererPointer;
            if (rendererPtr != null) {
              final rendererAddress = rendererPtr.address as int;
              if (rendererAddress != 0) {
                widget.onRendererPointer?.call(rendererAddress);
                LogManager.addLog(
                  'Renderer re-registered: 0x${rendererAddress.toRadixString(16)} '
                  'for ${widget.animationId}',
                  isExpected: true,
                );
              }
            }
          } catch (_) {
            // nativeRendererPointer not available in this rive_native version
          }
        } catch (e) {
          LogManager.addLog(
            'onTextureChanged error for ${widget.animationId}: $e',
            isExpected: false,
          );
        }
      };
    } catch (e) {
      LogManager.addLog(
        'Failed to setup headless texture for ${widget.animationId}: $e',
        isExpected: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 CPU OPTIMIZATION: Stop rendering/ticking if TickerMode is disabled (e.g. hidden tab)
    // 🚀 GPU PIPELINE: Don't stop headless texture rendering when ticker is
    // disabled (e.g. stealth mode). The Metal compositor reads this texture
    // directly — it doesn't flow through Flutter's visual pipeline.
    final tickerEnabled = TickerMode.of(context);
    if (!tickerEnabled) {}
    if (!tickerEnabled && widget.renderMode != RiveRenderMode.texture) {
      return const SizedBox.shrink();
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // === TEXTURE MODE: Headless GPU rendering ===
    if (widget.renderMode == RiveRenderMode.texture && _renderTexture != null) {
      // The texture widget drives the render loop via its internal ticker.
      // CRITICAL FIX #1 - CONSTRAINTS: The Rive RenderObject uses its Flutter
      // layout size to determine GPU texture resolution (via performLayout).
      // If parent constraints are small (e.g. stealth mode → 1px window),
      // performLayout resizes the MTLTexture. OverflowBox OVERRIDES parent
      // constraints with exact texture dimensions.
      //
      // CRITICAL FIX #2 - TICKER: The RenderTexture widget uses an internal
      // ticker that respects TickerMode.of(context). In stealth mode, the
      // parent window disables TickerMode, muting the ticker → no paint
      // calls → transparent texture. TickerMode(enabled: true) forces the
      // render loop to keep running so the GPU texture stays populated.
      return TickerMode(
        enabled: true,
        child: SizedBox.shrink(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: widget.textureWidth.toDouble(),
            maxWidth: widget.textureWidth.toDouble(),
            minHeight: widget.textureHeight.toDouble(),
            maxHeight: widget.textureHeight.toDouble(),
            child: _renderTexture!.widget(painter: _headlessPainter),
          ),
        ),
      );
    }

    // === WIDGET MODE: Standard visible rendering ===
    if (widget.fileLoader != null) {
      return RiveWidgetBuilder(
        fileLoader: widget.fileLoader!,
        artboardSelector: const ArtboardDefault(),
        stateMachineSelector: const StateMachineDefault(),
        builder: (context, state) {
          if (state is RiveLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RiveFailed) {
            return ErrorWidget(state.error);
          } else if (state is RiveLoaded) {
            return RiveWidget(
              controller: state.controller,
              fit: widget.fit,
              alignment: widget.alignment,
              hitTestBehavior: widget.hitTestBehavior,
              cursor: widget.cursor,
              layoutScaleFactor: widget.layoutScaleFactor,
            );
          } else {
            return const SizedBox.shrink();
          }
        },
        onFailed: (error, stack) {
          LogManager.addLog('Rive load failed: $error', isExpected: false);
        },
        onLoaded: (riveLoaded) async {
          // ✅ STORE THE CONTROLLER AND FILE
          _controller = riveLoaded.controller;
          _file = riveLoaded.file;

          // ✅ SETUP EVENT LISTENER
          _controller?.stateMachine.addEventListener(_onRiveEvent);

          // ✅ DISCOVER INPUTS & PROPERTIES
          await Future.wait([
            _discoverInputs(),
            _discoverDataBindingProperties(),
          ]);

          // ✅ SETUP HEADLESS TEXTURE IF NEEDED
          if (widget.renderMode == RiveRenderMode.texture) {
            await _setupHeadlessTexture();
          }

          // ✅ REGISTER WITH GLOBAL CONTROLLER
          RiveAnimationController.instance.register(widget.animationId, this);

          // ✅ CALL USER CALLBACK (deferred to post-frame to avoid dirty widget assertions)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onInit?.call(riveLoaded.controller.artboard);
            }
          });

          LogManager.addLog(
            'FileLoader animation fully initialized: ${widget.animationId}',
            isExpected: true,
          );
        },
      );
    }

    return RiveWidget(
      controller: _controller!,
      fit: widget.fit,
      alignment: widget.alignment,
      hitTestBehavior: widget.hitTestBehavior,
      cursor: widget.cursor,
      layoutScaleFactor: widget.layoutScaleFactor,
    );
  }
}
