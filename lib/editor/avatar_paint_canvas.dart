import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import 'avatar_preview.dart';

enum AvatarInteraction { paint, rotate, pan }

/// Paint one garment per stroke; camera gestures never resume an old stroke.
class AvatarPaintCanvas extends StatefulWidget {
  const AvatarPaintCanvas({
    super.key,
    required this.shirtTexture,
    required this.pantsTexture,
    required this.bodyShape,
    required this.clothingType,
    required this.tool,
    required this.color,
    required this.brushWidth,
    required this.pixelSize,
    required this.pixelErase,
    required this.rotation,
    required this.pitch,
    required this.zoom,
    required this.onOrbit,
    required this.onStrokeChanged,
    required this.onStrokeEnd,
    this.interaction = AvatarInteraction.paint,
    this.pan = Offset.zero,
    this.part = AvatarPart.wholeBody,
    this.hideArms = false,
    this.onViewChanged,
    this.onTargetChanged,
    this.onStrokeCancel,
    this.onDecalStart,
    this.onDecalMove,
    this.onDecalEnd,
    this.onDecalCancel,
  });

  final ui.Image? shirtTexture;
  final ui.Image? pantsTexture;
  final AvatarBodyShape bodyShape;
  final ClothingType clothingType;
  final EditorTool tool;
  final Color color;
  final double brushWidth;
  final double pixelSize;
  final bool pixelErase;
  final double rotation;
  final double pitch;
  final double zoom;
  final Offset pan;
  final AvatarPart part;
  final bool hideArms;
  final AvatarInteraction interaction;
  final void Function(double rotation, double pitch) onOrbit;
  final void Function(double zoom, Offset pan)? onViewChanged;
  final ValueChanged<ClothingType>? onTargetChanged;
  final ValueChanged<SkinStroke> onStrokeChanged;
  final VoidCallback onStrokeEnd;
  final VoidCallback? onStrokeCancel;
  final ValueChanged<AvatarSurfaceHit>? onDecalStart;
  final ValueChanged<AvatarSurfaceHit>? onDecalMove;
  final VoidCallback? onDecalEnd;
  final VoidCallback? onDecalCancel;

  @override
  State<AvatarPaintCanvas> createState() => _AvatarPaintCanvasState();
}

class _AvatarPaintCanvasState extends State<AvatarPaintCanvas> {
  final Map<int, Offset> _pointers = {};
  bool _navigating = false;
  bool _moved = false;
  bool _decalGesture = false;
  Rect? _lastFace;
  ClothingType? _strokeType;
  Offset? _cursor;
  late double _rotation, _pitch, _zoom;
  late Offset _pan;
  final List<SkinStroke> _segments = [];

  @override
  void initState() {
    super.initState();
    _syncCamera();
  }

  void _syncCamera() {
    _rotation = widget.rotation;
    _pitch = widget.pitch;
    _zoom = widget.zoom;
    _pan = widget.pan;
  }

  @override
  void didUpdateWidget(covariant AvatarPaintCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pointers.isEmpty) _syncCamera();
  }

  AvatarPainter get _painter => AvatarPainter(
    shirtTexture: widget.shirtTexture,
    pantsTexture: widget.pantsTexture,
    bodyShape: widget.bodyShape,
    rotation: _rotation,
    pitch: _pitch,
    zoom: _zoom,
    pan: _pan,
    allowAllClothing: true,
    part: widget.part,
    hideArms: widget.hideArms,
  );

  AvatarInteraction get _interaction => widget.tool == EditorTool.hand
      ? AvatarInteraction.rotate
      : widget.interaction;

  void _sample(Offset position, Size size, AvatarPainter painter) {
    final hit = painter.surfaceAt(position, size);
    if (hit == null || hit.clothingType != _strokeType) {
      _lastFace = null;
      _cursor = null;
      return;
    }
    _cursor = position;
    final pixel = widget.tool == EditorTool.pixel;
    final fill = widget.tool == EditorTool.fill;
    final point = pixel
        ? Offset(
            (hit.point.dx / widget.pixelSize).floor() * widget.pixelSize,
            (hit.point.dy / widget.pixelSize).floor() * widget.pixelSize,
          )
        : hit.point;
    if (fill && _segments.any((s) => s.clipRect == hit.rect)) return;
    if (!fill && _lastFace == hit.rect && _segments.isNotEmpty) {
      final segment = _segments.last;
      if (pixel && segment.points.contains(point)) return;
      _segments[_segments.length - 1] = segment.copyWith(
        points: [...segment.points, point],
      );
    } else {
      _segments.add(
        SkinStroke(
          points: fill ? [hit.rect.topLeft, hit.rect.bottomRight] : [point],
          color: widget.color,
          width: pixel ? widget.pixelSize : widget.brushWidth,
          isEraser:
              widget.tool == EditorTool.eraser || (pixel && widget.pixelErase),
          kind: fill
              ? StrokeKind.rectangle
              : pixel
              ? StrokeKind.pixel
              : StrokeKind.freehand,
          isFilled: fill,
          clipRect: hit.rect,
        ),
      );
    }
    _lastFace = hit.rect;
  }

  void _notify() {
    if (_segments.isEmpty) return;
    widget.onStrokeChanged(
      SkinStroke(
        points: const [],
        color: widget.color,
        width: widget.brushWidth,
        isEraser: false,
        segments: List.of(_segments),
      ),
    );
  }

  void _complete({bool cancel = false}) {
    if (_decalGesture) {
      if (cancel) {
        widget.onDecalCancel?.call();
      } else {
        widget.onDecalEnd?.call();
      }
      _decalGesture = false;
    }
    if (_segments.isNotEmpty) {
      if (cancel && widget.onStrokeCancel != null) {
        widget.onStrokeCancel!();
      } else {
        widget.onStrokeEnd();
      }
    }
    _segments.clear();
    _lastFace = null;
    _strokeType = null;
    _cursor = null;
  }

  void _cameraChanged() {
    widget.onOrbit(_rotation, _pitch);
    widget.onViewChanged?.call(_zoom, _pan);
  }

  void _down(PointerDownEvent event, Size size) {
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length > 1) {
      // A resting first finger in a pinch should not leave a paint dot.
      _complete(cancel: !_moved);
      setState(() => _navigating = true);
      return;
    }
    _moved = false;
    final painter = _painter;
    final hit = painter.surfaceAt(event.localPosition, size);
    _navigating =
        _interaction != AvatarInteraction.paint ||
        hit == null ||
        event.buttons == kSecondaryMouseButton;
    if (!_navigating) {
      _strokeType = hit!.clothingType;
      if (widget.tool == EditorTool.decal) {
        _decalGesture = true;
        widget.onDecalStart?.call(hit);
      } else {
        widget.onTargetChanged?.call(_strokeType!);
        _sample(event.localPosition, size, painter);
        _notify();
      }
    }
    setState(() {});
  }

  void _move(PointerMoveEvent event, Size size) {
    final previous = _pointers[event.pointer];
    if (previous == null) return;
    final oldPair = _pointers.values.take(2).toList();
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length >= 2) {
      final pair = _pointers.values.take(2).toList();
      final delta = (pair[0] + pair[1] - oldPair[0] - oldPair[1]) / 2;
      final oldDistance = (oldPair[0] - oldPair[1]).distance;
      if (oldDistance > 8) {
        _zoom = (_zoom * (pair[0] - pair[1]).distance / oldDistance).clamp(
          .75,
          4.0,
        );
      }
      if (_interaction == AvatarInteraction.pan) {
        _pan += delta;
      } else {
        _rotation += delta.dx * .015;
        _pitch = (_pitch + delta.dy * .015).clamp(-1.5, 1.5);
      }
      _cameraChanged();
    } else if (_navigating) {
      final delta = event.localPosition - previous;
      if (_interaction == AvatarInteraction.pan) {
        _pan += delta;
      } else {
        _rotation += delta.dx * .015;
        _pitch = (_pitch + delta.dy * .015).clamp(-1.5, 1.5);
      }
      _cameraChanged();
    } else if (_decalGesture) {
      _moved = true;
      final hit = _painter.surfaceAt(event.localPosition, size);
      if (hit != null && hit.clothingType == _strokeType) {
        widget.onDecalMove?.call(hit);
      }
    } else {
      _moved = true;
      final steps = math.max(
        1,
        ((event.localPosition - previous).distance / 2).ceil(),
      );
      final painter = _painter;
      for (var i = 1; i <= steps; i++) {
        _sample(
          Offset.lerp(previous, event.localPosition, i / steps)!,
          size,
          painter,
        );
      }
      _notify();
    }
    setState(() {});
  }

  void _end(PointerEvent event) {
    if (_pointers.remove(event.pointer) == null) return;
    if (_pointers.isEmpty) {
      _complete();
      _navigating = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF202429),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF353B42)),
              ),
            ),
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _down(e, size),
                onPointerMove: (e) => _move(e, size),
                onPointerUp: _end,
                onPointerCancel: _end,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    GestureBinding.instance.pointerSignalResolver.register(
                      event,
                      (_) {
                        setState(
                          () => _zoom =
                              (_zoom * math.exp(-event.scrollDelta.dy * .002))
                                  .clamp(.75, 4.0),
                        );
                        _cameraChanged();
                      },
                    );
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      key: const ValueKey('avatar-paint-surface'),
                      painter: _painter,
                    ),
                    if (_cursor != null)
                      Positioned(
                        left: _cursor!.dx - 10,
                        top: _cursor!.dy - 10,
                        child: IgnorePointer(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Text(
                          switch (_interaction) {
                            AvatarInteraction.paint =>
                              widget.tool == EditorTool.decal
                                  ? 'Tap or drag to place • Two fingers rotate'
                                  : 'Paint any limb • Two fingers rotate & pinch',
                            AvatarInteraction.rotate =>
                              'Drag to turn & tilt • Pinch to zoom',
                            AvatarInteraction.pan =>
                              'Drag to move the model • Pinch to zoom',
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB5BFCE),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
