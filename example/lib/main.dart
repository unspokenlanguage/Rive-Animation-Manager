// ========================================
// RIVE ANIMATION MANAGER - INTERACTIVE EXAMPLE
// ========================================
// This example demonstrates:
// - Bidirectional data binding with Rive animations
// - Real-time property updates (Rive ↔ UI)
// - Type-specific interactive controls (string, number, boolean, color, trigger, enum)
// - Event logging and state management
// - Responsive side-by-side layout (desktop) / stacked layout (mobile)
// - Dynamic UI generation based on ViewModel properties
// ========================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material_color;
import 'package:image_picker/image_picker.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_animation_manager/rive_animation_manager.dart';

void main() {
  runApp(const MyApp());
}

/// Root application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Animation Manager - Interactive',
      theme: ThemeData(
        primarySwatch: material_color.Colors.blue,
        useMaterial3: true,
      ),
      home: const RiveAnimationExample(),
    );
  }
}

/// Main example widget demonstrating interactive Rive animation controls
///
/// This widget showcases:
/// - Loading and displaying Rive animations with state machines
/// - Discovering ViewModel data binding properties automatically
/// - Creating type-specific UI controls for each property
/// - Handling bidirectional updates between UI and animation
class RiveAnimationExample extends StatefulWidget {
  const RiveAnimationExample({super.key});

  @override
  State<RiveAnimationExample> createState() => _RiveAnimationExampleState();
}

class _RiveAnimationExampleState extends State<RiveAnimationExample> {
  // ========================================
  // STATE VARIABLES
  // ========================================

  /// Current animation status message displayed to user
  String _currentStatus = 'Loading...';

  /// List of discovered ViewModel properties from the Rive file
  /// Each property contains: name, type, value, and property reference
  List<Map<String, dynamic>> _properties = [];

  /// Event log showing recent interactions and state changes
  /// Limited to last 10 events for performance
  final List<String> _eventLog = [];

  /// Global controller instance for managing Rive animations
  /// Used to update property values programmatically
  final RiveAnimationController _controller = RiveAnimationController.instance;

  // ========================================
  // CALLBACK HANDLERS
  // ========================================
  // These callbacks are triggered by RiveManager at various lifecycle events

  /// Called when the Rive animation is initialized and ready
  ///
  /// @param artboard The artboard instance that was initialized
  void _onInit(Artboard artboard) {
    _addEventLog('✅ Animation Initialized: ${artboard.name}');
    debugPrint('Animation initialized: ${artboard.name}');
  }

  /// Called when a state machine input changes (e.g., user clicks on animation)
  ///
  /// @param index The index of the input that changed
  /// @param name The name of the input
  /// @param value The new value of the input
  void _onInputChange(int index, String name, dynamic value) {
    _addEventLog('📝 Input Changed: $name = $value');
  }

  /// Called when a hover action occurs on the animation
  ///
  /// @param name The name of the hovered input
  /// @param value The value associated with the hover action
  void _onHoverAction(String name, dynamic value) {
    _addEventLog('🎯 Hover Action: $name = $value');
  }

  /// Called when a trigger input is fired in the state machine
  ///
  /// @param name The name of the trigger that was fired
  /// @param value The trigger value (typically true)
  void _onTriggerAction(String name, dynamic value) {
    _addEventLog('⚡ Trigger Fired: $name');
    _pendingStatus = 'Trigger fired: $name';
  }

  /// Called when ViewModel data binding properties are discovered in the Rive file
  /// This is where we receive the list of all bindable properties
  ///
  /// @param properties List of discovered properties with metadata
  void _onViewModelPropertiesDiscovered(List<Map<String, dynamic>> properties) {
    if (properties.isEmpty) {
      _addEventLog('⚠️ No ViewModel properties found');
    } else {
      _addEventLog('🔍 Discovered ${properties.length} properties');
    }

    // Batch property + status update into the next flush
    _pendingProperties = properties;
    _pendingStatus = properties.isEmpty
        ? 'No data binding properties'
        : 'Discovered ${properties.length} properties';
  }

  /// Called when a data binding property changes value in the Rive animation
  /// This enables Rive → UI updates (animation drives the UI)
  ///
  /// @param propertyName The name of the property that changed
  /// @param propertyType The type of the property (string, number, boolean, etc.)
  /// @param value The new value of the property
  void _onDataBindingChange(
    String propertyName,
    String propertyType,
    dynamic value,
  ) {
    _addEventLog('🔗 Property Updated:  = ');

    // Fetch fresh authoritative properties from RiveManager
    final updatedProps =
        RiveAnimationController.instance.getProperties('example_animation');
    if (updatedProps.isNotEmpty) {
      _pendingProperties = updatedProps;
    }
  }

  /// Called when a Rive event is fired from the state machine
  ///
  /// @param eventName The name of the event
  /// @param event The event object
  /// @param currentState The current state machine state
  void _onEventChange(String eventName, Event event, String currentState) {
    _addEventLog('📢 Event: $eventName (State: $currentState)');
  }

  /// Called when an animation completes playing
  void _onAnimationComplete() {
    _addEventLog('✨ Animation Complete!');
    _pendingStatus = 'Animation completed!';
  }

  // Pending state batching fields
  final List<String> _pendingLogs = [];
  bool _flushScheduled = false;
  String? _pendingStatus;
  List<Map<String, dynamic>>? _pendingProperties;

  /// Helper method to add a message to the event log.
  /// Batches all pending updates into a single setState per frame
  /// to avoid !_dirty assertion when multiple callbacks fire together.
  void _addEventLog(String message) {
    _pendingLogs.add(message);
    if (!_flushScheduled) {
      _flushScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flushScheduled = false;
        if (!mounted) return;
        setState(() {
          // Flush logs
          for (final log in _pendingLogs) {
            _eventLog.insert(0, log);
          }
          _pendingLogs.clear();
          while (_eventLog.length > 10) {
            _eventLog.removeLast();
          }
          // Flush status
          if (_pendingStatus != null) {
            _currentStatus = _pendingStatus!;
            _pendingStatus = null;
          }
          // Flush properties
          if (_pendingProperties != null) {
            _properties = _pendingProperties!;
            _pendingProperties = null;
          }
        });
      });
    }
  }

  // ========================================
  // USER INTERACTION HANDLERS
  // ========================================

  /// Called when user changes a property value via UI controls
  /// This enables UI → Rive updates (UI drives the animation)
  ///
  /// @param propertyName The name of the property to update
  /// @param propertyType The type of the property
  /// @param newValue The new value to set
  Future<void> _onPropertyChanged(
      String propertyName, String propertyType, dynamic newValue) async {
    try {
      _addEventLog('🎮 User Changed: $propertyName = $newValue');

      // Send the update to the Rive animation via the controller
      await _controller.updateNestedProperty(
        'example_animation', // Animation ID (must match RiveManager animationId)
        propertyName,
        newValue,
      );

      debugPrint('Property updated: $propertyName = $newValue');
    } catch (e) {
      _addEventLog('❌ Error updating $propertyName: $e');
      debugPrint('Error updating property: $e');
    }
  }

  // ========================================
  // BUILD METHOD
  // ========================================

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive Animation Manager - Interactive'),
        elevation: 0,
      ),
      // Use side-by-side layout for wide screens, stacked for narrow
      body: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ========================================
  // LAYOUT: WIDE SCREEN (DESKTOP)
  // ========================================

  /// Builds side-by-side layout for desktop/wide screens
  /// Left side: Rive animation (60% width)
  /// Right side: Interactive controls panel (40% width)
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====================================
        // LEFT SIDE: Animation Display
        // ====================================
        Expanded(
          flex: 6, // 60% of width
          child: Container(
            color: material_color.Colors.grey[100],
            child: Column(
              children: [
                // Animation Area
                Expanded(
                  child: Center(
                    child: RiveManager(
                      // Unique ID for this animation instance
                      animationId: 'example_animation',

                      // Path to your .riv file in assets
                      riveFilePath: 'assets/animations/NFL_-_Player_Lower_Third.riv',

                      // Use state machine for interactive animations
                      animationType: RiveAnimationType.stateMachine,

                      // Display properties
                      fit: Fit.contain,
                      alignment: Alignment.center,

                      // Callback handlers for various events
                      onInit: _onInit,
                      onInputChange: _onInputChange,
                      onHoverAction: _onHoverAction,
                      onTriggerAction: _onTriggerAction,
                      onViewModelPropertiesDiscovered:
                          _onViewModelPropertiesDiscovered,
                      onDataBindingChange: _onDataBindingChange,
                      onEventChange: _onEventChange,
                      onAnimationComplete: _onAnimationComplete,
                    ),
                  ),
                ),

                // Status Bar at Bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: material_color.Colors.white,
                    border: Border(
                      top: BorderSide(color: material_color.Colors.grey[300]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: material_color.Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ====================================
        // RIGHT SIDE: Controls Panel
        // ====================================
        Expanded(
          flex: 4, // 40% of width
          child: Container(
            decoration: BoxDecoration(
              color: material_color.Colors.white,
              border: Border(
                left: BorderSide(color: material_color.Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Panel Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: material_color.Colors.blue[50],
                    border: Border(
                      bottom:
                          BorderSide(color: material_color.Colors.blue[100]!),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Interactive Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Controls Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ====================================
                        // Property Controls Section
                        // ====================================
                        // This section dynamically generates UI controls
                        // based on discovered ViewModel properties

                        if (_properties.isEmpty)
                          // Show warning if no properties found
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: material_color.Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: material_color.Colors.amber[300]!),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ No properties discovered',
                                  style: TextStyle(
                                    color: material_color.Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Make sure your Rive file has ViewModel data binding configured.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: material_color.Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else
                          // Generate a card for each property
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _properties.length,
                            itemBuilder: (context, index) {
                              final prop = _properties[index];
                              if (prop['name'] == '__availableViewModels')
                                return const SizedBox.shrink();
                              final vms = _properties
                                      .where((p) =>
                                          p['name'] == '__availableViewModels')
                                      .map((p) =>
                                          (p['value'] as List).cast<String>())
                                      .firstOrNull ??
                                  [];
                              return InteractivePropertyCard(
                                property: prop,
                                onValueChanged: _onPropertyChanged,
                                availableViewModels: vms,
                              );
                            },
                          ),

                        const SizedBox(height: 24),

                        // ====================================
                        // Event Log Section
                        // ====================================
                        const Text(
                          '📋 Event Log:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_eventLog.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: material_color.Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No events yet - interact with animation!',
                              style:
                                  TextStyle(color: material_color.Colors.grey),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: material_color.Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: material_color.Colors.grey[50],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _eventLog.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 6.0,
                                  ),
                                  child: Text(
                                    _eventLog[index],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // LAYOUT: NARROW SCREEN (MOBILE/TABLET)
  // ========================================

  /// Builds stacked layout for mobile/narrow screens
  /// Animation on top, controls below
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Animation Display Area
          Container(
            color: material_color.Colors.grey[100],
            height: 300,
            child: RiveManager(
              animationId: 'example_animation',
              riveFilePath: 'assets/animations/NFL_-_Player_Lower_Third.riv',
              animationType: RiveAnimationType.stateMachine,
              fit: Fit.contain,
              alignment: Alignment.center,
              onInit: _onInit,
              onInputChange: _onInputChange,
              onHoverAction: _onHoverAction,
              onTriggerAction: _onTriggerAction,
              onViewModelPropertiesDiscovered: _onViewModelPropertiesDiscovered,
              onDataBindingChange: _onDataBindingChange,
              onEventChange: _onEventChange,
              onAnimationComplete: _onAnimationComplete,
            ),
          ),

          // Status Display
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: material_color.Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStatus,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Property Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Interactive Property Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_properties.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: material_color.Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: material_color.Colors.amber[300]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ No properties discovered',
                          style: TextStyle(
                            color: material_color.Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Make sure your Rive file has ViewModel data binding configured.',
                          style: TextStyle(
                              fontSize: 12, color: material_color.Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final prop = _properties[index];
                      if (prop['name'] == '__availableViewModels') {
                        return const SizedBox.shrink();
                      }
                      final vms = _properties
                              .where(
                                  (p) => p['name'] == '__availableViewModels')
                              .map((p) => (p['value'] as List).cast<String>())
                              .firstOrNull ??
                          [];
                      return InteractivePropertyCard(
                        property: prop,
                        onValueChanged: _onPropertyChanged,
                        availableViewModels: vms,
                      );
                    },
                  ),
              ],
            ),
          ),

          // Event Log
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📋 Event Log:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_eventLog.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _eventLog.clear();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_eventLog.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: material_color.Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No events yet - interact with animation!',
                      style: TextStyle(color: material_color.Colors.grey),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: material_color.Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: material_color.Colors.grey[50],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _eventLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          child: Text(
                            _eventLog[index],
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Courier',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ========================================
// INTERACTIVE PROPERTY CARD
// ========================================

/// Widget that displays a single property with type-specific controls
///
/// Automatically generates appropriate UI based on property type:
/// - string: TextField with send button
/// - number: Slider
/// - boolean: Switch
/// - color: Color palette buttons
/// - trigger: Fire button
/// - enumType: Dropdown selector
class _StringPropertyField extends StatefulWidget {
  final String name;
  final dynamic initialValue;
  final Function(String, String, dynamic) onValueChanged;

  const _StringPropertyField({
    required this.name,
    required this.initialValue,
    required this.onValueChanged,
  });

  @override
  State<_StringPropertyField> createState() => _StringPropertyFieldState();
}

class _StringPropertyFieldState extends State<_StringPropertyField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.initialValue?.toString() ?? '');
  }

  @override
  void didUpdateWidget(_StringPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newVal = widget.initialValue?.toString() ?? '';
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != newVal) {
      _controller.text = newVal;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Enter text',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffix: TextButton(
          child: const Text('Update'),
          onPressed: () =>
              widget.onValueChanged(widget.name, 'string', _controller.text),
        ),
      ),
      style: const TextStyle(fontSize: 13),
      onSubmitted: (newValue) =>
          widget.onValueChanged(widget.name, 'string', newValue),
    );
  }
}

class _AddItemControl extends StatefulWidget {
  final String listName;
  final String animationId;
  final List<String> availableViewModels;

  const _AddItemControl({
    required this.listName,
    required this.animationId,
    this.availableViewModels = const [],
  });

  @override
  State<_AddItemControl> createState() => _AddItemControlState();
}

class _AddItemControlState extends State<_AddItemControl> {
  String? _selectedVm;

  @override
  void initState() {
    super.initState();
    if (widget.availableViewModels.isNotEmpty) {
      _selectedVm = widget.availableViewModels.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vms = widget.availableViewModels;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: vms.isEmpty
                ? TextField(
                    decoration: const InputDecoration(
                      labelText: 'ViewModel Type (e.g. TickerItemVM)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _selectedVm = v,
                  )
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'ViewModel Type',
                      border: OutlineInputBorder(),
                    ),
                    initialValue:
                        _selectedVm != null && vms.contains(_selectedVm)
                            ? _selectedVm
                            : (vms.isNotEmpty ? vms.last : null),
                    items: vms
                        .map((vm) =>
                            DropdownMenuItem(value: vm, child: Text(vm)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedVm = v),
                  ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            onPressed: () {
              final vmName = _selectedVm?.trim() ?? '';
              if (vmName.isNotEmpty) {
                RiveAnimationController.instance.addListItem(
                  widget.animationId,
                  widget.listName,
                  itemViewModel: vmName,
                  attachListeners: true,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class InteractivePropertyCard extends StatefulWidget {
  /// The property data containing name, type, and value
  final Map<String, dynamic> property;

  /// Callback when user changes the property value
  final Function(String propertyName, String propertyType, dynamic newValue)
      onValueChanged;

  final List<String> availableViewModels;

  const InteractivePropertyCard({
    super.key,
    required this.property,
    required this.onValueChanged,
    this.availableViewModels = const [],
  });

  @override
  State<InteractivePropertyCard> createState() =>
      _InteractivePropertyCardState();
}

class _InteractivePropertyCardState extends State<InteractivePropertyCard> {
  String get propertyPath =>
      widget.property['fullPath'] as String? ??
      widget.property['name'] as String? ??
      '';
  @override
  Widget build(BuildContext context) {
    // Extract property metadata
    final name = widget.property['name'] as String? ?? '';
    final type = widget.property['type'] as String? ?? '';
    final value = widget.property['value'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================
            // Header: Property name, value, and type badge
            // ====================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Current value display
                      Text(
                        _formatValue(value, type),
                        style: TextStyle(
                          fontSize: 12,
                          color: material_color.Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Type badge with color coding
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 10,
                      color: material_color.Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ====================================
            // Dynamic control based on property type
            // ====================================
            _buildControlForType(context, name, type, value),
          ],
        ),
      ),
    );
  }

  /// Builds the appropriate UI control based on property type
  Widget _buildControlForType(
      BuildContext context, String name, String type, dynamic value) {
    switch (type) {
      case 'string':
        return _buildStringControl(name, value);
      case 'number':
        return _buildNumberControl(name, value);
      case 'boolean':
        return _buildBooleanControl(name, value);
      case 'color':
        return _buildColorControl(name, value);
      case 'trigger':
        return _buildTriggerControl(name);
      case 'enumType':
        return _buildEnumControl(name, value);
      case 'integer':
      case 'symbolListIndex':
        return _buildIntegerControl(name, value);
      case 'image':
        return _buildImageControl(name);
      case 'list':
        return _buildListInfoControl(name, widget.property);
      case 'artboard':
        return _buildArtboardInfoControl(name);
      case 'viewModel':
        return _buildViewModelInfoControl(name, widget.property);
      default:
        return Text('Unsupported type: $type',
            style: TextStyle(
                fontSize: 12, color: material_color.Colors.grey[500]));
    }
  }

  // ====================================
  // STRING CONTROL: TextField with send button
  // ====================================
  Widget _buildStringControl(String name, dynamic value) {
    return _StringPropertyField(
      name: name,
      initialValue: value,
      onValueChanged: (n, t, v) => widget.onValueChanged(propertyPath, t, v),
    );
  }

  // ====================================
  // NUMBER CONTROL: Slider
  // ====================================
  Widget _buildNumberControl(String name, dynamic value) {
    final numValue = (value is num) ? value.toDouble() : 0.0;

    return Column(
      children: [
        Slider(
          value: numValue.clamp(-1920, 1920), // Clamp to range
          min: -1920,
          max: 1920,
          divisions: 294, // Granularity of slider steps
          label: numValue.toStringAsFixed(1), // Show value as label
          onChanged: (newValue) {
            // Update Rive animation as user drags slider
            widget.onValueChanged(propertyPath, 'number', newValue);
          },
        ),
      ],
    );
  }

  // ====================================
  // BOOLEAN CONTROL: Switch with ON/OFF label
  // ====================================
  Widget _buildBooleanControl(String name, dynamic value) {
    final boolValue = value == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          boolValue ? 'ON' : 'OFF',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: boolValue
                ? material_color.Colors.green
                : material_color.Colors.grey,
          ),
        ),
        Switch(
          value: boolValue,
          onChanged: (newValue) {
            // Toggle boolean property
            widget.onValueChanged(propertyPath, 'boolean', newValue);
          },
        ),
      ],
    );
  }

  // ====================================
  // COLOR CONTROL: Palette of color buttons
  // ====================================
  Widget _buildColorControl(String name, dynamic value) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _colorButton(material_color.Colors.red, 'R', name),
        _colorButton(material_color.Colors.green, 'G', name),
        _colorButton(material_color.Colors.blue, 'B', name),
        _colorButton(material_color.Colors.yellow, 'Y', name),
        _colorButton(material_color.Colors.purple, 'P', name),
        _colorButton(material_color.Colors.orange, 'O', name),
        _colorButton(material_color.Colors.teal, 'T', name),
        _colorButton(material_color.Colors.pink, 'Pi', name),
      ],
    );
  }

  /// Helper: Creates a single color button
  Widget _colorButton(Color color, String label, String propertyName) {
    return InkWell(
      onTap: () {
        // Apply selected color to property
        widget.onValueChanged(propertyPath, 'color', color);
      },
      child: Container(
        width: 40,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: material_color.Colors.grey[300]!, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: material_color.Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ====================================
  // TRIGGER CONTROL: Fire button
  // ====================================
  Widget _buildTriggerControl(String name) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () {
          // Fire the trigger (send true value)
          widget.onValueChanged(propertyPath, 'trigger', true);
        },
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text('Fire: $name', style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: material_color.Colors.red,
          foregroundColor: material_color.Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  // ====================================
  // ENUM CONTROL: Dropdown selector
  // ====================================
  Widget _buildEnumControl(String name, dynamic value) {
    // Example enum values - customize based on your Rive file
    final enumOptions = ['Option 1', 'Option 2', 'Option 3'];
    final currentValue = value?.toString() ?? enumOptions.first;

    return DropdownButtonFormField<String>(
      initialValue:
          enumOptions.contains(currentValue) ? currentValue : enumOptions.first,
      decoration: const InputDecoration(
        labelText: 'Select option',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13, color: material_color.Colors.black),
      items: enumOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          widget.onValueChanged(propertyPath, 'enumType', newValue);
        }
      },
    );
  }

  // ====================================
  // HELPER METHODS
  // ====================================

  /// Returns color for type badge based on property type
  Color _getTypeColor(String type) {
    switch (type) {
      case 'string':
        return material_color.Colors.blue;
      case 'number':
        return material_color.Colors.green;
      case 'boolean':
        return material_color.Colors.orange;
      case 'color':
        return material_color.Colors.purple;
      case 'trigger':
        return material_color.Colors.red;
      case 'image':
        return material_color.Colors.teal;
      case 'enumType':
        return material_color.Colors.indigo;
      case 'integer':
        return material_color.Colors.teal;
      case 'list':
        return material_color.Colors.deepPurple;
      case 'artboard':
        return material_color.Colors.brown;
      case 'viewModel':
        return material_color.Colors.cyan;
      case 'symbolListIndex':
        return material_color.Colors.amber;
      default:
        return material_color.Colors.grey;
    }
  }

  /// Formats property value for display
  String _formatValue(dynamic value, String type) {
    if (value == null) {
      return type == 'trigger' ? 'Ready' : 'null';
    }
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    if (value is bool) {
      return value ? 'true' : 'false';
    }
    if (value is String) {
      return value.isEmpty ? '(empty)' : value;
    }
    if (value is int) {
      return value.toString();
    }
    return value.toString();
  }

  // ====================================
  // IMAGE CONTROL: File picker with thumbnail preview
  // ====================================
  Widget _buildImageControl(String name) {
    return _ImagePickerControl(
      propertyName: name,
      onImagePicked: (filePath, bytes) {
        widget.onValueChanged(propertyPath, 'image', bytes);
      },
    );
  }

  // ====================================
  // INTEGER CONTROL: Slider with int values
  // ====================================
  Widget _buildIntegerControl(String name, dynamic value) {
    final intValue = (value is num) ? value.toDouble() : 0.0;

    return Slider(
      value: intValue.clamp(-100, 100),
      min: -100,
      max: 100,
      divisions: 200,
      label: intValue.toInt().toString(),
      onChanged: (newValue) {
        widget.onValueChanged(propertyPath, 'integer', newValue.toInt());
      },
    );
  }

  // ====================================
  // LIST INFO: Display list length and items
  // ====================================
  Widget _buildListInfoControl(String name, Map<String, dynamic> property) {
    final length = property['value'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'List with $length item(s)',
          style:
              TextStyle(fontSize: 12, color: material_color.Colors.grey[700]),
        ),
        _buildListItems(property),
        _AddItemControl(
          listName: name,
          animationId: 'example_animation',
          availableViewModels: widget.availableViewModels,
        ),
      ],
    );
  }

  // ====================================
  // ARTBOARD INFO: Display artboard reference
  // ====================================

  Widget _buildListItems(Map<String, dynamic> property) {
    final listItems = property['listItems'] as List<dynamic>? ?? [];
    if (listItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: listItems.map((item) {
        final nestedProps = item['properties'] as List<dynamic>? ?? [];
        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border.all(color: material_color.Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: material_color.Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle,
                        size: 16, color: material_color.Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '[] ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: material_color.Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        RiveAnimationController.instance.removeListItemAt(
                            'example_animation',
                            property['name'],
                            item['index']);
                      },
                    ),
                  ],
                ),
              ),
              if (nestedProps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: nestedProps
                        .map((p) => InteractivePropertyCard(
                              property: p as Map<String, dynamic>,
                              onValueChanged: widget.onValueChanged,
                              availableViewModels: widget.availableViewModels,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArtboardInfoControl(String name) {
    return Text(
      'Artboard reference (set via BindableArtboard)',
      style: TextStyle(fontSize: 12, color: material_color.Colors.grey[600]),
    );
  }

  // ====================================
  // VIEWMODEL INFO: Display nested VM properties
  // ====================================
  Widget _buildViewModelInfoControl(
      String name, Map<String, dynamic> property) {
    final nestedProps =
        property['nestedProperties'] as List<Map<String, dynamic>>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nested ViewModel with ${nestedProps.length} properties',
          style:
              TextStyle(fontSize: 12, color: material_color.Colors.grey[700]),
        ),
        if (nestedProps.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...nestedProps.take(5).map((prop) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '  ${prop['name']} (${prop['type']})',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              )),
          if (nestedProps.length > 5)
            Text(
              '  ... and ${nestedProps.length - 5} more',
              style: TextStyle(
                  fontSize: 11, color: material_color.Colors.grey[500]),
            ),
        ],
      ],
    );
  }
}

// ========================================
// IMAGE PICKER CONTROL
// ========================================

/// Self-contained image picker widget for a single 'image' ViewModel property.
///
/// Shows:
/// - A thumbnail of the currently picked image (or placeholder)
/// - "Gallery" and "Camera" buttons to pick a replacement image
/// - A loading spinner while the controller decodes and applies the image
/// - A status line and a "Clear" button once an image is selected
///
/// Calls [onImagePicked] with the local file path; the controller's
/// [updateDataBindingProperty] handles file-path → RenderImage decoding.
class _ImagePickerControl extends StatefulWidget {
  final String propertyName;
  final void Function(String filePath, Uint8List bytes) onImagePicked;

  const _ImagePickerControl({
    required this.propertyName,
    required this.onImagePicked,
  });

  @override
  State<_ImagePickerControl> createState() => _ImagePickerControlState();
}

class _ImagePickerControlState extends State<_ImagePickerControl> {
  final _picker = ImagePicker();
  String? _pickedPath;
  bool _isLoading = false;

  /// Camera is only available on iOS and Android.
  /// macOS/Linux/Windows have no camera delegate in image_picker.
  bool get _supportsCameraSource =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null) await _applyImage(file);
  }

  Future<void> _pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file != null) await _applyImage(file);
  }

  Future<void> _applyImage(XFile file) async {
    setState(() {
      _pickedPath = file.path;
      _isLoading = true;
    });

    final bytes = await file.readAsBytes();
    widget.onImagePicked(file.path, bytes);

    // Allow the controller ~800 ms to decode and apply, then clear the spinner
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _clear() => setState(() {
        _pickedPath = null;
        _isLoading = false;
      });

  @override
  Widget build(BuildContext context) {
    final hasPick = _pickedPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Thumbnail + status ─────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / placeholder box
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: material_color.Colors.grey[100],
                  border: Border.all(color: material_color.Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : hasPick
                        ? Image.network(
                            // Image.network handles both file:// URIs and http:// URLs
                            _pickedPath!.startsWith('/')
                                ? 'file://$_pickedPath'
                                : _pickedPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 28,
                              color: material_color.Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: material_color.Colors.grey,
                          ),
              ),
            ),

            const SizedBox(width: 12),

            // Status text + filename + clear button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPick
                        ? _isLoading
                            ? 'Applying to Rive…'
                            : '✅ Applied to animation'
                        : 'No image selected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasPick && !_isLoading
                          ? material_color.Colors.green[700]
                          : material_color.Colors.grey[600],
                    ),
                  ),
                  if (hasPick) ...[
                    const SizedBox(height: 2),
                    Text(
                      _pickedPath!.split('/').last,
                      style: TextStyle(
                        fontSize: 10,
                        color: material_color.Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.close, size: 13),
                      label:
                          const Text('Clear', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: material_color.Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Picker buttons ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 15),
                label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: material_color.Colors.teal[300]!),
                  foregroundColor: material_color.Colors.teal[700],
                ),
              ),
            ),
            // Camera is only available on iOS / Android
            if (_supportsCameraSource) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 15),
                  label: const Text('Camera', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side:
                        BorderSide(color: material_color.Colors.blueGrey[300]!),
                    foregroundColor: material_color.Colors.blueGrey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
