import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../editor/avatar_preview.dart';
import '../editor/skin_canvas.dart';
import '../editor/template_geometry.dart';
import '../models/design_template.dart';
import '../models/editor_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.isReplay = false,
  });

  final Future<void> Function() onComplete;
  final bool isReplay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _ambientController;
  int _page = 0;
  double _avatarRotation = -.38;
  bool _finishing = false;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_page == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBackdrop(_ambientController)),
          SafeArea(
            child: Column(
              children: [
                _OnboardingHeader(
                  isReplay: widget.isReplay,
                  onClose: widget.isReplay ? _finish : null,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (value) => setState(() => _page = value),
                    children: [
                      _WelcomePage(
                        active: _page == 0,
                        animation: _ambientController,
                      ),
                      _EditorIntroPage(
                        active: _page == 1,
                        animation: _ambientController,
                      ),
                      _PreviewIntroPage(
                        active: _page == 2,
                        rotation: _avatarRotation,
                        onRotationChanged: (value) {
                          setState(() => _avatarRotation = value);
                        },
                      ),
                      _ExportIntroPage(active: _page == 3),
                    ],
                  ),
                ),
                _OnboardingFooter(
                  page: _page,
                  pageCount: _pageCount,
                  finishing: _finishing,
                  onBack: _back,
                  onSkip: _finish,
                  onNext: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.isReplay, this.onClose});

  final bool isReplay;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFB8F34A),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x44B8F34A), blurRadius: 18),
              ],
            ),
            child: const Icon(
              Icons.view_in_ar,
              color: Color(0xFF101214),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLOCK SKIN STUDIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                Text(
                  'CREATE • PREVIEW • EXPORT',
                  style: TextStyle(
                    color: Color(0xFF9BA3AD),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
          if (isReplay)
            IconButton(
              tooltip: 'Close introduction',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.page,
    required this.pageCount,
    required this.finishing,
    required this.onBack,
    required this.onSkip,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final bool finishing;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final last = page == pageCount - 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 18,
            8,
            compact ? 10 : 18,
            14,
          ),
          child: Row(
            children: [
              SizedBox(
                width: compact ? 48 : 72,
                child: page == 0
                    ? TextButton(
                        onPressed: finishing ? null : onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: TextStyle(fontSize: compact ? 11 : 14),
                        ),
                        child: const Text('Skip'),
                      )
                    : compact
                    ? IconButton(
                        tooltip: 'Back',
                        onPressed: finishing ? null : onBack,
                        icon: const Icon(Icons.arrow_back, size: 19),
                      )
                    : TextButton.icon(
                        onPressed: finishing ? null : onBack,
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Back'),
                      ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pageCount,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: index == page ? (compact ? 19 : 25) : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == page
                            ? const Color(0xFFB8F34A)
                            : const Color(0xFF4B5261),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              FilledButton(
                onPressed: finishing ? null : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: Size(compact ? 104 : 112, 48),
                  padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 17),
                  textStyle: TextStyle(
                    fontSize: compact ? 11 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: finishing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            last && compact
                                ? 'Start'
                                : last
                                ? 'Start creating'
                                : 'Continue',
                          ),
                          SizedBox(width: compact ? 4 : 6),
                          Icon(
                            last ? Icons.rocket_launch : Icons.arrow_forward,
                            size: compact ? 17 : 20,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.active, required this.animation});

  final bool active;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      active: active,
      eyebrow: 'WELCOME TO YOUR CREATOR WORKSPACE',
      title: 'Create without limits.',
      description:
          'Start blank or choose a ready design. Every template opens as real editable artwork—not a locked preview.',
      badges: const [
        _FeatureBadge(Icons.checkroom, 'Shirts'),
        _FeatureBadge(Icons.accessibility_new, 'Pants'),
        _FeatureBadge(Icons.texture, 'Textures'),
      ],
      preview: _TemplateDeck(animation: animation),
    );
  }
}

class _EditorIntroPage extends StatelessWidget {
  const _EditorIntroPage({required this.active, required this.animation});

  final bool active;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      active: active,
      eyebrow: 'STEP 1 • DESIGN',
      title: 'Paint, place & pixel.',
      description:
          'Zoom into the clothing map, draw immediately, import photos, add text, fill faces, and undo safely.',
      badges: const [
        _FeatureBadge(Icons.brush, 'Brush'),
        _FeatureBadge(Icons.grid_on, 'Pixel'),
        _FeatureBadge(Icons.text_fields, 'Text'),
      ],
      preview: _EditorMockup(animation: animation),
    );
  }
}

class _PreviewIntroPage extends StatelessWidget {
  const _PreviewIntroPage({
    required this.active,
    required this.rotation,
    required this.onRotationChanged,
  });

  final bool active;
  final double rotation;
  final ValueChanged<double> onRotationChanged;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      active: active,
      eyebrow: 'STEP 2 • INSPECT',
      title: 'See every angle.',
      description:
          'Preview shirts and pants together. Drag the character, rotate automatically, and test multiple body fits.',
      badges: const [
        _FeatureBadge(Icons.threed_rotation, '360°'),
        _FeatureBadge(Icons.accessibility_new, 'Body fits'),
        _FeatureBadge(Icons.visibility, 'Live'),
      ],
      preview: _AvatarMockup(
        rotation: rotation,
        onRotationChanged: onRotationChanged,
        autoRotate: active,
      ),
    );
  }
}

class _ExportIntroPage extends StatelessWidget {
  const _ExportIntroPage({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      active: active,
      eyebrow: 'STEP 3 • EXPORT',
      title: 'Finish with confidence.',
      description:
          'Export a transparent PNG, validate it, then upload separately through official Roblox tools.',
      badges: const [
        _FeatureBadge(Icons.image_outlined, 'PNG'),
        _FeatureBadge(Icons.verified_outlined, 'Validate'),
        _FeatureBadge(Icons.ios_share, 'Share'),
      ],
      preview: const _ExportMockup(),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.active,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.badges,
    required this.preview,
  });

  final bool active;
  final String eyebrow;
  final String title;
  final String description;
  final List<_FeatureBadge> badges;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      opacity: active ? 1 : .35,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        offset: active ? Offset.zero : const Offset(.05, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 780;
            final intro = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: Color(0xFFB8F34A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: wide ? 43 : 31,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFBEC3CE),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 7, runSpacing: 7, children: badges),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 42 : 20,
                wide ? 40 : 14,
                wide ? 42 : 20,
                16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: intro),
                            const SizedBox(width: 42),
                            Expanded(
                              child: SizedBox(height: 480, child: preview),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            intro,
                            const SizedBox(height: 20),
                            SizedBox(height: 350, child: preview),
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
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF272C36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A414F)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFB8F34A)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateDeck extends StatelessWidget {
  const _TemplateDeck({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final templates = DesignTemplateCatalog.all.take(3).toList();
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final phase = animation.value * math.pi * 2;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var index = 0; index < templates.length; index++)
              Transform.translate(
                offset: Offset(
                  (index - 1) * 72,
                  (index - 1).abs() * 18 + math.sin(phase + index) * 5,
                ),
                child: Transform.rotate(
                  angle: (index - 1) * .075,
                  child: _TemplatePreviewCard(
                    template: templates[index],
                    highlighted: index == 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  const _TemplatePreviewCard({
    required this.template,
    required this.highlighted,
  });

  final ReadyDesignTemplate template;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: highlighted ? 200 : 178,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xF5222631),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFB8F34A)
              : const Color(0xFF414856),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                template.type == ClothingType.shirt
                    ? Icons.checkroom
                    : Icons.accessibility_new,
                size: 15,
                color: const Color(0xFFB8F34A),
              ),
              const Spacer(),
              const Icon(Icons.edit, size: 14, color: Color(0xFF9BA3AD)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: ClothingTemplate.size.aspectRatio,
              child: CustomPaint(
                painter: SkinCanvasPainter(
                  strokes: template.createStrokes(),
                  showGuide: false,
                  clothingType: template.type,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            template.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          Text(
            template.category,
            style: const TextStyle(color: Color(0xFF9BA3AD), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _EditorMockup extends StatelessWidget {
  const _EditorMockup({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final template = DesignTemplateCatalog.all.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF5222631),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B4250)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _MockSegment(
                icon: Icons.checkroom,
                label: 'Shirt',
                active: true,
              ),
              const _MockSegment(icon: Icons.accessibility_new, label: 'Pants'),
              const Spacer(),
              _MockRoundButton(icon: Icons.undo, enabled: true),
              const SizedBox(width: 5),
              const _MockRoundButton(icon: Icons.redo),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: SkinCanvasPainter(
                      strokes: template.createStrokes(),
                      showGuide: true,
                      clothingType: ClothingType.shirt,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final phase = animation.value * math.pi * 2;
                      return Positioned(
                        left: 82 + math.sin(phase) * 52,
                        top: 62 + math.cos(phase * .72) * 28,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB8F34A,
                            ).withValues(alpha: .28),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFB8F34A),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.brush,
                            size: 13,
                            color: Color(0xFF101214),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              _MockTool(icon: Icons.pan_tool_outlined, label: 'Hand'),
              SizedBox(width: 5),
              _MockTool(icon: Icons.brush, label: 'Brush', active: true),
              SizedBox(width: 5),
              _MockTool(icon: Icons.grid_on, label: 'Pixel'),
              Spacer(),
              _ColorDot(Color(0xFF111318), selected: true),
              _ColorDot(Color(0xFF35D7E5)),
              _ColorDot(Color(0xFF9A6BFF)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockSegment extends StatelessWidget {
  const _MockSegment({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF465236) : const Color(0xFF2A2F3A),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MockRoundButton extends StatelessWidget {
  const _MockRoundButton({required this.icon, this.enabled = false});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF465236) : const Color(0xFF303642),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 15,
        color: enabled ? const Color(0xFFB8F34A) : null,
      ),
    );
  }
}

class _MockTool extends StatelessWidget {
  const _MockTool({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFB8F34A) : const Color(0xFF303642),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: active ? const Color(0xFF101214) : null),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFF101214) : null,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color, {this.selected = false});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFFB8F34A) : const Color(0xFF697181),
          width: selected ? 3 : 1,
        ),
      ),
    );
  }
}

class _AvatarMockup extends StatelessWidget {
  const _AvatarMockup({
    required this.rotation,
    required this.onRotationChanged,
    required this.autoRotate,
  });

  final double rotation;
  final ValueChanged<double> onRotationChanged;
  final bool autoRotate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF5222631),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B4250)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.view_in_ar, size: 18, color: Color(0xFFB8F34A)),
              SizedBox(width: 7),
              Text(
                '3D PREVIEW',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
              Spacer(),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF343C4A), Color(0xFF191D26)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AvatarPreview(
                shirtTexture: null,
                pantsTexture: null,
                bodyShape: AvatarBodyShape.classic,
                rotation: rotation,
                onRotationChanged: onRotationChanged,
                autoRotate: autoRotate,
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            children: [
              _BodyChip('Classic', selected: true),
              SizedBox(width: 6),
              _BodyChip('Broad'),
              SizedBox(width: 6),
              _BodyChip('Slender'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x2639D98A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'LIVE',
          style: TextStyle(
            color: Color(0xFF58E09A),
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BodyChip extends StatelessWidget {
  const _BodyChip(this.label, {this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF465236) : const Color(0xFF2A2F3A),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFFB8F34A) : const Color(0xFF414856),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? const Color(0xFFD8F5A0) : const Color(0xFFB8BEC9),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ExportMockup extends StatelessWidget {
  const _ExportMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xF5222631),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3B4250)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFFB8F34A)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'EXPORT CHECK',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
              _LiveBadge(),
            ],
          ),
          const SizedBox(height: 9),
          const _ExportCheck(
            icon: Icons.aspect_ratio,
            title: '585 × 559 canvas',
            subtitle: 'Classic clothing dimensions',
          ),
          const _ExportCheck(
            icon: Icons.layers_clear,
            title: 'Transparency ready',
            subtitle: 'Clean alpha outside template faces',
          ),
          const _ExportCheck(
            icon: Icons.undo,
            title: 'Editable source preserved',
            subtitle: 'Return and change any object',
          ),
          const SizedBox(height: 2),
          FilledButton.icon(
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            icon: const Icon(Icons.ios_share),
            label: const Text('Export PNG'),
          ),
          const SizedBox(height: 7),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: Color(0xFF9BA3AD)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Independent design app. Upload exported files separately using official Roblox tools.',
                  style: TextStyle(
                    color: Color(0xFF9BA3AD),
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportCheck extends StatelessWidget {
  const _ExportCheck({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0x2639D98A),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: const Color(0xFF58E09A)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9BA3AD),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Color(0xFF58E09A), size: 18),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  const _AnimatedBackdrop(this.animation);

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final phase = animation.value * math.pi * 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF101214)),
            Positioned(
              right: -130 + math.sin(phase) * 24,
              top: 45 + math.cos(phase) * 18,
              child: const _GlowOrb(color: Color(0xFF6D50E6), size: 310),
            ),
            Positioned(
              left: -150 + math.cos(phase * .8) * 30,
              bottom: -85 + math.sin(phase * .8) * 20,
              child: const _GlowOrb(color: Color(0xFF38D6C4), size: 330),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: .18), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
