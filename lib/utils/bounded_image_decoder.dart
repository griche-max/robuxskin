import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class BoundedImageResult {
  const BoundedImageResult({
    required this.image,
    required this.originalWidth,
    required this.originalHeight,
  });

  final ui.Image image;
  final int originalWidth;
  final int originalHeight;

  bool get wasDownsampled =>
      image.width != originalWidth || image.height != originalHeight;
}

Future<BoundedImageResult> decodeBoundedImage(
  Uint8List bytes, {
  int maxDimension = 2048,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  try {
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    try {
      final originalWidth = descriptor.width;
      final originalHeight = descriptor.height;
      final scale = math.min(
        1.0,
        maxDimension / math.max(originalWidth, originalHeight),
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (originalWidth * scale).round()),
        targetHeight: math.max(1, (originalHeight * scale).round()),
      );
      try {
        final frame = await codec.getNextFrame();
        return BoundedImageResult(
          image: frame.image,
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}
