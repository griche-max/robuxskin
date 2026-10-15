import 'package:flutter/material.dart';

import '../models/editor_models.dart';
import '../editor/avatar_preview.dart';
import '../theme/studio_theme.dart';
import '../models/studio_feature.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onCreate,
    required this.onOpenFeature,
    required this.onOpenCreate,
    required this.onOpenIdeas,
  });

  final ValueChanged<ClothingType> onCreate;
  final ValueChanged<StudioFeature> onOpenFeature;
  final VoidCallback onOpenCreate;
  final VoidCallback onOpenIdeas;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HomeHeader(onOpenCreate: onOpenCreate)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroBanner(onCreate: () => onCreate(ClothingType.shirt)),
                      const SizedBox(height: 30),
                      const _SectionTitle(
                        title: 'Start creating',
                        subtitle: 'Pick a canvas',
                      ),
                      const SizedBox(height: 14),
                      _CreationGrid(
                        onCreate: onCreate,
                        onOpenFeature: onOpenFeature,
                      ),
                      const SizedBox(height: 30),
                      _SectionTitle(
                        title: 'Pro creator tools',
                        subtitle: 'Build, texture, and prepare your export',
                        actionLabel: 'View all',
                        onAction: onOpenCreate,
                      ),
                      const SizedBox(height: 14),
                      _FeatureGrid(onOpenFeature: onOpenFeature),
                      const SizedBox(height: 30),
                      _ProductionBanner(
                        onValidate: () =>
                            onOpenFeature(StudioFeatures.uploadAssistant),
                        onIdeas: onOpenIdeas,
                      ),
                      const SizedBox(height: 18),
                      const _HomeDisclaimer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onOpenCreate});

  final VoidCallback onOpenCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1212),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Row(
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFB8F34A),
                  borderRadius: BorderRadius.all(Radius.circular(13)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.view_in_ar,
                    color: Color(0xFF101214),
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLOCK SKIN STUDIO',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      'CLOTHING + TEXTURE WORKSHOP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF9BA3AD), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Creator workspaces',
                onPressed: onOpenCreate,
                icon: const Icon(Icons.dashboard_customize_outlined),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Studio guide',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => const _StudioGuideSheet(),
                ),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StudioTheme.panel,
        border: Border.all(color: StudioTheme.line),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                Container(width: 3, height: 12, color: StudioTheme.accent),
                const SizedBox(width: 8),
                const Text(
                  'CHARACTER WORKSHOP',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: StudioTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 194,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 400;
                return Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 18,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your next\nmain fit.',
                                style: TextStyle(
                                  fontSize: narrow ? 32 : 42,
                                  height: 1.02,
                                  letterSpacing: -1.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Paint in 3D.\nMake every side yours.',
                              style: TextStyle(
                                color: StudioTheme.muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _WorkshopGrid(),
                          child: CustomPaint(
                            painter: AvatarPainter(
                              shirtTexture: null,
                              pantsTexture: null,
                              bodyShape: AvatarBodyShape.classic,
                              rotation: -.5,
                              pitch: .12,
                              zoom: 1.12,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'CLASSIC CLOTHING\n585 × 559 · PNG',
                    style: TextStyle(
                      color: StudioTheme.muted,
                      fontSize: 10,
                      letterSpacing: .5,
                      height: 1.6,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Start creating'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF2A3035)
      ..strokeWidth = .7;
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), ink);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ink);
    }
  }

  @override
  bool shouldRepaint(covariant _WorkshopGrid oldDelegate) => false;
}

class _CreationGrid extends StatelessWidget {
  const _CreationGrid({required this.onCreate, required this.onOpenFeature});

  final ValueChanged<ClothingType> onCreate;
  final ValueChanged<StudioFeature> onOpenFeature;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CreationData(
        title: 'Classic Shirt',
        subtitle: 'Torso + sleeves',
        image: 'assets/images/home/create-shirt.png',
        accent: const Color(0xFF9A6BFF),
        onTap: () => onCreate(ClothingType.shirt),
      ),
      _CreationData(
        title: 'Classic Pants',
        subtitle: 'Waist + legs',
        image: 'assets/images/home/create-pants.png',
        accent: const Color(0xFF39CFE2),
        onTap: () => onCreate(ClothingType.pants),
      ),
      _CreationData(
        title: 'Uniform Maker',
        subtitle: 'Groups and teams',
        image: 'assets/images/home/create-uniform.png',
        accent: const Color(0xFFFFC857),
        onTap: () => onOpenFeature(StudioFeatures.uniformMaker),
      ),
      _CreationData(
        title: 'Matching Set',
        subtitle: 'Complete outfit',
        image: 'assets/images/home/create-set.png',
        accent: const Color(0xFFB8F34A),
        onTap: () => onOpenFeature(StudioFeatures.matchingSet),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 460 ? 0.82 : 0.96,
          ),
          itemBuilder: (context, index) => _CreationCard(data: cards[index]),
        );
      },
    );
  }
}

class _CreationData {
  const _CreationData({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final Color accent;
  final VoidCallback onTap;
}

class _CreationCard extends StatelessWidget {
  const _CreationCard({required this.data});

  final _CreationData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1B1E22),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(data.image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF0181B24)],
                  stops: [0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          data.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB5BBC8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: StudioTheme.raised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.arrow_forward,
                        color: StudioTheme.accent,
                        size: 18,
                      ),
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

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onOpenFeature});

  final ValueChanged<StudioFeature> onOpenFeature;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: StudioFeatures.all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth < 500 ? 1.05 : 1.8,
          ),
          itemBuilder: (context, index) {
            final feature = StudioFeatures.all[index];
            return Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenFeature(feature),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: StudioTheme.raised,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(feature.icon, color: StudioTheme.muted),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        feature.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        feature.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9BA3AD),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductionBanner extends StatelessWidget {
  const _ProductionBanner({required this.onValidate, required this.onIdeas});

  final VoidCallback onValidate;
  final VoidCallback onIdeas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: StudioTheme.panel,
        border: Border.all(color: StudioTheme.line),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.verified_outlined, size: 34),
            ),
          ),
          const SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPORT WITH CONFIDENCE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  'Check your export.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Check PNG dimensions and transparency before uploading.',
                  style: TextStyle(color: Color(0xFFD7DBE4)),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: onValidate,
            child: const Text('Validate PNG'),
          ),
          TextButton(onPressed: onIdeas, child: const Text('Browse ideas')),
        ],
      ),
    );
  }
}

class _StudioGuideSheet extends StatelessWidget {
  const _StudioGuideSheet();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Studio guide',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('1')),
              title: Text('Choose a classic shirt or pants canvas'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('2')),
              title: Text('Draw, use pixel mode, add text, or import a photo'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('3')),
              title: Text('Inspect the outfit in 3D and export a PNG'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDisclaimer extends StatelessWidget {
  const _HomeDisclaimer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 17, color: Color(0xFF9BA3AD)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Block Skin Studio is an independent design utility. It is not an official Roblox app and is not affiliated with, sponsored, endorsed, or approved by Roblox Corporation.',
            style: TextStyle(
              color: Color(0xFF9BA3AD),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9BA3AD), fontSize: 13),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
