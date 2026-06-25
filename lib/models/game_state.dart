import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'item_model.dart';
import 'talent_model.dart';

class GameState {
  final int gold;
  final Map<String, int> inventoryRaw;
  final List<InventoryJewelry> inventoryJewelry;
  final Set<String> unlockedTalents;
  final List<InventoryJewelry?> showcase; // Fixed slots (2, 4, or 6 depending on shelf upgrade)
  final String? todayTrendId;
  final double trendMultiplier;
  final String activeThemeId;
  final Set<String> unlockedThemeIds;

  GameState({
    required this.gold,
    required this.inventoryRaw,
    required this.inventoryJewelry,
    required this.unlockedTalents,
    required this.showcase,
    this.todayTrendId,
    this.trendMultiplier = 1.0,
    required this.activeThemeId,
    required this.unlockedThemeIds,
  });

  GameState copyWith({
    int? gold,
    Map<String, int>? inventoryRaw,
    List<InventoryJewelry>? inventoryJewelry,
    Set<String>? unlockedTalents,
    List<InventoryJewelry?>? showcase,
    String? todayTrendId,
    double? trendMultiplier,
    String? activeThemeId,
    Set<String>? unlockedThemeIds,
  }) {
    return GameState(
      gold: gold ?? this.gold,
      inventoryRaw: inventoryRaw ?? Map.from(this.inventoryRaw),
      inventoryJewelry: inventoryJewelry ?? List.from(this.inventoryJewelry),
      unlockedTalents: unlockedTalents ?? Set.from(this.unlockedTalents),
      showcase: showcase ?? List.from(this.showcase),
      todayTrendId: todayTrendId ?? this.todayTrendId,
      trendMultiplier: trendMultiplier ?? this.trendMultiplier,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      unlockedThemeIds: unlockedThemeIds ?? Set.from(this.unlockedThemeIds),
    );
  }

  // Helper getters
  int get maxShowcaseSlots {
    if (unlockedTalents.contains('shelf_2')) return 6;
    if (unlockedTalents.contains('shelf_1')) return 4;
    return 2;
  }
}

class GameStateNotifier extends Notifier<GameState> {
  String _generateId() => 'j_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000)}';

  @override
  GameState build() {
    _loadStateFromPrefs();

    return GameState(
      gold: 150,
      inventoryRaw: {
        'shell': 5,
        'pearl': 1,
        'seaglass': 3,
        'coral': 0,
      },
      inventoryJewelry: [
        InventoryJewelry(
          id: 'init_ring_1',
          recipeId: 'shell_ring',
          quality: ItemQuality.normal,
          count: 1,
        )
      ],
      unlockedTalents: {},
      showcase: List.filled(2, null), // Initial 2 slots
      todayTrendId: 'shell_ring',
      trendMultiplier: 1.5,
      activeThemeId: 'default',
      unlockedThemeIds: {'default'},
    );
  }

  void addGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
    _saveStateToPrefs();
  }

  bool removeGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
    _saveStateToPrefs();
    return true;
  }

  void addRawMaterial(String id, int count) {
    final updated = Map<String, int>.from(state.inventoryRaw);
    // Double gatherer talent check (only for adding raw materials)
    int finalCount = count;
    if (state.unlockedTalents.contains('double_gather') && count > 0) {
      final random = Random();
      int doubleCount = 0;
      for (int i = 0; i < count; i++) {
        if (random.nextDouble() < 0.15) {
          doubleCount++;
        }
      }
      finalCount += doubleCount;
    }

    updated[id] = (updated[id] ?? 0) + finalCount;
    state = state.copyWith(inventoryRaw: updated);
    _saveStateToPrefs();
  }

  void removeRawMaterial(String id, int count) {
    final updated = Map<String, int>.from(state.inventoryRaw);
    final current = updated[id] ?? 0;
    updated[id] = max(0, current - count);
    state = state.copyWith(inventoryRaw: updated);
    _saveStateToPrefs();
  }

  void craftJewelry(String recipeId, ItemQuality quality) {
    final recipe = recipes.firstWhere((r) => r.resultId == recipeId);

    // Deduct ingredients
    final updatedRaw = Map<String, int>.from(state.inventoryRaw);
    recipe.ingredients.forEach((itemId, reqCount) {
      // Check luxury craft talent (reduces royal recipes costs by 1)
      int finalReqCount = reqCount;
      if (state.unlockedTalents.contains('luxury_craft') &&
          (recipeId == 'ocean_crown' || recipeId == 'deepsea_amulet')) {
        finalReqCount = max(1, reqCount - 1);
      }
      updatedRaw[itemId] = (updatedRaw[itemId] ?? 0) - finalReqCount;
    });

    // Add jewelry
    final updatedJewelry = List<InventoryJewelry>.from(state.inventoryJewelry);

    // Senser talent check (chance to upgrade normal/rare)
    ItemQuality finalQuality = quality;
    if (state.unlockedTalents.contains('rare_senser') &&
        finalQuality == ItemQuality.normal) {
      if (Random().nextDouble() < 0.15) {
        finalQuality = ItemQuality.rare;
      }
    }

    // Merge if same recipe and quality
    final existingIdx = updatedJewelry.indexWhere(
        (j) => j.recipeId == recipeId && j.quality == finalQuality);

    if (existingIdx != -1) {
      updatedJewelry[existingIdx] = updatedJewelry[existingIdx].copyWith(
        count: updatedJewelry[existingIdx].count + 1,
      );
    } else {
      updatedJewelry.add(InventoryJewelry(
        id: _generateId(),
        recipeId: recipeId,
        quality: finalQuality,
        count: 1,
      ));
    }

    state = state.copyWith(
      inventoryRaw: updatedRaw,
      inventoryJewelry: updatedJewelry,
    );
    _saveStateToPrefs();
  }

  // Showcase Placement
  void placeOnShowcase(int slotIdx, InventoryJewelry item) {
    final updatedShowcase = List<InventoryJewelry?>.from(state.showcase);
    if (slotIdx >= updatedShowcase.length) return;

    // Remove 1 from inventory
    final updatedJewelry = List<InventoryJewelry>.from(state.inventoryJewelry);
    final invIdx = updatedJewelry.indexWhere((j) => j.id == item.id);
    if (invIdx == -1) return;

    final currentItem = updatedJewelry[invIdx];
    if (currentItem.count > 1) {
      updatedJewelry[invIdx] = currentItem.copyWith(count: currentItem.count - 1);
    } else {
      updatedJewelry.removeAt(invIdx);
    }

    // Place on showcase (count = 1)
    updatedShowcase[slotIdx] = item.copyWith(count: 1);

    state = state.copyWith(
      inventoryJewelry: updatedJewelry,
      showcase: updatedShowcase,
    );
    _saveStateToPrefs();
  }

  void takeFromShowcase(int slotIdx) {
    final updatedShowcase = List<InventoryJewelry?>.from(state.showcase);
    if (slotIdx >= updatedShowcase.length || updatedShowcase[slotIdx] == null) return;

    final item = updatedShowcase[slotIdx]!;
    updatedShowcase[slotIdx] = null;

    // Return to inventory
    final updatedJewelry = List<InventoryJewelry>.from(state.inventoryJewelry);
    final existingIdx = updatedJewelry.indexWhere(
        (j) => j.recipeId == item.recipeId && j.quality == item.quality);

    if (existingIdx != -1) {
      updatedJewelry[existingIdx] = updatedJewelry[existingIdx].copyWith(
        count: updatedJewelry[existingIdx].count + 1,
      );
    } else {
      updatedJewelry.add(item.copyWith(id: _generateId()));
    }

    state = state.copyWith(
      inventoryJewelry: updatedJewelry,
      showcase: updatedShowcase,
    );
    _saveStateToPrefs();
  }

  // Selling logic
  int sellItem(int slotIdx, {double vipMultiplier = 1.0}) {
    final updatedShowcase = List<InventoryJewelry?>.from(state.showcase);
    if (slotIdx >= updatedShowcase.length || updatedShowcase[slotIdx] == null) return 0;

    final item = updatedShowcase[slotIdx]!;
    final recipe = recipes.firstWhere((r) => r.resultId == item.recipeId);

    // Calculate Price
    double price = recipe.baseValue * item.quality.multiplier * vipMultiplier;

    // Apply Trend
    if (state.todayTrendId == item.recipeId) {
      price *= state.trendMultiplier;
    }

    // Apply Theme Bonus (Coral theme gives +15% price for Coral items and Crown)
    if (state.activeThemeId == 'coral' && (item.recipeId == 'coral_brooch' || item.recipeId == 'ocean_crown')) {
      price *= 1.15;
    }

    // Apply Sales Pitch talent (increases price by 20%)
    if (state.unlockedTalents.contains('sales_pitch')) {
      price *= 1.20;
    }

    final finalPrice = price.round();

    // Clear shelf
    updatedShowcase[slotIdx] = null;

    // Add gold
    final newGold = state.gold + finalPrice;

    state = state.copyWith(
      gold: newGold,
      showcase: updatedShowcase,
    );
    _saveStateToPrefs();

    // Auto stocker talent check
    if (state.unlockedTalents.contains('auto_stocker')) {
      _tryAutoRefill(slotIdx, item.recipeId, item.quality);
    }

    return finalPrice;
  }

  void _tryAutoRefill(int slotIdx, String recipeId, ItemQuality quality) {
    // Find matching item in inventory
    final updatedJewelry = List<InventoryJewelry>.from(state.inventoryJewelry);
    final invIdx = updatedJewelry.indexWhere(
        (j) => j.recipeId == recipeId && j.quality == quality);

    if (invIdx != -1) {
      final itemToPlace = updatedJewelry[invIdx];
      
      final updatedShowcase = List<InventoryJewelry?>.from(state.showcase);
      
      // Remove 1 from inventory
      if (itemToPlace.count > 1) {
        updatedJewelry[invIdx] = itemToPlace.copyWith(count: itemToPlace.count - 1);
      } else {
        updatedJewelry.removeAt(invIdx);
      }

      updatedShowcase[slotIdx] = itemToPlace.copyWith(count: 1);

      state = state.copyWith(
        inventoryJewelry: updatedJewelry,
        showcase: updatedShowcase,
      );
      _saveStateToPrefs();
    }
  }

  // Unlock Talent
  bool unlockTalent(String talentId) {
    final talent = talentNodes.firstWhere((t) => t.id == talentId);

    // Check cost
    if (state.gold < talent.cost) return false;

    // Check prerequisite
    if (talent.prerequisiteId != null &&
        !state.unlockedTalents.contains(talent.prerequisiteId)) {
      return false;
    }

    final updatedTalents = Set<String>.from(state.unlockedTalents);
    updatedTalents.add(talentId);

    // Adjust showcase slots if shelf upgrades are unlocked
    List<InventoryJewelry?> updatedShowcase = List.from(state.showcase);
    int newSlots = state.showcase.length;
    if (talentId == 'shelf_1' && state.showcase.length < 4) {
      newSlots = 4;
    } else if (talentId == 'shelf_2' && state.showcase.length < 6) {
      newSlots = 6;
    }

    if (newSlots > state.showcase.length) {
      final int diff = newSlots - state.showcase.length;
      updatedShowcase.addAll(List.filled(diff, null));
    }

    state = state.copyWith(
      gold: state.gold - talent.cost,
      unlockedTalents: updatedTalents,
      showcase: updatedShowcase,
    );
    _saveStateToPrefs();

    return true;
  }

  // Trend Change
  void rollTrend() {
    final random = Random();
    final allRecipes = recipes.map((r) => r.resultId).toList();
    final currentTrend = state.todayTrendId;
    
    String newTrend = allRecipes[random.nextInt(allRecipes.length)];
    // Ensure trend actually changes if there are multiple items
    if (newTrend == currentTrend && allRecipes.length > 1) {
      newTrend = allRecipes.firstWhere((id) => id != currentTrend);
    }

    // Trend multiplier: either 1.5x or 2.0x
    final double mult = random.nextDouble() < 0.3 ? 2.0 : 1.5;

    state = state.copyWith(
      todayTrendId: newTrend,
      trendMultiplier: mult,
    );
    _saveStateToPrefs();
  }

  // Theme Management Methods
  bool unlockTheme(String themeId, int cost) {
    if (state.gold < cost) return false;
    final updatedThemes = Set<String>.from(state.unlockedThemeIds);
    updatedThemes.add(themeId);
    state = state.copyWith(
      gold: state.gold - cost,
      unlockedThemeIds: updatedThemes,
    );
    _saveStateToPrefs();
    return true;
  }

  void equipTheme(String themeId) {
    if (state.unlockedThemeIds.contains(themeId)) {
      state = state.copyWith(activeThemeId: themeId);
      _saveStateToPrefs();
    }
  }

  // Persistence Implementation
  Future<void> _loadStateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGold = prefs.getInt('gold');
      if (savedGold == null) return;

      final activeThemeId = prefs.getString('activeThemeId') ?? 'default';
      final unlockedThemeList = prefs.getStringList('unlockedThemeIds') ?? ['default'];
      final unlockedTalentList = prefs.getStringList('unlockedTalents') ?? [];
      
      final Map<String, int> inventoryRaw = {};
      for (var mat in GameItem.rawMaterials) {
        inventoryRaw[mat.id] = prefs.getInt('raw_${mat.id}') ?? 0;
      }
      
      final jewelryJsonList = prefs.getStringList('inventoryJewelry') ?? [];
      final List<InventoryJewelry> inventoryJewelry = [];
      for (var jsonStr in jewelryJsonList) {
        final parts = jsonStr.split(':');
        if (parts.length == 4) {
          inventoryJewelry.add(InventoryJewelry(
            id: parts[0],
            recipeId: parts[1],
            quality: ItemQuality.values.firstWhere(
              (q) => q.name == parts[2],
              orElse: () => ItemQuality.normal,
            ),
            count: int.tryParse(parts[3]) ?? 1,
          ));
        }
      }

      final int showcaseSize = prefs.getInt('showcaseSize') ?? 2;
      final List<InventoryJewelry?> showcase = List.filled(showcaseSize, null);
      for (int i = 0; i < showcaseSize; i++) {
        final slotData = prefs.getString('showcase_slot_$i');
        if (slotData != null && slotData.isNotEmpty) {
          final parts = slotData.split(':');
          if (parts.length == 4) {
            showcase[i] = InventoryJewelry(
              id: parts[0],
              recipeId: parts[1],
              quality: ItemQuality.values.firstWhere(
                (q) => q.name == parts[2],
                orElse: () => ItemQuality.normal,
              ),
              count: int.tryParse(parts[3]) ?? 1,
            );
          }
        }
      }

      state = GameState(
        gold: savedGold,
        inventoryRaw: inventoryRaw,
        inventoryJewelry: inventoryJewelry,
        unlockedTalents: unlockedTalentList.toSet(),
        showcase: showcase,
        todayTrendId: prefs.getString('todayTrendId') ?? state.todayTrendId,
        trendMultiplier: prefs.getDouble('trendMultiplier') ?? state.trendMultiplier,
        activeThemeId: activeThemeId,
        unlockedThemeIds: unlockedThemeList.toSet(),
      );
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _saveStateToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('gold', state.gold);
      await prefs.setString('activeThemeId', state.activeThemeId);
      await prefs.setStringList('unlockedThemeIds', state.unlockedThemeIds.toList());
      await prefs.setStringList('unlockedTalents', state.unlockedTalents.toList());
      
      for (var entry in state.inventoryRaw.entries) {
        await prefs.setInt('raw_${entry.key}', entry.value);
      }

      final List<String> jewelryJsonList = [];
      for (var j in state.inventoryJewelry) {
        jewelryJsonList.add('${j.id}:${j.recipeId}:${j.quality.name}:${j.count}');
      }
      await prefs.setStringList('inventoryJewelry', jewelryJsonList);

      await prefs.setInt('showcaseSize', state.showcase.length);
      for (int i = 0; i < state.showcase.length; i++) {
        final item = state.showcase[i];
        if (item != null) {
          await prefs.setString('showcase_slot_$i', '${item.id}:${item.recipeId}:${item.quality.name}:${item.count}');
        } else {
          await prefs.remove('showcase_slot_$i');
        }
      }

      if (state.todayTrendId != null) {
        await prefs.setString('todayTrendId', state.todayTrendId!);
      }
      await prefs.setDouble('trendMultiplier', state.trendMultiplier);
    } catch (e) {
      // Fail silently
    }
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);
