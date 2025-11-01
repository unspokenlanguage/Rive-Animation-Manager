// lib/src/widgets/rive_manager.dart


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;


import '../controller/rive_animation_controller.dart';
import '../helpers/log_manager.dart';
import '../models/rive_animation_type.dart';
import 'package:rive_animation_manager/rive.dart';

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

  // Display properties
  final Fit fit;
  final Alignment alignment;
  final RiveHitTestBehavior hitTestBehavior;
  final MouseCursor cursor;
  final double layoutScaleFactor;

  // Image replacement
  final bool enableImageReplacement;
  final ImageAsset? imageAssetReference;

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
    this.fit = Fit.contain,
    this.alignment = Alignment.center,
    this.hitTestBehavior = RiveHitTestBehavior.opaque,
    this.cursor = MouseCursor.defer,
    this.layoutScaleFactor = 1.0,
    this.enableImageReplacement = false,
    this.imageAssetReference,
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

  //String _previousStateName = '';
  String _currentStateName = '';
  bool _isInitialized = false;

  // State machine inputs
  final Map<String, Input> inputs = {};

  // Data binding properties
  final List<Map<String, dynamic>> _properties = [];

  // Image asset reference
  ImageAsset? _imageAssetReference;

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

  // ========== END PUBLIC GETTERS ==========

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
        LogManager.addLog('Error removing event listener: $e', isExpected: false);
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

    if (_isInitialized) {
      LogManager.addLog(
        'RiveManager already initialized for: ${widget.animationId}',
        isExpected: true,
      );
      return;
    }

    try {
      LogManager.addLog(
        'Starting Rive initialization for: ${widget.animationId}',
        isExpected: true,
      );

      if (widget.fileLoader != null) {
        LogManager.addLog('Loading via FileLoader for ${widget.animationId}');
        setState(() => _isInitialized = true);
        return;
      }

      if (widget.externalFile != null) {
        LogManager.addLog(
          'Loading external file for: ${widget.animationId}',
          isExpected: true,
        );
        loadExternalFile(widget.externalFile!);
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
      setState(() => _isInitialized = true);
    } catch (e) {
      LogManager.addLog(
        'RiveManager init failed for ${widget.animationId}: $e',
        isExpected: false,
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadRiveFileStandard() async {
    try {
      _file = await File.asset(
        widget.riveFilePath!,
        riveFactory: Factory.rive,
      );

      LogManager.addLog(
        'Rive file loaded from: ${widget.riveFilePath}',
        isExpected: true,
      );

      _controller = RiveWidgetController(_file!);

      _controller?.stateMachine.addEventListener(_onRiveEvent);

      await _discoverArtboards();
      await _discoverInputs();
      await _discoverDataBindingProperties();

      RiveAnimationController.instance.register(widget.animationId, this);

      if (widget.onInit != null) {
        widget.onInit!(_controller!.artboard);
        LogManager.addLog(
          'onInit callback executed for: ${widget.animationId}',
          isExpected: true,
        );
      }

      setState(() => _isInitialized = true);

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
            RiveAnimationController.instance
                .registerImageAsset(widget.animationId, asset);

            LogManager.addLog(
              'Image asset intercepted for: ${widget.animationId}',
              isExpected: true,
            );

            return true;
          }

          if (asset is FontAsset && bytes == null) {
            LogManager.addLog(
              'Font asset detected for: ${widget.animationId}',
              isExpected: true,
            );
            return false;
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

      RiveAnimationController.instance.register(widget.animationId, this);

      if (widget.onInit != null) {
        widget.onInit!(_controller!.artboard);
      }

      setState(() => _isInitialized = true);

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

  void loadExternalFile(File file) {
    try {
      _file = file;

      if (_file == null) {
        LogManager.addLog(
          'External file is null for ${widget.animationId}',
          isExpected: false,
        );
        return;
      }

      _controller = RiveWidgetController(_file!);
      _isInitialized = false;
      inputs.clear();

      _controller?.stateMachine.addEventListener(_onRiveEvent);

      Future.wait([
        _discoverInputs(),
        _discoverDataBindingProperties(),
      ]).then((_) {
        RiveAnimationController.instance.register(widget.animationId, this);

        if (widget.onInit != null) {
          widget.onInit!(_controller!.artboard);
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }

        LogManager.addLog(
          'External file loaded successfully for ${widget.animationId}',
          isExpected: true,
        );
      });
    } catch (e) {
      LogManager.addLog(
        'Failed to load external file for ${widget.animationId}: $e',
        isExpected: false,
      );
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
      try {
        _viewModelInstance = _controller?.dataBind(DataBind.auto());

        if (_viewModelInstance != null &&
            _viewModelInstance!.properties.isNotEmpty) {
          LogManager.addLog(
            'Auto-discovered ViewModel for ${widget.animationId} with ${_viewModelInstance!.properties.length} properties',
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
          'Auto-discovery failed for ${widget.animationId}: $autoDiscoveryError',
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
                _viewModelInstance =
                    _controller?.dataBind(DataBind.byInstance(vmInstance));

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
        widget.onViewModelPropertiesDiscovered?.call(_properties);
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
      } else if (type == DataType.number) {
        final numberProp = vmInstance.number(name);
        _properties.add({
          'name': name,
          'type': 'number',
          'value': numberProp?.value ?? 0.0,
          'property': numberProp,
        });
      } else if (type == DataType.boolean) {
        final boolProp = vmInstance.boolean(name);
        _properties.add({
          'name': name,
          'type': 'boolean',
          'value': boolProp?.value ?? false,
          'property': boolProp,
        });
      } else if (type == DataType.color) {
        final colorProp = vmInstance.color(name);
        _properties.add({
          'name': name,
          'type': 'color',
          'value': colorProp?.value ?? Colors.transparent,
          'property': colorProp,
        });
      } else if (type == DataType.image) {
        final imageProp = vmInstance.image(name);
        _properties.add({
          'name': name,
          'type': 'image',
          'value': null,
          'property': imageProp,
        });

        LogManager.addLog(
          'Discovered image property: $name',
          isExpected: true,
        );
      } else if (type == DataType.enumType) {
        final enumProp = vmInstance.enumerator(name);
        _properties.add({
          'name': name,
          'type': 'enumType',
          'value': enumProp?.value ?? '',
          'property': enumProp,
        });
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

    if (widget.onInit != null) {
      widget.onInit!(_controller!.artboard);
    }

    setState(() => _isInitialized = true);

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
        prop is ViewModelInstanceEnum) {
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
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
        onLoaded: (riveLoaded) {
          widget.onInit?.call(riveLoaded.controller.artboard);
          LogManager.addLog('Rive loaded: ${widget.animationId}',
              isExpected: true);
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
