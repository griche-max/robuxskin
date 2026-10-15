import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import 'template_geometry.dart';
import 'decal_painter.dart';

class ArtworkRenderer {
  static void paint(
    Canvas canvas, {
    required List<SkinStroke> strokes,
    ui.Image? photo,
    double photoScale = 1,
    Offset photoOffset = Offset.zero,
    double photoOpacity = 1,
  }) {
    canvas.save();
    canvas.clipPath(ClothingTemplate.clipPath);
    canvas.saveLayer(Offset.zero & ClothingTemplate.size, Paint());

    if (photo != null) {
      final coverScale =
          mathMax(
            ClothingTemplate.size.width / photo.width,
            ClothingTemplate.size.height / photo.height,
          ) *
          photoScale;
      final width = photo.width * coverScale;
      final height = photo.height * coverScale;
      final destination = Rect.fromLTWH(
        (ClothingTemplate.size.width - width) / 2 + photoOffset.dx,
        (ClothingTemplate.size.height - height) / 2 + photoOffset.dy,
        width,
        height,
      );
      canvas.drawImageRect(
        photo,
        Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
        destination,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..color = Color.fromRGBO(255, 255, 255, photoOpacity),
      );
    }

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    canvas.restore();
    canvas.restore();
  }

  static void _paintStroke(Canvas canvas, SkinStroke stroke) {
    if (stroke.segments.isNotEmpty) {
      for (final segment in stroke.segments) {
        _paintStroke(canvas, segment);
      }
      return;
    }
    if (stroke.points.isEmpty) return;
    canvas.save();
    if (stroke.clipRect != null) canvas.clipRect(stroke.clipRect!);
    try {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver;

      if (stroke.kind == StrokeKind.decal && stroke.decal != null) {
        canvas.translate(stroke.points.first.dx, stroke.points.first.dy);
        canvas.rotate(stroke.rotation);
        canvas.scale(stroke.flipX ? -1 : 1, 1);
        final bounds = Rect.fromCenter(
          center: Offset.zero,
          width: stroke.decalSize,
          height: stroke.decalSize / stroke.decal!.aspectRatio,
        );
        canvas.saveLayer(
          bounds.inflate(2),
          Paint()..color = Color.fromRGBO(255, 255, 255, stroke.opacity),
        );
        DecalPainter.draw(canvas, stroke.decal!, bounds, stroke.color);
        canvas.restore();
        return;
      }
      if (stroke.kind == StrokeKind.text) {
        final value = stroke.text;
        if (value == null || value.isEmpty) return;
        final textPainter = TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              color: stroke.color,
              fontSize: stroke.width,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: ClothingTemplate.size.width);
        textPainter.paint(canvas, stroke.points.first);
        return;
      }

      if (stroke.kind == StrokeKind.pixel) {
        paint.style = PaintingStyle.fill;
        for (final point in stroke.points) {
          canvas.drawRect(
            Rect.fromLTWH(point.dx, point.dy, stroke.width, stroke.width),
            paint,
          );
        }
        return;
      }

      if (stroke.kind != StrokeKind.freehand && stroke.points.length >= 2) {
        final bounds = Rect.fromPoints(stroke.points.first, stroke.points.last);
        paint.style = stroke.isFilled
            ? PaintingStyle.fill
            : PaintingStyle.stroke;
        switch (stroke.kind) {
          case StrokeKind.line:
            canvas.drawLine(stroke.points.first, stroke.points.last, paint);
          case StrokeKind.rectangle:
            canvas.drawRect(bounds, paint);
          case StrokeKind.ellipse:
            canvas.drawOval(bounds, paint);
          case StrokeKind.freehand ||
              StrokeKind.pixel ||
              StrokeKind.text ||
              StrokeKind.decal:
            break;
        }
        return;
      }

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
      } else {
        final path = Path()
          ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (var i = 1; i < stroke.points.length; i++) {
          final previous = stroke.points[i - 1];
          final current = stroke.points[i];
          final midpoint = Offset(
            (previous.dx + current.dx) / 2,
            (previous.dy + current.dy) / 2,
          );
          path.quadraticBezierTo(
            previous.dx,
            previous.dy,
            midpoint.dx,
            midpoint.dy,
          );
        }
        path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
        canvas.drawPath(path, paint);
      }
    } finally {
      canvas.restore();
    }
  }

  static Future<ui.Image> render({
    required List<SkinStroke> strokes,
    ui.Image? photo,
    double photoScale = 1,
    Offset photoOffset = Offset.zero,
    double photoOpacity = 1,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paint(
      canvas,
      strokes: strokes,
      photo: photo,
      photoScale: photoScale,
      photoOffset: photoOffset,
      photoOpacity: photoOpacity,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        ClothingTemplate.size.width.toInt(),
        ClothingTemplate.size.height.toInt(),
      );
    } finally {
      picture.dispose();
    }
  }
}

double mathMax(double a, double b) => a > b ? a : b;

class SkinCanvasPainter extends CustomPainter {
  SkinCanvasPainter({
    required this.strokes,
    required this.showGuide,
    required this.clothingType,
    this.photo,
    this.photoScale = 1,
    this.photoOffset = Offset.zero,
    this.photoOpacity = 1,
    this.showPixelGrid = false,
    this.pixelSize = 16,
  });

  final List<SkinStroke> strokes;
  final bool showGuide;
  final ClothingType clothingType;
  final ui.Image? photo;
  final double photoScale;
  final Offset photoOffset;
  final double photoOpacity;
  final bool showPixelGrid;
  final double pixelSize;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / ClothingTemplate.size.width;
    final sy = size.height / ClothingTemplate.size.height;
    canvas.save();
    canvas.scale(sx, sy);
    _paintCheckerboard(canvas);
    ArtworkRenderer.paint(
      canvas,
      strokes: strokes,
      photo: photo,
      photoScale: photoScale,
      photoOffset: photoOffset,
      photoOpacity: photoOpacity,
    );
    if (showGuide) _paintGuide(canvas);
    if (showPixelGrid) _paintPixelGrid(canvas);
    canvas.restore();
  }

  void _paintPixelGrid(Canvas canvas) {
    canvas.save();
    canvas.clipPath(ClothingTemplate.clipPath);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..color = const Color(0xA61A1E27);
    final path = Path();
    for (var x = 0.0; x <= ClothingTemplate.size.width; x += pixelSize) {
      path
        ..moveTo(x, 0)
        ..lineTo(x, ClothingTemplate.size.height);
    }
    for (var y = 0.0; y <= ClothingTemplate.size.height; y += pixelSize) {
      path
        ..moveTo(0, y)
        ..lineTo(ClothingTemplate.size.width, y);
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _paintCheckerboard(Canvas canvas) {
    const cell = 16.0;
    final background = Paint()..color = const Color(0xFFF4F5F7);
    final alternate = Paint()..color = const Color(0xFFE3E6EA);
    canvas.drawRect(Offset.zero & ClothingTemplate.size, background);
    for (var y = 0; y < ClothingTemplate.size.height; y += cell.toInt()) {
      for (var x = 0; x < ClothingTemplate.size.width; x += cell.toInt()) {
        if (((x ~/ cell) + (y ~/ cell)).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), cell, cell),
            alternate,
          );
        }
      }
    }
  }

  void _paintGuide(Canvas canvas) {
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xCCFFFFFF);
    for (final region in ClothingTemplate.all) {
      canvas.drawRect(
        region.rect,
        Paint()..color = region.color.withValues(alpha: 0.28),
      );
      canvas.drawRect(region.rect.deflate(1), border);
      final textPainter = TextPainter(
        text: TextSpan(
          text: region.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: region.rect.width >= 100 ? 24 : 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: region.rect.width);
      textPainter.paint(
        canvas,
        Offset(
          region.rect.center.dx - textPainter.width / 2,
          region.rect.center.dy - textPainter.height / 2,
        ),
      );
    }

    final label = clothingType == ClothingType.shirt ? 'ARMS' : 'LEGS';
    _paintSectionLabel(canvas, 'TORSO', const Offset(386, 23));
    _paintSectionLabel(canvas, 'RIGHT $label', const Offset(20, 520));
    _paintSectionLabel(canvas, 'LEFT $label', const Offset(414, 520));
  }

  void _paintSectionLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF5F6570),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SkinCanvasPainter oldDelegate) => true;
}
