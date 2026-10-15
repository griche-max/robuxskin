import 'dart:ui';
import 'decal_artwork.dart';

enum ClothingType { shirt, pants }

enum EditorTool {
  hand,
  brush,
  pixel,
  eraser,
  line,
  rectangle,
  ellipse,
  fill,
  text,
  decal,
}

enum StrokeKind { freehand, pixel, line, rectangle, ellipse, text, decal }

class SkinStroke {
  SkinStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.isEraser,
    this.kind = StrokeKind.freehand,
    this.isFilled = false,
    this.text,
    this.clipRect,
    this.segments = const [],
    this.decal,
    this.decalSize = 64,
    this.rotation = 0,
    this.opacity = 1,
    this.flipX = false,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  final StrokeKind kind;
  final bool isFilled;
  final String? text;
  final Rect? clipRect;
  // A 3D gesture can cross several faces; keep it as one undoable action.
  final List<SkinStroke> segments;

  final DecalArtwork? decal;
  final double decalSize;
  final double rotation;
  final double opacity;
  final bool flipX;

  SkinStroke copyWith({
    List<Offset>? points,
    Rect? clipRect,
    Color? color,
    double? decalSize,
    double? rotation,
    double? opacity,
    bool? flipX,
  }) {
    return SkinStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width,
      isEraser: isEraser,
      kind: kind,
      isFilled: isFilled,
      text: text,
      clipRect: clipRect ?? this.clipRect,
      segments: segments,
      decal: decal,
      decalSize: decalSize ?? this.decalSize,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      flipX: flipX ?? this.flipX,
    );
  }
}
