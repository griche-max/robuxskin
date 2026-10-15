import 'dart:ui';

class TemplateRegion {
  const TemplateRegion(this.rect, this.label, this.color);

  final Rect rect;
  final String label;
  final Color color;
}

class ClothingTemplate {
  static const Size size = Size(585, 559);

  static const red = Color(0xFFE72B25);
  static const blue = Color(0xFF0878B9);
  static const green = Color(0xFF00B85A);
  static const gold = Color(0xFFFFB20A);
  static const orange = Color(0xFFF47C08);
  static const cyan = Color(0xFF08A6EE);

  static const List<TemplateRegion> torso = [
    TemplateRegion(Rect.fromLTWH(231, 8, 128, 64), 'UP', cyan),
    TemplateRegion(Rect.fromLTWH(165, 74, 64, 128), 'R', green),
    TemplateRegion(Rect.fromLTWH(231, 74, 128, 128), 'FRONT', red),
    TemplateRegion(Rect.fromLTWH(361, 74, 64, 128), 'L', gold),
    TemplateRegion(Rect.fromLTWH(427, 74, 128, 128), 'BACK', blue),
    TemplateRegion(Rect.fromLTWH(231, 204, 128, 64), 'DOWN', orange),
  ];

  static const List<TemplateRegion> rightLimb = [
    TemplateRegion(Rect.fromLTWH(217, 289, 64, 64), 'U', cyan),
    TemplateRegion(Rect.fromLTWH(19, 355, 64, 128), 'L', gold),
    TemplateRegion(Rect.fromLTWH(85, 355, 64, 128), 'B', blue),
    TemplateRegion(Rect.fromLTWH(151, 355, 64, 128), 'R', green),
    TemplateRegion(Rect.fromLTWH(217, 355, 64, 128), 'F', red),
    TemplateRegion(Rect.fromLTWH(217, 485, 64, 64), 'D', orange),
  ];

  static const List<TemplateRegion> leftLimb = [
    TemplateRegion(Rect.fromLTWH(307, 289, 64, 64), 'U', cyan),
    TemplateRegion(Rect.fromLTWH(307, 355, 64, 128), 'F', red),
    TemplateRegion(Rect.fromLTWH(373, 355, 64, 128), 'L', gold),
    TemplateRegion(Rect.fromLTWH(439, 355, 64, 128), 'B', blue),
    TemplateRegion(Rect.fromLTWH(505, 355, 64, 128), 'R', green),
    TemplateRegion(Rect.fromLTWH(307, 485, 64, 64), 'D', orange),
  ];

  static List<TemplateRegion> get all => [...torso, ...rightLimb, ...leftLimb];

  static Path get clipPath {
    final path = Path();
    for (final region in all) {
      path.addRect(region.rect);
    }
    return path;
  }

  static const Map<String, Rect> torsoFaces = {
    'top': Rect.fromLTWH(231, 8, 128, 64),
    'right': Rect.fromLTWH(165, 74, 64, 128),
    'front': Rect.fromLTWH(231, 74, 128, 128),
    'left': Rect.fromLTWH(361, 74, 64, 128),
    'back': Rect.fromLTWH(427, 74, 128, 128),
    'bottom': Rect.fromLTWH(231, 204, 128, 64),
  };

  static const Map<String, Rect> rightLimbFaces = {
    'top': Rect.fromLTWH(217, 289, 64, 64),
    'left': Rect.fromLTWH(19, 355, 64, 128),
    'back': Rect.fromLTWH(85, 355, 64, 128),
    'right': Rect.fromLTWH(151, 355, 64, 128),
    'front': Rect.fromLTWH(217, 355, 64, 128),
    'bottom': Rect.fromLTWH(217, 485, 64, 64),
  };

  static const Map<String, Rect> leftLimbFaces = {
    'top': Rect.fromLTWH(307, 289, 64, 64),
    'front': Rect.fromLTWH(307, 355, 64, 128),
    'left': Rect.fromLTWH(373, 355, 64, 128),
    'back': Rect.fromLTWH(439, 355, 64, 128),
    'right': Rect.fromLTWH(505, 355, 64, 128),
    'bottom': Rect.fromLTWH(307, 485, 64, 64),
  };
}
