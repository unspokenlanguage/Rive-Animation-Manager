# Rive Animation Manager Example

This example demonstrates how to use the **Rive Animation Manager** package to manage Rive animations with data binding, property discovery, and input handling.

## Features Demonstrated

✅ **Animation Display** - Render Rive animations with RiveManager widget
✅ **Property Discovery** - Automatically discover animation properties (strings, numbers, booleans, colors, triggers, etc.)
✅ **Input Handling** - Respond to animation input changes and trigger events
✅ **Status Display** - Show real-time animation status and events
✅ **UI Controls** - Buttons to refresh properties and show package information

## Project Structure

```
example/
├── main.dart           # Main application entry point
└── README.md           # This file
```

## Getting Started

### 1. Add Animation Assets

Create an `assets/animations/` directory and add your Rive file:

```bash
mkdir -p assets/animations
# Copy your .riv file to assets/animations/
cp path/to/your/animation.riv assets/animations/example.riv
```

### 2. Update pubspec.yaml

Add assets to your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/animations/example.riv
```

### 3. Run the Example

```bash
flutter pub get
flutter run
```

## Key Widgets Used

### RiveManager

The main widget that displays the Rive animation:

```dart
RiveManager(
  animationId: 'example_animation',
  riveFilePath: 'assets/animations/example.riv',
  animationType: RiveAnimationType.stateMachine,
  onViewModelPropertiesDiscovered: (properties) {
    // Handle discovered properties
  },
  onTriggerAction: (name, value) {
    // Handle trigger events
  },
  onInputChange: (index, name, value) {
    // Handle input changes
  },
)
```

### PropertyCard

Custom widget that displays animation properties with type-specific styling.

## Understanding Properties

The example discovers and displays various property types:

| Type | Color | Purpose |
|------|-------|---------|
| `string` | Blue | Text values |
| `number` | Green | Numeric values |
| `boolean` | Orange | Boolean flags |
| `color` | Purple | Color values |
| `trigger` | Red | One-time events |
| `image` | Teal | Image assets |
| `enumType` | Indigo | Enumeration values |

## Callbacks

### onInit
Called when the animation is initialized:
```dart
onInit: (artboard) {
  print('Initialized: ${artboard.name}');
}
```

### onViewModelPropertiesDiscovered
Called when properties are discovered:
```dart
onViewModelPropertiesDiscovered: (properties) {
  print('Found ${properties.length} properties');
}
```

### onInputChange
Called when animation inputs change:
```dart
onInputChange: (index, name, value) {
  print('$name changed to $value');
}
```

### onTriggerAction
Called when trigger events fire:
```dart
onTriggerAction: (name, value) {
  print('Trigger $name fired');
}
```

## Customization

### Change Animation File
Replace `example.riv` with your own animation:
```dart
riveFilePath: 'assets/animations/your_animation.riv',
```

### Adjust Display Size
Modify the container height or use Fit properties:
```dart
fit: Fit.contain,  // or Fit.cover, Fit.fill
alignment: Alignment.center,
```

### Add More Properties
Listen to property discovery and update UI dynamically:
```dart
onViewModelPropertiesDiscovered: (properties) {
  // Process properties
}
```

## Troubleshooting

**Animation not loading?**
- Ensure the `.riv` file exists at `assets/animations/example.riv`
- Check `pubspec.yaml` assets configuration
- Run `flutter pub get` and `flutter clean`

**Properties not discovered?**
- Check if your animation has ViewModel bindings
- Ensure animation type is `stateMachine` if using inputs
- Check LogManager logs for errors

**Input not responding?**
- Verify state machine inputs are properly configured in Rive editor
- Check input names match your animation file
- Ensure callbacks are properly implemented

## Next Steps

- Explore the [API documentation](https://pub.dev/documentation/rive_animation_manager/latest/)
- Check the [GitHub repository](https://github.com/unspokenlanguage/rive_animation_manager) for more examples
- Review [Rive documentation](https://help.rive.app/) for animation creation

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/unspokenlanguage/rive_animation_manager/issues)
- Check the package [documentation](https://pub.dev/packages/rive_animation_manager)

---

Happy animating! 🎬
