import 'package:flutter/material.dart';

class StudioFeature {
  const StudioFeature({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
}

abstract final class StudioFeatures {
  static const matchingSet = StudioFeature(
    title: 'Matching Set',
    subtitle: 'Shirt + pants together',
    description:
        'Build a coordinated outfit from one palette, pattern, or photo and keep every piece visually consistent.',
    icon: Icons.auto_awesome,
    color: Color(0xFF9A6BFF),
  );

  static const uniformMaker = StudioFeature(
    title: 'Uniform Maker',
    subtitle: 'Teams, groups and role-play',
    description:
        'Create reusable uniforms with logos, rank badges, names, numbers, and color variants.',
    icon: Icons.shield_outlined,
    color: Color(0xFFFFC857),
  );

  static const patternLab = StudioFeature(
    title: 'Pattern Lab',
    subtitle: 'Materials and seamless styles',
    description:
        'Apply recolorable denim, camouflage, gradients, plaid, flames, and original repeating patterns.',
    icon: Icons.texture,
    color: Color(0xFF3ED6C3),
  );

  static const uploadAssistant = StudioFeature(
    title: 'Upload Assistant',
    subtitle: 'Validate before upload',
    description:
        'Check dimensions and transparency, then prepare titles and descriptions for Roblox upload.',
    icon: Icons.cloud_upload_outlined,
    color: Color(0xFF6AA9FF),
  );

  static const avatarCloset = StudioFeature(
    title: 'Avatar Closet',
    subtitle: 'Plan looks in this session',
    description:
        'Plan outfit ideas, color combinations, and accessories before opening a coordinated design in the editor.',
    icon: Icons.checkroom,
    color: Color(0xFFB8F34A),
  );

  static const decalTextureMaker = StudioFeature(
    title: 'Decal & Texture Maker',
    subtitle: 'Images for parts, UI and materials',
    description:
        'Clean photos, create transparent decals, build repeating textures, preview tiled surfaces, and export optimized Roblox-ready PNG assets.',
    icon: Icons.texture,
    color: Color(0xFF38D6C4),
  );

  static const all = [
    decalTextureMaker,
    matchingSet,
    uniformMaker,
    patternLab,
    uploadAssistant,
    avatarCloset,
  ];
}
