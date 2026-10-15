import 'package:flutter/material.dart';

import '../ads/interstitial_ad_service.dart';
import '../editor/skin_canvas.dart';
import '../editor/template_geometry.dart';
import '../models/app_preferences.dart';
import '../models/design_template.dart';
import '../models/editor_models.dart';
import '../models/studio_feature.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({
    super.key,
    required this.onCreate,
    required this.onOpenFeature,
  });

  final ValueChanged<ClothingType> onCreate;
  final ValueChanged<StudioFeature> onOpenFeature;

  @override
  Widget build(BuildContext context) {
    return _ProductPage(
      title: 'Create',
      subtitle: 'Start from a canvas or a guided workflow',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final cards = [
                _LaunchCard(
                  title: 'Classic Shirt',
                  subtitle: 'Open the pro editor',
                  image: 'assets/images/home/create-shirt.png',
                  accent: const Color(0xFF9A6BFF),
                  onTap: () => onCreate(ClothingType.shirt),
                ),
                _LaunchCard(
                  title: 'Classic Pants',
                  subtitle: 'Design waist and legs',
                  image: 'assets/images/home/create-pants.png',
                  accent: const Color(0xFF39CFE2),
                  onTap: () => onCreate(ClothingType.pants),
                ),
              ];
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 2 : 1,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: wide ? 2.05 : 1.7,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 30),
          const _PageSectionTitle(
            title: 'Guided creators',
            subtitle: 'Purpose-built flows for common projects',
          ),
          const SizedBox(height: 14),
          _FeatureList(features: StudioFeatures.all, onTap: onOpenFeature),
          const SizedBox(height: 30),
          _TemplatePromo(
            onBrowse: () => onOpenFeature(StudioFeatures.patternLab),
          ),
        ],
      ),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.onOpenFeature,
    required this.onUseTemplate,
  });

  final ValueChanged<StudioFeature> onOpenFeature;
  final ValueChanged<ReadyDesignTemplate> onUseTemplate;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _query = '';
  String _category = 'All';

  Future<void> _search() async {
    var draft = _query;
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search ideas'),
        content: TextFormField(
          initialValue: _query,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Try neon, cargo, or league',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => draft = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draft),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (value != null && mounted) setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.toLowerCase();
    final templates = DesignTemplateCatalog.all.where((template) {
      final categoryMatches =
          _category == 'All' || template.category == _category;
      final queryMatches =
          normalizedQuery.isEmpty ||
          template.title.toLowerCase().contains(normalizedQuery) ||
          template.subtitle.toLowerCase().contains(normalizedQuery) ||
          template.category.toLowerCase().contains(normalizedQuery) ||
          template.type.name.contains(normalizedQuery);
      return categoryMatches && queryMatches;
    }).toList();
    final ideas = _ideaCatalog
        .where((idea) => idea.matches(normalizedQuery))
        .toList();

    return _ProductPage(
      title: 'Ideas',
      subtitle: 'Ready templates and original directions to make your own',
      trailing: IconButton.filledTonal(
        onPressed: _search,
        tooltip: 'Search ideas',
        icon: const Icon(Icons.search),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFF59319D), Color(0xFF173E5D)],
              ),
            ),
            child: Wrap(
              spacing: 22,
              runSpacing: 18,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 58,
                  color: Color(0xFFB8F34A),
                ),
                const SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREATIVE PROMPT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Cyber City Streetwear',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Combine neon trims, dark panels, and one original emblem. Keep every detail readable at avatar scale.',
                        style: TextStyle(color: Color(0xFFD6DAE5)),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          widget.onUseTemplate(DesignTemplateCatalog.all.first),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Use ready template'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          widget.onOpenFeature(StudioFeatures.matchingSet),
                      child: const Text('Build a matching set'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _PageSectionTitle(
            title: 'Ready templates',
            subtitle:
                '${DesignTemplateCatalog.all.length} editable shirt and pants designs',
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DesignTemplateCatalog.categories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (templates.isEmpty)
            _IdeasEmptyState(
              message: 'No templates match “$_query” in $_category.',
              onClear: () => setState(() {
                _query = '';
                _category = 'All';
              }),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 1040
                    ? 3
                    : constraints.maxWidth >= 650
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: templates.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: count == 1 ? 1.95 : 1.72,
                  ),
                  itemBuilder: (context, index) => _ReadyTemplateCard(
                    template: templates[index],
                    onTap: () => widget.onUseTemplate(templates[index]),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
          _PageSectionTitle(
            title: 'Creative directions',
            subtitle: '${_ideaCatalog.length} guided ideas with working tools',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 820 ? 3 : 1;
              if (ideas.isEmpty) {
                return _IdeasEmptyState(
                  message: 'No creative directions match “$_query”.',
                  onClear: () => setState(() => _query = ''),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ideas.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: count == 1 ? 2.2 : 0.92,
                ),
                itemBuilder: (context, index) => _TrendCard(
                  data: ideas[index],
                  onTap: () => widget.onOpenFeature(ideas[index].feature),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onPreferencesChanged,
    required this.onResetPreferences,
    required this.onCreate,
    required this.onOpenFeature,
    required this.onReplayOnboarding,
  });

  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onPreferencesChanged;
  final Future<void> Function() onResetPreferences;
  final ValueChanged<ClothingType> onCreate;
  final ValueChanged<StudioFeature> onOpenFeature;
  final VoidCallback onReplayOnboarding;

  @override
  Widget build(BuildContext context) {
    return _ProductPage(
      title: 'Settings',
      subtitle: 'Editor defaults, privacy, and app information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingsOverview(),
          const SizedBox(height: 26),
          const _PageSectionTitle(
            title: 'Editor defaults',
            subtitle: 'Saved on this device and applied to new editor sessions',
          ),
          const SizedBox(height: 12),
          _EditorSettingsCard(
            preferences: preferences,
            onChanged: onPreferencesChanged,
            onReset: () async {
              await onResetPreferences();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editor defaults restored.')),
              );
            },
          ),
          const SizedBox(height: 26),
          const _PageSectionTitle(
            title: 'Tools and export',
            subtitle: 'Open production utilities directly',
          ),
          const SizedBox(height: 12),
          _StudioActionsCard(
            onNewShirt: () => onCreate(ClothingType.shirt),
            onValidate: () => onOpenFeature(StudioFeatures.uploadAssistant),
            onTextures: () => onOpenFeature(StudioFeatures.decalTextureMaker),
          ),
          const SizedBox(height: 26),
          const _PageSectionTitle(
            title: 'Independent app disclosure',
            subtitle: 'Third-party relationship and product scope',
          ),
          const SizedBox(height: 12),
          const _IndependenceDisclaimer(),
          const SizedBox(height: 26),
          const _PageSectionTitle(
            title: 'Help and learning',
            subtitle: 'Review the creation workflow at any time',
          ),
          const SizedBox(height: 12),
          _ReplayOnboardingCard(onTap: onReplayOnboarding),
          const SizedBox(height: 26),
          const _PageSectionTitle(
            title: 'Privacy and legal',
            subtitle: 'How files, permissions, and trademarks are handled',
          ),
          const SizedBox(height: 12),
          const _PrivacyCard(),
        ],
      ),
    );
  }
}

class _ReplayOnboardingCard extends StatelessWidget {
  const _ReplayOnboardingCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        leading: const CircleAvatar(
          backgroundColor: Color(0x2638D6C4),
          foregroundColor: Color(0xFF38D6C4),
          child: Icon(Icons.play_circle_outline),
        ),
        title: const Text(
          'Replay app introduction',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text(
          'See templates, editor tools, 3D preview, and export guidance again.',
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}

class _ProductPage extends StatelessWidget {
  const _ProductPage({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Color(0xFF9BA3AD)),
                          ),
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchCard extends StatelessWidget {
  const _LaunchCard({
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

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF5131721)],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Color(0xFFCED2DC)),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF101214),
                    child: const Icon(Icons.arrow_forward),
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

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features, required this.onTap});

  final List<StudioFeature> features;
  final ValueChanged<StudioFeature> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 780
            ? 3
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: count == 1 ? 3.4 : 1.5,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onTap(feature),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: feature.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(feature.icon, color: feature.color),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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

class _TemplatePromo extends StatelessWidget {
  const _TemplatePromo({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 18,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_customize,
              color: Color(0xFFB8F34A),
              size: 38,
            ),
            const SizedBox(
              width: 600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pattern presets',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Generate editable plaid, stripe, grid, and dot artwork with your own scale and colors.',
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onBrowse,
              child: const Text('Open Pattern Lab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadyTemplateCard extends StatelessWidget {
  const _ReadyTemplateCard({required this.template, required this.onTap});

  final ReadyDesignTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strokes = template.createStrokes();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Container(
                width: 126,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF191D26),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF343A47)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: ClothingTemplate.size.aspectRatio,
                    child: CustomPaint(
                      painter: SkinCanvasPainter(
                        strokes: strokes,
                        showGuide: false,
                        clothingType: template.type,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _MiniLabel(
                          icon: template.type == ClothingType.shirt
                              ? Icons.checkroom
                              : Icons.accessibility_new,
                          text: template.type == ClothingType.shirt
                              ? 'SHIRT'
                              : 'PANTS',
                        ),
                        _MiniLabel(
                          icon: Icons.category_outlined,
                          text: template.category.toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      template.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ...template.palette.map(
                          (color) => Container(
                            width: 17,
                            height: 17,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .38),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'EDIT',
                          style: TextStyle(
                            color: Color(0xFFB8F34A),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFFB8F34A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF303642),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFFB8F34A)),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeasEmptyState extends StatelessWidget {
  const _IdeasEmptyState({required this.message, required this.onClear});

  final String message;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

const _ideaCatalog = [
  _TrendData(
    title: 'Neon Techwear',
    image: 'assets/images/home/create-set.png',
    count: 'Coordinate dark panels and electric accents',
    keywords: 'cyber neon streetwear matching purple',
    feature: StudioFeatures.matchingSet,
  ),
  _TrendData(
    title: 'Aqua Cargo Remix',
    image: 'assets/images/home/create-pants.png',
    count: 'Build utility rhythm with repeatable geometry',
    keywords: 'cargo pants aqua utility repeat',
    feature: StudioFeatures.patternLab,
  ),
  _TrendData(
    title: 'Night League',
    image: 'assets/images/home/create-uniform.png',
    count: 'Create a numbered team and rank system',
    keywords: 'sport team league uniform gold',
    feature: StudioFeatures.uniformMaker,
  ),
  _TrendData(
    title: 'Monochrome Core',
    image: 'assets/images/home/create-shirt.png',
    count: 'Use proportion and contrast instead of noise',
    keywords: 'minimal black white clean shirt',
    feature: StudioFeatures.patternLab,
  ),
  _TrendData(
    title: 'Frost Runner Duo',
    image: 'assets/images/home/create-set.png',
    count: 'Link an icy palette across a complete outfit',
    keywords: 'winter ice cyan matching seasonal',
    feature: StudioFeatures.matchingSet,
  ),
  _TrendData(
    title: 'Pixel Arcade',
    image: 'assets/images/home/create-shirt.png',
    count: 'Turn simple pixel clusters into readable symbols',
    keywords: 'pixel arcade retro grid colorful',
    feature: StudioFeatures.patternLab,
  ),
  _TrendData(
    title: 'Ember Squad',
    image: 'assets/images/home/create-uniform.png',
    count: 'Combine warm trims, numbers, and role badges',
    keywords: 'fire orange red squad uniform',
    feature: StudioFeatures.uniformMaker,
  ),
  _TrendData(
    title: 'Forest Explorer',
    image: 'assets/images/home/create-pants.png',
    count: 'Plan an earthy palette and accessory story',
    keywords: 'forest nature green brown adventure',
    feature: StudioFeatures.avatarCloset,
  ),
  _TrendData(
    title: 'Creator Emblem Drop',
    image: 'assets/images/home/create-shirt.png',
    count: 'Prepare an original transparent emblem or logo',
    keywords: 'logo emblem decal transparent creator',
    feature: StudioFeatures.decalTextureMaker,
  ),
];

class _TrendData {
  const _TrendData({
    required this.title,
    required this.image,
    required this.count,
    required this.keywords,
    required this.feature,
  });
  final String title;
  final String image;
  final String count;
  final String keywords;
  final StudioFeature feature;

  bool matches(String query) =>
      query.isEmpty ||
      title.toLowerCase().contains(query) ||
      count.toLowerCase().contains(query) ||
      keywords.contains(query);
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.data, required this.onTap});
  final _TrendData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(data.image, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xEF161922)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    data.count,
                    style: const TextStyle(
                      color: Color(0xFFC4C9D3),
                      fontSize: 12,
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

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF29343A), Color(0xFF1B1E22)],
        ),
        border: Border.all(color: const Color(0xFF3A4548)),
      ),
      child: const Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFB8F34A),
              borderRadius: BorderRadius.all(Radius.circular(17)),
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Icon(
                Icons.settings_rounded,
                color: Color(0xFF101214),
                size: 30,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Block Skin Studio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text(
                  'Preferences are stored locally. Artwork is processed on your device unless you explicitly export it.',
                  style: TextStyle(color: Color(0xFFC6CCD6), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSettingsCard extends StatelessWidget {
  const _EditorSettingsCard({
    required this.preferences,
    required this.onChanged,
    required this.onReset,
  });

  final AppPreferences preferences;
  final ValueChanged<AppPreferences> onChanged;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.grid_on_outlined),
            title: const Text('Show template guides'),
            subtitle: const Text('Display face labels when opening the editor'),
            value: preferences.showTemplateGuides,
            onChanged: (value) =>
                onChanged(preferences.copyWith(showTemplateGuides: value)),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.view_in_ar_outlined),
            title: const Text('Auto-rotate 3D preview'),
            subtitle: const Text('Start new previews with rotation enabled'),
            value: preferences.autoRotatePreview,
            onChanged: (value) =>
                onChanged(preferences.copyWith(autoRotatePreview: value)),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Confirm before clearing artwork'),
            subtitle: const Text('Prevent accidental removal of all objects'),
            value: preferences.confirmBeforeClear,
            onChanged: (value) =>
                onChanged(preferences.copyWith(confirmBeforeClear: value)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Restore editor defaults'),
            subtitle: const Text('Reset all three preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _StudioActionsCard extends StatelessWidget {
  const _StudioActionsCard({
    required this.onNewShirt,
    required this.onValidate,
    required this.onTextures,
  });

  final VoidCallback onNewShirt;
  final VoidCallback onValidate;
  final VoidCallback onTextures;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.brush_outlined),
            title: const Text('Open clothing editor'),
            subtitle: const Text('Start a new classic shirt'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onNewShirt,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Validate an exported PNG'),
            subtitle: const Text('Check size and transparency'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onValidate,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.texture),
            title: const Text('Open decal and texture maker'),
            subtitle: const Text('Prepare images and repeating textures'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: onTextures,
          ),
        ],
      ),
    );
  }
}

class _IndependenceDisclaimer extends StatelessWidget {
  const _IndependenceDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF292A22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF62633E)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFD66B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Independent design utility',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Block Skin Studio is an independent third-party app. It is not an official Roblox app and is not affiliated with, sponsored, endorsed, or approved by Roblox Corporation.',
            style: TextStyle(color: Color(0xFFE6E3D4), height: 1.45),
          ),
          SizedBox(height: 10),
          Text(
            'Roblox is a trademark of Roblox Corporation. This app does not provide Roblox account sign-in, Robux purchases or rewards, catalog access, or direct asset uploads. Users export files and upload them separately through official Roblox tools.',
            style: TextStyle(color: Color(0xFFBBB9AB), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.phonelink_lock_outlined),
            title: Text('On-device processing'),
            subtitle: Text(
              'Artwork and imported photos are processed locally. The app does not automatically upload files or collect Roblox account credentials.',
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.photo_library_outlined),
            title: Text('Photo library access'),
            subtitle: Text(
              'Access is requested only when you choose to import an image. Export uses the system share sheet.',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Ad privacy choices'),
            subtitle: const Text(
              'Manage consent choices when advertising privacy options are required in your region.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final shown = await InterstitialAdService.instance
                  .showPrivacyOptions();
              if (!context.mounted || shown) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No additional ad privacy choices are required right now.',
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copyright_outlined),
            title: const Text('Content rights'),
            subtitle: const Text('Review original-content guidance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Content rights'),
                content: const Text(
                  'Use artwork you created or have permission to use. Do not use third-party logos, characters, photos, or trademarks without authorization. Exported assets may be reviewed under the rules of the platform where you upload them.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Understood'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App information'),
            subtitle: Text('Block Skin Studio • Version 1.0.0 (1)'),
          ),
        ],
      ),
    );
  }
}

class _PageSectionTitle extends StatelessWidget {
  const _PageSectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(subtitle, style: const TextStyle(color: Color(0xFF9BA3AD))),
      ],
    );
  }
}
