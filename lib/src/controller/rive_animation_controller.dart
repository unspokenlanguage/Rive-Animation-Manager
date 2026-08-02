import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:rive_native/rive_native.dart';
import '../helpers/io_stub.dart' if (dart.library.io) 'dart:io' as io;
import '../helpers/log_manager.dart';
import '../widgets/rive_manager.dart';
import 'package:flutter/material.dart';

/// Global singleton controller for managing all Rive animations across the app.
class RiveAnimationController {
  static final RiveAnimationController _instance =
      RiveAnimationController._internal();

  factory RiveAnimationController() => _instance;

  RiveAnimationController._internal();

  static RiveAnimationController get instance => _instance;

  // Registry of all active animations
  final Map<String, RiveManagerState> _animations = {};
  final Map<String, ImageAsset> _imageAssets = {};
  final Map<String, FontAsset> _fontAssets = {};
  final Map<String, List<RenderImage>> _imageCache = {};
  final Map<String, Map<String, Map<String, dynamic>>> _propertyPathCache = {};

  /// Remembers the element view-model name used for each list, keyed by
  /// `animationId → listName → itemViewModelName`. Lets callers name the item
  /// view-model once (on the first [addListItem]) and omit it afterwards.
  final Map<String, Map<String, String>> _listItemViewModels = {};

  /// Register an animation instance
  void register(String animationId, RiveManagerState state) {
    _animations[animationId] = state;
    LogManager.addLog(
      'Registered animation: $animationId',
      isExpected: true,
    );
  }

  /// Get Artboards from an animation
  List<Map<String, dynamic>> getArtboards(String animationId) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot get Artboards: Animation $animationId not found',
        isExpected: false,
      );
      return [];
    }

    return state.getArtboards();
  }

  /// Determine the type of a Rive input
  String getInputType(Input input) {
    try {
      final trigger = input as TriggerInput;
      trigger.fire();
      return 'trigger';
    } catch (_) {}

    try {
      final bool = input as BooleanInput;
      final _ = bool.value;
      return 'bool';
    } catch (_) {}

    try {
      final number = input as NumberInput;
      final _ = number.value;
      return 'number';
    } catch (_) {}

    return 'unknown';
  }

  /// Clear property path cache for a specific animation
  void clearPropertyCache(String animationId) {
    _propertyPathCache.remove(animationId);
    LogManager.addLog('Cleared property cache for $animationId');
  }

  /// Clear all property path caches
  void clearAllPropertyCaches() {
    final count = _propertyPathCache.length;
    _propertyPathCache.clear();
    LogManager.addLog('Cleared property cache for $count animations');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    int totalCachedPaths = 0;
    for (var cache in _propertyPathCache.values) {
      totalCachedPaths += cache.length;
    }

    return {
      'animations': _animations.length,
      'imageAssets': _imageAssets.length,
      'cachedImageSets': _imageCache.length,
      'totalCachedImages':
          _imageCache.values.fold(0, (sum, list) => sum + list.length),
      'animationsWithPropertyCache': _propertyPathCache.length,
      'totalCachedPropertyPaths': totalCachedPaths,
    };
  }

  /// Deregister an animation and clean up resources
  void deregister(String animationId) {
    _animations.remove(animationId);
    _imageAssets.remove(animationId);
    _fontAssets.remove(animationId);

    final cache = _imageCache.remove(animationId);
    if (cache != null) {
      for (var image in cache) {
        try {
          image.dispose();
        } catch (_) {}
      }
      LogManager.addLog(
          'Cleared ${cache.length} cached images for $animationId');
    }

    _propertyPathCache.remove(animationId);
    _listItemViewModels.remove(animationId);
    LogManager.addLog('Deregistered animation: $animationId', isExpected: true);
  }

  /// Get the native GPU texture pointer address for an animation.
  ///
  /// Returns the MTLTexture pointer address on macOS, or null if the
  /// animation is not in texture render mode or hasn't been initialized.
  ///
  /// Use this for FFI-based IOSurface integration in broadcast pipelines.
  ///
  /// Example:
  /// ```dart
  /// final pointer = RiveAnimationController.instance
  ///     .getNativeTexturePointer('myAnimation');
  /// if (pointer != null) {
  ///   // Pass to native code via FFI
  ///   nativeBridge.attachTexture(Pointer.fromAddress(pointer));
  /// }
  /// ```
  int? getNativeTexturePointer(String animationId) {
    final state = _animations[animationId];
    if (state?.renderTexture == null) {
      LogManager.addLog(
        'No render texture for $animationId (not in texture mode?)',
        isExpected: false,
      );
      return null;
    }
    try {
      final nativePtr = state!.renderTexture!.nativeTexture;
      if (nativePtr == null) return null;
      return nativePtr.address;
    } catch (e) {
      LogManager.addLog(
        'Failed to get native texture pointer for $animationId: $e',
        isExpected: false,
      );
      return null;
    }
  }

  /// Update a data binding property by name
  Future<bool> updateDataBindingProperty(
    String animationId,
    String propertyName,
    dynamic newValue,
  ) async {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot update property: Animation $animationId not found',
        isExpected: false,
      );
      return false;
    }

    final propertyInfo = state.properties.firstWhere(
      (prop) => prop['name'] == propertyName,
      orElse: () => <String, dynamic>{},
    );

    if (propertyInfo.isEmpty) {
      LogManager.addLog(
        'Property $propertyName not found in animation $animationId',
        isExpected: false,
      );
      return false;
    }

    final propertyInstance = propertyInfo['property'];
    final propertyType = propertyInfo['type'] as String;

    return await _updatePropertyInstance(
      propertyInstance,
      propertyType,
      newValue,
      propertyInfo,
      propertyName,
      animationId,
    );
  }

  /// Update a nested property using path notation
  Future<bool> updateNestedProperty(
    String animationId,
    String fullPath,
    dynamic newValue,
  ) async {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog('Animation $animationId not found', isExpected: false);
      return false;
    }

    List<String> pathParts;
    if (fullPath.contains('/')) {
      pathParts = fullPath.split('/');
    } else if (fullPath.contains('.')) {
      pathParts = fullPath.split('.');
    } else {
      pathParts = [fullPath];
    }

    if (pathParts.length < 2) {
      return await updateDataBindingProperty(animationId, fullPath, newValue);
    }

    final cacheKey = pathParts.join('/');
    final animationCache = _propertyPathCache[animationId];

    if (animationCache != null && animationCache.containsKey(cacheKey)) {
      final cachedProperty = animationCache[cacheKey]!;
      final propertyInstance = cachedProperty['property'];
      final propertyType = cachedProperty['type'] as String;

      LogManager.addLog('Using cached property path: $cacheKey',
          isExpected: true);

      return await _updatePropertyInstance(
        propertyInstance,
        propertyType,
        newValue,
        cachedProperty,
        fullPath,
        animationId,
      );
    }

    Map<String, dynamic>? findNestedProperty(
      List<Map<String, dynamic>> props,
      List<String> path,
      int index,
    ) {
      if (index >= path.length) return null;

      String currentName = path[index];

      // Handle array indices like tickerItems[1]
      int? listIndex;
      final bracketIndex = currentName.indexOf('[');
      if (bracketIndex != -1 && currentName.endsWith(']')) {
        final indexStr =
            currentName.substring(bracketIndex + 1, currentName.length - 1);
        listIndex = int.tryParse(indexStr);
        currentName = currentName.substring(0, bracketIndex);
      }

      for (final prop in props) {
        if (prop['name'] == currentName) {
          if (index == path.length - 1) {
            return prop;
          }

          // If it's a list and we parsed an index
          if (prop['type'] == 'list' && listIndex != null) {
            final listItems = prop['listItems'] as List<Map<String, dynamic>>?;
            if (listItems != null &&
                listIndex >= 0 &&
                listIndex < listItems.length) {
              final item = listItems[listIndex];
              final itemProps =
                  item['properties'] as List<Map<String, dynamic>>?;
              if (itemProps != null) {
                return findNestedProperty(itemProps, path, index + 1);
              }
            }
          }

          // Fallback to nestedProperties if it exists (for non-list nested structures)
          final nestedProps =
              prop['nestedProperties'] as List<Map<String, dynamic>>?;
          if (nestedProps != null) {
            return findNestedProperty(nestedProps, path, index + 1);
          }

          return null;
        }
      }

      return null;
    }

    final targetProperty = findNestedProperty(state.properties, pathParts, 0);

    if (targetProperty == null) {
      LogManager.addLog(
        'Nested property $fullPath not found in $animationId',
        isExpected: false,
      );
      return false;
    }

    _propertyPathCache.putIfAbsent(animationId, () => {});
    _propertyPathCache[animationId]![cacheKey] = targetProperty;

    LogManager.addLog('Cached property path: $cacheKey', isExpected: true);

    final propertyInstance = targetProperty['property'];
    final propertyType = targetProperty['type'] as String;

    return await _updatePropertyInstance(
      propertyInstance,
      propertyType,
      newValue,
      targetProperty,
      fullPath,
      animationId,
    );
  }

  Future<bool> _updatePropertyInstance(
    dynamic propertyInstance,
    String propertyType,
    dynamic newValue,
    Map<String, dynamic> propertyInfo,
    String propertyName,
    String animationId,
  ) async {
    try {
      switch (propertyType) {
        case 'number':
          if (propertyInstance is ViewModelInstanceNumber && newValue is num) {
            propertyInstance.value = newValue.toDouble();
            propertyInfo['value'] = newValue.toDouble();
            LogManager.addLog(
              'Updated number property $propertyName to $newValue in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'boolean':
          if (propertyInstance is ViewModelInstanceBoolean &&
              newValue is bool) {
            propertyInstance.value = newValue;
            propertyInfo['value'] = newValue;
            LogManager.addLog(
              'Updated boolean property $propertyName to $newValue in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'string':
          if (propertyInstance is ViewModelInstanceString) {
            propertyInstance.value = newValue.toString();
            propertyInfo['value'] = newValue.toString();
            LogManager.addLog(
              'Updated string property $propertyName to $newValue in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'color':
          if (propertyInstance is ViewModelInstanceColor) {
            try {
              final colorValue = _flexibleColorConvert(newValue);

              propertyInstance.value = colorValue;
              propertyInfo['value'] = colorValue;

              // ✅ Use modern accessors (.r, .g, .b, .a)
              final components = _getColorComponents(colorValue);
              final int r = components['red']!;
              final int g = components['green']!;
              final int b = components['blue']!;
              final int a = components['alpha']!;

              LogManager.addLog(
                'Updated color property $propertyName in $animationId to Color(r:${(r / 255.0).toStringAsFixed(4)}, g:${(g / 255.0).toStringAsFixed(4)}, b:${(b / 255.0).toStringAsFixed(4)}, a:${(a / 255.0).toStringAsFixed(4)})',
                isExpected: true,
              );
              return true;
            } catch (e) {
              LogManager.addLog(
                'Error setting color property $propertyName: $e',
                isExpected: false,
              );
              return false;
            }
          }
          break;

        case 'enumType':
          if (propertyInstance is ViewModelInstanceEnum) {
            propertyInstance.value = newValue.toString();
            propertyInfo['value'] = newValue.toString();
            LogManager.addLog(
              'Updated enum property $propertyName to $newValue in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'trigger':
          if (propertyInstance is ViewModelInstanceTrigger) {
            propertyInstance.trigger();
            LogManager.addLog(
              'Triggered property $propertyName in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'image':
          return await _updateImageProperty(
            animationId,
            propertyName,
            newValue,
            propertyInfo,
          );

        case 'font':
          return await _updateFontProperty(
            animationId,
            propertyName,
            newValue,
            propertyInfo,
          );

        case 'integer':
        case 'symbolListIndex':
          if (propertyInstance is ViewModelInstanceNumber && newValue is num) {
            propertyInstance.value = newValue.toDouble();
            propertyInfo['value'] = newValue.toInt();
            LogManager.addLog(
              'Updated $propertyType property $propertyName to ${newValue.toInt()} in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        case 'list':
          LogManager.addLog(
            'List property $propertyName is a collection — use the list API (add/remove/insert) to modify items',
            isExpected: true,
          );
          return false;

        case 'artboard':
          if (propertyInstance is ViewModelInstanceArtboard &&
              newValue is BindableArtboard) {
            propertyInstance.value = newValue;
            propertyInfo['value'] = newValue;
            LogManager.addLog(
              'Updated artboard property $propertyName in $animationId',
              isExpected: true,
            );
            return true;
          }
          break;

        default:
          LogManager.addLog(
            'Unsupported property type: $propertyType for $propertyName',
            isExpected: false,
          );
          return false;
      }
    } catch (e) {
      LogManager.addLog(
        'Error updating property $propertyName in $animationId: $e',
        isExpected: false,
      );
      return false;
    }

    LogManager.addLog(
      'Failed to update property $propertyName: Type mismatch or invalid value',
      isExpected: false,
    );
    return false;
  }

  /// Update a font property in a ViewModel instance.
  ///
  /// Accepts:
  /// - [String] file path or URL
  /// - [Uint8List] raw font bytes (.ttf, .otf)
  Future<bool> _updateFontProperty(
    String animationId,
    String propertyName,
    dynamic value,
    Map<String, dynamic> propertyInfo,
  ) async {
    try {
      final state = _animations[animationId];
      if (state == null) {
        LogManager.addLog('Animation $animationId not found',
            isExpected: false);
        return false;
      }

      Uint8List? bytes;

      // Handle string (file path or URL)
      if (value is String) {
        // Local file path
        if (!value.startsWith('http')) {
          LogManager.addLog(
            'Loading font from local file: $value',
            isExpected: true,
          );

          final file = io.File(value);
          if (!await file.exists()) {
            LogManager.addLog(
              'Font file not found: $value',
              isExpected: false,
            );
            return false;
          }
          bytes = await file.readAsBytes();
        }
        // URL
        else {
          LogManager.addLog(
            'Loading font from URL: $value',
            isExpected: true,
          );
          final response = await http.get(Uri.parse(value));
          if (response.statusCode != 200) {
            LogManager.addLog(
              'Failed to fetch font from URL: ${response.statusCode}',
              isExpected: false,
            );
            return false;
          }
          bytes = response.bodyBytes;
        }
      }
      // Raw bytes
      else if (value is Uint8List) {
        bytes = value;
      } else {
        LogManager.addLog(
          'Invalid font value type: ${value.runtimeType}',
          isExpected: false,
        );
        return false;
      }

      // Use the font asset reference from the state
      final fontAsset = state.fontAssetReference;
      if (fontAsset == null) {
        LogManager.addLog(
          'No font asset reference for $animationId — cannot decode font',
          isExpected: false,
        );
        return false;
      }

      final success = await fontAsset.decode(bytes);
      if (!success) {
        LogManager.addLog(
          'Failed to decode font for $propertyName in $animationId',
          isExpected: false,
        );
        return false;
      }

      LogManager.addLog(
        '✅ Successfully updated font property $propertyName in $animationId',
        isExpected: true,
      );
      return true;
    } catch (e, stack) {
      LogManager.addLog(
        'Error updating font property: $e\n$stack',
        isExpected: false,
      );
      return false;
    }
  }

  Future<bool> _updateImageProperty(
    String animationId,
    String propertyName,
    dynamic value,
    Map<String, dynamic> propertyInfo,
  ) async {
    try {
      final state = _animations[animationId];
      if (state == null) {
        LogManager.addLog('Animation $animationId not found',
            isExpected: false);
        return false;
      }

      final viewModelInstance = state.viewModelInstance;
      if (viewModelInstance == null) {
        LogManager.addLog(
          'ViewModelInstance not found for $animationId',
          isExpected: false,
        );
        return false;
      }

      final imageProperty = viewModelInstance.image(propertyName);
      if (imageProperty == null) {
        LogManager.addLog(
          'Image property $propertyName not found in ViewModelInstance',
          isExpected: false,
        );
        return false;
      }

      Uint8List? bytes;

      // ✅ Handle string (file path or URL)
      if (value is String) {
        // Local file path
        if (!value.startsWith('http')) {
          LogManager.addLog(
            'Loading image from local file: $value',
            isExpected: true,
          );

          final file = io.File(value);
          if (!await file.exists()) {
            LogManager.addLog(
              'File not found: $value',
              isExpected: false,
            );
            return false;
          }
          bytes = await file.readAsBytes();
        }
        // URL
        else {
          LogManager.addLog(
            'Loading image from URL: $value',
            isExpected: true,
          );
          final response = await http.get(Uri.parse(value));
          if (response.statusCode != 200) {
            LogManager.addLog(
              'Failed to fetch image from URL: ${response.statusCode}',
              isExpected: false,
            );
            return false;
          }
          bytes = response.bodyBytes;
        }
      }
      // Pre-decoded RenderImage
      else if (value is RenderImage) {
        imageProperty.value = value;
        propertyInfo['value'] = value;
        LogManager.addLog(
          'Using pre-decoded RenderImage for $propertyName in $animationId',
          isExpected: true,
        );
        return true;
      }
      // Raw bytes
      else if (value is Uint8List) {
        bytes = value;
      } else {
        LogManager.addLog(
          'Invalid image value type: ${value.runtimeType}',
          isExpected: false,
        );
        return false;
      }

      // Decode bytes to renderImage
      final renderImage = await Factory.rive.decodeImage(bytes);
      if (renderImage == null) {
        LogManager.addLog(
          'Failed to decode image for $propertyName in $animationId',
          isExpected: false,
        );
        return false;
      }

      imageProperty.value = renderImage;
      propertyInfo['value'] = renderImage;

      LogManager.addLog(
        '✅ Successfully updated image property $propertyName in $animationId',
        isExpected: true,
      );
      return true;
    } catch (e, stack) {
      LogManager.addLog(
        'Error updating image property: $e\n$stack',
        isExpected: false,
      );
      return false;
    }
  }

  /// Get current value of a data binding property
  dynamic getDataBindingPropertyValue(String animationId, String propertyName) {
    final state = _animations[animationId];
    if (state == null) return null;

    final propertyInfo = state.properties.firstWhere(
      (prop) => prop['name'] == propertyName,
      orElse: () => <String, dynamic>{},
    );

    return propertyInfo.isEmpty ? null : propertyInfo['value'];
  }

  /// Get all current property values for an animation
  Map<String, dynamic> getAllPropertyValues(String animationId) {
    final state = _animations[animationId];
    if (state == null) return {};

    final Map<String, dynamic> values = {};
    for (final prop in state.properties) {
      values[prop['name'] as String] = prop['value'];
    }
    return values;
  }

  /// Get animation state by ID
  RiveManagerState? getAnimationState(String animationId) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Animation state not found: $animationId',
        isExpected: false,
      );
    }
    return state;
  }

  /// Lift the initial-sync data-binding suppression window for an animation.
  ///
  /// Only meaningful when the [RiveManager] was created with
  /// `suppressDataBindingCallbacksUntilReady: true`. Call this once you have
  /// applied your saved values to the artboard (typically at the end of your
  /// `onInit`) so that [RiveManager.onDataBindingChange] callbacks resume for
  /// genuine, post-init changes. No-op if the animation isn't registered.
  void markDataBindingReady(String animationId) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot mark data-binding ready: Animation $animationId not found',
        isExpected: false,
      );
      return;
    }
    state.markDataBindingReady();
  }

  /// Get current state name for an animation
  String? getCurrentStateName(String animationId) {
    final stateName = _animations[animationId]?.currentStateName;
    if (stateName != null) {
      LogManager.addLog(
        'Current state for $animationId: $stateName',
        isExpected: true,
      );
    } else {
      LogManager.addLog(
        'No current state found for: $animationId',
        isExpected: false,
      );
    }
    return stateName;
  }

  /// Trigger an input by animation ID and input name
  void triggerInput(String animationId, String inputName) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot trigger input "$inputName": Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    final input = state.inputs[inputName];
    if (input is TriggerInput) {
      input.fire();
      LogManager.addLog(
        'Triggered input "$inputName" on $animationId',
        isExpected: true,
      );
    } else {
      LogManager.addLog(
        'Input "$inputName" is not a trigger on $animationId',
        isExpected: false,
      );
    }
  }

  /// Update a boolean input
  void updateBool(String animationId, String inputName, bool value) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot update bool "$inputName": Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    final input = state.inputs[inputName];
    if (input is BooleanInput) {
      input.value = value;
      LogManager.addLog(
        'Updated bool "$inputName" = $value on $animationId',
        isExpected: true,
      );
    } else {
      LogManager.addLog(
        'Input "$inputName" is not a boolean on $animationId',
        isExpected: false,
      );
    }
  }

  /// Update a number input
  void updateNumber(String animationId, String inputName, double value) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot update number "$inputName": Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    final input = state.inputs[inputName];
    if (input is NumberInput) {
      input.value = value;
      LogManager.addLog(
        'Updated number "$inputName" = $value on $animationId',
        isExpected: true,
      );
    } else {
      LogManager.addLog(
        'Input "$inputName" is not a number on $animationId',
        isExpected: false,
      );
    }
  }

  /// Set text run value in an Artboard
  void setTextRunValue(
    String animationId,
    String textRunName,
    String value, {
    String? path,
  }) {
    final state = _animations[animationId];
    if (state?.controller == null) {
      LogManager.addLog(
        'Cannot set text "$textRunName": Controller not found for $animationId',
        isExpected: false,
      );
      return;
    }

    try {
      // ignore: deprecated_member_use
      state!.controller!.artboard.setText(textRunName, value, path: path);
      LogManager.addLog(
        'Updated text "$textRunName" = "$value" on $animationId${path != null ? ' (path: $path)' : ''}',
        isExpected: true,
      );
    } catch (e) {
      LogManager.addLog(
        'Error updating text "$textRunName" on $animationId: $e',
        isExpected: false,
      );
    }
  }

  /// Get text run value from an Artboard
  String? getTextRunValue(
    String animationId,
    String textRunName, {
    String? path,
  }) {
    final state = _animations[animationId];
    if (state?.controller == null) {
      LogManager.addLog(
        'Cannot get text "$textRunName": Controller not found for $animationId',
        isExpected: false,
      );
      return null;
    }

    try {
      // ignore: deprecated_member_use
      final text = state!.controller!.artboard.getText(textRunName, path: path);
      LogManager.addLog(
        'Retrieved text "$textRunName" = "$text" from $animationId',
        isExpected: true,
      );
      return text;
    } catch (e) {
      LogManager.addLog(
        'Error getting text "$textRunName" from $animationId: $e',
        isExpected: false,
      );
      return null;
    }
  }

  /// Register image asset
  void registerImageAsset(String animationId, ImageAsset asset) {
    _imageAssets[animationId] = asset;
    LogManager.addLog(
      'Registered image asset for: $animationId',
      isExpected: true,
    );
  }

  /// Get ImageAsset from an animation
  ImageAsset? getImageAsset(String animationId) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot get ImageAsset: Animation $animationId not found',
        isExpected: false,
      );
      return null;
    }

    return state.getImageAsset();
  }

  /// Update image from URL for an animation
  Future<void> updateImageFromUrl(String animationId, String url) async {
    final state = _animations[animationId];

    if (state == null) {
      LogManager.addLog(
        'Cannot update image: Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    await state.updateImageFromUrl(url);
  }

  // ========== FONT ASSET API ==========

  /// Register font asset
  void registerFontAsset(String animationId, FontAsset asset) {
    _fontAssets[animationId] = asset;
    LogManager.addLog(
      'Registered font asset for: $animationId',
      isExpected: true,
    );
  }

  /// Get FontAsset from an animation
  FontAsset? getFontAsset(String animationId) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot get FontAsset: Animation $animationId not found',
        isExpected: false,
      );
      return null;
    }

    return state.getFontAsset();
  }

  /// Update font from URL for an animation
  Future<void> updateFontFromUrl(String animationId, String url) async {
    final state = _animations[animationId];

    if (state == null) {
      LogManager.addLog(
        'Cannot update font: Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    await state.updateFontFromUrl(url);
  }

  /// Update font from raw bytes for an animation
  Future<void> updateFontFromBytes(String animationId, Uint8List bytes) async {
    final state = _animations[animationId];

    if (state == null) {
      LogManager.addLog(
        'Cannot update font: Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    await state.updateFontFromBytes(bytes);
  }

  /// Update font from asset bundle for an animation
  Future<void> updateFontFromAsset(String animationId, String assetPath) async {
    final state = _animations[animationId];

    if (state == null) {
      LogManager.addLog(
        'Cannot update font: Animation $animationId not found',
        isExpected: false,
      );
      return;
    }

    await state.updateFontFromAsset(assetPath);
  }

  // ========== THUMBNAIL / SNAPSHOT API ==========

  /// Capture a thumbnail for any registered animation by ID.
  ///
  /// Uses RenderTexture.toImage() for GPU-direct snapshot capture.
  /// Works in both widget mode and texture mode.
  Future<Uint8List?> captureAnimationThumbnail(
    String animationId, {
    required int width,
    required int height,
  }) async {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot capture thumbnail: Animation $animationId not found',
        isExpected: false,
      );
      return null;
    }

    return state.captureSnapshotAsPng(width: width, height: height);
  }

  /// Preload and cache images for instant swapping
  Future<void> preloadImagesForAnimation(
    String animationId,
    List<String> urls,
    Factory factory,
  ) async {
    LogManager.addLog(
      'Starting image preload for $animationId (${urls.length} images)',
      isExpected: true,
    );

    final List<RenderImage> cache = [];
    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      try {
        final response = await http.get(Uri.parse(url));
        final image = await factory.decodeImage(
          Uint8List.view(response.bodyBytes.buffer),
        );

        if (image != null) {
          cache.add(image);
          successCount++;
          LogManager.addLog(
            'Cached image $i/${urls.length} for $animationId from: $url',
            isExpected: true,
          );
        } else {
          errorCount++;
          LogManager.addLog(
            'Failed to decode image $i from: $url',
            isExpected: false,
          );
        }
      } catch (e) {
        errorCount++;
        LogManager.addLog(
          'Error caching image $i for $animationId: $e',
          isExpected: false,
        );
      }
    }

    _imageCache[animationId] = cache;
    LogManager.addLog(
      'Image preload complete for $animationId: $successCount success, $errorCount errors',
      isExpected: errorCount == 0,
    );
  }

  /// Update image from cache for instant display
  void updateImageFromCache(String animationId, int index) {
    final state = _animations[animationId];
    final cache = _imageCache[animationId];

    if (state?.imageAssetReference == null) {
      LogManager.addLog(
        'Cannot update image from cache: No image asset for $animationId',
        isExpected: false,
      );
      return;
    }

    if (cache == null) {
      LogManager.addLog(
        'Cannot update image from cache: No cache found for $animationId',
        isExpected: false,
      );
      return;
    }

    if (index >= cache.length) {
      LogManager.addLog(
        'Cannot update image from cache: Index $index out of bounds (cache size: ${cache.length})',
        isExpected: false,
      );
      return;
    }

    state!.imageAssetReference!.renderImage(cache[index]);

    LogManager.addLog(
      'Updated image from cache for $animationId (index: $index)',
      isExpected: true,
    );
  }

  /// Get all inputs for an animation
  Map<String, Input> getInputs(String animationId) {
    return _animations[animationId]?.inputs ?? {};
  }

  /// Get all properties for an animation
  List<Map<String, dynamic>> getProperties(String animationId) {
    return _animations[animationId]?.properties ?? [];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA-BINDING LIST API — add / remove / reorder list items by animationId
  //
  // A Rive data-binding list is typed to a single element view-model. To add an
  // item you name that view-model once (e.g. 'listItem') and supply a field
  // map; the value types are auto-detected (string / number / bool / color /
  // enum), with colors parsed through the same flexible converter used
  // elsewhere. The item view-model name is remembered per list, so later adds
  // can omit it. Every mutation rebuilds the cached `listItems` snapshot and
  // fires a single ('<list>', 'list', length) data-binding change.
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number of items currently in [listName]. Returns 0 if unavailable.
  int listLength(String animationId, String listName) =>
      _animations[animationId]?.listLength(listName) ?? 0;

  /// Snapshot of the current items in [listName] (index / name / properties),
  /// or an empty list if unavailable. Reflects the most recent mutation.
  List<Map<String, dynamic>> getListItems(String animationId, String listName) {
    final state = _animations[animationId];
    if (state == null) return const [];
    final entry = state.properties.firstWhere(
      (p) => p['name'] == listName && p['type'] == 'list',
      orElse: () => <String, dynamic>{},
    );
    if (entry.isEmpty) return const [];
    return (entry['listItems'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];
  }

  /// Add an item to [listName], optionally at index [at] (defaults to append).
  ///
  /// [itemViewModel] is the element view-model name (e.g. 'listItem'); it is
  /// required the first time a given list is mutated and may be omitted on
  /// later calls (the name is cached per list). [fields] maps property names to
  /// values; types are auto-detected and colors accept the same formats as
  /// [updateDataBindingProperty] (Color, hex/rgb strings, maps, lists).
  ///
  /// Returns true on success.
  bool addListItem(
    String animationId,
    String listName, {
    String? itemViewModel,
    Map<String, dynamic> fields = const {},
    int? at,
    bool attachListeners = false,
  }) {
    final state = _animations[animationId];
    if (state == null) {
      LogManager.addLog(
        'Cannot add list item: animation $animationId not found',
        isExpected: false,
      );
      return false;
    }

    final vmName = itemViewModel ?? _listItemViewModels[animationId]?[listName];
    if (vmName == null) {
      LogManager.addLog(
        'Cannot add item to "$listName": specify itemViewModel at least once '
        'for animation $animationId',
        isExpected: false,
      );
      return false;
    }

    final item = _createListItemInstance(state, vmName, fields);
    if (item == null) return false;

    bool ok = false;
    try {
      ok = state.addListItemInstance(
        listName,
        item,
        at: at,
        attachListeners: attachListeners,
      );
    } finally {
      // The list retains its own reference; free the local handle either way.
      try {
        item.dispose();
      } catch (_) {}
    }

    if (ok) {
      _listItemViewModels.putIfAbsent(animationId, () => {})[listName] = vmName;
      LogManager.addLog(
        'Added item to list "$listName" on $animationId'
        '${at != null ? ' at $at' : ''}',
        isExpected: true,
      );
    }
    return ok;
  }

  /// Remove the item at [index] from [listName]. Returns true on success.
  bool removeListItemAt(String animationId, String listName, int index) =>
      _animations[animationId]?.removeListItemAt(listName, index) ?? false;

  /// Move the item at [from] to [to] in [listName], keeping other items in
  /// order. Implemented with swaps only (no create/destroy). True on success.
  bool moveListItem(
    String animationId,
    String listName,
    int from,
    int to,
  ) =>
      _animations[animationId]?.moveListItem(listName, from, to) ?? false;

  /// Swap the items at [a] and [b] in [listName]. Returns true on success.
  bool swapListItems(String animationId, String listName, int a, int b) =>
      _animations[animationId]?.swapListItems(listName, a, b) ?? false;

  /// Remove every item from [listName]. Returns true on success.
  bool clearList(String animationId, String listName) =>
      _animations[animationId]?.clearList(listName) ?? false;

  /// Update a single [field] on the existing list item at [index] in
  /// [listName] (in place, no reorder). Value type is auto-detected. True on
  /// success.
  bool updateListItemField(
    String animationId,
    String listName,
    int index,
    String field,
    dynamic value,
  ) {
    final state = _animations[animationId];
    final list = state?.listHandle(listName);
    if (list == null) {
      LogManager.addLog(
        'Cannot update list item field: list "$listName" not found on $animationId',
        isExpected: false,
      );
      return false;
    }
    if (index < 0 || index >= list.length) {
      LogManager.addLog(
        'Cannot update list item field: index $index out of bounds '
        '(len ${list.length}) for "$listName" on $animationId',
        isExpected: false,
      );
      return false;
    }
    final ok = _applyFieldToInstance(list.instanceAt(index), field, value);
    if (ok) state!.refreshListProperty(listName);
    return ok;
  }

  /// Build a populated list-item [ViewModelInstance] from its view-model name.
  /// Returns null (and logs) if the view-model or instance can't be created.
  ViewModelInstance? _createListItemInstance(
    RiveManagerState state,
    String itemViewModelName,
    Map<String, dynamic> fields,
  ) {
    final file = state.file;
    if (file == null) {
      LogManager.addLog(
        'Cannot create list item: no Rive file loaded',
        isExpected: false,
      );
      return null;
    }
    final vm = file.viewModelByName(itemViewModelName);
    if (vm == null) {
      LogManager.addLog(
        'Cannot create list item: view-model "$itemViewModelName" not found',
        isExpected: false,
      );
      return null;
    }
    final instance = vm.createInstance();
    if (instance == null) {
      LogManager.addLog(
        'Cannot create list item: createInstance() returned null for "$itemViewModelName"',
        isExpected: false,
      );
      return null;
    }
    fields.forEach((field, value) {
      _applyFieldToInstance(instance, field, value);
    });
    return instance;
  }

  /// Set [field] on a list-item [ViewModelInstance] by auto-detecting its type.
  /// Probes each typed accessor (a wrong-typed field returns null) and writes
  /// the first match. Returns true if the field was written.
  bool _applyFieldToInstance(
    ViewModelInstance item,
    String field,
    dynamic value,
  ) {
    // String
    final s = item.string(field);
    if (s != null) {
      s.value = value?.toString() ?? '';
      return true;
    }
    // Color (before number: colors accept ints/strings too)
    final c = item.color(field);
    if (c != null) {
      c.value = _flexibleColorConvert(value);
      return true;
    }
    // Number / integer
    final n = item.number(field);
    if (n != null) {
      final d = value is num ? value.toDouble() : double.tryParse('$value');
      if (d != null) {
        n.value = d;
        return true;
      }
    }
    // Boolean
    final b = item.boolean(field);
    if (b != null && value is bool) {
      b.value = value;
      return true;
    }
    // Enum
    final e = item.enumerator(field);
    if (e != null) {
      e.value = value.toString();
      return true;
    }
    // Trigger (fire when value is truthy)
    final t = item.trigger(field);
    if (t != null) {
      if (value == true) t.trigger();
      return true;
    }

    LogManager.addLog(
      'List item field "$field" not found or value type mismatch '
      '(${value.runtimeType})',
      isExpected: false,
    );
    return false;
  }

  // ═════════════════════════════════════════════════════════════════════════════════════
  // ✅ COLOR CONVERSION METHODS - Handle multiple color formats for Rive
  // ═════════════════════════════════════════════════════════════════════════════════════

  /// Convert any color format to Flutter Color object
  ///
  /// Supports:
  /// - Color objects (0-255 internal, 0.0-1.0 normalized getters)
  /// - Hex strings (#RGB, #RRGGBB, #AARRGGBB)
  /// - RGB/RGBA strings ("rgb(255,0,0)", "rgba(255,0,0,1.0)")
  /// - Map formats ({r: 62, g: 194, b: 147} OR {r: 0.2431, g: 0.7608, b: 0.5764})
  /// - List formats ([62, 194, 147] OR [0.2431, 0.7608, 0.5764])
  /// - Named colors ("red", "blue", etc.)

  Map<String, int> _getColorComponents(Color color) {
    return {
      'red': (color.r * 255.0).round() & 0xff,
      'green': (color.g * 255.0).round() & 0xff,
      'blue': (color.b * 255.0).round() & 0xff,
      'alpha': (color.a * 255.0).round() & 0xff,
    };
  }

  Color _flexibleColorConvert(dynamic value) {
    // ✅ Already a Color object (has normalized getters)
    if (value is Color) {
      return value;
    }

    // ✅ String formats
    if (value is String) {
      return _stringToColor(value);
    }

    // ✅ Map format (handles both 0-255 AND 0.0-1.0)
    if (value is Map<String, dynamic>) {
      return _mapToColor(value);
    }

    // ✅ List format [R, G, B] or [R, G, B, A]
    if (value is List) {
      return _listToColor(value);
    }

    // ✅ Fallback - FIX: Use Colors.white (not materialColor.Colors.white)
    LogManager.addLog(
      'Unknown color format: ${value.runtimeType}. Defaulting to white.',
      isExpected: false,
    );
    return Colors.white; // ← FIXED: Just Colors.white
  }

  /// Convert string to Color
  Color _stringToColor(String input) {
    final trimmed = input.trim().toLowerCase();

    if (trimmed.startsWith('#') || trimmed.startsWith('0x')) {
      return _hexToColor(input);
    }

    if (trimmed.startsWith('rgb(')) {
      return _rgbToColor(input);
    }

    if (trimmed.startsWith('rgba(')) {
      return _rgbaToColor(input);
    }

    return _namedColorToColor(input);
  }

  /// Convert hex string to Color
  Color _hexToColor(String hex) {
    try {
      String cleanHex =
          hex.replaceFirst('0x', '').replaceFirst('#', '').toUpperCase();

      if (cleanHex.length == 3) {
        cleanHex = '${cleanHex[0]}${cleanHex[0]}'
            '${cleanHex[1]}${cleanHex[1]}'
            '${cleanHex[2]}${cleanHex[2]}';
      }

      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }

      if (cleanHex.length != 8) {
        throw FormatException('Invalid hex length: ${cleanHex.length}');
      }

      final colorInt = int.parse('0x$cleanHex');
      return Color(colorInt);
    } catch (e) {
      LogManager.addLog('Error parsing hex color $hex: $e', isExpected: false);
      return Colors.white;
    }
  }

  /// Convert RGB string to Color
  Color _rgbToColor(String rgb) {
    try {
      final match = RegExp(r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)')
          .firstMatch(rgb.toLowerCase());

      if (match == null) {
        throw FormatException('Invalid RGB format');
      }

      final r = int.parse(match.group(1)!).clamp(0, 255);
      final g = int.parse(match.group(2)!).clamp(0, 255);
      final b = int.parse(match.group(3)!).clamp(0, 255);

      return Color.fromARGB(255, r, g, b);
    } catch (e) {
      LogManager.addLog('Error parsing RGB color $rgb: $e', isExpected: false);
      return Colors.white;
    }
  }

  /// Convert RGBA string to Color
  Color _rgbaToColor(String rgba) {
    try {
      final match = RegExp(
              r'rgba\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d.]+)\s*\)')
          .firstMatch(rgba.toLowerCase());

      if (match == null) {
        throw FormatException('Invalid RGBA format');
      }

      final r = int.parse(match.group(1)!).clamp(0, 255);
      final g = int.parse(match.group(2)!).clamp(0, 255);
      final b = int.parse(match.group(3)!).clamp(0, 255);
      final aStr = match.group(4)!;

      int a;
      if (aStr.contains('.')) {
        a = (double.parse(aStr) * 255).toInt();
      } else {
        a = int.parse(aStr);
      }
      a = a.clamp(0, 255);

      return Color.fromARGB(a, r, g, b);
    } catch (e) {
      LogManager.addLog('Error parsing RGBA color $rgba: $e',
          isExpected: false);
      return Colors.white;
    }
  }

  /// Convert named color string to Color
  Color _namedColorToColor(String name) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'lime': Colors.lime,
      'indigo': Colors.indigo,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'amber': Colors.amber,
      'brown': Colors.brown,
    };

    if (colorMap.containsKey(name)) {
      return colorMap[name]!;
    }

    LogManager.addLog('Unknown named color: $name. Using white.',
        isExpected: false);
    return Colors.white;
  }

  /// Convert Map to Color
  Color _mapToColor(Map<String, dynamic> map) {
    try {
      final r = (map['r'] ?? map['red'] ?? 1.0);
      final g = (map['g'] ?? map['green'] ?? 1.0);
      final b = (map['b'] ?? map['blue'] ?? 1.0);
      final a = (map['a'] ?? map['alpha'] ?? 1.0);

      bool isNormalized = (r is double && r <= 1.0) ||
          (g is double && g <= 1.0) ||
          (b is double && b <= 1.0);

      int rInt, gInt, bInt, aInt;

      if (isNormalized) {
        rInt = (r * 255).round().clamp(0, 255);
        gInt = (g * 255).round().clamp(0, 255);
        bInt = (b * 255).round().clamp(0, 255);
        aInt = (a * 255).round().clamp(0, 255);

        LogManager.addLog(
          'Converted normalized map color: {r:$r,g:$g,b:$b,a:$a} → Color($rInt,$gInt,$bInt,$aInt)',
          isExpected: true,
        );
      } else {
        rInt = (r as num).toInt().clamp(0, 255);
        gInt = (g as num).toInt().clamp(0, 255);
        bInt = (b as num).toInt().clamp(0, 255);
        aInt = (a as num).toInt().clamp(0, 255);

        LogManager.addLog(
          'Converted standard map color: {r:$r,g:$g,b:$b,a:$a} → Color($rInt,$gInt,$bInt,$aInt)',
          isExpected: true,
        );
      }

      return Color.fromARGB(aInt, rInt, gInt, bInt);
    } catch (e) {
      LogManager.addLog('Error parsing map color: $e', isExpected: false);
      return Colors.white;
    }
  }

  /// Convert List to Color
  Color _listToColor(List list) {
    try {
      if (list.isEmpty || list.length < 3) {
        throw Exception('List must have at least 3 elements [R, G, B]');
      }

      final r = list[0];
      final g = list[1];
      final b = list[2];
      final a = list.length > 3 ? list[3] : 255;

      bool isNormalized = (r is double && r <= 1.0) ||
          (g is double && g <= 1.0) ||
          (b is double && b <= 1.0);

      int rInt, gInt, bInt, aInt;

      if (isNormalized) {
        rInt = (r * 255).round().clamp(0, 255);
        gInt = (g * 255).round().clamp(0, 255);
        bInt = (b * 255).round().clamp(0, 255);
        aInt = (a * 255).round().clamp(0, 255);
      } else {
        rInt = (r as num).toInt().clamp(0, 255);
        gInt = (g as num).toInt().clamp(0, 255);
        bInt = (b as num).toInt().clamp(0, 255);
        aInt = (a as num).toInt().clamp(0, 255);
      }

      return Color.fromARGB(aInt, rInt, gInt, bInt);
    } catch (e) {
      LogManager.addLog('Error parsing list color: $e', isExpected: false);
      return Colors.white;
    }
  }
}
