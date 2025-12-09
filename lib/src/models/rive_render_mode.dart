// lib/src/models/rive_render_mode.dart

/// Rendering mode for RiveManager.
///
/// Controls whether the Rive animation renders as a visible Flutter widget
/// or as a headless GPU texture for broadcast/compositing pipelines.
enum RiveRenderMode {
  /// Default: renders as a standard Flutter widget.
  /// Use for on-screen UI animations.
  widget,

  /// Headless: renders to a GPU texture with no visible widget output.
  /// Use for broadcast pipelines, off-screen compositing, or zero-copy
  /// GPU handoff via IOSurface (macOS) or similar mechanisms.
  ///
  /// When using this mode:
  /// - Provide [textureWidth] and [textureHeight] on [RiveManager]
  /// - Use [onTextureReady] to receive the [RenderTexture] once created
  /// - Use [onNativeTexturePointer] for direct FFI access to the GPU texture
  /// - All data binding, property discovery, and controller APIs still work
  texture,
}
