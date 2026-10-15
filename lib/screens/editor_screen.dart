import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart' as cross_file;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../ads/interstitial_ad_service.dart';
import '../editor/avatar_preview.dart';
import '../editor/decal_painter.dart';
import '../models/decal_artwork.dart';
import '../editor/avatar_paint_canvas.dart';
import '../editor/skin_canvas.dart';
import '../editor/template_geometry.dart';
import '../models/editor_models.dart';
import '../utils/bounded_image_decoder.dart';
import '../utils/share_sheet.dart';
import '../widgets/pro_color_picker.dart';

enum _ToolboxTab { draw, add, objects }

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    this.initialType = ClothingType.shirt,
    this.initialStrokes = const [],
    this.initialShowGuide = true,
    this.initialAutoRotate = true,
    this.confirmBeforeClear = true,
  });

  final ClothingType initialType;
  final List<SkinStroke> initialStrokes;
  final bool initialShowGuide;
  final bool initialAutoRotate;
  final bool confirmBeforeClear;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const _palette = <Color>[
    Color(0xFF111318),
    Color(0xFFFFFFFF),
    Color(0xFF697181),
    Color(0xFFAEB4C0),
    Color(0xFF6D3B22),
    Color(0xFFB86B35),
    Color(0xFFE72B25),
    Color(0xFFFF5A5F),
    Color(0xFFFF9F1C),
    Color(0xFFFFD23F),
    Color(0xFFB8F34A),
    Color(0xFF13C46B),
    Color(0xFF008F73),
    Color(0xFF2ED3C6),
    Color(0xFF18A7E0),
    Color(0xFF1769E0),
    Color(0xFF203B78),
    Color(0xFF6558F5),
    Color(0xFF8E44D6),
    Color(0xFFEE5CB6),
    Color(0xFFFF8FC7),
  ];

  final _imagePicker = ImagePicker();
  final _canvasTransform = TransformationController();
  final Map<ClothingType, List<SkinStroke>> _strokesByType = {
    ClothingType.shirt: [],
    ClothingType.pants: [],
  };
  final Map<ClothingType, List<List<SkinStroke>>> _undoByType = {
    ClothingType.shirt: [],
    ClothingType.pants: [],
  };
  final Map<ClothingType, List<List<SkinStroke>>> _redoByType = {
    ClothingType.shirt: [],
    ClothingType.pants: [],
  };
  final Map<ClothingType, ui.Image?> _photosByType = {};
  final Map<ClothingType, double> _photoScalesByType = {};
  final Map<ClothingType, Offset> _photoOffsetsByType = {};
  final Map<ClothingType, double> _photoOpacitiesByType = {};
  final Map<ClothingType, ui.Image?> _previewTextures = {};

  late ClothingType _clothingType;
  EditorTool _tool = EditorTool.brush;
  _ToolboxTab _toolboxTab = _ToolboxTab.draw;
  DecalArtwork? _pendingDecal;
  final List<ui.Image> _decalImages = [];
  int? _selectedDecalIndex;
  int? _editingDecalIndex;
  bool _importingDecal = false;
  double _decalSize = 64, _decalRotation = 0, _decalOpacity = 1;
  bool _decalFlip = false;

  List<SkinStroke> get _visibleStrokes => [
    for (var i = 0; i < _strokes.length; i++)
      if (i == _editingDecalIndex && _activeStroke != null)
        _activeStroke!
      else
        _strokes[i],
    if (_editingDecalIndex == null && _activeStroke != null) _activeStroke!,
  ];
  SkinStroke? get _selectedDecal =>
      _selectedDecalIndex != null &&
          _selectedDecalIndex! < _strokes.length &&
          _strokes[_selectedDecalIndex!].decal != null
      ? _strokes[_selectedDecalIndex!]
      : null;
  Color _color = _palette.first;
  double _brushWidth = 13;
  double _textSize = 38;
  double _pixelSize = 16;
  double _canvasZoom = 1;
  bool _fillShapes = false;
  bool _showPixelGrid = true;
  bool _pixelErase = false;
  bool _isFocusMode = false;
  bool _paintIn3D = false;
  double _paintRotation = -.48;
  double _paintPitch = .17;
  double _paintZoom = 1;
  Offset _paintPan = Offset.zero;
  AvatarPart _paintPart = AvatarPart.wholeBody;
  bool _hideArms = false;
  AvatarInteraction _interaction = AvatarInteraction.paint;
  double _brushOpacity = 1;
  bool _previewRendering = false;
  final Set<ClothingType> _previewDirtyTypes = {};
  late bool _showGuide;
  SkinStroke? _activeStroke;
  int? _drawingPointer;
  AvatarBodyShape _avatarBodyShape = AvatarBodyShape.classic;
  double _avatarRotation = -0.48;
  late bool _autoRotate;
  int _renderGeneration = 0;
  bool _isExporting = false;

  List<SkinStroke> get _strokes => _strokesByType[_clothingType]!;
  List<List<SkinStroke>> get _redoStrokes => _redoByType[_clothingType]!;
  List<List<SkinStroke>> get _undoStrokes => _undoByType[_clothingType]!;
  ui.Image? get _photo => _photosByType[_clothingType];
  set _photo(ui.Image? value) => _photosByType[_clothingType] = value;
  double get _photoScale => _photoScalesByType[_clothingType] ?? 1;
  set _photoScale(double value) => _photoScalesByType[_clothingType] = value;
  Offset get _photoOffset => _photoOffsetsByType[_clothingType] ?? Offset.zero;
  set _photoOffset(Offset value) => _photoOffsetsByType[_clothingType] = value;
  double get _photoOpacity => _photoOpacitiesByType[_clothingType] ?? 1;
  set _photoOpacity(double value) =>
      _photoOpacitiesByType[_clothingType] = value;
  ui.Image? get _shirtPreviewTexture => _previewTextures[ClothingType.shirt];
  ui.Image? get _pantsPreviewTexture => _previewTextures[ClothingType.pants];

  @override
  void initState() {
    super.initState();
    _clothingType = widget.initialType;
    _showGuide = widget.initialShowGuide;
    _autoRotate = widget.initialAutoRotate;
    _strokesByType[_clothingType]!.addAll(widget.initialStrokes);
    _canvasTransform.addListener(_handleCanvasTransform);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  @override
  void dispose() {
    if (_isFocusMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _canvasTransform
      ..removeListener(_handleCanvasTransform)
      ..dispose();
    for (final image in _decalImages) {
      image.dispose();
    }
    for (final photo in _photosByType.values) {
      photo?.dispose();
    }
    for (final texture in _previewTextures.values) {
      texture?.dispose();
    }
    super.dispose();
  }

  void _handleCanvasTransform() {
    final zoom = _canvasTransform.value.getMaxScaleOnAxis();
    if ((zoom - _canvasZoom).abs() < 0.001 || !mounted) return;
    setState(() => _canvasZoom = zoom);
  }

  void _zoomCanvas(double factor) {
    if (_paintIn3D) {
      setState(() => _paintZoom = (_paintZoom * factor).clamp(.75, 4.0));
      return;
    }
    final current = _canvasTransform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.5, 8.0);
    final ratio = target / current;
    final matrix = _canvasTransform.value.clone()
      ..scaleByDouble(ratio, ratio, 1, 1);
    _canvasTransform.value = matrix;
  }

  void _resetCanvasView() {
    if (_paintIn3D) {
      setState(() {
        _paintRotation = -.48;
        _paintPitch = .17;
        _paintZoom = 1;
        _paintPan = Offset.zero;
      });
      return;
    }
    final matrix = _canvasTransform.value.clone()..setIdentity();
    _canvasTransform.value = matrix;
  }

  Future<void> _toggleFocusMode() async {
    final next = !_isFocusMode;
    setState(() => _isFocusMode = next);
    await SystemChrome.setEnabledSystemUIMode(
      next ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Offset _toTemplatePoint(Offset localPosition, Size localSize) {
    return Offset(
      (localPosition.dx / localSize.width * ClothingTemplate.size.width).clamp(
        0.0,
        ClothingTemplate.size.width,
      ),
      (localPosition.dy / localSize.height * ClothingTemplate.size.height)
          .clamp(0.0, ClothingTemplate.size.height),
    );
  }

  void _startStroke(Offset localPosition, Size canvasSize) {
    final point = _toTemplatePoint(localPosition, canvasSize);
    if (_tool == EditorTool.hand) return;
    if (_tool == EditorTool.decal) {
      final region = _regionAt(point);
      if (region != null) {
        _startDecal(AvatarSurfaceHit(point, region, _clothingType));
      }
      return;
    }
    if (_tool == EditorTool.fill) {
      _fillTemplateRegion(point);
      return;
    }
    if (_tool == EditorTool.text) {
      _addText(point);
      return;
    }
    final kind = switch (_tool) {
      EditorTool.pixel => StrokeKind.pixel,
      EditorTool.line => StrokeKind.line,
      EditorTool.rectangle => StrokeKind.rectangle,
      EditorTool.ellipse => StrokeKind.ellipse,
      _ => StrokeKind.freehand,
    };
    setState(() {
      _activeStroke = SkinStroke(
        points: kind == StrokeKind.pixel
            ? [_snapToPixel(point)]
            : kind == StrokeKind.freehand
            ? [point]
            : [point, point],
        color: _color,
        width: kind == StrokeKind.pixel ? _pixelSize : _brushWidth,
        isEraser:
            _tool == EditorTool.eraser ||
            (_tool == EditorTool.pixel && _pixelErase),
        kind: kind,
        isFilled: _fillShapes,
      );
    });
  }

  void _updateStroke(Offset localPosition, Size canvasSize) {
    final active = _activeStroke;
    if (active == null) return;
    final point = _toTemplatePoint(localPosition, canvasSize);
    if (active.kind == StrokeKind.decal) {
      final region = _regionAt(point);
      if (region != null) {
        _moveDecal(AvatarSurfaceHit(point, region, _clothingType));
      }
      return;
    }
    if (active.kind == StrokeKind.pixel) {
      final pixel = _snapToPixel(point);
      if (active.points.contains(pixel)) return;
      setState(
        () =>
            _activeStroke = active.copyWith(points: [...active.points, pixel]),
      );
      return;
    }
    setState(() {
      _activeStroke = active.copyWith(
        points: active.kind == StrokeKind.freehand
            ? [...active.points, point]
            : [active.points.first, point],
      );
    });
  }

  Offset _snapToPixel(Offset point) {
    return Offset(
      (point.dx / _pixelSize).floor() * _pixelSize,
      (point.dy / _pixelSize).floor() * _pixelSize,
    );
  }

  void _finishStroke() {
    final active = _activeStroke;
    if (active == null) return;
    setState(() {
      _checkpoint();
      if (_editingDecalIndex != null) {
        _strokes[_editingDecalIndex!] = active;
        _selectedDecalIndex = _editingDecalIndex;
      } else {
        _strokes.add(active);
        if (active.decal != null) _selectedDecalIndex = _strokes.length - 1;
      }
      if (active.decal != null) _pendingDecal = null;
      _editingDecalIndex = null;
      _activeStroke = null;
    });
    _refreshPreview();
  }

  void _handlePointerDown(PointerDownEvent event, Size canvasSize) {
    if (_tool == EditorTool.hand || _drawingPointer != null) return;
    if (_tool == EditorTool.fill || _tool == EditorTool.text) {
      _startStroke(event.localPosition, canvasSize);
      return;
    }
    _drawingPointer = event.pointer;
    _startStroke(event.localPosition, canvasSize);
  }

  void _handlePointerMove(PointerMoveEvent event, Size canvasSize) {
    if (event.pointer != _drawingPointer) return;
    _updateStroke(event.localPosition, canvasSize);
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer != _drawingPointer) return;
    _drawingPointer = null;
    _finishStroke();
  }

  void _fillTemplateRegion(Offset point) {
    TemplateRegion? selected;
    for (final region in ClothingTemplate.all) {
      if (region.rect.contains(point)) {
        selected = region;
        break;
      }
    }
    if (selected == null) return;
    final fill = SkinStroke(
      points: [selected.rect.topLeft, selected.rect.bottomRight],
      color: _color,
      width: 1,
      isEraser: false,
      kind: StrokeKind.rectangle,
      isFilled: true,
    );
    setState(() {
      _checkpoint();
      _strokes.add(fill);
      _redoStrokes.clear();
    });
    _refreshPreview();
  }

  Future<void> _addText(Offset point) async {
    var draft = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextFormField(
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Enter text',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => draft = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draft.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (!mounted || value == null || value.isEmpty) return;
    setState(() {
      _checkpoint();
      _strokes.add(
        SkinStroke(
          points: [point],
          color: _color,
          width: _textSize,
          isEraser: false,
          kind: StrokeKind.text,
          text: value,
        ),
      );
      _redoStrokes.clear();
    });
    _refreshPreview();
  }

  void _checkpoint() {
    _undoStrokes.add(List.of(_strokes));
    _redoStrokes.clear();
  }

  void _undo() {
    if (_undoStrokes.isEmpty) return;
    setState(() {
      _redoStrokes.add(List.of(_strokes));
      _strokes
        ..clear()
        ..addAll(_undoStrokes.removeLast());
      _selectedDecalIndex = null;
      _editingDecalIndex = null;
      _activeStroke = null;
    });
    _refreshPreview();
  }

  void _redo() {
    if (_redoStrokes.isEmpty) return;
    setState(() {
      _undoStrokes.add(List.of(_strokes));
      _strokes
        ..clear()
        ..addAll(_redoStrokes.removeLast());
      _selectedDecalIndex = null;
    });
    _refreshPreview();
  }

  Future<void> _clearDrawing() async {
    if (_strokes.isEmpty) return;
    if (widget.confirmBeforeClear) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear current artwork?'),
          content: Text(
            'This removes all ${_strokes.length} objects from the current ${_clothingType.name}. You can undo the action afterward.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear artwork'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _checkpoint();
      _strokes.clear();
      _selectedDecalIndex = null;
    });
    _refreshPreview();
  }

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final decoded = await decodeBoundedImage(bytes);
      if (!mounted) {
        decoded.image.dispose();
        return;
      }
      final oldPhoto = _photo;
      setState(() {
        _photo = decoded.image;
        _photoScale = 1;
        _photoOffset = Offset.zero;
        _photoOpacity = 1;
      });
      oldPhoto?.dispose();
      await _refreshPreview();
      if (mounted && decoded.wasDownsampled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Large photo optimized to ${decoded.image.width} × ${decoded.image.height} for stable editing.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That image could not be opened.')),
        );
      }
    }
  }

  void _removePhoto() {
    final oldPhoto = _photo;
    setState(() {
      _photo = null;
      _photoScale = 1;
      _photoOffset = Offset.zero;
    });
    oldPhoto?.dispose();
    _refreshPreview();
  }

  void _adjustPhoto({Offset delta = Offset.zero, double scaleFactor = 1}) {
    setState(() {
      _photoOffset += delta;
      _photoScale = (_photoScale * scaleFactor).clamp(0.35, 4.0);
    });
    _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    if (!mounted) return;
    _previewDirtyTypes.add(_clothingType);
    if (_previewRendering) return;
    _previewRendering = true;
    try {
      while (mounted && _previewDirtyTypes.isNotEmpty) {
        final clothingType = _previewDirtyTypes.first;
        _previewDirtyTypes.remove(clothingType);
        final generation = ++_renderGeneration;
        final image = await ArtworkRenderer.render(
          strokes: [
            if (clothingType == _clothingType)
              ..._visibleStrokes
            else
              ..._strokesByType[clothingType]!,
          ],
          photo: _photosByType[clothingType],
          photoScale: _photoScalesByType[clothingType] ?? 1,
          photoOffset: _photoOffsetsByType[clothingType] ?? Offset.zero,
          photoOpacity: _photoOpacitiesByType[clothingType] ?? 1,
        );
        if (!mounted || generation != _renderGeneration) {
          image.dispose();
          continue;
        }
        final oldTexture = _previewTextures[clothingType];
        setState(() => _previewTextures[clothingType] = image);
        // The previous frame can still hold a painter using the old image.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => oldTexture?.dispose(),
        );
      }
    } finally {
      _previewRendering = false;
    }
  }

  Future<void> _exportPng() async {
    if (_isExporting) return;
    _finishStroke();
    setState(() => _isExporting = true);
    ui.Image? image;
    try {
      image = await ArtworkRenderer.render(
        strokes: _strokes,
        photo: _photo,
        photoScale: _photoScale,
        photoOffset: _photoOffset,
        photoOpacity: _photoOpacity,
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed');
      final bytes = data.buffer.asUint8List();
      final type = _clothingType == ClothingType.shirt ? 'shirt' : 'pants';
      final fileName = 'block_skin_$type.png';
      if (!mounted) return;
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Export Roblox $type template',
          text: '585×559 classic $type template',
          sharePositionOrigin: sharePositionOrigin(context),
          files: [
            cross_file.XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );
      if (result.status == ShareResultStatus.success) {
        await InterstitialAdService.instance.recordSuccessfulExport();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export the PNG.')),
        );
      }
    } finally {
      image?.dispose();
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFocusMode
          ? null
          : AppBar(
              titleSpacing: 20,
              title: Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFB8F34A),
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.view_in_ar,
                        color: Color(0xFF101214),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Block Skin Studio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Export PNG',
                  onPressed: _isExporting ? null : _exportPng,
                  icon: _isExporting
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share, size: 19),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: _paintIn3D
            ? _build3DWorkspace()
            : _isFocusMode
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: _buildEditorCard(compact: false),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 940;
                  if (wide) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildEditorCard(compact: false),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(width: 350, child: _buildPreviewCard()),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                    child: Column(
                      children: [
                        _buildEditorCard(compact: true),
                        const SizedBox(height: 14),
                        SizedBox(height: 430, child: _buildPreviewCard()),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _build3DWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final controls = AbsorbPointer(
          absorbing: _activeStroke != null,
          child: _buildProPaintTools(),
        );
        return Padding(
          padding: EdgeInsets.all(_isFocusMode ? 8 : 12),
          child: Column(
            children: [
              if (!_isFocusMode) ...[
                AbsorbPointer(
                  absorbing: _activeStroke != null,
                  child: _buildDocumentBar(compact: !wide),
                ),
                const SizedBox(height: 6),
                _buildModePicker(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<AvatarInteraction>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: AvatarInteraction.paint,
                            icon: Icon(Icons.brush_outlined, size: 17),
                            label: Text('Paint'),
                          ),
                          ButtonSegment(
                            value: AvatarInteraction.rotate,
                            icon: Icon(Icons.threed_rotation, size: 17),
                            label: Text('Rotate'),
                          ),
                          ButtonSegment(
                            value: AvatarInteraction.pan,
                            icon: Icon(Icons.open_with, size: 17),
                            label: Text('Pan'),
                          ),
                        ],
                        selected: {_interaction},
                        onSelectionChanged: (values) {
                          _finishStroke();
                          setState(() {
                            _interaction = values.first;
                            if (_tool == EditorTool.hand) {
                              _tool = EditorTool.brush;
                            }
                          });
                        },
                      ),
                    ),
                    PopupMenuButton<AvatarBodyShape>(
                      tooltip: 'Body shape',
                      icon: const Icon(
                        Icons.accessibility_new,
                        color: Color(0xFFB8F34A),
                      ),
                      initialValue: _avatarBodyShape,
                      onSelected: (shape) =>
                          setState(() => _avatarBodyShape = shape),
                      itemBuilder: (_) => [
                        for (final shape in AvatarBodyShape.values)
                          CheckedPopupMenuItem(
                            value: shape,
                            checked: _avatarBodyShape == shape,
                            child: Text(shape.label),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: PopupMenuButton<AvatarPart>(
                          tooltip: 'Isolate body part',
                          initialValue: _paintPart,
                          onSelected: (part) {
                            _finishStroke();
                            setState(() {
                              _paintPart = part;
                              _paintPan = Offset.zero;
                              _paintZoom = 1;
                            });
                          },
                          itemBuilder: (_) => [
                            for (final part in AvatarPart.values)
                              CheckedPopupMenuItem(
                                value: part,
                                checked: part == _paintPart,
                                child: Text(part.label),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.view_in_ar, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _paintPart.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.expand_more, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Hide arms'),
                        selected:
                            _hideArms && _paintPart == AvatarPart.wholeBody,
                        onSelected: (hidden) {
                          _finishStroke();
                          setState(() {
                            _hideArms = hidden;
                            _paintPart = AvatarPart.wholeBody;
                            _paintZoom = 1;
                            _paintPan = Offset.zero;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final view in const [
                        'Front',
                        'Back',
                        'Left',
                        'Right',
                        'Top',
                        'Bottom',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(view),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _set3DView(view),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _build3DViewport()),
                    if (wide) ...[
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 310,
                        child: SingleChildScrollView(child: controls),
                      ),
                    ],
                  ],
                ),
              ),
              if (!wide) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: (constraints.maxHeight * .32).clamp(150, 280),
                  ),
                  child: SingleChildScrollView(
                    key: const ValueKey('pro-paint-controls'),
                    child: controls,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _build3DViewport() => Stack(
    fit: StackFit.expand,
    children: [
      _buildCanvas(_visibleStrokes),
      Positioned(
        left: 8,
        right: 8,
        top: 6,
        child: AbsorbPointer(
          absorbing: _activeStroke != null,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Zoom out',
                visualDensity: VisualDensity.compact,
                onPressed: _paintZoom <= .75 ? null : () => _zoomCanvas(.8),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
              ),
              Text(
                '${(_paintZoom * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFFB8F34A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: 'Zoom in',
                visualDensity: VisualDensity.compact,
                onPressed: _paintZoom >= 4 ? null : () => _zoomCanvas(1.25),
                icon: const Icon(Icons.add_circle_outline, size: 20),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Reset view',
                visualDensity: VisualDensity.compact,
                onPressed: _resetCanvasView,
                icon: const Icon(Icons.center_focus_strong, size: 20),
              ),
              IconButton(
                tooltip: _isFocusMode
                    ? 'Exit full screen'
                    : 'Full-screen editor',
                visualDensity: VisualDensity.compact,
                onPressed: _toggleFocusMode,
                icon: Icon(
                  _isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _set3DView(String view) {
    _finishStroke();
    setState(() {
      _paintRotation = switch (view) {
        'Back' => math.pi,
        'Left' => -math.pi / 2,
        'Right' => math.pi / 2,
        _ => 0,
      };
      _paintPitch = switch (view) {
        'Top' => 1.5,
        'Bottom' => -1.5,
        _ => 0,
      };
      _paintPan = Offset.zero;
    });
  }

  Rect? _regionAt(Offset point) {
    for (final region in ClothingTemplate.all) {
      if (region.rect.contains(point)) return region.rect;
    }
    return null;
  }

  void _chooseDecal(DecalArtwork artwork) {
    _finishStroke();
    setState(() {
      _pendingDecal = artwork;
      _selectedDecalIndex = null;
      _toolboxTab = _ToolboxTab.add;
      _tool = EditorTool.decal;
      _interaction = AvatarInteraction.paint;
      _decalSize = 64;
      _decalRotation = 0;
      _decalOpacity = 1;
      _decalFlip = false;
    });
  }

  void _startDecal(AvatarSurfaceHit hit) {
    final existing = _selectedDecal;
    if (_pendingDecal == null && existing == null) return;
    if (existing != null && hit.clothingType != _clothingType) return;
    setState(() {
      if (_clothingType != hit.clothingType) {
        _clothingType = hit.clothingType;
        _selectedDecalIndex = null;
      }
      _editingDecalIndex = existing == null ? null : _selectedDecalIndex;
      _activeStroke =
          existing?.copyWith(points: [hit.point], clipRect: hit.rect) ??
          SkinStroke(
            points: [hit.point],
            color: _color,
            width: 1,
            isEraser: false,
            kind: StrokeKind.decal,
            decal: _pendingDecal,
            decalSize: _decalSize,
            rotation: _decalRotation,
            opacity: _decalOpacity,
            flipX: _decalFlip,
            clipRect: hit.rect,
          );
    });
    _refreshPreview();
  }

  void _moveDecal(AvatarSurfaceHit hit) {
    if (_activeStroke?.decal == null || hit.clothingType != _clothingType) {
      return;
    }
    setState(
      () => _activeStroke = _activeStroke!.copyWith(
        points: [hit.point],
        clipRect: hit.rect,
      ),
    );
    _refreshPreview();
  }

  void _cancelDecal() {
    setState(() {
      _activeStroke = null;
      _editingDecalIndex = null;
    });
    _refreshPreview();
  }

  void _selectDecal(int index) {
    final stroke = _strokes[index];
    if (stroke.decal == null) return;
    setState(() {
      _pendingDecal = null;
      _selectedDecalIndex = index;
      _decalSize = stroke.decalSize;
      _decalRotation = stroke.rotation;
      _decalOpacity = stroke.opacity;
      _decalFlip = stroke.flipX;
      _color = stroke.color;
      _tool = EditorTool.decal;
      _interaction = AvatarInteraction.paint;
      _toolboxTab = _ToolboxTab.add;
    });
  }

  void _updateDecal({
    double? size,
    double? rotation,
    double? opacity,
    bool? flip,
    Color? color,
  }) {
    setState(() {
      _decalSize = size ?? _decalSize;
      _decalRotation = rotation ?? _decalRotation;
      _decalOpacity = opacity ?? _decalOpacity;
      _decalFlip = flip ?? _decalFlip;
      _color = color ?? _color;
      if (_selectedDecal != null) {
        _strokes[_selectedDecalIndex!] = _selectedDecal!.copyWith(
          decalSize: _decalSize,
          rotation: _decalRotation,
          opacity: _decalOpacity,
          flipX: _decalFlip,
          color: _color,
        );
      }
    });
    _refreshPreview();
  }

  void _beginDecalEdit() {
    if (_selectedDecal != null) _checkpoint();
  }

  Future<void> _pickDecalImage() async {
    if (_importingDecal) return;
    setState(() => _importingDecal = true);
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      ui.Image? image;
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          final scale = math.min(
            1.0,
            1024 / math.max(descriptor.width, descriptor.height),
          );
          final codec = await descriptor.instantiateCodec(
            targetWidth: math.max(1, (descriptor.width * scale).round()),
            targetHeight: math.max(1, (descriptor.height * scale).round()),
          );
          try {
            image = (await codec.getNextFrame()).image;
          } finally {
            codec.dispose();
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
      if (!mounted) {
        image.dispose();
        return;
      }
      _decalImages.add(image);
      _chooseDecal(DecalArtwork(label: file.name, image: image));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open this image. Try another photo or PNG.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingDecal = false);
    }
  }

  Future<void> _showStickers() async {
    final selected = await showModalBottomSheet<StickerShape>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sticker library',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a design, then tap your clothing to place it.',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: math.min(320, MediaQuery.sizeOf(context).height * .5),
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .82,
                  children: [
                    for (final shape in StickerShape.values)
                      Semantics(
                        button: true,
                        label: shape.label,
                        excludeSemantics: true,
                        onTap: () => Navigator.pop(context, shape),
                        child: Material(
                          color: const Color(0xFF25292E),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, shape),
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox.square(
                                  dimension: 38,
                                  child: CustomPaint(
                                    painter: DecalPainter(
                                      DecalArtwork(
                                        label: shape.label,
                                        sticker: shape,
                                      ),
                                      const Color(0xFFB8F34A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  shape.label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      _chooseDecal(DecalArtwork(label: selected.label, sticker: selected));
    }
  }

  Future<void> _addTextDecal() async {
    var draft = '';
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text label'),
        content: TextField(
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Your name, team, or message',
          ),
          onChanged: (value) => draft = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draft.trim()),
            child: const Text('Place text'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty && mounted) {
      _chooseDecal(DecalArtwork(label: value, text: value));
    }
  }

  void _objectAction(int index, String action) {
    setState(() {
      _checkpoint();
      final stroke = _strokes[index];
      switch (action) {
        case 'delete':
          _strokes.removeAt(index);
        case 'duplicate':
          _strokes.insert(index + 1, stroke.copyWith());
        case 'forward':
          if (index < _strokes.length - 1) {
            _strokes.removeAt(index);
            _strokes.insert(index + 1, stroke);
          }
        case 'backward':
          if (index > 0) {
            _strokes.removeAt(index);
            _strokes.insert(index - 1, stroke);
          }
      }
      _selectedDecalIndex = null;
      _toolboxTab = _ToolboxTab.objects;
    });
    _refreshPreview();
  }

  Widget _buildProPaintTools() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          for (final entry in const [
            (_ToolboxTab.draw, Icons.brush_outlined, 'Draw'),
            (_ToolboxTab.add, Icons.add_photo_alternate_outlined, 'Add'),
            (_ToolboxTab.objects, Icons.layers_outlined, 'Objects'),
          ])
            Expanded(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: _toolboxTab == entry.$1
                      ? const Color(0xFFB8F34A)
                      : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: Icon(entry.$2, size: 17),
                label: Text(entry.$3, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  if (entry.$1 == _ToolboxTab.add && _selectedDecal != null) {
                    _selectDecal(_selectedDecalIndex!);
                    return;
                  }
                  setState(() {
                    _toolboxTab = entry.$1;
                    if (entry.$1 == _ToolboxTab.draw &&
                        _tool == EditorTool.decal) {
                      _tool = EditorTool.brush;
                    }
                    if (entry.$1 == _ToolboxTab.add && _pendingDecal != null) {
                      _tool = EditorTool.decal;
                      _interaction = AvatarInteraction.paint;
                    }
                  });
                },
              ),
            ),
        ],
      ),
      switch (_toolboxTab) {
        _ToolboxTab.draw => _buildBrushTools(),
        _ToolboxTab.add => _buildAddTools(),
        _ToolboxTab.objects => _buildObjectTools(),
      },
    ],
  );

  Widget _buildAddTools() {
    final art = _pendingDecal ?? _selectedDecal?.decal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final entry in [
              (Icons.layers_outlined, 'Stickers', _showStickers),
              (
                Icons.add_photo_alternate_outlined,
                _importingDecal ? 'Opening…' : 'Image',
                _pickDecalImage,
              ),
              (Icons.title, 'Text', _addTextDecal),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    onPressed: _importingDecal ? null : entry.$3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Icon(entry.$1, size: 22),
                          const SizedBox(height: 4),
                          Text(entry.$2, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (art == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Add stickers, photos, logos, or text. Transparent PNGs keep their cutout edges.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          )
        else ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CustomPaint(painter: DecalPainter(art, _color)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      art.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _pendingDecal != null
                          ? 'Tap clothing to place'
                          : 'Drag on clothing to reposition',
                      style: const TextStyle(
                        color: Color(0xFFB8F34A),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (art.image == null)
                AnyColorButton(
                  color: _color,
                  tooltip: 'Sticker color',
                  size: 28,
                  onSelected: (color) {
                    _beginDecalEdit();
                    _updateDecal(color: color);
                  },
                ),
              IconButton(
                tooltip: 'Done placing',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _pendingDecal = null;
                  _selectedDecalIndex = null;
                  _tool = EditorTool.brush;
                  _toolboxTab = _ToolboxTab.draw;
                }),
                icon: const Icon(Icons.check, size: 18),
              ),
            ],
          ),
          _decalSlider(
            'Width',
            _decalSize,
            8,
            200,
            '${_decalSize.round()} px',
            (v) => _updateDecal(size: v),
          ),
          _decalSlider(
            'Angle',
            _decalRotation,
            -math.pi,
            math.pi,
            '${(_decalRotation * 180 / math.pi).round()}°',
            (v) => _updateDecal(rotation: v),
          ),
          _decalSlider(
            'Opacity',
            _decalOpacity,
            .05,
            1,
            '${(_decalOpacity * 100).round()}%',
            (v) => _updateDecal(opacity: v),
          ),
          Row(
            children: [
              FilterChip(
                label: const Text('Flip'),
                avatar: const Icon(Icons.flip, size: 15),
                selected: _decalFlip,
                onSelected: (v) {
                  _beginDecalEdit();
                  _updateDecal(flip: v);
                },
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              if (_selectedDecalIndex != null) ...[
                IconButton(
                  tooltip: 'Duplicate object',
                  onPressed: () =>
                      _objectAction(_selectedDecalIndex!, 'duplicate'),
                  icon: const Icon(Icons.copy, size: 18),
                ),
                IconButton(
                  tooltip: 'Delete object',
                  onPressed: () =>
                      _objectAction(_selectedDecalIndex!, 'delete'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _decalSlider(
    String label,
    double value,
    double min,
    double max,
    String text,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    height: 34,
    child: Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: Slider(
            key: ValueKey('decal-${label.toLowerCase()}'),
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChangeStart: (_) => _beginDecalEdit(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 43,
          child: Text(text, style: const TextStyle(fontSize: 11)),
        ),
      ],
    ),
  );

  Widget _buildObjectTools() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${_clothingType.name.toUpperCase()} OBJECTS • ${_strokes.length}',
        style: const TextStyle(
          color: Color(0xFFB8F34A),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      if (_strokes.isEmpty)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Your artwork will appear here. Add a sticker or image to start.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ),
      for (var index = _strokes.length - 1; index >= 0; index--)
        ListTile(
          key: ValueKey('art-object-$index'),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          leading: _strokes[index].decal != null
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(
                    painter: DecalPainter(
                      _strokes[index].decal!,
                      _strokes[index].color,
                    ),
                  ),
                )
              : const Icon(Icons.brush, size: 20),
          title: Text(
            _strokes[index].decal?.label ??
                '${_strokes[index].isEraser ? 'Eraser' : 'Drawing'} ${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _strokes[index].decal != null ? 'Tap to edit' : 'Drawing layer',
            style: const TextStyle(fontSize: 10),
          ),
          onTap: _strokes[index].decal != null
              ? () => _selectDecal(index)
              : null,
          trailing: PopupMenuButton<String>(
            tooltip: 'Object ${index + 1} actions',
            onSelected: (action) => _objectAction(index, action),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem(
                value: 'forward',
                enabled: index < _strokes.length - 1,
                child: const Text('Bring forward'),
              ),
              PopupMenuItem(
                value: 'backward',
                enabled: index > 0,
                child: const Text('Send backward'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
    ],
  );

  Widget _buildBrushTools() {
    const lime = Color(0xFFB8F34A);
    final erasing =
        _tool == EditorTool.eraser ||
        (_tool == EditorTool.pixel && _pixelErase);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_outlined, size: 14, color: lime),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_clothingType == ClothingType.shirt ? 'SHIRT' : 'PANTS'} • ${_strokes.length} objects',
                    style: const TextStyle(
                      color: lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                    ),
                  ),
                ),
                const Text(
                  'AUTO TARGET',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 9,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final entry in const [
                  (EditorTool.brush, Icons.brush, 'Brush'),
                  (EditorTool.pixel, Icons.grid_4x4, 'Pixel'),
                  (EditorTool.eraser, Icons.auto_fix_normal, 'Eraser'),
                  (EditorTool.fill, Icons.format_color_fill, 'Face fill'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Material(
                        color:
                            _tool == entry.$1 &&
                                _interaction == AvatarInteraction.paint
                            ? lime
                            : const Color(0xFF25292E),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _finishStroke();
                            setState(() {
                              _tool = entry.$1;
                              _interaction = AvatarInteraction.paint;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                              children: [
                                Icon(
                                  entry.$2,
                                  size: 19,
                                  color:
                                      _tool == entry.$1 &&
                                          _interaction ==
                                              AvatarInteraction.paint
                                      ? const Color(0xFF101214)
                                      : Colors.white,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.$3,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _tool == entry.$1 &&
                                            _interaction ==
                                                AvatarInteraction.paint
                                        ? const Color(0xFF101214)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                AnyColorButton(
                  color: _color,
                  title: 'Brush color',
                  tooltip: 'Custom hex color',
                  size: 30,
                  onSelected: (value) => setState(() => _color = value),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final color in [
                          _palette[1],
                          _palette[0],
                          _palette[10],
                          _palette[14],
                          _palette[6],
                          _palette[9],
                          _palette[18],
                          _palette[19],
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => setState(() => _color = color),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == color
                                        ? lime
                                        : const Color(0xFF657186),
                                    width: _color == color ? 3 : 1,
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
            if (_tool == EditorTool.pixel)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final value in const [4.0, 8.0, 16.0, 32.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text('${value.round()} px'),
                          selected: _pixelSize == value,
                          onSelected: (_) => setState(() => _pixelSize = value),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    FilterChip(
                      label: const Text('Erase'),
                      selected: _pixelErase,
                      onSelected: (value) =>
                          setState(() => _pixelErase = value),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              )
            else if (_tool != EditorTool.fill)
              Row(
                children: [
                  const SizedBox(
                    width: 45,
                    child: Text('Size', style: TextStyle(fontSize: 11)),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: Slider(
                        key: const ValueKey('3d-brush-size'),
                        value: _brushWidth,
                        min: 2,
                        max: 56,
                        onChanged: (value) =>
                            setState(() => _brushWidth = value),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${_brushWidth.round()} px',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                const SizedBox(
                  width: 45,
                  child: Text('Opacity', style: TextStyle(fontSize: 11)),
                ),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: Slider(
                      key: const ValueKey('3d-brush-opacity'),
                      value: _brushOpacity,
                      min: .05,
                      max: 1,
                      onChanged: erasing
                          ? null
                          : (value) => setState(() => _brushOpacity = value),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    erasing ? 'Clear' : '${(_brushOpacity * 100).round()}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCard({required bool compact}) {
    final strokes = _visibleStrokes;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 18),
        child: Column(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _buildDocumentBar(compact: compact),
            const SizedBox(height: 8),
            _buildModePicker(),
            const SizedBox(height: 14),
            if (compact)
              AspectRatio(
                aspectRatio: ClothingTemplate.size.aspectRatio,
                child: _buildCanvas(strokes),
              )
            else
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ClothingTemplate.size.aspectRatio,
                    child: _buildCanvas(strokes),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _buildTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildModePicker() => SegmentedButton<bool>(
    segments: const [
      ButtonSegment(
        value: false,
        icon: Icon(Icons.grid_on, size: 18),
        label: Text('2D Template'),
      ),
      ButtonSegment(
        value: true,
        icon: Icon(Icons.view_in_ar, size: 18),
        label: Text('3D Paint'),
      ),
    ],
    selected: {_paintIn3D},
    onSelectionChanged: (values) {
      _finishStroke();
      setState(() {
        _paintIn3D = values.first;
        if (_paintIn3D &&
            !const [
              EditorTool.brush,
              EditorTool.pixel,
              EditorTool.eraser,
              EditorTool.fill,
              EditorTool.decal,
            ].contains(_tool)) {
          _tool = EditorTool.brush;
        }
      });
      _refreshPreview();
    },
  );

  Widget _buildDocumentBar({required bool compact}) {
    final typePicker = SegmentedButton<ClothingType>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ClothingType.shirt,
          icon: Icon(Icons.checkroom, size: 18),
          label: Text('Shirt'),
        ),
        ButtonSegment(
          value: ClothingType.pants,
          icon: Icon(Icons.accessibility_new, size: 18),
          label: Text('Pants'),
        ),
      ],
      selected: {_clothingType},
      onSelectionChanged: (value) {
        _finishStroke();
        setState(() {
          _clothingType = value.first;
          _selectedDecalIndex = null;
        });
        if (!_paintIn3D) _resetCanvasView();
        _refreshPreview();
      },
    );
    final history = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'Undo',
          onPressed: _undoStrokes.isEmpty ? null : _undo,
          icon: const Icon(Icons.undo),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          tooltip: 'Redo',
          onPressed: _redoStrokes.isEmpty ? null : _redo,
          icon: const Icon(Icons.redo),
          style: IconButton.styleFrom(
            minimumSize: const Size.square(40),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
    final viewControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_paintIn3D)
          IconButton(
            tooltip: _showGuide ? 'Hide template guide' : 'Show template guide',
            onPressed: () => setState(() => _showGuide = !_showGuide),
            icon: Icon(_showGuide ? Icons.grid_on : Icons.grid_off),
          ),
        IconButton(
          tooltip: 'Zoom out',
          onPressed: (_paintIn3D ? _paintZoom <= .75 : _canvasZoom <= .51)
              ? null
              : () => _zoomCanvas(0.8),
          icon: const Icon(Icons.zoom_out),
        ),
        SizedBox(
          width: 52,
          child: Text(
            '${((_paintIn3D ? _paintZoom : _canvasZoom) * 100).round()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB8F34A),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Zoom in',
          onPressed: (_paintIn3D ? _paintZoom >= 4 : _canvasZoom >= 7.99)
              ? null
              : () => _zoomCanvas(1.25),
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton(
          tooltip: 'Reset view',
          onPressed: _resetCanvasView,
          icon: const Icon(Icons.center_focus_strong),
        ),
        if (_isFocusMode)
          IconButton(
            tooltip: 'Export PNG',
            onPressed: _isExporting ? null : _exportPng,
            icon: _isExporting
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
          ),
      ],
    );
    final fullscreenControl = IconButton(
      tooltip: _isFocusMode ? 'Exit full screen' : 'Full-screen editor',
      onPressed: _toggleFocusMode,
      icon: Icon(_isFocusMode ? Icons.fullscreen_exit : Icons.fullscreen),
    );
    final narrowContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(fit: BoxFit.scaleDown, child: typePicker),
              ),
            ),
            const SizedBox(width: 6),
            history,
          ],
        ),
        if (!_paintIn3D)
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: viewControls,
                ),
              ),
              fullscreenControl,
            ],
          ),
      ],
    );
    final wideContent = Row(
      children: [
        typePicker,
        const SizedBox(width: 8),
        history,
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: _paintIn3D ? const SizedBox.shrink() : viewControls,
          ),
        ),
        if (!_paintIn3D) fullscreenControl,
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return compact || constraints.maxWidth < 560
            ? narrowContent
            : wideContent;
      },
    );
  }

  Widget _buildCanvas(List<SkinStroke> strokes) {
    if (_paintIn3D) {
      return AvatarPaintCanvas(
        key: const ValueKey('outfit-paint-canvas'),
        shirtTexture: _shirtPreviewTexture,
        pantsTexture: _pantsPreviewTexture,
        bodyShape: _avatarBodyShape,
        clothingType: _clothingType,
        tool: _tool,
        color: _color.withValues(alpha: _color.a * _brushOpacity),
        brushWidth: _brushWidth,
        pixelSize: _pixelSize,
        pixelErase: _pixelErase,
        rotation: _paintRotation,
        pitch: _paintPitch,
        zoom: _paintZoom,
        pan: _paintPan,
        part: _paintPart,
        hideArms: _hideArms,
        interaction: _interaction,
        onTargetChanged: (type) {
          if (_clothingType == type) return;
          _finishStroke();
          setState(() {
            _clothingType = type;
            _selectedDecalIndex = null;
          });
          _refreshPreview();
        },
        onViewChanged: (zoom, pan) => setState(() {
          _paintZoom = zoom;
          _paintPan = pan;
        }),
        onStrokeCancel: () {
          setState(() => _activeStroke = null);
          _refreshPreview();
        },
        onOrbit: (rotation, pitch) => setState(() {
          _paintRotation = rotation;
          _paintPitch = pitch;
        }),
        onStrokeChanged: (stroke) {
          setState(() => _activeStroke = stroke);
          _refreshPreview();
        },
        onStrokeEnd: _finishStroke,
        onDecalStart: _startDecal,
        onDecalMove: _moveDecal,
        onDecalEnd: _finishStroke,
        onDecalCancel: _cancelDecal,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final canvas = Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _handlePointerDown(event, size),
          onPointerMove: (event) => _handlePointerMove(event, size),
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerUp,
          child: CustomPaint(
            size: size,
            painter: SkinCanvasPainter(
              strokes: strokes,
              showGuide: _showGuide,
              clothingType: _clothingType,
              photo: _photo,
              photoScale: _photoScale,
              photoOffset: _photoOffset,
              photoOpacity: _photoOpacity,
              showPixelGrid: _tool == EditorTool.pixel && _showPixelGrid,
              pixelSize: _pixelSize,
            ),
          ),
        );
        final inputSurface = _tool == EditorTool.hand
            ? GestureDetector(onDoubleTap: _resetCanvasView, child: canvas)
            : RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  EagerGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        EagerGestureRecognizer
                      >(EagerGestureRecognizer.new, (_) {}),
                },
                child: canvas,
              );
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InteractiveViewer(
            transformationController: _canvasTransform,
            minScale: 0.5,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(220),
            panEnabled: _tool == EditorTool.hand,
            scaleEnabled: _tool == EditorTool.hand,
            trackpadScrollCausesScale: true,
            child: SizedBox.fromSize(size: size, child: inputSurface),
          ),
        );
      },
    );
  }

  Widget _buildTools() {
    if (_tool == EditorTool.decal) {
      return SizedBox(
        height: 240,
        child: SingleChildScrollView(child: _buildProPaintTools()),
      );
    }
    final toolButtons = <Widget>[
      _ToolButton(
        selected: _tool == EditorTool.hand,
        icon: Icons.pan_tool_alt_outlined,
        label: _paintIn3D ? 'Rotate' : 'Hand',
        onTap: () => setState(() => _tool = EditorTool.hand),
      ),
      _ToolButton(
        selected: _tool == EditorTool.brush,
        icon: Icons.brush,
        label: 'Brush',
        onTap: () => setState(() => _tool = EditorTool.brush),
      ),
      _ToolButton(
        selected: _tool == EditorTool.pixel,
        icon: Icons.grid_4x4,
        label: 'Pixel',
        onTap: () => setState(() => _tool = EditorTool.pixel),
      ),
      _ToolButton(
        selected: _tool == EditorTool.eraser,
        icon: Icons.auto_fix_normal,
        label: 'Eraser',
        onTap: () => setState(() => _tool = EditorTool.eraser),
      ),
      if (!_paintIn3D)
        _ToolButton(
          selected: _tool == EditorTool.line,
          icon: Icons.show_chart,
          label: 'Line',
          onTap: () => setState(() => _tool = EditorTool.line),
        ),
      if (!_paintIn3D)
        _ToolButton(
          selected: _tool == EditorTool.rectangle,
          icon: Icons.rectangle_outlined,
          label: 'Rectangle',
          onTap: () => setState(() => _tool = EditorTool.rectangle),
        ),
      if (!_paintIn3D)
        _ToolButton(
          selected: _tool == EditorTool.ellipse,
          icon: Icons.circle_outlined,
          label: 'Ellipse',
          onTap: () => setState(() => _tool = EditorTool.ellipse),
        ),
      _ToolButton(
        selected: _tool == EditorTool.fill,
        icon: Icons.format_color_fill,
        label: 'Face fill',
        onTap: () => setState(() => _tool = EditorTool.fill),
      ),
      if (!_paintIn3D)
        _ToolButton(
          selected: _tool == EditorTool.text,
          icon: Icons.text_fields,
          label: 'Text',
          onTap: () => setState(() => _tool = EditorTool.text),
        ),
      _ToolButton(
        selected: false,
        icon: Icons.layers_outlined,
        label: 'Stickers',
        onTap: _showStickers,
      ),
      _ToolButton(
        selected: false,
        icon: Icons.image_outlined,
        label: 'Image sticker',
        onTap: _pickDecalImage,
      ),
      _ToolButton(
        selected: false,
        icon: Icons.layers_outlined,
        label: 'Objects',
        onTap: () => setState(() {
          _toolboxTab = _ToolboxTab.objects;
          _tool = EditorTool.decal;
        }),
      ),
      _ToolButton(
        selected: false,
        icon: Icons.add_photo_alternate_outlined,
        label: _photo == null ? 'Add photo' : 'Replace photo',
        onTap: _pickPhoto,
      ),
      _ToolButton(
        selected: false,
        icon: Icons.delete_sweep_outlined,
        label: 'Clear art',
        onTap: _clearDrawing,
      ),
    ];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < toolButtons.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                toolButtons[index],
              ],
            ],
          ),
        ),
        if (_tool == EditorTool.pixel) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.grid_on, size: 18, color: Color(0xFFB8F34A)),
                const SizedBox(width: 7),
                const Text(
                  'PIXEL SIZE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(width: 8),
                for (final size in const [8.0, 16.0, 24.0, 32.0]) ...[
                  ChoiceChip(
                    label: Text('${size.round()} px'),
                    selected: _pixelSize == size,
                    onSelected: (_) => setState(() => _pixelSize = size),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 5),
                ],
                if (!_paintIn3D)
                  FilterChip(
                    selected: _showPixelGrid,
                    label: const Text('Grid'),
                    avatar: const Icon(Icons.grid_3x3, size: 16),
                    onSelected: (value) =>
                        setState(() => _showPixelGrid = value),
                    visualDensity: VisualDensity.compact,
                  ),
                const SizedBox(width: 5),
                FilterChip(
                  selected: _pixelErase,
                  label: const Text('Erase'),
                  avatar: const Icon(Icons.auto_fix_normal, size: 16),
                  onSelected: (value) => setState(() => _pixelErase = value),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              _tool == EditorTool.text
                  ? Icons.format_size
                  : _tool == EditorTool.pixel
                  ? Icons.grid_4x4
                  : Icons.line_weight,
              size: 19,
              color: const Color(0xFF9CA3AF),
            ),
            SizedBox(
              width: _tool == EditorTool.pixel ? 68 : 128,
              child: _tool == EditorTool.pixel
                  ? Text(
                      '${_pixelSize.round()} px',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB8F34A),
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Slider(
                      value: _tool == EditorTool.text ? _textSize : _brushWidth,
                      min: _tool == EditorTool.text ? 12 : 2,
                      max: _tool == EditorTool.text ? 96 : 56,
                      onChanged: (value) => setState(() {
                        if (_tool == EditorTool.text) {
                          _textSize = value;
                        } else {
                          _brushWidth = value;
                        }
                      }),
                    ),
            ),
            if (_tool == EditorTool.rectangle ||
                _tool == EditorTool.ellipse) ...[
              FilterChip(
                selected: _fillShapes,
                label: const Text('Filled'),
                avatar: const Icon(Icons.format_color_fill, size: 17),
                onSelected: (value) => setState(() => _fillShapes = value),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: AnyColorButton(
                        color: _color,
                        onSelected: (value) => setState(() {
                          _color = value;
                          _tool = EditorTool.brush;
                        }),
                        title: 'Custom color',
                        tooltip: 'Custom hex color',
                        size: 32,
                      ),
                    ),
                    ..._palette.map((color) {
                      final selected = color == _color;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _color = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: selected ? 32 : 27,
                            height: selected ? 32 : 27,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFB8F34A)
                                    : const Color(0xFF596170),
                                width: selected ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_photo != null) ...[
          const SizedBox(height: 10),
          _buildPhotoControls(),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF737B8C)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _tool == EditorTool.hand
                    ? (_paintIn3D
                          ? 'Drag to rotate & tilt • Use + / − to zoom'
                          : 'Pan and pinch to zoom • Double-tap to reset')
                    : '585 × 559 px • PNG with transparency • ${_strokes.length} objects',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF737B8C), fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoControls() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E27),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Move left',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(delta: const Offset(-12, 0)),
                icon: const Icon(Icons.arrow_left),
              ),
              IconButton(
                tooltip: 'Move right',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(delta: const Offset(12, 0)),
                icon: const Icon(Icons.arrow_right),
              ),
              IconButton(
                tooltip: 'Move up',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(delta: const Offset(0, -12)),
                icon: const Icon(Icons.arrow_drop_up),
              ),
              IconButton(
                tooltip: 'Move down',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(delta: const Offset(0, 12)),
                icon: const Icon(Icons.arrow_drop_down),
              ),
              IconButton(
                tooltip: 'Zoom out',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(scaleFactor: 0.9),
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Zoom in',
                visualDensity: VisualDensity.compact,
                onPressed: () => _adjustPhoto(scaleFactor: 1.1),
                icon: const Icon(Icons.zoom_in),
              ),
              SizedBox(
                width: 150,
                child: Slider(
                  value: _photoOpacity,
                  min: 0.15,
                  max: 1,
                  onChanged: (value) => setState(() => _photoOpacity = value),
                  onChangeEnd: (_) => _refreshPreview(),
                ),
              ),
              IconButton(
                tooltip: 'Remove photo',
                onPressed: _removePhoto,
                icon: const Icon(Icons.close, color: Color(0xFFFF7A7A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.view_in_ar, color: Color(0xFFB8F34A)),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    '3D PREVIEW',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _autoRotate ? 'Pause rotation' : 'Start rotation',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _autoRotate = !_autoRotate),
                  icon: Icon(
                    _autoRotate
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: const Color(0xFFB8F34A),
                  ),
                ),
                const SizedBox(width: 4),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x2639D98A),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF58E09A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final shape in AvatarBodyShape.values) ...[
                      ChoiceChip(
                        label: Text(shape.label),
                        selected: _avatarBodyShape == shape,
                        onSelected: (_) =>
                            setState(() => _avatarBodyShape = shape),
                        visualDensity: VisualDensity.compact,
                        labelStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (shape != AvatarBodyShape.values.last)
                        const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF303744), Color(0xFF1A1E27)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AvatarPreview(
                  shirtTexture: _shirtPreviewTexture,
                  pantsTexture: _pantsPreviewTexture,
                  bodyShape: _avatarBodyShape,
                  rotation: _avatarRotation,
                  autoRotate: _autoRotate,
                  onRotationChanged: (value) {
                    setState(() => _avatarRotation = value % (math.pi * 2));
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Shirt + pants • ${_avatarBodyShape.label} ${_avatarBodyShape.fitNote}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFB8F34A) : const Color(0xFF303542),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? const Color(0xFF101214) : Colors.white,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF101214) : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
