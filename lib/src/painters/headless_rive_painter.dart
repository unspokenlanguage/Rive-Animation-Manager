// lib/src/painters/headless_rive_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart' show Alignment;
import 'package:rive/rive.dart';
import 'package:rive_native/rive_native.dart';

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
  final RiveWidgetController controller;
  final Fit fit;
  final Alignment alignment;
  final double layoutScaleFactor;

  HeadlessRivePainter({
    required this.controller,
    this.fit = Fit.contain,
    this.alignment = Alignment.center,
    this.layoutScaleFactor = 1.0,
  });

  @override
  Color get background => const Color(0x00000000); // fully transparent

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
