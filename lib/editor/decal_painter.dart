import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/decal_artwork.dart';

class DecalPainter extends CustomPainter {
  const DecalPainter(this.artwork, this.color);
  final DecalArtwork artwork;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      draw(canvas, artwork, Offset.zero & size, color);

  static void draw(Canvas canvas, DecalArtwork art, Rect bounds, Color color) {
    final image = art.image;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bounds,
        Paint()..filterQuality = FilterQuality.high,
      );
      return;
    }
    if (art.text != null) {
      final text = TextPainter(
        text: TextSpan(
          text: art.text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 64,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final scale = math.min(
        bounds.width / math.max(1, text.width),
        bounds.height / math.max(1, text.height),
      );
      canvas.save();
      canvas.translate(
        bounds.center.dx - text.width * scale / 2,
        bounds.center.dy - text.height * scale / 2,
      );
      canvas.scale(scale);
      text.paint(canvas, Offset.zero);
      canvas.restore();
      text.dispose();
      return;
    }
    canvas.save();
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(bounds.width / 100, bounds.height / 100);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    final path = Path();
    switch (art.sticker) {
      case StickerShape.star:
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 48.0 : 22.0;
          final p = Offset(50 + r * math.cos(angle), 50 + r * math.sin(angle));
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
      case StickerShape.heart:
        path.moveTo(50, 94);
        path.cubicTo(-25, 45, 0, -10, 50, 24);
        path.cubicTo(100, -10, 125, 45, 50, 94);
        path.close();
      case StickerShape.lightning:
        path.moveTo(54, 0);
        path.lineTo(14, 57);
        path.lineTo(44, 57);
        path.lineTo(34, 100);
        path.lineTo(88, 37);
        path.lineTo(56, 37);
        path.close();
      case StickerShape.crown:
        path.moveTo(12, 82);
        path.lineTo(2, 22);
        path.lineTo(30, 46);
        path.lineTo(50, 6);
        path.lineTo(70, 46);
        path.lineTo(98, 22);
        path.lineTo(88, 82);
        path.close();
        path.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 88, 76, 9),
            const Radius.circular(3),
          ),
        );
      case StickerShape.smile:
        canvas.drawCircle(const Offset(50, 50), 47, paint);
        final ink = Paint()..color = const Color(0xFF17202B);
        canvas.drawOval(const Rect.fromLTWH(27, 27, 11, 17), ink);
        canvas.drawOval(const Rect.fromLTWH(62, 27, 11, 17), ink);
        canvas.drawArc(
          const Rect.fromLTWH(24, 33, 52, 43),
          0,
          math.pi,
          false,
          ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
      case StickerShape.flower:
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          canvas.drawCircle(
            Offset(50 + 27 * math.cos(a), 50 + 27 * math.sin(a)),
            22,
            paint,
          );
        }
        canvas.drawCircle(
          const Offset(50, 50),
          16,
          Paint()..color = const Color(0xFFFFE08A),
        );
      case StickerShape.diamond:
        path.moveTo(50, 1);
        path.lineTo(97, 50);
        path.lineTo(50, 99);
        path.lineTo(3, 50);
        path.close();
      case StickerShape.shield:
        path.moveTo(8, 9);
        path.lineTo(92, 9);
        path.lineTo(87, 58);
        path.quadraticBezierTo(78, 84, 50, 99);
        path.quadraticBezierTo(22, 84, 13, 58);
        path.close();
      case null:
        break;
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DecalPainter oldDelegate) =>
      oldDelegate.artwork != artwork || oldDelegate.color != color;
}
