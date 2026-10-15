import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart' as cross_file;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../ads/interstitial_ad_service.dart';
import '../models/starter_texture.dart';
import '../utils/bounded_image_decoder.dart';
import '../utils/share_sheet.dart';
import '../widgets/pro_color_picker.dart';

enum DecalAssetMode { decal, texture }

enum TextureRepeatMode { repeat, mirror, brick }

enum DecalImageFit { cover, contain }

Uint8List _removeSolidBackgroundPixels(Map<String, Object> request) {
  final source = request['pixels']! as Uint8List;
  final width = request['width']! as int;
  final height = request['height']! as int;
  final threshold = request['threshold']! as double;
  final output = Uint8List.fromList(source);
  final corners = [
    0,
    (width - 1) * 4,
    (height - 1) * width * 4,
    ((height * width) - 1) * 4,
  ];
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  for (final index in corners) {
    red += source[index];
    green += source[index + 1];
    blue += source[index + 2];
  }
  red /= corners.length;
  green /= corners.length;
  blue /= corners.length;
  final feather = math.max(12.0, threshold * 0.35);
  for (var index = 0; index < output.length; index += 4) {
    final dr = output[index] - red;
    final dg = output[index + 1] - green;
    final db = output[index + 2] - blue;
    final distance = math.sqrt(dr * dr + dg * dg + db * db);
    if (distance <= threshold) {
      output[index + 3] = 0;
    } else if (distance < threshold + feather) {
      final factor = (distance - threshold) / feather;
      output[index + 3] = (output[index + 3] * factor).round();
    }
  }
  return output;
}

class DecalTextureMakerScreen extends StatefulWidget {
  const DecalTextureMakerScreen({super.key});

  @override
  State<DecalTextureMakerScreen> createState() =>
      _DecalTextureMakerScreenState();
}

class _DecalTextureMakerScreenState extends State<DecalTextureMakerScreen> {
  static const _accent = Color(0xFF38D6C4);
  static const _colors = [
    Color(0x00000000),
    Color(0xFF111318),
    Color(0xFFFFFFFF),
    Color(0xFF192F62),
    Color(0xFF6D50E6),
    Color(0xFF39CFE2),
    Color(0xFF13C46B),
    Color(0xFFFFC857),
    Color(0xFFE72B25),
  ];

  final _picker = ImagePicker();
  ui.Image? _image;
  Uint8List? _originalRgba;
  int? _sourceWidth;
  int? _sourceHeight;
  String _assetName = 'roblox_asset';
  DecalAssetMode _mode = DecalAssetMode.decal;
  TextureRepeatMode _repeatMode = TextureRepeatMode.mirror;
  DecalImageFit _fit = DecalImageFit.cover;
  int _outputSize = 1024;
  double _imageScale = 1;
  double _rotation = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  double _tileScale = 0.46;
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  double _backgroundThreshold = 58;
  bool _backgroundRemoved = false;
  bool _showGuides = true;
  Color _backgroundColor = const Color(0x00000000);
  String _overlayText = '';
  double _textSize = 72;
  double _textY = 0.32;
  Color _textColor = Colors.white;
  bool _isBusy = false;
  int _previewIndex = 0;

  DecalTextureSettings get _settings => DecalTextureSettings(
    mode: _mode,
    repeatMode: _repeatMode,
    fit: _fit,
    imageScale: _imageScale,
    rotation: _rotation,
    offsetX: _offsetX,
    offsetY: _offsetY,
    tileScale: _tileScale,
    brightness: _brightness,
    contrast: _contrast,
    saturation: _saturation,
    backgroundColor: _backgroundColor,
    overlayText: _overlayText,
    textSize: _textSize,
    textY: _textY,
    textColor: _textColor,
    showGuides: _showGuides,
  );

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _loadEncodedImage(await file.readAsBytes(), file.name);
  }

  Future<void> _loadEncodedImage(Uint8List bytes, String name) async {
    _setBusy(true);
    try {
      final decoded = await decodeBoundedImage(bytes);
      final rgba = await decoded.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) {
        decoded.image.dispose();
        throw StateError('Could not read pixels');
      }
      final raw = Uint8List.fromList(rgba.buffer.asUint8List());
      if (!mounted) {
        decoded.image.dispose();
        return;
      }
      final old = _image;
      setState(() {
        _image = decoded.image;
        _originalRgba = raw;
        _sourceWidth = decoded.image.width;
        _sourceHeight = decoded.image.height;
        _assetName = _cleanName(name);
        _backgroundRemoved = _containsTransparency(raw);
        _resetTransformValues();
      });
      old?.dispose();
      if (decoded.wasDownsampled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Large image optimized to ${decoded.image.width} × ${decoded.image.height} for stable editing.',
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
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _generatePreset(String preset) async {
    _setBusy(true);
    const size = 512;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
    canvas.drawRect(rect, Paint()..color = const Color(0xFF172033));
    switch (preset) {
      case 'Brick':
        const brickW = 128.0;
        const brickH = 64.0;
        for (var row = 0; row < 8; row++) {
          final shift = row.isOdd ? -brickW / 2 : 0.0;
          for (var col = -1; col < 5; col++) {
            final brick = Rect.fromLTWH(
              col * brickW + shift + 3,
              row * brickH + 3,
              brickW - 6,
              brickH - 6,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(brick, const Radius.circular(5)),
              Paint()
                ..color = row.isEven
                    ? const Color(0xFFB54D3E)
                    : const Color(0xFFD2644F),
            );
          }
        }
      case 'Checker':
        const cell = 64.0;
        for (var y = 0; y < 8; y++) {
          for (var x = 0; x < 8; x++) {
            canvas.drawRect(
              Rect.fromLTWH(x * cell, y * cell, cell, cell),
              Paint()
                ..color = (x + y).isEven
                    ? const Color(0xFF6D50E6)
                    : const Color(0xFF1B2030),
            );
          }
        }
      case 'Metal':
        canvas.drawRect(rect, Paint()..color = const Color(0xFF4E5968));
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            final panel = Rect.fromLTWH(x * 128 + 5, y * 128 + 5, 118, 118);
            canvas.drawRect(
              panel,
              Paint()
                ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF758294), Color(0xFF323B48)],
                ).createShader(panel),
            );
            for (final point in [
              panel.topLeft + const Offset(10, 10),
              panel.topRight + const Offset(-10, 10),
              panel.bottomLeft + const Offset(10, -10),
              panel.bottomRight + const Offset(-10, -10),
            ]) {
              canvas.drawCircle(
                point,
                4,
                Paint()..color = const Color(0xFF151A22),
              );
            }
          }
        }
      default:
        canvas.drawRect(rect, Paint()..color = const Color(0xFF081526));
        for (var value = 0.0; value <= size; value += 64) {
          canvas.drawLine(
            Offset(value, 0),
            Offset(value, size.toDouble()),
            Paint()
              ..color = const Color(0xFF31DAE6)
              ..strokeWidth = 5,
          );
          canvas.drawLine(
            Offset(0, value),
            Offset(size.toDouble(), value),
            Paint()
              ..color = const Color(0xFF8B55FF)
              ..strokeWidth = 5,
          );
        }
    }
    final generated = await recorder.endRecording().toImage(size, size);
    final rgba = await generated.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || rgba == null) {
      generated.dispose();
      _setBusy(false);
      return;
    }
    final old = _image;
    setState(() {
      _image = generated;
      _originalRgba = Uint8List.fromList(rgba.buffer.asUint8List());
      _sourceWidth = size;
      _sourceHeight = size;
      _assetName = '${preset.toLowerCase()}_texture';
      _mode = DecalAssetMode.texture;
      _backgroundRemoved = false;
      _resetTransformValues();
    });
    old?.dispose();
    _setBusy(false);
  }

  Future<void> _openStarterTextureLibrary() async {
    final selection = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _StarterTextureLibrarySheet(),
    );
    if (!mounted || selection == null) return;
    if (selection is StarterTexture) {
      await _loadStarterTexture(selection);
    } else if (selection is String) {
      await _generatePreset(selection);
    }
  }

  Future<void> _loadStarterTexture(StarterTexture texture) async {
    _setBusy(true);
    try {
      final data = await rootBundle.load(texture.assetPath);
      await _loadEncodedImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        '${texture.name}.png',
      );
      if (mounted) setState(() => _mode = DecalAssetMode.texture);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${texture.name} could not be loaded.')),
        );
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _removeSolidBackground() async {
    final source = _originalRgba;
    final width = _sourceWidth;
    final height = _sourceHeight;
    if (source == null || width == null || height == null) return;
    _setBusy(true);
    try {
      final output = await compute(_removeSolidBackgroundPixels, {
        'pixels': source,
        'width': width,
        'height': height,
        'threshold': _backgroundThreshold,
      });
      final processed = await _imageFromRgba(output, width, height);
      if (!mounted) {
        processed.dispose();
        return;
      }
      final old = _image;
      setState(() {
        _image = processed;
        _backgroundRemoved = true;
        _backgroundColor = Colors.transparent;
      });
      old?.dispose();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove this background.')),
        );
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _restoreOriginal() async {
    final source = _originalRgba;
    final width = _sourceWidth;
    final height = _sourceHeight;
    if (source == null || width == null || height == null) return;
    _setBusy(true);
    final restored = await _imageFromRgba(source, width, height);
    if (!mounted) {
      restored.dispose();
      return;
    }
    final old = _image;
    setState(() {
      _image = restored;
      _backgroundRemoved = _containsTransparency(source);
    });
    old?.dispose();
    _setBusy(false);
  }

  Future<ui.Image> _imageFromRgba(
    Uint8List bytes,
    int width,
    int height,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      rowBytes: width * 4,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }

  Future<void> _exportPng() async {
    if (_image == null || _isBusy) return;
    _setBusy(true);
    ui.Image? rendered;
    try {
      rendered = await DecalTextureRenderer.render(
        image: _image!,
        settings: _settings.copyWith(showGuides: false),
        outputSize: _outputSize,
      );
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed');
      final kind = _mode == DecalAssetMode.decal ? 'decal' : 'texture';
      final fileName = '${_cleanName(_assetName)}_${_outputSize}_$kind.png';
      if (!mounted) return;
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Export Roblox $kind',
          text: '$_outputSize × $_outputSize Roblox-ready PNG',
          sharePositionOrigin: sharePositionOrigin(context),
          files: [
            cross_file.XFile.fromData(
              data.buffer.asUint8List(),
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
          const SnackBar(content: Text('Could not export this PNG.')),
        );
      }
    } finally {
      rendered?.dispose();
      _setBusy(false);
    }
  }

  Future<void> _copyStudioSetup() async {
    final snippet = _mode == DecalAssetMode.decal
        ? '''local decal = Instance.new("Decal")
decal.Texture = "rbxassetid://YOUR_ASSET_ID"
decal.Face = Enum.NormalId.Front
decal.Parent = workspace.Part'''
        : '''local texture = Instance.new("Texture")
texture.Texture = "rbxassetid://YOUR_ASSET_ID"
texture.StudsPerTileU = 2
texture.StudsPerTileV = 2
texture.Face = Enum.NormalId.Front
texture.Parent = workspace.Part''';
    await Clipboard.setData(ClipboardData(text: snippet));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Roblox Studio setup copied.')),
    );
  }

  void _resetAllAdjustments() {
    setState(() {
      _resetTransformValues();
      _brightness = 0;
      _contrast = 1;
      _saturation = 1;
      _overlayText = '';
      _backgroundColor = Colors.transparent;
    });
  }

  void _resetTransformValues() {
    _imageScale = 1;
    _rotation = 0;
    _offsetX = 0;
    _offsetY = 0;
    _tileScale = 0.46;
  }

  void _setBusy(bool value) {
    if (mounted) setState(() => _isBusy = value);
  }

  String _cleanName(String input) {
    final withoutExtension = input.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final cleaned = withoutExtension
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'roblox_asset' : cleaned;
  }

  bool _containsTransparency(Uint8List bytes) {
    for (var index = 3; index < bytes.length; index += 4) {
      if (bytes[index] < 255) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decal & Texture Maker'),
        actions: [
          IconButton(
            tooltip: 'Reset adjustments',
            onPressed: _resetAllAdjustments,
            icon: const Icon(Icons.restart_alt),
          ),
          IconButton(
            tooltip: 'Export PNG',
            onPressed: _image == null || _isBusy ? null : _exportPng,
            icon: _isBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final mobile = viewport.maxWidth < 900;
            if (mobile) {
              final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
              return Column(
                children: [
                  _buildPinnedPreview(compact: keyboardOpen),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('decal-controls-scroll'),
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 36),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHero(),
                              const SizedBox(height: 14),
                              _buildControls(),
                              const SizedBox(height: 14),
                              _buildExportCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _buildPreviewCard()),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: _buildControls()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildExportCard(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinnedPreview({required bool compact}) {
    final previewSettings = _settings.copyWith(showGuides: _showGuides);
    return Material(
      key: const ValueKey('pinned-live-preview'),
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      shadowColor: Colors.black54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: compact ? 132 : 224,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onPanUpdate: _image == null
                            ? null
                            : (details) {
                                setState(() {
                                  _offsetX = (_offsetX + details.delta.dx / 260)
                                      .clamp(-0.75, 0.75);
                                  _offsetY = (_offsetY + details.delta.dy / 260)
                                      .clamp(-0.75, 0.75);
                                });
                              },
                        child: CustomPaint(
                          painter: _previewIndex == 0
                              ? DecalTexturePainter(
                                  image: _image,
                                  settings: previewSettings,
                                )
                              : TextureSurfacePreviewPainter(
                                  image: _image,
                                  settings: previewSettings,
                                ),
                          child: _image == null
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: _accent,
                                        size: 30,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Import or generate',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: compact ? 118 : 132,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'LIVE RESULT',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 3),
                        Text(
                          _image == null
                              ? 'Waiting for source'
                              : '${_mode == DecalAssetMode.decal ? 'Decal' : 'Texture'} • $_outputSize px',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: IconButton.filledTonal(
                              tooltip: 'Asset preview',
                              onPressed: () =>
                                  setState(() => _previewIndex = 0),
                              style: IconButton.styleFrom(
                                backgroundColor: _previewIndex == 0
                                    ? _accent.withValues(alpha: 0.24)
                                    : null,
                              ),
                              icon: const Icon(Icons.image_outlined, size: 19),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: IconButton.filledTonal(
                              tooltip: 'Surface preview',
                              onPressed: () =>
                                  setState(() => _previewIndex = 1),
                              style: IconButton.styleFrom(
                                backgroundColor: _previewIndex == 1
                                    ? _accent.withValues(alpha: 0.24)
                                    : null,
                              ),
                              icon: const Icon(Icons.grid_view, size: 19),
                            ),
                          ),
                        ],
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showGuides = !_showGuides),
                          icon: Icon(
                            _showGuides ? Icons.grid_on : Icons.grid_off,
                            size: 16,
                          ),
                          label: Text(_showGuides ? 'Guides on' : 'Guides off'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF174B52), Color(0xFF25213F)],
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Icon(Icons.texture, color: Color(0xFF111318), size: 30),
            ),
          ),
          const SizedBox(
            width: 650,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRO IMAGE ASSET WORKSPACE',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create decals that fit once or textures that repeat cleanly across Roblox parts.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text(
                  'Local processing • transparent PNG • 256 / 512 / 1024 export',
                  style: TextStyle(color: Color(0xFFC8CDD7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final previewSettings = _settings.copyWith(showGuides: _showGuides);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'LIVE PREVIEW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Asset')),
                    ButtonSegment(value: 1, label: Text('Surface')),
                  ],
                  selected: {_previewIndex},
                  onSelectionChanged: (value) {
                    setState(() => _previewIndex = value.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onPanUpdate: _image == null
                      ? null
                      : (details) {
                          setState(() {
                            _offsetX = (_offsetX + details.delta.dx / 340)
                                .clamp(-0.75, 0.75);
                            _offsetY = (_offsetY + details.delta.dy / 340)
                                .clamp(-0.75, 0.75);
                          });
                        },
                  child: CustomPaint(
                    painter: _previewIndex == 0
                        ? DecalTexturePainter(
                            image: _image,
                            settings: previewSettings,
                          )
                        : TextureSurfacePreviewPainter(
                            image: _image,
                            settings: previewSettings,
                          ),
                    child: _image == null
                        ? _EmptyAsset(onImport: _pickImage)
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.touch_app, size: 16, color: Color(0xFF9BA3AD)),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Drag the preview to reposition the source image.',
                    style: TextStyle(color: Color(0xFF9BA3AD), fontSize: 11),
                  ),
                ),
                IconButton(
                  tooltip: _showGuides ? 'Hide guides' : 'Show guides',
                  onPressed: () => setState(() => _showGuides = !_showGuides),
                  icon: Icon(_showGuides ? Icons.grid_on : Icons.grid_off),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        _ControlCard(
          title: '1 • Source and asset type',
          icon: Icons.add_photo_alternate_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<DecalAssetMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: DecalAssetMode.decal,
                    icon: Icon(Icons.crop_square),
                    label: Text('Decal'),
                  ),
                  ButtonSegment(
                    value: DecalAssetMode.texture,
                    icon: Icon(Icons.grid_view),
                    label: Text('Texture'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.first),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isBusy ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_image == null ? 'Import image' : 'Replace image'),
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _isBusy ? null : _openStarterTextureLibrary,
                child: const _MenuButton(
                  icon: Icons.dashboard_outlined,
                  label: 'Starter texture library',
                ),
              ),
              if (_sourceWidth != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Source: $_sourceWidth × $_sourceHeight px • ${_backgroundRemoved ? 'alpha detected' : 'opaque'}',
                  style: const TextStyle(
                    color: Color(0xFF9BA3AD),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ControlCard(
          title: '2 • Layout and repeat',
          icon: Icons.dashboard_customize_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mode == DecalAssetMode.decal)
                SegmentedButton<DecalImageFit>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: DecalImageFit.cover,
                      label: Text('Fill'),
                    ),
                    ButtonSegment(
                      value: DecalImageFit.contain,
                      label: Text('Fit'),
                    ),
                  ],
                  selected: {_fit},
                  onSelectionChanged: (value) =>
                      setState(() => _fit = value.first),
                )
              else ...[
                DropdownButtonFormField<TextureRepeatMode>(
                  initialValue: _repeatMode,
                  decoration: const InputDecoration(labelText: 'Repeat method'),
                  items: const [
                    DropdownMenuItem(
                      value: TextureRepeatMode.repeat,
                      child: Text('Standard repeat'),
                    ),
                    DropdownMenuItem(
                      value: TextureRepeatMode.mirror,
                      child: Text('Mirror seamless edges'),
                    ),
                    DropdownMenuItem(
                      value: TextureRepeatMode.brick,
                      child: Text('Brick row offset'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _repeatMode = value);
                  },
                ),
                const SizedBox(height: 8),
                _LabeledSlider(
                  label: 'Tile size',
                  valueLabel: '${(_tileScale * 100).round()}%',
                  value: _tileScale,
                  min: 0.2,
                  max: 1,
                  onChanged: (value) => setState(() => _tileScale = value),
                ),
              ],
              _LabeledSlider(
                label: 'Image scale',
                valueLabel: '${(_imageScale * 100).round()}%',
                value: _imageScale,
                min: 0.35,
                max: 3,
                onChanged: (value) => setState(() => _imageScale = value),
              ),
              _LabeledSlider(
                label: 'Rotation',
                valueLabel: '${_rotation.round()}°',
                value: _rotation,
                min: -180,
                max: 180,
                onChanged: (value) => setState(() => _rotation = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ControlCard(
          title: '3 • Cleanup and color',
          icon: Icons.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledSlider(
                label: 'Brightness',
                valueLabel: '${(_brightness * 100).round()}',
                value: _brightness,
                min: -0.6,
                max: 0.6,
                onChanged: (value) => setState(() => _brightness = value),
              ),
              _LabeledSlider(
                label: 'Contrast',
                valueLabel: '${(_contrast * 100).round()}%',
                value: _contrast,
                min: 0.35,
                max: 1.8,
                onChanged: (value) => setState(() => _contrast = value),
              ),
              _LabeledSlider(
                label: 'Saturation',
                valueLabel: '${(_saturation * 100).round()}%',
                value: _saturation,
                min: 0,
                max: 2,
                onChanged: (value) => setState(() => _saturation = value),
              ),
              const Divider(height: 24),
              _LabeledSlider(
                label: 'Background tolerance',
                valueLabel: _backgroundThreshold.round().toString(),
                value: _backgroundThreshold,
                min: 12,
                max: 140,
                onChanged: (value) =>
                    setState(() => _backgroundThreshold = value),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _image == null || _isBusy
                          ? null
                          : _removeSolidBackground,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Remove solid BG'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Restore original pixels',
                    onPressed: _originalRgba == null || _isBusy
                        ? null
                        : _restoreOriginal,
                    icon: const Icon(Icons.restore),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Canvas background', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 7),
              _ColorRow(
                colors: _colors,
                selected: _backgroundColor,
                pickerTitle: 'Canvas background color',
                allowTransparency: true,
                onSelected: (value) => setState(() => _backgroundColor = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ControlCard(
          title: '4 • Text overlay',
          icon: Icons.text_fields,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _overlayText,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: 'Optional label or logo text',
                ),
                onChanged: (value) => setState(() => _overlayText = value),
              ),
              _LabeledSlider(
                label: 'Text size',
                valueLabel: _textSize.round().toString(),
                value: _textSize,
                min: 24,
                max: 160,
                onChanged: (value) => setState(() => _textSize = value),
              ),
              _LabeledSlider(
                label: 'Vertical position',
                valueLabel: '${(_textY * 100).round()}%',
                value: _textY,
                min: -0.42,
                max: 0.42,
                onChanged: (value) => setState(() => _textY = value),
              ),
              _ColorRow(
                colors: _colors.skip(1).toList(),
                selected: _textColor,
                pickerTitle: 'Text color',
                onSelected: (value) => setState(() => _textColor = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportCard() {
    final alphaReady = _backgroundRemoved || _backgroundColor.a < 1;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'EXPORT & ROBLOX STUDIO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: _image == null
                      ? Icons.error_outline
                      : Icons.check_circle,
                  label: _image == null ? 'Image required' : 'Source loaded',
                  good: _image != null,
                ),
                _StatusChip(
                  icon: Icons.aspect_ratio,
                  label: '$_outputSize × $_outputSize PNG',
                  good: true,
                ),
                _StatusChip(
                  icon: alphaReady ? Icons.layers_clear : Icons.crop_square,
                  label: alphaReady
                      ? 'Transparency ready'
                      : 'Opaque background',
                  good: true,
                ),
                _StatusChip(
                  icon: _mode == DecalAssetMode.texture
                      ? Icons.grid_view
                      : Icons.image_outlined,
                  label: _mode == DecalAssetMode.texture
                      ? 'Repeating texture'
                      : 'Single-fit decal',
                  good: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final sizePicker = DropdownButtonFormField<int>(
                  initialValue: _outputSize,
                  decoration: const InputDecoration(
                    labelText: 'Export resolution',
                  ),
                  items: const [256, 512, 1024]
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text('$size × $size'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _outputSize = value);
                  },
                );
                final nameField = TextFormField(
                  initialValue: _assetName,
                  decoration: const InputDecoration(labelText: 'File name'),
                  onChanged: (value) => _assetName = value,
                );
                if (compact) {
                  return Column(
                    children: [
                      nameField,
                      const SizedBox(height: 10),
                      sizePicker,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 12),
                    SizedBox(width: 210, child: sizePicker),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _image == null || _isBusy ? null : _exportPng,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export Roblox PNG'),
                ),
                OutlinedButton.icon(
                  onPressed: _copyStudioSetup,
                  icon: const Icon(Icons.code),
                  label: const Text('Copy Studio setup'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Use only images you created or have permission to upload. Roblox moderates imported assets before they become visible in published experiences.',
              style: TextStyle(color: Color(0xFF9BA3AD), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class DecalTextureSettings {
  const DecalTextureSettings({
    required this.mode,
    required this.repeatMode,
    required this.fit,
    required this.imageScale,
    required this.rotation,
    required this.offsetX,
    required this.offsetY,
    required this.tileScale,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.backgroundColor,
    required this.overlayText,
    required this.textSize,
    required this.textY,
    required this.textColor,
    required this.showGuides,
  });

  final DecalAssetMode mode;
  final TextureRepeatMode repeatMode;
  final DecalImageFit fit;
  final double imageScale;
  final double rotation;
  final double offsetX;
  final double offsetY;
  final double tileScale;
  final double brightness;
  final double contrast;
  final double saturation;
  final Color backgroundColor;
  final String overlayText;
  final double textSize;
  final double textY;
  final Color textColor;
  final bool showGuides;

  DecalTextureSettings copyWith({bool? showGuides}) => DecalTextureSettings(
    mode: mode,
    repeatMode: repeatMode,
    fit: fit,
    imageScale: imageScale,
    rotation: rotation,
    offsetX: offsetX,
    offsetY: offsetY,
    tileScale: tileScale,
    brightness: brightness,
    contrast: contrast,
    saturation: saturation,
    backgroundColor: backgroundColor,
    overlayText: overlayText,
    textSize: textSize,
    textY: textY,
    textColor: textColor,
    showGuides: showGuides ?? this.showGuides,
  );
}

class DecalTextureRenderer {
  static Future<ui.Image> render({
    required ui.Image image,
    required DecalTextureSettings settings,
    required int outputSize,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    DecalTexturePainter.paintAsset(
      canvas,
      Size.square(outputSize.toDouble()),
      image,
      settings,
    );
    return recorder.endRecording().toImage(outputSize, outputSize);
  }
}

class DecalTexturePainter extends CustomPainter {
  const DecalTexturePainter({required this.image, required this.settings});

  final ui.Image? image;
  final DecalTextureSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTransparencyGrid(canvas, size);
    final source = image;
    if (source != null) paintAsset(canvas, size, source, settings);
    if (settings.showGuides) _paintGuides(canvas, size, settings.mode);
  }

  static void paintAsset(
    Canvas canvas,
    Size size,
    ui.Image image,
    DecalTextureSettings settings,
  ) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);
    if (settings.backgroundColor.a > 0) {
      canvas.drawRect(bounds, Paint()..color = settings.backgroundColor);
    }
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..colorFilter = _adjustmentFilter(settings);
    if (settings.mode == DecalAssetMode.decal) {
      _paintDecal(canvas, size, image, settings, paint);
    } else {
      _paintTexture(canvas, size, image, settings, paint);
    }
    _paintOverlayText(canvas, size, settings);
    canvas.restore();
  }

  static void _paintDecal(
    Canvas canvas,
    Size size,
    ui.Image image,
    DecalTextureSettings settings,
    Paint paint,
  ) {
    final cover = math.max(
      size.width / image.width,
      size.height / image.height,
    );
    final contain = math.min(
      size.width / image.width,
      size.height / image.height,
    );
    final base = settings.fit == DecalImageFit.cover ? cover : contain;
    final width = image.width * base * settings.imageScale;
    final height = image.height * base * settings.imageScale;
    final center = Offset(
      size.width / 2 + settings.offsetX * size.width,
      size.height / 2 + settings.offsetY * size.height,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(settings.rotation * math.pi / 180);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      paint,
    );
    canvas.restore();
  }

  static void _paintTexture(
    Canvas canvas,
    Size size,
    ui.Image image,
    DecalTextureSettings settings,
    Paint paint,
  ) {
    final tile = math.max(48.0, size.shortestSide * settings.tileScale);
    final columns = (size.width / tile).ceil() + 4;
    final rows = (size.height / tile).ceil() + 4;
    final offset = Offset(
      settings.offsetX * tile * 2,
      settings.offsetY * tile * 2,
    );
    for (var row = -2; row < rows; row++) {
      final brickShift =
          settings.repeatMode == TextureRepeatMode.brick && row.isOdd
          ? tile / 2
          : 0.0;
      for (var column = -2; column < columns; column++) {
        final tileRect = Rect.fromLTWH(
          column * tile + brickShift + offset.dx,
          row * tile + offset.dy,
          tile,
          tile,
        );
        final mirrorX =
            settings.repeatMode == TextureRepeatMode.mirror && column.isOdd;
        final mirrorY =
            settings.repeatMode == TextureRepeatMode.mirror && row.isOdd;
        canvas.save();
        canvas.translate(tileRect.center.dx, tileRect.center.dy);
        canvas.rotate(settings.rotation * math.pi / 180);
        canvas.scale(mirrorX ? -1 : 1, mirrorY ? -1 : 1);
        final fitted = tile * settings.imageScale;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: fitted, height: fitted),
          paint,
        );
        canvas.restore();
      }
    }
  }

  static ColorFilter _adjustmentFilter(DecalTextureSettings settings) {
    final saturation = settings.saturation;
    final inv = 1 - saturation;
    final red = 0.213 * inv;
    final green = 0.715 * inv;
    final blue = 0.072 * inv;
    final contrast = settings.contrast;
    final translate = 128 * (1 - contrast) + settings.brightness * 255;
    return ColorFilter.matrix([
      (red + saturation) * contrast,
      green * contrast,
      blue * contrast,
      0,
      translate,
      red * contrast,
      (green + saturation) * contrast,
      blue * contrast,
      0,
      translate,
      red * contrast,
      green * contrast,
      (blue + saturation) * contrast,
      0,
      translate,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  static void _paintOverlayText(
    Canvas canvas,
    Size size,
    DecalTextureSettings settings,
  ) {
    if (settings.overlayText.trim().isEmpty) return;
    final scale = size.width / 1024;
    final painter = TextPainter(
      text: TextSpan(
        text: settings.overlayText.trim(),
        style: TextStyle(
          color: settings.textColor,
          fontSize: settings.textSize * scale,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
              color: Color(0x99000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: size.width * 0.88);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        size.height / 2 + settings.textY * size.height - painter.height / 2,
      ),
    );
  }

  static void _paintTransparencyGrid(Canvas canvas, Size size) {
    const cells = 16;
    final cell = size.width / cells;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEEF0F3),
    );
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            Paint()..color = const Color(0xFFDDE1E6),
          );
        }
      }
    }
  }

  static void _paintGuides(Canvas canvas, Size size, DecalAssetMode mode) {
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width / 400)
      ..color = const Color(0x99FFFFFF);
    canvas.drawRect((Offset.zero & size).deflate(size.width * 0.04), guide);
    if (mode == DecalAssetMode.decal) {
      canvas.drawCircle(size.center(Offset.zero), size.width * 0.38, guide);
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guide,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guide,
      );
    } else {
      for (
        var value = size.width / 3;
        value < size.width;
        value += size.width / 3
      ) {
        canvas.drawLine(Offset(value, 0), Offset(value, size.height), guide);
        canvas.drawLine(Offset(0, value), Offset(size.width, value), guide);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DecalTexturePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.settings != settings;
}

class TextureSurfacePreviewPainter extends CustomPainter {
  const TextureSurfacePreviewPainter({
    required this.image,
    required this.settings,
  });

  final ui.Image? image;
  final DecalTextureSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF151922),
    );
    final source = image;
    if (source == null) return;
    final faceSettings = settings.copyWith(showGuides: false);
    final margin = size.width * 0.08;
    final face = Rect.fromLTWH(
      margin,
      margin,
      size.width * 0.84,
      size.height * 0.84,
    );
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(face, const Radius.circular(12)));
    canvas.translate(face.left, face.top);
    DecalTexturePainter.paintAsset(
      canvas,
      face.size,
      source,
      faceSettings.copyWith(showGuides: false),
    );
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF38D6C4),
    );
    final label = TextPainter(
      text: const TextSpan(
        text: 'PART SURFACE PREVIEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(margin, size.height - margin + 10));
  }

  @override
  bool shouldRepaint(covariant TextureSurfacePreviewPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.settings != settings;
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF38D6C4), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              valueLabel,
              style: const TextStyle(
                color: Color(0xFF38D6C4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.colors,
    required this.selected,
    required this.onSelected,
    this.pickerTitle = 'Custom color',
    this.allowTransparency = false,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;
  final String pickerTitle;
  final bool allowTransparency;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnyColorButton(
              color: selected,
              onSelected: onSelected,
              title: pickerTitle,
              tooltip: 'Choose any color',
              allowTransparency: allowTransparency,
              size: 32,
            ),
          ),
          ...colors.map(
            (color) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => onSelected(color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.a == 0 ? Colors.white : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected == color
                          ? const Color(0xFF38D6C4)
                          : const Color(0xFF5B6270),
                      width: selected == color ? 4 : 1,
                    ),
                  ),
                  child: color.a == 0
                      ? const Icon(
                          Icons.layers_clear,
                          size: 16,
                          color: Colors.black,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.good,
  });

  final IconData icon;
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (good ? const Color(0xFF38D6C4) : const Color(0xFFFF7A8A))
            .withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (good ? const Color(0xFF38D6C4) : const Color(0xFFFF7A8A))
              .withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: good ? const Color(0xFF38D6C4) : null),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAsset extends StatelessWidget {
  const _EmptyAsset({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xDD171A21),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.texture, size: 58, color: Color(0xFF38D6C4)),
            const SizedBox(height: 12),
            const Text(
              'Import an image or generate a starter texture',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Import image'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarterTextureLibrarySheet extends StatefulWidget {
  const _StarterTextureLibrarySheet();

  @override
  State<_StarterTextureLibrarySheet> createState() =>
      _StarterTextureLibrarySheetState();
}

class _StarterTextureLibrarySheetState
    extends State<_StarterTextureLibrarySheet> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    const categories = [
      'All',
      'Natural',
      'Building',
      'Fantasy',
      'Material',
      'Technology',
    ];
    final textures = StarterTextures.all.where((texture) {
      final matchesCategory =
          _category == 'All' || texture.category == _category;
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          texture.name.toLowerCase().contains(query) ||
          texture.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starter Texture Library',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Choose a seamless PNG or generate a procedural pattern.',
                  style: TextStyle(color: Color(0xFF9BA3AD), fontSize: 12),
                ),
                const SizedBox(height: 13),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search wood, stone, fantasy…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) {
                                setState(() => _category = category);
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 4 : 2;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(3, 0, 3, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'SEAMLESS PNG ASSETS',
                                  style: TextStyle(
                                    color: Color(0xFF38D6C4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                              Text(
                                '${textures.length} textures',
                                style: const TextStyle(
                                  color: Color(0xFF9BA3AD),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (textures.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('No textures match this filter.'),
                            ),
                          ),
                        )
                      else
                        SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.88,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final texture = textures[index];
                            return _StarterTextureCard(
                              texture: texture,
                              onTap: () => Navigator.pop(context, texture),
                            );
                          }, childCount: textures.length),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(3, 0, 3, 10),
                          child: Text(
                            'PROCEDURAL STARTERS',
                            style: TextStyle(
                              color: Color(0xFF38D6C4),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.45,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          const presets = [
                            ('Brick', Icons.view_module, Color(0xFFB95848)),
                            ('Checker', Icons.grid_4x4, Color(0xFF6D50E6)),
                            ('Metal', Icons.deblur, Color(0xFF718093)),
                            ('Neon Grid', Icons.grid_on, Color(0xFF31DAE6)),
                          ];
                          final preset = presets[index];
                          return _ProceduralTextureCard(
                            name: preset.$1,
                            icon: preset.$2,
                            color: preset.$3,
                            onTap: () => Navigator.pop(context, preset.$1),
                          );
                        }, childCount: 4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterTextureCard extends StatelessWidget {
  const _StarterTextureCard({required this.texture, required this.onTap});

  final StarterTexture texture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('starter-texture-${texture.name}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(texture.assetPath, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x7711151D)],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xBB11151D),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.grid_view, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 30,
                    decoration: BoxDecoration(
                      color: texture.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texture.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          texture.category,
                          style: const TextStyle(
                            color: Color(0xFF9BA3AD),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProceduralTextureCard extends StatelessWidget {
  const _ProceduralTextureCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.48), const Color(0xFF1B202A)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: const Color(0xFF111318),
                  child: Icon(icon, size: 19),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF505767)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
