import 'package:flutter/material.dart';

class StarterTexture {
  const StarterTexture({
    required this.name,
    required this.category,
    required this.assetPath,
    required this.accent,
  });

  final String name;
  final String category;
  final String assetPath;
  final Color accent;
}

abstract final class StarterTextures {
  static const all = [
    StarterTexture(
      name: 'Wood Planks',
      category: 'Natural',
      assetPath: 'assets/images/textures/starters/wood-planks.png',
      accent: Color(0xFFB77A45),
    ),
    StarterTexture(
      name: 'Stone Wall',
      category: 'Building',
      assetPath: 'assets/images/textures/starters/stone-wall.png',
      accent: Color(0xFF7E8995),
    ),
    StarterTexture(
      name: 'Lush Grass',
      category: 'Natural',
      assetPath: 'assets/images/textures/starters/lush-grass.png',
      accent: Color(0xFF4E9F48),
    ),
    StarterTexture(
      name: 'Desert Sand',
      category: 'Natural',
      assetPath: 'assets/images/textures/starters/desert-sand.png',
      accent: Color(0xFFD8AE63),
    ),
    StarterTexture(
      name: 'Cracked Ice',
      category: 'Fantasy',
      assetPath: 'assets/images/textures/starters/cracked-ice.png',
      accent: Color(0xFF77D9F4),
    ),
    StarterTexture(
      name: 'Molten Lava',
      category: 'Fantasy',
      assetPath: 'assets/images/textures/starters/molten-lava.png',
      accent: Color(0xFFFF6A2B),
    ),
    StarterTexture(
      name: 'Woven Fabric',
      category: 'Material',
      assetPath: 'assets/images/textures/starters/woven-fabric.png',
      accent: Color(0xFF8A6CE8),
    ),
    StarterTexture(
      name: 'Sci-Fi Panels',
      category: 'Technology',
      assetPath: 'assets/images/textures/starters/scifi-panels.png',
      accent: Color(0xFF3DD5CA),
    ),
  ];
}
