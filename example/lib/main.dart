import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_animation_manager/rive_animation_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Animation Manager Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RiveAnimationExample(),
    );
  }
}

class RiveAnimationExample extends StatefulWidget {
  const RiveAnimationExample({Key? key}) : super(key: key);

  @override
  State<RiveAnimationExample> createState() => _RiveAnimationExampleState();
}

class _RiveAnimationExampleState extends State<RiveAnimationExample> {
  String _currentStatus = 'Loading...';
  List<Map<String, dynamic>> _properties = [];
  List<String> _eventLog = [];
  Map<String, dynamic> _lastInput = {};
  Map<String, dynamic> _lastPropertyChange = {};

  final Map<String, dynamic> _propertyValues = {};

  // ========== CALLBACK HANDLERS ==========

  /// Called when animation is initialized
  void _onInit(Artboard artboard) {
    _addEventLog('✅ Animation Initialized: ${artboard.name}');
    print('Animation initialized: ${artboard.name}');
    print('Artboard dimensions: ${artboard.width}x${artboard.height}');
  }

  /// Called when state machine inputs change
  void _onInputChange(int index, String name, dynamic value) {
    _addEventLog('📝 Input Changed: $name = $value');
    setState(() {
      _lastInput = {
        'name': name,
        'value': value,
        'index': index,
        'time': DateTime.now().toString().split('.')[0],
      };
    });
    print('Input changed: $name = $value (index: $index)');
  }

  /// Called when hovering/boolean input changes
  void _onHoverAction(String name, dynamic value) {
    _addEventLog('🎯 Hover Action: $name = $value');
    print('Hover action: $name = $value');
  }

  /// Called when trigger inputs fire
  void _onTriggerAction(String name, dynamic value) {
    _addEventLog('⚡ Trigger Fired: $name');
    setState(() {
      _currentStatus = 'Trigger fired: $name';
    });
    print('Trigger action: $name = $value');
  }

  /// Called when ViewModel properties are discovered
  void _onViewModelPropertiesDiscovered(List<Map<String, dynamic>> properties) {
    if (properties.isEmpty) {
      _addEventLog(
        '⚠️ No ViewModel properties (animation may not have data binding)',
      );
      print(
        'WARNING: No ViewModel properties discovered. '
        'Make sure your Rive file has ViewModel bindings configured in the editor.',
      );
    } else {
      _addEventLog('🔍 Properties Discovered: ${properties.length} properties');
      print('ViewModel properties discovered: ${properties.length}');

      _propertyValues.clear();
      for (var prop in properties) {
        _propertyValues[prop['name']] = prop['value'];
        print('  - ${prop['name']} (${prop['type']}): ${prop['value']}');
      }
    }

    setState(() {
      _properties = properties;
      _currentStatus = properties.isEmpty
          ? 'No data binding properties'
          : 'Discovered ${properties.length} properties';
    });
  }

  /// Called when data binding properties change (REAL-TIME!)
  void _onDataBindingChange(
    String propertyName,
    String propertyType,
    dynamic value,
  ) {
    _addEventLog(
      '🔗 Data Binding: $propertyName ($propertyType) = $value',
    );
    print('Data binding changed: $propertyName = $value');

    setState(() {
      _propertyValues[propertyName] = value;
      _lastPropertyChange = {
        'name': propertyName,
        'type': propertyType,
        'value': value,
        'time': DateTime.now().toString().split('.')[0],
      };

      for (int i = 0; i < _properties.length; i++) {
        if (_properties[i]['name'] == propertyName) {
          _properties[i] = {
            ..._properties[i],
            'value': value,
          };
          break;
        }
      }
    });
  }

  /// Called when Rive events occur
  void _onEventChange(String eventName, Event event, String currentState) {
    _addEventLog('📢 Event: $eventName (State: $currentState)');
    print('Event fired: $eventName (current state: $currentState)');
  }

  /// Called when animation completes
  void _onAnimationComplete() {
    _addEventLog('✨ Animation Complete!');
    setState(() {
      _currentStatus = 'Animation completed!';
    });
    print('Animation complete');
  }

  /// Helper to add events to log
  void _addEventLog(String message) {
    setState(() {
      _eventLog.insert(0, message);
      if (_eventLog.length > 10) {
        _eventLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive Animation Manager - Complete Example'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Animation Display Area
            Container(
              color: Colors.grey[100],
              height: 300,
              child: RiveManager(
                animationId: 'example_animation',
                riveFilePath: 'assets/animations/data-change-on-click.riv',
                animationType: RiveAnimationType.stateMachine,
                fit: Fit.contain,
                alignment: Alignment.center,
                // ✅ ALL 8 CALLBACKS IMPLEMENTED AND WORKING
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
                          color: Colors.grey,
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

            // Last Input Display
            if (_lastInput.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Last Input:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: ${_lastInput['name']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Value: ${_lastInput['value']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Time: ${_lastInput['time']}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Last Property Change Display
            if (_lastPropertyChange.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Colors.purple[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔗 Last Property Change:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Name: ${_lastPropertyChange['name']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Type: ${_lastPropertyChange['type']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Value: ${_lastPropertyChange['value']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Time: ${_lastPropertyChange['time']}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Properties List
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 Animation Properties (Real-Time):',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_properties.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '⚠️ No properties discovered',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Make sure your Rive file has ViewModel data binding configured.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                        return PropertyCard(property: prop);
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
                        '📋 Event Log (Latest 10):',
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No events yet - interact with animation to see events!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _eventLog.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              _eventLog[index],
                              style: const TextStyle(
                                fontSize: 12,
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

            // Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ All 8 Callbacks Working',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. onInit - Animation initialized\n'
                        '2. onInputChange - Inputs changed\n'
                        '3. onHoverAction - Hover/boolean actions\n'
                        '4. onTriggerAction - Triggers fired\n'
                        '5. onViewModelPropertiesDiscovered - Properties found\n'
                        '6. onDataBindingChange - Properties changed in real-time ⚡\n'
                        '7. onEventChange - Rive events fired\n'
                        '8. onAnimationComplete - Animation completed',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Watch the Event Log and Property Display update in real-time!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Property Card Widget
class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyCard({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = property['name'] as String? ?? '';
    final type = property['type'] as String? ?? '';
    final value = property['value'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Value: ${_formatValue(value, type)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'string':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'boolean':
        return Colors.orange;
      case 'color':
        return Colors.purple;
      case 'trigger':
        return Colors.red;
      case 'image':
        return Colors.teal;
      case 'enumType':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatValue(dynamic value, String type) {
    if (value == null) {
      return type == 'trigger' ? 'Ready to trigger' : 'null';
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
    return value.toString();
  }
}
