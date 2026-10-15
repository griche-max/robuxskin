import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<Color?> showProColorPicker(
  BuildContext context, {
  required Color initialColor,
  String title = 'Choose any color',
  bool allowTransparency = false,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _ProColorPickerDialog(
      initialColor: initialColor,
      title: title,
      allowTransparency: allowTransparency,
    ),
  );
}

class AnyColorButton extends StatelessWidget {
  const AnyColorButton({
    super.key,
    required this.color,
    required this.onSelected,
    this.title = 'Choose any color',
    this.tooltip = 'Choose any color',
    this.allowTransparency = false,
    this.size = 34,
  });

  final Color color;
  final ValueChanged<Color> onSelected;
  final String title;
  final String tooltip;
  final bool allowTransparency;
  final double size;

  Future<void> _open(BuildContext context) async {
    final selected = await showProColorPicker(
      context,
      initialColor: color,
      title: title,
      allowTransparency: allowTransparency,
    );
    if (selected != null && context.mounted) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final transparent = color.a == 0;
    final foreground = transparent || color.computeLuminance() > .48
        ? const Color(0xFF171A21)
        : Colors.white;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: () => _open(context),
          radius: size,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFFFF4D4D),
                  Color(0xFFFFD84D),
                  Color(0xFF43E06F),
                  Color(0xFF3EDBE8),
                  Color(0xFF4A78FF),
                  Color(0xFFB95CFF),
                  Color(0xFFFF4D9D),
                  Color(0xFFFF4D4D),
                ],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: transparent ? Colors.white : color,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF171A21), width: 1.5),
              ),
              child: Icon(
                transparent ? Icons.layers_clear : Icons.colorize,
                size: size * .43,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProColorPickerDialog extends StatefulWidget {
  const _ProColorPickerDialog({
    required this.initialColor,
    required this.title,
    required this.allowTransparency,
  });

  final Color initialColor;
  final String title;
  final bool allowTransparency;

  @override
  State<_ProColorPickerDialog> createState() => _ProColorPickerDialogState();
}

class _ProColorPickerDialogState extends State<_ProColorPickerDialog> {
  late HSVColor _hsv;
  late double _alpha;
  late final TextEditingController _hexController;
  bool _hexValid = true;

  Color get _color {
    final rgb = _hsv.toColor().toARGB32() & 0x00FFFFFF;
    final alpha = (_alpha * 255).round().clamp(0, 255);
    return Color((alpha << 24) | rgb);
  }

  String get _hex =>
      '#${(_color.toARGB32() & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  void initState() {
    super.initState();
    final argb = widget.initialColor.toARGB32();
    _alpha = ((argb >> 24) & 0xFF) / 255;
    _hsv = HSVColor.fromColor(Color(0xFF000000 | (argb & 0x00FFFFFF)));
    _hexController = TextEditingController(text: _hex);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor value) {
    setState(() {
      _hsv = value;
      _hexController.text = _hex;
      _hexValid = true;
    });
  }

  void _readHex(String value) {
    final hex = value.replaceAll('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    final valid = hex.length == 6 && parsed != null;
    setState(() {
      _hexValid = valid || hex.length < 6;
      if (valid) {
        _hsv = HSVColor.fromColor(Color(0xFF000000 | parsed));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF697181), width: 2),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 370,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SaturationValuePicker(
              hue: _hsv.hue,
              saturation: _hsv.saturation,
              value: _hsv.value,
              onChanged: (saturation, value) =>
                  _setHsv(_hsv.withSaturation(saturation).withValue(value)),
            ),
            const SizedBox(height: 18),
            const Text(
              'HUE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            _HuePicker(
              hue: _hsv.hue,
              onChanged: (value) => _setHsv(_hsv.withHue(value)),
            ),
            if (widget.allowTransparency) ...[
              const SizedBox(height: 17),
              Row(
                children: [
                  const Text(
                    'OPACITY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    '${(_alpha * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Slider(
                value: _alpha,
                onChanged: (value) => setState(() => _alpha = value),
              ),
            ],
            const SizedBox(height: 18),
            TextFormField(
              controller: _hexController,
              maxLength: 7,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
              ],
              decoration: InputDecoration(
                labelText: 'Hex color',
                hintText: '#B8F34A',
                errorText: _hexValid ? null : 'Enter six hexadecimal digits',
                counterText: '',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFF596071)),
                    ),
                  ),
                ),
              ),
              onChanged: _readHex,
            ),
            const SizedBox(height: 8),
            Text(
              'H ${_hsv.hue.round()}°  •  S ${(_hsv.saturation * 100).round()}%  •  B ${(_hsv.value * 100).round()}%',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _color),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Use color'),
        ),
      ],
    );
  }
}

class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  void _update(Offset localPosition, Size size) {
    onChanged(
      (localPosition.dx / size.width).clamp(0, 1),
      (1 - localPosition.dy / size.height).clamp(0, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Builder(
        builder: (context) {
          Size currentSize() => (context.findRenderObject()! as RenderBox).size;
          return GestureDetector(
            onTapDown: (details) =>
                _update(details.localPosition, currentSize()),
            onPanStart: (details) =>
                _update(details.localPosition, currentSize()),
            onPanUpdate: (details) =>
                _update(details.localPosition, currentSize()),
            child: CustomPaint(
              size: Size.infinite,
              painter: _SaturationValuePainter(
                hue: hue,
                saturation: saturation,
                value: value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = BorderRadius.circular(14);
    canvas.save();
    canvas.clipRRect(radius.toRRect(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, HSVColor.fromAHSV(1, hue, 1, 1).toColor()],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();

    final point = Offset(saturation * size.width, (1 - value) * size.height);
    canvas.drawCircle(point, 9, Paint()..color = Colors.white);
    canvas.drawCircle(point, 6, Paint()..color = Colors.black);
    canvas.drawCircle(
      point,
      4.5,
      Paint()..color = HSVColor.fromAHSV(1, hue, saturation, value).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue ||
      oldDelegate.saturation != saturation ||
      oldDelegate.value != value;
}

class _HuePicker extends StatelessWidget {
  const _HuePicker({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  void _update(Offset position, Size size) {
    onChanged((position.dx / size.width).clamp(0, 1) * 360);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Builder(
        builder: (context) {
          Size currentSize() => (context.findRenderObject()! as RenderBox).size;
          return GestureDetector(
            onTapDown: (details) =>
                _update(details.localPosition, currentSize()),
            onPanStart: (details) =>
                _update(details.localPosition, currentSize()),
            onPanUpdate: (details) =>
                _update(details.localPosition, currentSize()),
            child: CustomPaint(size: Size.infinite, painter: _HuePainter(hue)),
          );
        },
      ),
    );
  }
}

class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = BorderRadius.circular(size.height / 2).toRRect(rect);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(rect),
    );
    final x = (hue / 360).clamp(0, 1) * size.width;
    canvas.drawCircle(
      Offset(x, size.height / 2),
      9,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x, size.height / 2),
      6,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}
