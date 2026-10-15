import 'package:flutter/material.dart';

Rect sharePositionOrigin(BuildContext context) {
  final overlay = Overlay.maybeOf(context);
  final renderObject = overlay?.context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 1,
    height: 1,
  );
}
