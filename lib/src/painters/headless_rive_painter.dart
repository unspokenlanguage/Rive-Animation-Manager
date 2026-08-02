// lib/src/painters/headless_rive_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart' show Alignment;
import 'package:rive/rive.dart';


/// A [RenderTexturePainter] that drives Rive animation rendering into a
/// GPU texture without requiring visible widget output.
///
/// Used by [RiveManager] in [RiveRenderMode.texture] mode to enable
/// headless rendering for broadcast pipelines and zero-copy GPU compositing.
///
/// The painter:
/// - Clears the texture with a transparent background (preserves alpha)
/// - Advances the state machine each frame
/// - Renders the artboard into the GPU texture via Rive's C++ renderer
/// - Keeps the ticker alive so animation continues off-screen
base class HeadlessRivePainter extends RenderTexturePainter {
  /// The controller that manages the Rive artboard and state machine.
  final RiveWidgetController controller;
  
  /// How the Rive animation should be inscribed into the texture space.
  final Fit fit;
  
  /// How to align the Rive animation within the texture bounds.
  final Alignment alignment;
  
  /// The scale factor to apply to the layout, defaults to 1.0.
  final double layoutScaleFactor;

  /// Creates a new [HeadlessRivePainter].
  ///
  /// The [controller] is required to drive the animation.
  HeadlessRivePainter({
    required this.controller,
    this.fit = Fit.contain,
    this.alignment = Alignment.center,
    this.layoutScaleFactor = 1.0,
  });

  /// The background color to clear the texture with before each frame.
  /// Defaults to fully transparent to allow composition.
  @override
  Color get background => const Color(0x00000000); // fully transparent

  /// Indicates whether the texture should be cleared before rendering a new frame.
  @override
  bool get clear => super.clear;

  /// Indicates whether this painter requires a clip.
  @override
  bool get needsClip => super.needsClip;

  /// Indicates whether this painter will paint to a Flutter [Canvas].
  @override
  bool get paintsCanvas => super.paintsCanvas;

  /// Paints directly to the Flutter [Canvas].
  /// Overridden to provide missing dartdoc.
  @override
  void paintCanvas(Canvas canvas, Offset offset, Size size) {
    super.paintCanvas(canvas, offset, size);
  }

  /// Renders the Rive artboard into the GPU texture and advances the animation.
  @override
  bool paint(
    RenderTexture texture,
    double devicePixelRatio,
    Size size,
    double elapsedSeconds,
  ) {
    final artboard = controller.artboard;

    // Advance the state machine
    final shouldContinue =
        controller.stateMachine.advanceAndApply(elapsedSeconds);

    // Draw artboard into the texture
    final renderer = texture.renderer;
    renderer.save();
    renderer.align(
      fit,
      alignment,
      AABB.fromValues(0, 0, size.width, size.height),
      artboard.bounds,
      layoutScaleFactor,
    );
    artboard.draw(renderer);
    renderer.restore();

    return shouldContinue;
  }
}
