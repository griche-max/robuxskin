import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../editor/skin_canvas.dart';
import '../editor/template_geometry.dart';
import '../models/editor_models.dart';
import '../models/studio_feature.dart';
import '../widgets/pro_color_picker.dart';
import 'decal_texture_maker_screen.dart';

typedef OpenGeneratedDesign =
    void Function(ClothingType type, List<SkinStroke> strokes);

class FeatureToolsScreen extends StatelessWidget {
  const FeatureToolsScreen({
    super.key,
    required this.feature,
    required this.onOpenEditor,
  });

  final StudioFeature feature;
  final OpenGeneratedDesign onOpenEditor;

  @override
  Widget build(BuildContext context) {
    if (feature.title == StudioFeatures.decalTextureMaker.title) {
      return const DecalTextureMakerScreen();
    }
    final child = switch (feature.title) {
      'Matching Set' => MatchingSetTool(onOpenEditor: onOpenEditor),
      'Uniform Maker' => UniformMakerTool(onOpenEditor: onOpenEditor),
      'Pattern Lab' => PatternLabTool(onOpenEditor: onOpenEditor),
      'Upload Assistant' => const UploadAssistantTool(),
      'Avatar Closet' => AvatarClosetTool(onOpenEditor: onOpenEditor),
      _ => MatchingSetTool(onOpenEditor: onOpenEditor),
    };
    return _ToolScaffold(feature: feature, child: child);
  }
}

class _ToolScaffold extends StatelessWidget {
  const _ToolScaffold({required this.feature, required this.child});

  final StudioFeature feature;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(feature.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ToolHeader(feature: feature),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolHeader extends StatelessWidget {
  const _ToolHeader({required this.feature});

  final StudioFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            feature.color.withValues(alpha: 0.38),
            const Color(0xFF1B1E22),
          ],
        ),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: feature.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Icon(
                feature.icon,
                color: const Color(0xFF101214),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.subtitle.toUpperCase(),
                  style: TextStyle(
                    color: feature.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(color: Color(0xFFD3D7E0), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchingSetTool extends StatefulWidget {
  const MatchingSetTool({super.key, required this.onOpenEditor});

  final OpenGeneratedDesign onOpenEditor;

  @override
  State<MatchingSetTool> createState() => _MatchingSetToolState();
}

class _MatchingSetToolState extends State<MatchingSetTool> {
  Color _primary = const Color(0xFF6D50E6);
  Color _accent = const Color(0xFFB8F34A);
  bool _linked = true;
  bool _stripe = true;
  ClothingType _previewType = ClothingType.shirt;

  List<SkinStroke> _design(ClothingType type) {
    final strokes = _baseDesign(_primary);
    if (_stripe) {
      strokes.addAll(
        _stripeDesign(_accent, type == ClothingType.shirt ? 18 : 26),
      );
    }
    return strokes;
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPanel(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('OUTFIT COLORS'),
          _ColorSelector(
            label: 'Primary',
            selected: _primary,
            onSelected: (value) => setState(() => _primary = value),
          ),
          _ColorSelector(
            label: 'Accent',
            selected: _accent,
            onSelected: (value) => setState(() => _accent = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Link shirt and pants'),
            subtitle: const Text('Use one palette across both exports'),
            value: _linked,
            onChanged: (value) => setState(() => _linked = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add matching side stripe'),
            value: _stripe,
            onChanged: (value) => setState(() => _stripe = value),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ClothingType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ClothingType.shirt, label: Text('Shirt')),
              ButtonSegment(value: ClothingType.pants, label: Text('Pants')),
            ],
            selected: {_previewType},
            onSelectionChanged: (value) {
              setState(() => _previewType = value.first);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                widget.onOpenEditor(_previewType, _design(_previewType)),
            icon: const Icon(Icons.edit),
            label: Text('Edit ${_previewType.name} design'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              final other = _previewType == ClothingType.shirt
                  ? ClothingType.pants
                  : ClothingType.shirt;
              widget.onOpenEditor(
                other,
                _design(_linked ? other : _previewType),
              );
            },
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Open matching piece'),
          ),
        ],
      ),
      preview: _DesignPreview(
        label: '${_previewType.name.toUpperCase()} LIVE PREVIEW',
        type: _previewType,
        strokes: _design(_previewType),
      ),
    );
  }
}

class UniformMakerTool extends StatefulWidget {
  const UniformMakerTool({super.key, required this.onOpenEditor});

  final OpenGeneratedDesign onOpenEditor;

  @override
  State<UniformMakerTool> createState() => _UniformMakerToolState();
}

class _UniformMakerToolState extends State<UniformMakerTool> {
  String _team = 'NIGHT LEAGUE';
  String _player = 'PLAYER';
  String _number = '07';
  String _role = 'Member';
  Color _primary = const Color(0xFF192F62);
  Color _accent = const Color(0xFFFFC857);

  List<SkinStroke> get _design {
    final strokes = _baseDesign(_primary);
    strokes.addAll([
      _filled(const Rect.fromLTWH(231, 142, 128, 25), _accent),
      _filled(const Rect.fromLTWH(217, 402, 64, 22), _accent),
      _filled(const Rect.fromLTWH(307, 402, 64, 22), _accent),
      _text(_team, const Offset(245, 91), Colors.white, 17),
      _text(_number, const Offset(275, 113), _accent, 32),
      _text(_player, const Offset(443, 106), Colors.white, 16),
      _text(_role.toUpperCase(), const Offset(443, 132), _accent, 13),
    ]);
    return strokes;
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPanel(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('UNIFORM DETAILS'),
          TextFormField(
            initialValue: _team,
            maxLength: 18,
            decoration: const InputDecoration(labelText: 'Team or group'),
            onChanged: (value) => setState(() => _team = value),
          ),
          TextFormField(
            initialValue: _player,
            maxLength: 14,
            decoration: const InputDecoration(labelText: 'Player name'),
            onChanged: (value) => setState(() => _player = value),
          ),
          TextFormField(
            initialValue: _number,
            maxLength: 3,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number'),
            onChanged: (value) => setState(() => _number = value),
          ),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Rank variant'),
            items: const ['Member', 'Captain', 'Officer', 'Coach']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _role = value ?? _role),
          ),
          const SizedBox(height: 12),
          _ColorSelector(
            label: 'Team color',
            selected: _primary,
            onSelected: (value) => setState(() => _primary = value),
          ),
          _ColorSelector(
            label: 'Trim color',
            selected: _accent,
            onSelected: (value) => setState(() => _accent = value),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => widget.onOpenEditor(ClothingType.shirt, _design),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Build uniform in editor'),
          ),
        ],
      ),
      preview: _DesignPreview(
        label: 'PERSONALIZED UNIFORM',
        type: ClothingType.shirt,
        strokes: _design,
      ),
    );
  }
}

class PatternLabTool extends StatefulWidget {
  const PatternLabTool({super.key, required this.onOpenEditor});

  final OpenGeneratedDesign onOpenEditor;

  @override
  State<PatternLabTool> createState() => _PatternLabToolState();
}

class _PatternLabToolState extends State<PatternLabTool> {
  String _pattern = 'Plaid';
  double _scale = 40;
  double _weight = 7;
  double _angle = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  double _opacity = 1;
  Color _background = const Color(0xFF14284A);
  Color _patternColor = const Color(0xFF39CFE2);
  Color _secondaryColor = const Color(0xFF6D50E6);
  bool _twoColor = true;
  bool _stagger = true;
  bool _overlayOnly = false;
  ClothingType _type = ClothingType.shirt;

  static const _patterns = [
    'Plaid',
    'Stripes',
    'Grid',
    'Dots',
    'Checker',
    'Diamonds',
    'Herringbone',
  ];

  static const _presets = [
    _PatternPreset(
      name: 'Tech Grid',
      pattern: 'Grid',
      background: Color(0xFF101827),
      primary: Color(0xFF39CFE2),
      secondary: Color(0xFF6D50E6),
      scale: 42,
      weight: 6,
      angle: 0,
    ),
    _PatternPreset(
      name: 'Candy Pop',
      pattern: 'Dots',
      background: Color(0xFFFFE6F2),
      primary: Color(0xFFEE5CB6),
      secondary: Color(0xFFFFC857),
      scale: 44,
      weight: 13,
      angle: 0,
    ),
    _PatternPreset(
      name: 'Street Stripe',
      pattern: 'Stripes',
      background: Color(0xFF20242C),
      primary: Color(0xFFB8F34A),
      secondary: Color(0xFFFFFFFF),
      scale: 54,
      weight: 12,
      angle: -38,
    ),
    _PatternPreset(
      name: 'Heritage',
      pattern: 'Plaid',
      background: Color(0xFF14284A),
      primary: Color(0xFFFFC857),
      secondary: Color(0xFFE72B25),
      scale: 48,
      weight: 8,
      angle: 0,
    ),
  ];

  Color get _primaryPaint => _patternColor.withValues(alpha: _opacity);
  Color get _secondaryPaint => _secondaryColor.withValues(alpha: _opacity);

  List<SkinStroke> get _design {
    final strokes = _overlayOnly ? <SkinStroke>[] : _baseDesign(_background);
    switch (_pattern) {
      case 'Stripes':
        strokes.addAll(_parallelLines(_angle, _primaryPaint, _weight));
        if (_twoColor) {
          strokes.addAll(
            _parallelLines(
              _angle,
              _secondaryPaint,
              math.max(2, _weight * .42),
              phase: _scale / 2,
            ),
          );
        }
      case 'Grid':
        strokes.addAll(
          _parallelLines(_angle, _primaryPaint, math.max(2, _weight / 2)),
        );
        strokes.addAll(
          _parallelLines(
            _angle + 90,
            _twoColor ? _secondaryPaint : _primaryPaint,
            math.max(2, _weight / 2),
          ),
        );
      case 'Dots':
        var row = 0;
        for (
          double y = -180 - _scale + _phaseY;
          y < ClothingTemplate.size.height + 180 + _scale;
          y += _scale
        ) {
          final stagger = _stagger && row.isOdd ? _scale / 2 : 0.0;
          var column = 0;
          for (
            double x = -180 - _scale + _phaseX + stagger;
            x < ClothingTemplate.size.width + 180 + _scale;
            x += _scale
          ) {
            final dotSize = math.min(_scale * .7, _weight * 1.6);
            final center = _rotate(Offset(x + dotSize / 2, y + dotSize / 2));
            strokes.add(
              SkinStroke(
                points: [
                  center - Offset(dotSize / 2, dotSize / 2),
                  center + Offset(dotSize / 2, dotSize / 2),
                ],
                color: _twoColor && (row + column).isOdd
                    ? _secondaryPaint
                    : _primaryPaint,
                width: 1,
                isEraser: false,
                kind: StrokeKind.ellipse,
                isFilled: true,
              ),
            );
            column++;
          }
          row++;
        }
      case 'Checker':
        strokes.addAll(_checkerPattern());
      case 'Diamonds':
        strokes.addAll(_parallelLines(_angle + 45, _primaryPaint, _weight / 2));
        strokes.addAll(
          _parallelLines(
            _angle - 45,
            _twoColor ? _secondaryPaint : _primaryPaint,
            _weight / 2,
          ),
        );
      case 'Herringbone':
        strokes.addAll(_herringbonePattern());
      default:
        strokes.addAll(
          _parallelLines(_angle, _primaryPaint, math.max(2, _weight / 2)),
        );
        strokes.addAll(
          _parallelLines(
            _angle + 90,
            _twoColor ? _secondaryPaint : _primaryPaint,
            _weight,
          ),
        );
        if (_twoColor) {
          strokes.addAll(
            _parallelLines(
              _angle,
              _secondaryPaint,
              math.max(1, _weight * .28),
              phase: _scale * .34,
            ),
          );
        }
    }
    return strokes;
  }

  double get _phaseX => _offsetX % _scale;
  double get _phaseY => _offsetY % _scale;

  List<SkinStroke> _parallelLines(
    double degrees,
    Color color,
    double width, {
    double phase = 0,
  }) {
    final radians = degrees * math.pi / 180;
    final direction = Offset(math.cos(radians), math.sin(radians));
    final normal = Offset(-direction.dy, direction.dx);
    final center = Offset(
      ClothingTemplate.size.width / 2 + _phaseX,
      ClothingTemplate.size.height / 2 + _phaseY,
    );
    final output = <SkinStroke>[];
    for (double value = -900 + phase; value <= 900; value += _scale) {
      final point = center + normal * value;
      output.add(
        _line(
          point - direction * 900,
          point + direction * 900,
          color,
          math.max(1, width),
        ),
      );
    }
    return output;
  }

  List<SkinStroke> _checkerPattern() {
    final primary = <Offset>[];
    final secondary = <Offset>[];
    var row = 0;
    for (
      double y = -180 - _scale + _phaseY;
      y < ClothingTemplate.size.height + 180 + _scale;
      y += _scale
    ) {
      var column = 0;
      final stagger = _stagger && row.isOdd ? _scale / 2 : 0.0;
      for (
        double x = -180 - _scale + _phaseX + stagger;
        x < ClothingTemplate.size.width + 180 + _scale;
        x += _scale
      ) {
        if ((row + column).isEven) {
          primary.add(_rotate(Offset(x, y)));
        } else if (_twoColor) {
          secondary.add(_rotate(Offset(x, y)));
        }
        column++;
      }
      row++;
    }
    return [
      SkinStroke(
        points: primary,
        color: _primaryPaint,
        width: _scale,
        isEraser: false,
        kind: StrokeKind.pixel,
      ),
      if (secondary.isNotEmpty)
        SkinStroke(
          points: secondary,
          color: _secondaryPaint,
          width: _scale,
          isEraser: false,
          kind: StrokeKind.pixel,
        ),
    ];
  }

  List<SkinStroke> _herringbonePattern() {
    final output = <SkinStroke>[];
    final half = _scale / 2;
    var row = 0;
    for (
      double y = -180 - _scale + _phaseY;
      y < ClothingTemplate.size.height + 180 + _scale;
      y += half
    ) {
      var column = 0;
      for (
        double x = -180 - _scale + _phaseX;
        x < ClothingTemplate.size.width + 180 + _scale;
        x += _scale
      ) {
        final flips = (row + column).isOdd;
        final a = Offset(x, y);
        final b = Offset(x + half, y + (flips ? -half : half));
        final c = Offset(x + _scale, y);
        final color = _twoColor && flips ? _secondaryPaint : _primaryPaint;
        output
          ..add(_line(_rotate(a), _rotate(b), color, _weight / 2))
          ..add(_line(_rotate(b), _rotate(c), color, _weight / 2));
        column++;
      }
      row++;
    }
    return output;
  }

  Offset _rotate(Offset point) {
    if (_angle == 0) return point;
    final center = Offset(
      ClothingTemplate.size.width / 2,
      ClothingTemplate.size.height / 2,
    );
    final radians = _angle * math.pi / 180;
    final delta = point - center;
    return center +
        Offset(
          delta.dx * math.cos(radians) - delta.dy * math.sin(radians),
          delta.dx * math.sin(radians) + delta.dy * math.cos(radians),
        );
  }

  void _applyPreset(_PatternPreset preset) {
    setState(() {
      _pattern = preset.pattern;
      _background = preset.background;
      _patternColor = preset.primary;
      _secondaryColor = preset.secondary;
      _scale = preset.scale;
      _weight = preset.weight;
      _angle = preset.angle;
      _opacity = 1;
      _twoColor = true;
      _overlayOnly = false;
      _offsetX = 0;
      _offsetY = 0;
    });
  }

  void _resetPattern() {
    setState(() {
      _pattern = 'Plaid';
      _background = const Color(0xFF14284A);
      _patternColor = const Color(0xFF39CFE2);
      _secondaryColor = const Color(0xFF6D50E6);
      _scale = 40;
      _weight = 7;
      _angle = 0;
      _offsetX = 0;
      _offsetY = 0;
      _opacity = 1;
      _twoColor = true;
      _stagger = true;
      _overlayOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPanel(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('GENERATE A PATTERN'),
          const Text(
            'PRESETS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final preset in _presets)
                ActionChip(
                  avatar: const Icon(Icons.layers_outlined, size: 15),
                  label: Text(preset.name),
                  onPressed: () => _applyPreset(preset),
                ),
              ActionChip(
                avatar: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset'),
                onPressed: _resetPattern,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'PATTERN ENGINE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _patterns
                .map(
                  (name) => ChoiceChip(
                    label: Text(name),
                    selected: _pattern == name,
                    onSelected: (_) => setState(() => _pattern = name),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Text('Repeat size • ${_scale.round()} px'),
          Slider(
            key: const ValueKey('pattern-scale'),
            value: _scale,
            min: 24,
            max: 96,
            divisions: 18,
            onChanged: (value) => setState(() => _scale = value),
          ),
          Text('Element weight • ${_weight.round()} px'),
          Slider(
            key: const ValueKey('pattern-weight'),
            value: _weight,
            min: 2,
            max: 20,
            divisions: 18,
            onChanged: (value) => setState(() => _weight = value),
          ),
          _ColorSelector(
            label: 'Background',
            selected: _background,
            onSelected: (value) => setState(() => _background = value),
          ),
          _ColorSelector(
            label: 'Primary',
            selected: _patternColor,
            onSelected: (value) => setState(() => _patternColor = value),
          ),
          _ColorSelector(
            label: 'Accent',
            selected: _secondaryColor,
            onSelected: (value) => setState(() => _secondaryColor = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Two-color repeat'),
            subtitle: const Text('Alternate primary and accent elements'),
            value: _twoColor,
            onChanged: (value) => setState(() => _twoColor = value),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text(
              'ADVANCED REPEAT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            subtitle: const Text('Rotation, phase, opacity, and overlay'),
            children: [
              Text('Rotation • ${_angle.round()}°'),
              Slider(
                key: const ValueKey('pattern-angle'),
                value: _angle,
                min: -90,
                max: 90,
                divisions: 36,
                onChanged: (value) => setState(() => _angle = value),
              ),
              Text('Horizontal phase • ${_offsetX.round()} px'),
              Slider(
                key: const ValueKey('pattern-offset-x'),
                value: _offsetX,
                min: -96,
                max: 96,
                divisions: 24,
                onChanged: (value) => setState(() => _offsetX = value),
              ),
              Text('Vertical phase • ${_offsetY.round()} px'),
              Slider(
                key: const ValueKey('pattern-offset-y'),
                value: _offsetY,
                min: -96,
                max: 96,
                divisions: 24,
                onChanged: (value) => setState(() => _offsetY = value),
              ),
              Text('Pattern opacity • ${(_opacity * 100).round()}%'),
              Slider(
                key: const ValueKey('pattern-opacity'),
                value: _opacity,
                min: .2,
                max: 1,
                divisions: 16,
                onChanged: (value) => setState(() => _opacity = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stagger alternate rows'),
                value: _stagger,
                onChanged: (value) => setState(() => _stagger = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Transparent overlay only'),
                subtitle: const Text(
                  'Generate pattern strokes without a base color',
                ),
                value: _overlayOnly,
                onChanged: (value) => setState(() => _overlayOnly = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ClothingType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ClothingType.shirt, label: Text('Shirt')),
              ButtonSegment(value: ClothingType.pants, label: Text('Pants')),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => widget.onOpenEditor(_type, _design),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Apply pattern in editor'),
          ),
        ],
      ),
      preview: _DesignPreview(
        label:
            '${_overlayOnly ? 'OVERLAY' : 'FULL'} $_pattern • ${_scale.round()} PX REPEAT',
        type: _type,
        strokes: _design,
      ),
    );
  }
}

class _PatternPreset {
  const _PatternPreset({
    required this.name,
    required this.pattern,
    required this.background,
    required this.primary,
    required this.secondary,
    required this.scale,
    required this.weight,
    required this.angle,
  });

  final String name;
  final String pattern;
  final Color background;
  final Color primary;
  final Color secondary;
  final double scale;
  final double weight;
  final double angle;
}

class UploadAssistantTool extends StatefulWidget {
  const UploadAssistantTool({super.key});

  @override
  State<UploadAssistantTool> createState() => _UploadAssistantToolState();
}

class _UploadAssistantToolState extends State<UploadAssistantTool> {
  final _picker = ImagePicker();
  String? _fileName;
  int? _width;
  int? _height;
  bool? _isPng;
  bool? _hasTransparency;
  bool _checking = false;
  String _title = '';
  String _description = '';

  Future<void> _prepareUploadPackage() async {
    final title = _title.trim();
    final description = _description.trim();
    await Clipboard.setData(
      ClipboardData(
        text: [
          'Title: $title',
          if (description.isNotEmpty) 'Description: $description',
          if (_fileName != null) 'Validated file: $_fileName',
        ].join('\n'),
      ),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listing details copied'),
        content: Text(
          '“$title” passed the local 585 × 559 format check. Your listing details are on the clipboard for the Roblox upload form.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndValidate() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _checking = true;
      _fileName = file.name;
    });
    try {
      final bytes = await file.readAsBytes();
      final isPng = _hasPngSignature(bytes);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      late int width;
      late int height;
      bool? transparencyChecked;
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          width = descriptor.width;
          height = descriptor.height;
          if (isPng && width == 585 && height == 559) {
            final codec = await descriptor.instantiateCodec();
            try {
              final frame = await codec.getNextFrame();
              final image = frame.image;
              final ByteData? rgba;
              try {
                rgba = await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                );
              } finally {
                image.dispose();
              }
              if (rgba != null) {
                final values = rgba.buffer.asUint8List();
                var transparent = false;
                for (var index = 3; index < values.length; index += 4) {
                  if (values[index] < 255) {
                    transparent = true;
                    break;
                  }
                }
                transparencyChecked = transparent;
              }
            } finally {
              codec.dispose();
            }
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _width = width;
        _height = height;
        _isPng = isPng;
        _hasTransparency = transparencyChecked;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected image could not be validated.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctSize = _width == 585 && _height == 559;
    final hasFile = _width != null;
    final accepted =
        correctSize && _isPng == true && _hasTransparency == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('1 • SELECT EXPORTED PNG'),
                OutlinedButton.icon(
                  onPressed: _checking ? null : _pickAndValidate,
                  icon: const Icon(Icons.image_search),
                  label: Text(_fileName ?? 'Choose image to validate'),
                ),
                if (_checking) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('2 • VALIDATION RESULTS'),
                _ValidationRow(
                  label: 'Classic template dimensions',
                  detail: hasFile
                      ? '$_width × $_height px'
                      : 'Expected 585 × 559 px',
                  state: !hasFile ? null : correctSize,
                ),
                _ValidationRow(
                  label: 'PNG file format',
                  detail: !hasFile
                      ? 'Waiting for image'
                      : _isPng == true
                      ? 'PNG signature detected'
                      : 'Choose a PNG file',
                  state: !hasFile ? null : _isPng,
                ),
                _ValidationRow(
                  label: 'PNG transparency channel',
                  detail: !hasFile
                      ? 'Waiting for image'
                      : _hasTransparency == true
                      ? 'Transparent pixels detected'
                      : _hasTransparency == false
                      ? 'Image is fully opaque'
                      : 'Checked after format and dimensions pass',
                  state: _hasTransparency,
                ),
                _ValidationRow(
                  label: 'Ready for upload checklist',
                  detail: accepted
                      ? 'Template format accepted'
                      : 'Fix errors before upload',
                  state: !hasFile ? null : accepted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('3 • LISTING DETAILS'),
                TextFormField(
                  maxLength: 50,
                  decoration: const InputDecoration(labelText: 'Item title'),
                  onChanged: (value) => setState(() => _title = value),
                ),
                TextFormField(
                  maxLength: 160,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) => setState(() => _description = value),
                ),
                FilledButton.icon(
                  onPressed: accepted && _title.trim().isNotEmpty
                      ? _prepareUploadPackage
                      : null,
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Copy validated listing details'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _hasPngSignature(Uint8List bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }
}

class AvatarClosetTool extends StatefulWidget {
  const AvatarClosetTool({super.key, required this.onOpenEditor});

  final OpenGeneratedDesign onOpenEditor;

  @override
  State<AvatarClosetTool> createState() => _AvatarClosetToolState();
}

class _AvatarClosetToolState extends State<AvatarClosetTool> {
  final List<_ClosetLook> _looks = [];
  String _name = 'New Outfit';
  String _accessory = 'Headphones';
  Color _color = const Color(0xFF9A6BFF);

  void _saveLook() {
    setState(() {
      _looks.insert(
        0,
        _ClosetLook(
          name: _name.trim().isEmpty ? 'Untitled Look' : _name.trim(),
          accessory: _accessory,
          color: _color,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit saved to this closet session.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('BUILD AN OUTFIT BOARD'),
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Outfit name'),
                  onChanged: (value) => _name = value,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Headphones', 'Cap', 'Backpack', 'Glasses']
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item),
                          selected: _accessory == item,
                          onSelected: (_) => setState(() => _accessory = item),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                _ColorSelector(
                  label: 'Main outfit color',
                  selected: _color,
                  onSelected: (value) => setState(() => _color = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saveLook,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Save look'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onOpenEditor(
                          ClothingType.shirt,
                          _baseDesign(_color),
                        ),
                        icon: const Icon(Icons.brush),
                        label: const Text('Design shirt'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'SAVED LOOKS • ${_looks.length}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (_looks.isEmpty)
          const _InfoBanner(
            icon: Icons.checkroom,
            text:
                'No looks yet. Choose a name, accessory, and color, then save your first outfit board.',
          )
        else
          for (final look in _looks)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: look.color,
                  child: const Icon(Icons.checkroom, color: Colors.white),
                ),
                title: Text(look.name),
                subtitle: Text('${look.accessory} • Coordinated palette'),
                trailing: IconButton(
                  tooltip: 'Remove look',
                  onPressed: () => setState(() => _looks.remove(look)),
                  icon: const Icon(Icons.delete_outline),
                ),
                onTap: () => widget.onOpenEditor(
                  ClothingType.shirt,
                  _baseDesign(look.color),
                ),
              ),
            ),
      ],
    );
  }
}

class _ClosetLook {
  const _ClosetLook({
    required this.name,
    required this.accessory,
    required this.color,
  });

  final String name;
  final String accessory;
  final Color color;
}

class _TwoPanel extends StatelessWidget {
  const _TwoPanel({required this.controls, required this.preview});

  final Widget controls;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final controlsCard = Card(
          margin: EdgeInsets.zero,
          child: Padding(padding: const EdgeInsets.all(20), child: controls),
        );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [controlsCard, const SizedBox(height: 14), preview],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: controlsCard),
            const SizedBox(width: 16),
            Expanded(child: preview),
          ],
        );
      },
    );
  }
}

class _DesignPreview extends StatelessWidget {
  const _DesignPreview({
    required this.label,
    required this.type,
    required this.strokes,
  });

  final String label;
  final ClothingType type;
  final List<SkinStroke> strokes;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB8F34A),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: ClothingTemplate.size.aspectRatio,
                child: CustomPaint(
                  painter: SkinCanvasPainter(
                    strokes: strokes,
                    showGuide: false,
                    clothingType: type,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  static const colors = [
    Color(0xFF111318),
    Color(0xFFFFFFFF),
    Color(0xFF697181),
    Color(0xFFB86B35),
    Color(0xFFE72B25),
    Color(0xFFFF6B6B),
    Color(0xFFFF9F1C),
    Color(0xFFFFC857),
    Color(0xFFB8F34A),
    Color(0xFF13C46B),
    Color(0xFF008F73),
    Color(0xFF2ED3C6),
    Color(0xFF39CFE2),
    Color(0xFF1769E0),
    Color(0xFF203B78),
    Color(0xFF6D50E6),
    Color(0xFF8E44D6),
    Color(0xFFEE5CB6),
  ];

  final String label;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: AnyColorButton(
                      color: selected,
                      onSelected: onSelected,
                      title: '$label color',
                      tooltip: 'Choose any $label color',
                      size: 32,
                    ),
                  ),
                  ...colors.map(
                    (color) => Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: InkWell(
                        key: ValueKey('$label-${color.toARGB32()}'),
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => onSelected(color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected == color
                                  ? const Color(0xFFB8F34A)
                                  : const Color(0xFF596071),
                              width: selected == color ? 4 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({
    required this.label,
    required this.detail,
    required this.state,
  });

  final String label;
  final String detail;
  final bool? state;

  @override
  Widget build(BuildContext context) {
    final icon = state == null
        ? Icons.hourglass_empty
        : state!
        ? Icons.check_circle
        : Icons.error;
    final color = state == null
        ? const Color(0xFF9BA3AD)
        : state!
        ? const Color(0xFF62D8A0)
        : const Color(0xFFFF7A8A);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(detail),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF343947)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFB8F34A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFFC8CDD7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

List<SkinStroke> _baseDesign(Color color) => ClothingTemplate.all
    .map((region) => _filled(region.rect, color))
    .toList(growable: true);

List<SkinStroke> _stripeDesign(Color color, double width) => [
  _filled(Rect.fromLTWH(231, 74, width, 128), color),
  _filled(Rect.fromLTWH(217, 355, width, 128), color),
  _filled(Rect.fromLTWH(307, 355, width, 128), color),
  _filled(Rect.fromLTWH(427, 74, width, 128), color),
];

SkinStroke _filled(Rect rect, Color color) => SkinStroke(
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
