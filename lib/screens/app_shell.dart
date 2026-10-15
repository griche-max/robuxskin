import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_preferences.dart';
import '../models/design_template.dart';
import '../models/editor_models.dart';
import '../models/studio_feature.dart';
import 'editor_screen.dart';
import 'feature_tools_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'product_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  AppPreferences _preferences = const AppPreferences();

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final preferences = await AppPreferencesStore.load();
    if (mounted) setState(() => _preferences = preferences);
  }

  void _updatePreferences(AppPreferences preferences) {
    setState(() => _preferences = preferences);
    unawaited(_savePreferences(preferences));
  }

  Future<void> _savePreferences(AppPreferences preferences) async {
    try {
      await AppPreferencesStore.save(preferences);
    } catch (_) {
      // Keep the in-memory setting usable if device storage is unavailable.
    }
  }

  Future<void> _resetPreferences() async {
    const defaults = AppPreferences();
    setState(() => _preferences = defaults);
    try {
      await AppPreferencesStore.reset();
    } catch (_) {
      // Defaults are still applied for the current session.
    }
  }

  void _openEditor(ClothingType type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditorScreen(
          initialType: type,
          initialShowGuide: _preferences.showTemplateGuides,
          initialAutoRotate: _preferences.autoRotatePreview,
          confirmBeforeClear: _preferences.confirmBeforeClear,
        ),
      ),
    );
  }

  void _openTemplate(ReadyDesignTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EditorScreen(
          initialType: template.type,
          initialStrokes: template.createStrokes(),
          initialShowGuide: _preferences.showTemplateGuides,
          initialAutoRotate: _preferences.autoRotatePreview,
          confirmBeforeClear: _preferences.confirmBeforeClear,
        ),
      ),
    );
  }

  void _openFeature(StudioFeature feature) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FeatureToolsScreen(
          feature: feature,
          onOpenEditor: (type, strokes) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => EditorScreen(
                  initialType: type,
                  initialStrokes: strokes,
                  initialShowGuide: _preferences.showTemplateGuides,
                  initialAutoRotate: _preferences.autoRotatePreview,
                  confirmBeforeClear: _preferences.confirmBeforeClear,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _replayOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OnboardingScreen(
          isReplay: true,
          onComplete: () async {
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _showQuickCreate() async {
    final selection = await showModalBottomSheet<_QuickCreateAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => const _QuickCreateSheet(),
    );
    if (!mounted || selection == null) return;
    switch (selection) {
      case _QuickCreateAction.shirt:
        _openEditor(ClothingType.shirt);
      case _QuickCreateAction.pants:
        _openEditor(ClothingType.pants);
      case _QuickCreateAction.decal:
        _openFeature(StudioFeatures.decalTextureMaker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onCreate: _openEditor,
        onOpenFeature: _openFeature,
        onOpenCreate: () => setState(() => _selectedIndex = 1),
        onOpenIdeas: () => setState(() => _selectedIndex = 2),
      ),
      CreateHubScreen(onCreate: _openEditor, onOpenFeature: _openFeature),
      DiscoverScreen(onOpenFeature: _openFeature, onUseTemplate: _openTemplate),
      SettingsScreen(
        preferences: _preferences,
        onPreferencesChanged: _updatePreferences,
        onResetPreferences: _resetPreferences,
        onCreate: _openEditor,
        onOpenFeature: _openFeature,
        onReplayOnboarding: _replayOnboarding,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final body = IndexedStack(index: _selectedIndex, children: pages);
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                _StudioRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() => _selectedIndex = value);
                  },
                  onNewDesign: _showQuickCreate,
                ),
                const VerticalDivider(width: 1, color: Color(0xFF303542)),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: body),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StudioBottomBar(
                  selectedIndex: _selectedIndex,
                  onSelected: (value) => setState(() => _selectedIndex = value),
                  onNewDesign: _showQuickCreate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _QuickCreateAction { shirt, pants, decal }

class _QuickCreateSheet extends StatelessWidget {
  const _QuickCreateSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start something new',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a canvas to start editing.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          _QuickCreateTile(
            icon: Icons.checkroom,
            color: const Color(0xFF9A6BFF),
            title: 'Classic Shirt',
            subtitle: 'Torso and sleeve template',
            onTap: () => Navigator.pop(context, _QuickCreateAction.shirt),
          ),
          const SizedBox(height: 9),
          _QuickCreateTile(
            icon: Icons.accessibility_new,
            color: const Color(0xFF39CFE2),
            title: 'Classic Pants',
            subtitle: 'Waist and leg template',
            onTap: () => Navigator.pop(context, _QuickCreateAction.pants),
          ),
          const SizedBox(height: 9),
          _QuickCreateTile(
            icon: Icons.texture,
            color: const Color(0xFF38D6C4),
            title: 'Decal or Texture',
            subtitle: 'Image cleanup and tile workspace',
            onTap: () => Navigator.pop(context, _QuickCreateAction.decal),
          ),
        ],
      ),
    );
  }
}

class _QuickCreateTile extends StatelessWidget {
  const _QuickCreateTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF25292E),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(icon, color: color),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioBottomBar extends StatelessWidget {
  const _StudioBottomBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.onNewDesign,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onNewDesign;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A404E)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(
                child: _StudioNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              Expanded(
                child: _StudioNavItem(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Create',
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),
              Expanded(child: _NewDesignButton(onTap: onNewDesign)),
              Expanded(
                child: _StudioNavItem(
                  icon: Icons.grid_view_outlined,
                  label: 'Ideas',
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ),
              Expanded(
                child: _StudioNavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioNavItem extends StatelessWidget {
  const _StudioNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFB8F34A) : const Color(0xFF939AA9);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0x1FB8F34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewDesignButton extends StatelessWidget {
  const _NewDesignButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New design',
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD0FF67), Color(0xFF8EEB36)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x55B8F34A), blurRadius: 14),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF101214),
                size: 29,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioRail extends StatelessWidget {
  const _StudioRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onNewDesign,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onNewDesign;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: 112,
        child: Column(
          children: [
            const SizedBox(height: 18),
            const _BrandMark(),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onNewDesign,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    selectedIcon: Icon(Icons.dashboard_customize),
                    label: Text('Create'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.layers_outlined),
                    label: Text('Ideas'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('Settings'),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD0FF67), Color(0xFF8EEB36)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.view_in_ar, color: Color(0xFF101214), size: 26),
      ),
    );
  }
}
