import 'dart:ui';

enum StickerShape {
  star,
  heart,
  lightning,
  crown,
  smile,
  flower,
  diamond,
  shield,
}

extension StickerShapeInfo on StickerShape {
  String get label => switch (this) {
    StickerShape.star => 'Star',
    StickerShape.heart => 'Heart',
    StickerShape.lightning => 'Lightning',
    StickerShape.crown => 'Crown',
    StickerShape.smile => 'Smile',
    StickerShape.flower => 'Flower',
    StickerShape.diamond => 'Diamond',
    StickerShape.shield => 'Shield',
  };
}

/// The editor owns imported images for the lifetime of its undo history.
class DecalArtwork {
  const DecalArtwork({
    required this.label,
    this.image,
    this.sticker,
    this.text,
  });
  final String label;
  final Image? image;
  final StickerShape? sticker;
  final String? text;
  double get aspectRatio => image != null
      ? image!.width / image!.height
      : text != null
      ? 2.5
      : 1;
}
