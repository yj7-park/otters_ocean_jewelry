import 'package:flutter/material.dart';

enum ItemType { raw, jewelry }

class GameItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final ItemType type;
  final int baseValue;
  final Color color;

  const GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.baseValue,
    required this.color,
  });

  // Raw Materials
  static const shell = GameItem(
    id: 'shell',
    name: '조개껍데기',
    description: '파도에 씻겨 매끄러운 껍질입니다.',
    icon: '🐚',
    type: ItemType.raw,
    baseValue: 5,
    color: Colors.amberAccent,
  );

  static const pearl = GameItem(
    id: 'pearl',
    name: '진주',
    description: '심해 조개에서 자란 은은한 빛깔의 진주입니다.',
    icon: '⚪',
    type: ItemType.raw,
    baseValue: 15,
    color: Colors.white,
  );

  static const seaglass = GameItem(
    id: 'seaglass',
    name: '바다유리',
    description: '바다의 흐름에 따라 둥글게 깎인 오색 빛깔 유리입니다.',
    icon: '💎',
    type: ItemType.raw,
    baseValue: 10,
    color: Colors.cyanAccent,
  );

  static const coral = GameItem(
    id: 'coral',
    name: '산호 조각',
    description: '바다 깊은 곳에서 채취한 붉은 산호입니다.',
    icon: '🪸',
    type: ItemType.raw,
    baseValue: 20,
    color: Colors.deepOrangeAccent,
  );

  static List<GameItem> get rawMaterials => [shell, pearl, seaglass, coral];

  static GameItem fromId(String id) {
    switch (id) {
      case 'shell': return shell;
      case 'pearl': return pearl;
      case 'seaglass': return seaglass;
      case 'coral': return coral;
      default:
        // Try jewelry
        final recipe = recipes.firstWhere((r) => r.resultId == id, orElse: () => recipes.first);
        return GameItem(
          id: recipe.resultId,
          name: recipe.name,
          description: recipe.description,
          icon: recipe.icon,
          type: ItemType.jewelry,
          baseValue: recipe.baseValue,
          color: recipe.color,
        );
    }
  }
}

class CraftingRecipe {
  final String resultId;
  final String name;
  final String description;
  final String icon;
  final Map<String, int> ingredients; // Item ID -> Count
  final int baseValue;
  final Color color;

  const CraftingRecipe({
    required this.resultId,
    required this.name,
    required this.description,
    required this.icon,
    required this.ingredients,
    required this.baseValue,
    required this.color,
  });
}

const List<CraftingRecipe> recipes = [
  CraftingRecipe(
    resultId: 'shell_ring',
    name: '조개 반지',
    description: '은은한 조개껍데기를 세공하여 만든 심플한 반지입니다.',
    icon: '💍',
    ingredients: {'shell': 2},
    baseValue: 25,
    color: Colors.amber,
  ),
  CraftingRecipe(
    resultId: 'pearl_earrings',
    name: '진주 귀걸이',
    description: '반짝이는 조개 귀걸이에 진주를 올려 품격을 더했습니다.',
    icon: '✨',
    ingredients: {'shell': 1, 'pearl': 1},
    baseValue: 60,
    color: Colors.white,
  ),
  CraftingRecipe(
    resultId: 'seaglass_necklace',
    name: '바다유리 목걸이',
    description: '햇빛을 머금은 듯 영롱한 바다유리를 꿴 목걸이입니다.',
    icon: '📿',
    ingredients: {'shell': 1, 'seaglass': 2},
    baseValue: 90,
    color: Colors.tealAccent,
  ),
  CraftingRecipe(
    resultId: 'coral_brooch',
    name: '산호 브로치',
    description: '진붉은 산호를 세밀하게 다듬어 만든 브로치입니다.',
    icon: '🔱',
    ingredients: {'seaglass': 1, 'coral': 2},
    baseValue: 140,
    color: Colors.deepOrange,
  ),
  CraftingRecipe(
    resultId: 'deepsea_amulet',
    name: '심해 아뮬렛',
    description: '진주와 바다유리, 산호의 마력이 어우러진 신비한 수호 부적입니다.',
    icon: '🧿',
    ingredients: {'pearl': 2, 'seaglass': 2, 'coral': 1},
    baseValue: 280,
    color: Colors.indigoAccent,
  ),
  CraftingRecipe(
    resultId: 'ocean_crown',
    name: '바다 왕관',
    description: '바다의 지배자를 위해 진주와 붉은 산호로 빚어낸 최고급 왕관입니다.',
    icon: '👑',
    ingredients: {'pearl': 3, 'coral': 2},
    baseValue: 350,
    color: Colors.yellowAccent,
  ),
];

enum ItemQuality { normal, rare, perfect }

extension ItemQualityExtension on ItemQuality {
  double get multiplier {
    switch (this) {
      case ItemQuality.normal: return 1.0;
      case ItemQuality.rare: return 1.4;
      case ItemQuality.perfect: return 2.0;
    }
  }

  String get label {
    switch (this) {
      case ItemQuality.normal: return '일반';
      case ItemQuality.rare: return '희귀';
      case ItemQuality.perfect: return '완벽';
    }
  }

  Color get color {
    switch (this) {
      case ItemQuality.normal: return Colors.grey;
      case ItemQuality.rare: return Colors.blueAccent;
      case ItemQuality.perfect: return Colors.purpleAccent;
    }
  }
}

class InventoryJewelry {
  final String id;
  final String recipeId;
  final ItemQuality quality;
  final int count;

  InventoryJewelry({
    required this.id,
    required this.recipeId,
    required this.quality,
    this.count = 1,
  });

  InventoryJewelry copyWith({
    String? id,
    String? recipeId,
    ItemQuality? quality,
    int? count,
  }) {
    return InventoryJewelry(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      quality: quality ?? this.quality,
      count: count ?? this.count,
    );
  }
}
