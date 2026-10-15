import 'dart:ui';

import '../editor/template_geometry.dart';
import 'editor_models.dart';

class ReadyDesignTemplate {
  const ReadyDesignTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.type,
    required this.palette,
    required List<SkinStroke> Function() build,
  }) : _build = build;

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final ClothingType type;
  final List<Color> palette;
  final List<SkinStroke> Function() _build;

  List<SkinStroke> createStrokes() => _build();
}

abstract final class DesignTemplateCatalog {
  static const categories = [
    'All',
    'Streetwear',
    'Sport',
    'Minimal',
    'Fantasy',
    'Seasonal',
  ];

  static final List<ReadyDesignTemplate> all = [
    ReadyDesignTemplate(
      id: 'cyber-circuit',
      title: 'Cyber Circuit',
      subtitle: 'Dark tech panels with electric trim',
      category: 'Streetwear',
      type: ClothingType.shirt,
      palette: const [Color(0xFF111827), Color(0xFF35D7E5), Color(0xFF9A6BFF)],
      build: _cyberCircuit,
    ),
    ReadyDesignTemplate(
      id: 'aqua-cargo',
      title: 'Aqua Cargo',
      subtitle: 'Utility pockets and asymmetric leg panels',
      category: 'Streetwear',
      type: ClothingType.pants,
      palette: const [Color(0xFFE4E7EC), Color(0xFF159FB1), Color(0xFFFF6F61)],
      build: _aquaCargo,
    ),
    ReadyDesignTemplate(
      id: 'night-league',
      title: 'Night League',
      subtitle: 'Numbered team jersey with gold trim',
      category: 'Sport',
      type: ClothingType.shirt,
      palette: const [Color(0xFF14284A), Color(0xFFFFC857), Color(0xFFFFFFFF)],
      build: _nightLeague,
    ),
    ReadyDesignTemplate(
      id: 'sunset-runner',
      title: 'Sunset Runner',
      subtitle: 'Fast diagonal stripes for both legs',
      category: 'Sport',
      type: ClothingType.pants,
      palette: const [Color(0xFF34245F), Color(0xFFFF8C42), Color(0xFFFF4D6D)],
      build: _sunsetRunner,
    ),
    ReadyDesignTemplate(
      id: 'mono-core',
      title: 'Mono Core',
      subtitle: 'Clean monochrome blocks and cuffs',
      category: 'Minimal',
      type: ClothingType.shirt,
      palette: const [Color(0xFF1A1D24), Color(0xFFF3F4F6), Color(0xFF777E8C)],
      build: _monoCore,
    ),
    ReadyDesignTemplate(
      id: 'royal-formal',
      title: 'Royal Formal',
      subtitle: 'Tailored navy trousers with gold seams',
      category: 'Minimal',
      type: ClothingType.pants,
      palette: const [Color(0xFF182B50), Color(0xFFD8AE63), Color(0xFFF5F0E5)],
      build: _royalFormal,
    ),
    ReadyDesignTemplate(
      id: 'ember-drake',
      title: 'Ember Drake',
      subtitle: 'Layered flame marks and a bold crest',
      category: 'Fantasy',
      type: ClothingType.shirt,
      palette: const [Color(0xFF2A1118), Color(0xFFFF5A36), Color(0xFFFFC857)],
      build: _emberDrake,
    ),
    ReadyDesignTemplate(
      id: 'forest-scout',
      title: 'Forest Scout',
      subtitle: 'Trail-ready panels, straps, and knee guards',
      category: 'Fantasy',
      type: ClothingType.pants,
      palette: const [Color(0xFF244535), Color(0xFF8B5E3C), Color(0xFFD8C27A)],
      build: _forestScout,
    ),
    ReadyDesignTemplate(
      id: 'frost-grid',
      title: 'Frost Grid',
      subtitle: 'Layered ice-blue technical grid',
      category: 'Seasonal',
      type: ClothingType.shirt,
      palette: const [Color(0xFF163B63), Color(0xFF76D9F4), Color(0xFFFFFFFF)],
      build: _frostGrid,
    ),
    ReadyDesignTemplate(
      id: 'ice-racer',
      title: 'Ice Racer',
      subtitle: 'Crisp white legs with cyan speed panels',
      category: 'Seasonal',
      type: ClothingType.pants,
      palette: const [Color(0xFFF4F7FA), Color(0xFF31C4E8), Color(0xFF2463B6)],
      build: _iceRacer,
    ),
    ReadyDesignTemplate(
      id: 'sakura-pop',
      title: 'Sakura Pop',
      subtitle: 'Soft color blocks with pixel blossom details',
      category: 'Seasonal',
      type: ClothingType.shirt,
      palette: const [Color(0xFFFFD9E8), Color(0xFFEE5CB6), Color(0xFFFFF4D6)],
      build: _sakuraPop,
    ),
    ReadyDesignTemplate(
      id: 'shadow-utility',
      title: 'Shadow Utility',
      subtitle: 'Dark cargo structure with signal straps',
      category: 'Streetwear',
      type: ClothingType.pants,
      palette: const [Color(0xFF171A21), Color(0xFF4F5665), Color(0xFFB8F34A)],
      build: _shadowUtility,
    ),
  ];
}

List<SkinStroke> _cyberCircuit() => [
  ..._base(const Color(0xFF111827)),
  ..._sideStripes(const Color(0xFF35D7E5), 14),
  _line(
    const Offset(238, 185),
    const Offset(352, 89),
    const Color(0xFF9A6BFF),
    12,
  ),
  _line(
    const Offset(241, 111),
    const Offset(347, 173),
    const Color(0xFF35D7E5),
    7,
  ),
  _rect(const Rect.fromLTWH(278, 120, 33, 33), const Color(0xFF9A6BFF)),
  _rect(const Rect.fromLTWH(286, 128, 17, 17), const Color(0xFF111827)),
];

List<SkinStroke> _aquaCargo() => [
  ..._base(const Color(0xFFE4E7EC)),
  _rect(const Rect.fromLTWH(217, 355, 64, 128), const Color(0xFF159FB1)),
  _rect(const Rect.fromLTWH(439, 355, 64, 128), const Color(0xFF159FB1)),
  _rect(const Rect.fromLTWH(229, 386, 45, 52), const Color(0xFFFF6F61)),
  _rect(const Rect.fromLTWH(446, 401, 48, 49), const Color(0xFFFF6F61)),
  _rect(const Rect.fromLTWH(307, 355, 13, 128), const Color(0xFF246879)),
  _rect(const Rect.fromLTWH(151, 355, 13, 128), const Color(0xFF246879)),
  _line(
    const Offset(218, 370),
    const Offset(280, 370),
    const Color(0xFFFFFFFF),
    5,
  ),
  _line(
    const Offset(439, 385),
    const Offset(502, 385),
    const Color(0xFFFFFFFF),
    5,
  ),
];

List<SkinStroke> _nightLeague() => [
  ..._base(const Color(0xFF14284A)),
  _rect(const Rect.fromLTWH(231, 74, 128, 20), const Color(0xFFFFC857)),
  _rect(const Rect.fromLTWH(217, 355, 64, 18), const Color(0xFFFFC857)),
  _rect(const Rect.fromLTWH(307, 355, 64, 18), const Color(0xFFFFC857)),
  _text('07', const Offset(276, 113), const Color(0xFFFFC857), 35),
  _text('NIGHT', const Offset(263, 92), const Color(0xFFFFFFFF), 14),
];

List<SkinStroke> _sunsetRunner() => [
  ..._base(const Color(0xFF34245F)),
  _line(
    const Offset(217, 470),
    const Offset(281, 365),
    const Color(0xFFFF8C42),
    17,
  ),
  _line(
    const Offset(307, 470),
    const Offset(371, 365),
    const Color(0xFFFF8C42),
    17,
  ),
  _line(
    const Offset(228, 480),
    const Offset(281, 393),
    const Color(0xFFFF4D6D),
    9,
  ),
  _line(
    const Offset(318, 480),
    const Offset(371, 393),
    const Color(0xFFFF4D6D),
    9,
  ),
  _rect(const Rect.fromLTWH(231, 74, 128, 18), const Color(0xFFFF8C42)),
];

List<SkinStroke> _monoCore() => [
  ..._base(const Color(0xFF1A1D24)),
  _rect(const Rect.fromLTWH(255, 98, 80, 80), const Color(0xFFF3F4F6)),
  _rect(const Rect.fromLTWH(271, 114, 48, 48), const Color(0xFF1A1D24)),
  _rect(const Rect.fromLTWH(217, 460, 64, 23), const Color(0xFFF3F4F6)),
  _rect(const Rect.fromLTWH(307, 460, 64, 23), const Color(0xFFF3F4F6)),
  _rect(const Rect.fromLTWH(165, 74, 12, 128), const Color(0xFF777E8C)),
  _rect(const Rect.fromLTWH(543, 74, 12, 128), const Color(0xFF777E8C)),
];

List<SkinStroke> _royalFormal() => [
  ..._base(const Color(0xFF182B50)),
  _rect(const Rect.fromLTWH(231, 74, 128, 17), const Color(0xFFD8AE63)),
  _rect(const Rect.fromLTWH(273, 91, 8, 111), const Color(0xFFD8AE63)),
  _rect(const Rect.fromLTWH(307, 355, 7, 128), const Color(0xFFD8AE63)),
  _rect(const Rect.fromLTWH(274, 355, 7, 128), const Color(0xFFD8AE63)),
  _rect(const Rect.fromLTWH(217, 464, 64, 19), const Color(0xFF101D36)),
  _rect(const Rect.fromLTWH(307, 464, 64, 19), const Color(0xFF101D36)),
];

List<SkinStroke> _emberDrake() => [
  ..._base(const Color(0xFF2A1118)),
  _line(
    const Offset(236, 186),
    const Offset(282, 91),
    const Color(0xFFFF5A36),
    18,
  ),
  _line(
    const Offset(282, 91),
    const Offset(319, 173),
    const Color(0xFFFFC857),
    13,
  ),
  _line(
    const Offset(319, 173),
    const Offset(352, 103),
    const Color(0xFFFF5A36),
    17,
  ),
  ..._sideStripes(const Color(0xFFFF5A36), 11),
  _text('EMBER', const Offset(251, 176), const Color(0xFFFFC857), 15),
];

List<SkinStroke> _forestScout() => [
  ..._base(const Color(0xFF244535)),
  _rect(const Rect.fromLTWH(217, 396, 64, 50), const Color(0xFF8B5E3C)),
  _rect(const Rect.fromLTWH(307, 396, 64, 50), const Color(0xFF8B5E3C)),
  _rect(const Rect.fromLTWH(231, 74, 128, 17), const Color(0xFFD8C27A)),
  _rect(const Rect.fromLTWH(151, 355, 10, 128), const Color(0xFFD8C27A)),
  _rect(const Rect.fromLTWH(505, 355, 10, 128), const Color(0xFFD8C27A)),
  _line(
    const Offset(225, 410),
    const Offset(274, 410),
    const Color(0xFFD8C27A),
    5,
  ),
  _line(
    const Offset(315, 410),
    const Offset(364, 410),
    const Color(0xFFD8C27A),
    5,
  ),
];

List<SkinStroke> _frostGrid() {
  final strokes = <SkinStroke>[..._base(const Color(0xFF163B63))];
  for (double x = 20; x < ClothingTemplate.size.width; x += 34) {
    strokes.add(
      _line(Offset(x, 0), Offset(x, 559), const Color(0x6676D9F4), 3),
    );
  }
  for (double y = 12; y < ClothingTemplate.size.height; y += 34) {
    strokes.add(
      _line(Offset(0, y), Offset(585, y), const Color(0x66FFFFFF), 3),
    );
  }
  strokes.add(
    _rect(const Rect.fromLTWH(275, 118, 40, 40), const Color(0xFF76D9F4)),
  );
  return strokes;
}

List<SkinStroke> _iceRacer() => [
  ..._base(const Color(0xFFF4F7FA)),
  _rect(const Rect.fromLTWH(217, 355, 30, 128), const Color(0xFF31C4E8)),
  _rect(const Rect.fromLTWH(341, 355, 30, 128), const Color(0xFF31C4E8)),
  _line(
    const Offset(247, 470),
    const Offset(281, 374),
    const Color(0xFF2463B6),
    11,
  ),
  _line(
    const Offset(307, 374),
    const Offset(341, 470),
    const Color(0xFF2463B6),
    11,
  ),
  _rect(const Rect.fromLTWH(231, 74, 128, 15), const Color(0xFF2463B6)),
];

List<SkinStroke> _sakuraPop() => [
  ..._base(const Color(0xFFFFD9E8)),
  _rect(const Rect.fromLTWH(231, 74, 64, 128), const Color(0xFFFFF4D6)),
  _rect(const Rect.fromLTWH(295, 74, 64, 128), const Color(0xFFEE5CB6)),
  _pixels(
    const [
      Offset(270, 110),
      Offset(286, 94),
      Offset(286, 110),
      Offset(286, 126),
      Offset(302, 110),
    ],
    const Color(0xFFFFFFFF),
    14,
  ),
  _rect(const Rect.fromLTWH(217, 450, 64, 33), const Color(0xFFEE5CB6)),
  _rect(const Rect.fromLTWH(307, 450, 64, 33), const Color(0xFFFFF4D6)),
];

List<SkinStroke> _shadowUtility() => [
  ..._base(const Color(0xFF171A21)),
  _rect(const Rect.fromLTWH(217, 392, 64, 58), const Color(0xFF4F5665)),
  _rect(const Rect.fromLTWH(307, 392, 64, 58), const Color(0xFF4F5665)),
  _rect(const Rect.fromLTWH(217, 382, 64, 10), const Color(0xFFB8F34A)),
  _rect(const Rect.fromLTWH(307, 382, 64, 10), const Color(0xFFB8F34A)),
  _rect(const Rect.fromLTWH(231, 74, 128, 12), const Color(0xFFB8F34A)),
  _line(
    const Offset(151, 355),
    const Offset(215, 483),
    const Color(0xFF4F5665),
    9,
  ),
  _line(
    const Offset(505, 355),
    const Offset(569, 483),
    const Color(0xFF4F5665),
    9,
  ),
];

List<SkinStroke> _base(Color color) => ClothingTemplate.all
    .map((region) => _rect(region.rect, color))
    .toList(growable: true);

List<SkinStroke> _sideStripes(Color color, double width) => [
  _rect(Rect.fromLTWH(231, 74, width, 128), color),
  _rect(Rect.fromLTWH(217, 355, width, 128), color),
  _rect(Rect.fromLTWH(307, 355, width, 128), color),
  _rect(Rect.fromLTWH(427, 74, width, 128), color),
];

SkinStroke _rect(Rect rect, Color color) => SkinStroke(
  points: [rect.topLeft, rect.bottomRight],
  color: color,
  width: 1,
  isEraser: false,
  kind: StrokeKind.rectangle,
  isFilled: true,
);

SkinStroke _line(Offset start, Offset end, Color color, double width) =>
    SkinStroke(
      points: [start, end],
      color: color,
      width: width,
      isEraser: false,
      kind: StrokeKind.line,
    );

SkinStroke _text(String value, Offset point, Color color, double size) =>
    SkinStroke(
      points: [point],
      color: color,
      width: size,
      isEraser: false,
      kind: StrokeKind.text,
      text: value,
    );

SkinStroke _pixels(List<Offset> points, Color color, double size) => SkinStroke(
  points: points,
  color: color,
  width: size,
  isEraser: false,
  kind: StrokeKind.pixel,
);
