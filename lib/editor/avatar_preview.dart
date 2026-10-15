import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import 'template_geometry.dart';

enum AvatarBodyShape { classic, broad, slender, curvy }

extension AvatarBodyShapeInfo on AvatarBodyShape {
  String get label => switch (this) {
    AvatarBodyShape.classic => 'Classic',
    AvatarBodyShape.broad => 'Broad',
    AvatarBodyShape.slender => 'Slender',
    AvatarBodyShape.curvy => 'Curvy',
  };

  String get fitNote => switch (this) {
    AvatarBodyShape.classic => 'block fit',
    AvatarBodyShape.broad => 'wide fit',
    AvatarBodyShape.slender => 'slim fit',
    AvatarBodyShape.curvy => 'custom fit',
  };
}

class AvatarPreview extends StatefulWidget {
  const AvatarPreview({
    super.key,
    required this.shirtTexture,
    required this.pantsTexture,
    required this.bodyShape,
    required this.rotation,
    required this.onRotationChanged,
    required this.autoRotate,
  });

  final ui.Image? shirtTexture;
  final ui.Image? pantsTexture;
  final AvatarBodyShape bodyShape;
  final double rotation;
  final ValueChanged<double> onRotationChanged;
  final bool autoRotate;

  @override
  State<AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<AvatarPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.autoRotate) _rotationController.repeat();
  }

  @override
  void didUpdateWidget(covariant AvatarPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoRotate == oldWidget.autoRotate) return;
    if (widget.autoRotate) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final animatedRotation =
            widget.rotation + _rotationController.value * math.pi * 2;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            widget.onRotationChanged(
              widget.rotation + details.delta.dx * 0.018,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: AvatarPainter(
                  shirtTexture: widget.shirtTexture,
                  pantsTexture: widget.pantsTexture,
                  bodyShape: widget.bodyShape,
                  rotation: animatedRotation,
                ),
              ),
              const Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe, size: 16, color: Color(0xFF9CA3AF)),
                    SizedBox(width: 7),
                    Text(
                      'Drag to rotate',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A visible clothing face mapped back into the exported template.
class AvatarSurfaceHit {
  const AvatarSurfaceHit(this.point, this.rect, this.clothingType);

  final Offset point;
  final Rect rect;
  final ClothingType clothingType;
}

enum AvatarPart {
  wholeBody('Whole body'),
  torso('Torso'),
  rightArm('Right arm'),
  leftArm('Left arm'),
  rightLeg('Right leg'),
  leftLeg('Left leg');

  const AvatarPart(this.label);
  final String label;
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Face {
  const _Face({
    required this.vertices,
    required this.depth,
    required this.color,
    this.textureRect,
    this.textureSlot,
  });

  final List<Offset> vertices;
  final double depth;
  final Color color;
  final Rect? textureRect;
  final _TextureSlot? textureSlot;
}

enum _TextureSlot { shirt, pants }

class _BodyProportions {
  const _BodyProportions({
    required this.torsoHalfWidth,
    required this.hipHalfWidth,
    required this.torsoDepth,
    required this.armWidth,
    required this.legWidth,
    required this.headHalfWidth,
    required this.headHeight,
    required this.bodyHeight,
  });

  final double torsoHalfWidth;
  final double hipHalfWidth;
  final double torsoDepth;
  final double armWidth;
  final double legWidth;
  final double headHalfWidth;
  final double headHeight;
  final double bodyHeight;

  static _BodyProportions forShape(AvatarBodyShape shape) => switch (shape) {
    AvatarBodyShape.classic => const _BodyProportions(
      torsoHalfWidth: 1,
      hipHalfWidth: .92,
      torsoDepth: .5,
      armWidth: .64,
      legWidth: .84,
      headHalfWidth: .72,
      headHeight: 1.4,
      bodyHeight: 5.75,
    ),
    AvatarBodyShape.broad => const _BodyProportions(
      torsoHalfWidth: 1.18,
      hipHalfWidth: .94,
      torsoDepth: .56,
      armWidth: .70,
      legWidth: .82,
      headHalfWidth: .74,
      headHeight: 1.38,
      bodyHeight: 5.82,
    ),
    AvatarBodyShape.slender => const _BodyProportions(
      torsoHalfWidth: .82,
      hipHalfWidth: .76,
      torsoDepth: .42,
      armWidth: .48,
      legWidth: .65,
      headHalfWidth: .64,
      headHeight: 1.32,
      bodyHeight: 6.12,
    ),
    AvatarBodyShape.curvy => const _BodyProportions(
      torsoHalfWidth: .88,
      hipHalfWidth: 1.04,
      torsoDepth: .52,
      armWidth: .54,
      legWidth: .88,
      headHalfWidth: .69,
      headHeight: 1.36,
      bodyHeight: 5.94,
    ),
  };
}

class AvatarPainter extends CustomPainter {
  AvatarPainter({
    required this.shirtTexture,
    required this.pantsTexture,
    required this.bodyShape,
    required this.rotation,
    this.pitch = .17,
    this.zoom = 1,
    this.editingType,
    this.allowAllClothing = false,
    this.pan = Offset.zero,
    this.part = AvatarPart.wholeBody,
    this.hideArms = false,
  });

  final ui.Image? shirtTexture;
  final ui.Image? pantsTexture;
  final AvatarBodyShape bodyShape;
  final double rotation;

  final double pitch;
  final double zoom;
  final ClothingType? editingType;
  final bool allowAllClothing;
  final Offset pan;
  final AvatarPart part;
  final bool hideArms;
  _Vec3 _pivot = const _Vec3(0, 2.9, 0);
  Size _viewport = Size.zero;

  Size? _cachedSize;
  List<_Face>? _cachedFaces;

  List<_Face> _faces(Size size) {
    if (_cachedSize == size && _cachedFaces != null) return _cachedFaces!;
    _viewport = size;
    final proportions = _BodyProportions.forShape(bodyShape);
    final scale = math.min(size.width / 6.5, size.height / 8.1) * zoom;
    final origin = Offset(size.width / 2, size.height * 0.49) + pan;
    final faces = <_Face>[];
    final heightDelta = proportions.bodyHeight - 5.75;
    final legTop = 2.05 + heightDelta * .42;
    final torsoBottom = legTop + .10;
    final torsoTop = 4.25 + heightDelta * .70;
    final headBottom = torsoTop + .10;
    final headTop = headBottom + proportions.headHeight;
    final armGap = .08;
    final armInner = proportions.torsoHalfWidth + armGap;
    final armOuter = armInner + proportions.armWidth;
    final legGap = .08;
    final legInner = legGap;
    final legOuter = math.max(
      proportions.hipHalfWidth,
      legInner + proportions.legWidth,
    );

    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(-proportions.headHalfWidth, headBottom, -.55),
      max: _Vec3(proportions.headHalfWidth, headTop, .55),
      baseColor: const Color(0xFFD8DBE2),
    );

    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(
        -proportions.torsoHalfWidth,
        torsoBottom,
        -proportions.torsoDepth,
      ),
      max: _Vec3(proportions.torsoHalfWidth, torsoTop, proportions.torsoDepth),
      baseColor: const Color(0xFF697181),
      part: AvatarPart.torso,
      faceTextures: ClothingTemplate.torsoFaces,
      textureSlot: editingType == ClothingType.pants
          ? _TextureSlot.pants
          : _TextureSlot.shirt,
    );

    // Classic pants include a torso section. A cropped waist overlay keeps the
    // shirt visible while accurately previewing the pants around the hips.
    if ((pantsTexture != null || allowAllClothing) && editingType == null) {
      _addBox(
        faces,
        origin,
        scale,
        min: _Vec3(
          -proportions.hipHalfWidth,
          torsoBottom,
          -proportions.torsoDepth - .012,
        ),
        max: _Vec3(
          proportions.hipHalfWidth,
          torsoBottom + (torsoTop - torsoBottom) * .28,
          proportions.torsoDepth + .012,
        ),
        baseColor: Colors.transparent,
        faceTextures: _lowerTorsoFaces,
        textureSlot: _TextureSlot.pants,
      );
    }

    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(-armOuter, torsoBottom, -.45),
      max: _Vec3(-armInner, torsoTop - .05, .45),
      baseColor: const Color(0xFFB7BDC8),
      part: AvatarPart.rightArm,
      faceTextures: ClothingTemplate.rightLimbFaces,
      textureSlot: _TextureSlot.shirt,
    );
    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(armInner, torsoBottom, -.45),
      max: _Vec3(armOuter, torsoTop - .05, .45),
      baseColor: const Color(0xFFB7BDC8),
      part: AvatarPart.leftArm,
      faceTextures: ClothingTemplate.leftLimbFaces,
      textureSlot: _TextureSlot.shirt,
    );

    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(-legOuter, 0, -.46),
      max: _Vec3(-legInner, legTop, .46),
      baseColor: const Color(0xFF9299A7),
      part: AvatarPart.rightLeg,
      faceTextures: ClothingTemplate.rightLimbFaces,
      textureSlot: _TextureSlot.pants,
    );
    _addBox(
      faces,
      origin,
      scale,
      min: _Vec3(legInner, 0, -.46),
      max: _Vec3(legOuter, legTop, .46),
      baseColor: const Color(0xFF9299A7),
      part: AvatarPart.leftLeg,
      faceTextures: ClothingTemplate.leftLimbFaces,
      textureSlot: _TextureSlot.pants,
    );

    faces.sort((a, b) => a.depth.compareTo(b.depth));
    _cachedSize = size;
    _cachedFaces = faces;
    return faces;
  }

  AvatarSurfaceHit? surfaceAt(Offset point, Size size) {
    // Reverse painter order so hidden surfaces never receive paint.
    for (final face in _faces(size).reversed) {
      final x = face.vertices[1] - face.vertices[0];
      final y = face.vertices[3] - face.vertices[0];
      final delta = point - face.vertices[0];
      final determinant = x.dx * y.dy - x.dy * y.dx;
      if (determinant.abs() < .001) continue;
      final u = (delta.dx * y.dy - delta.dy * y.dx) / determinant;
      final v = (x.dx * delta.dy - x.dy * delta.dx) / determinant;
      if (u < 0 || u > 1 || v < 0 || v > 1) continue;
      final type = switch (face.textureSlot) {
        _TextureSlot.shirt => ClothingType.shirt,
        _TextureSlot.pants => ClothingType.pants,
        null => null,
      };
      final rect = face.textureRect;
      if (rect == null ||
          type == null ||
          (!allowAllClothing && editingType != null && type != editingType)) {
        return null;
      }
      return AvatarSurfaceHit(
        Offset(rect.left + u * rect.width, rect.top + v * rect.height),
        rect,
        type,
      );
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 6.5, size.height / 8.1) * zoom;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .87),
        width: scale * 4.5,
        height: scale * .7,
      ),
      Paint()..color = Colors.black.withValues(alpha: .24),
    );
    for (final face in _faces(size)) {
      final path = Path()
        ..moveTo(face.vertices.first.dx, face.vertices.first.dy);
      for (final point in face.vertices.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = face.color);
      final texture = switch (face.textureSlot) {
        _TextureSlot.shirt => shirtTexture,
        _TextureSlot.pants => pantsTexture,
        null => null,
      };
      if (texture != null && face.textureRect != null) {
        canvas.save();
        canvas.clipPath(path);
        _drawTextureFace(canvas, texture, face.textureRect!, face.vertices);
        canvas.restore();
      }
      if (face.color.a > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.black.withValues(alpha: 0.22),
        );
      }
    }
  }

  void _addBox(
    List<_Face> output,
    Offset origin,
    double scale, {
    required _Vec3 min,
    required _Vec3 max,
    required Color baseColor,
    Map<String, Rect>? faceTextures,
    _TextureSlot? textureSlot,
    AvatarPart? part,
  }) {
    if (this.part != AvatarPart.wholeBody && this.part != part) return;
    if (this.part == AvatarPart.wholeBody &&
        hideArms &&
        (part == AvatarPart.leftArm || part == AvatarPart.rightArm)) {
      return;
    }
    if (this.part != AvatarPart.wholeBody) {
      _pivot = _Vec3(
        (min.x + max.x) / 2,
        (min.y + max.y) / 2,
        (min.z + max.z) / 2,
      );
      // A bounding sphere keeps the isolated part in view at every angle.
      final diameter = math.sqrt(
        math.pow(max.x - min.x, 2) +
            math.pow(max.y - min.y, 2) +
            math.pow(max.z - min.z, 2),
      );
      scale =
          math.min(_viewport.width * .82, _viewport.height * .70) /
          diameter *
          zoom;
    }

    final definitions = <String, List<_Vec3>>{
      'front': [
        _Vec3(min.x, max.y, max.z),
        _Vec3(max.x, max.y, max.z),
        _Vec3(max.x, min.y, max.z),
        _Vec3(min.x, min.y, max.z),
      ],
      'back': [
        _Vec3(max.x, max.y, min.z),
        _Vec3(min.x, max.y, min.z),
        _Vec3(min.x, min.y, min.z),
        _Vec3(max.x, min.y, min.z),
      ],
      'left': [
        _Vec3(min.x, max.y, min.z),
        _Vec3(min.x, max.y, max.z),
        _Vec3(min.x, min.y, max.z),
        _Vec3(min.x, min.y, min.z),
      ],
      'right': [
        _Vec3(max.x, max.y, max.z),
        _Vec3(max.x, max.y, min.z),
        _Vec3(max.x, min.y, min.z),
        _Vec3(max.x, min.y, max.z),
      ],
      'top': [
        _Vec3(min.x, max.y, min.z),
        _Vec3(max.x, max.y, min.z),
        _Vec3(max.x, max.y, max.z),
        _Vec3(min.x, max.y, max.z),
      ],
      'bottom': [
        _Vec3(min.x, min.y, max.z),
        _Vec3(max.x, min.y, max.z),
        _Vec3(max.x, min.y, min.z),
        _Vec3(min.x, min.y, min.z),
      ],
    };

    for (final entry in definitions.entries) {
      final projected = entry.value
          .map((v) => _project(v, origin, scale))
          .toList();
      final x = projected[1] - projected[0];
      final y = projected[3] - projected[0];
      if (x.dx * y.dy - x.dy * y.dx <= .001) continue;
      final depth = entry.value.map(_depth).reduce((a, b) => a + b) / 4;
      final shade = switch (entry.key) {
        'top' => 0.13,
        'bottom' => -0.20,
        'left' || 'right' => -0.08,
        _ => 0.0,
      };
      output.add(
        _Face(
          vertices: projected,
          depth: depth,
          color: _shiftLightness(baseColor, shade),
          textureRect: faceTextures?[entry.key],
          textureSlot: textureSlot,
        ),
      );
    }
  }

  Offset _project(_Vec3 point, Offset origin, double scale) {
    point = _Vec3(point.x - _pivot.x, point.y - _pivot.y, point.z - _pivot.z);
    final horizontal =
        point.x * math.cos(rotation) + point.z * math.sin(rotation);
    final depth = -point.x * math.sin(rotation) + point.z * math.cos(rotation);
    return Offset(
      origin.dx + horizontal * scale,
      origin.dy - (point.y * math.cos(pitch) - depth * math.sin(pitch)) * scale,
    );
  }

  double _depth(_Vec3 point) {
    point = _Vec3(point.x - _pivot.x, point.y - _pivot.y, point.z - _pivot.z);
    final depth = -point.x * math.sin(rotation) + point.z * math.cos(rotation);
    return depth * math.cos(pitch) + point.y * math.sin(pitch);
  }

  void _drawTextureFace(
    Canvas canvas,
    ui.Image image,
    Rect source,
    List<Offset> points,
  ) {
    final xAxis = points[1] - points[0];
    final yAxis = points[3] - points[0];
    canvas.translate(points[0].dx, points[0].dy);
    canvas.transform(
      Float64List.fromList([
        xAxis.dx / source.width,
        xAxis.dy / source.width,
        0,
        0,
        yAxis.dx / source.height,
        yAxis.dy / source.height,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    );
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, source.width, source.height),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  Color _shiftLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.shirtTexture != shirtTexture ||
        oldDelegate.pantsTexture != pantsTexture ||
        oldDelegate.rotation != rotation ||
        oldDelegate.bodyShape != bodyShape ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.editingType != editingType ||
        oldDelegate.allowAllClothing != allowAllClothing ||
        oldDelegate.pan != pan ||
        oldDelegate.part != part ||
        oldDelegate.hideArms != hideArms;
  }

  static final Map<String, Rect> _lowerTorsoFaces = {
    for (final entry in ClothingTemplate.torsoFaces.entries)
      entry.key: entry.key == 'top' || entry.key == 'bottom'
          ? entry.value
          : Rect.fromLTWH(
              entry.value.left,
              entry.value.top + entry.value.height * .72,
              entry.value.width,
              entry.value.height * .28,
            ),
  };
}
