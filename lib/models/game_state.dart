import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  GameState({
    required this.gold,
    required this.inventoryRaw,
    required this.inventoryJewelry,
    required this.unlockedTalents,
    required this.showcase,
    this.todayTrendId,
    this.trendMultiplier = 1.0,
  });

  GameState copyWith({
    int? gold,
    Map<String, int>? inventoryRaw,
    List<InventoryJewelry>? inventoryJewelry,
    Set<String>? unlockedTalents,
    List<InventoryJewelry?>? showcase,
    String? todayTrendId,
    double? trendMultiplier,
  }) {
    return GameState(
      gold: gold ?? this.gold,
      inventoryRaw: inventoryRaw ?? Map.from(this.inventoryRaw),
      inventoryJewelry: inventoryJewelry ?? List.from(this.inventoryJewelry),
      unlockedTalents: unlockedTalents ?? Set.from(this.unlockedTalents),
      showcase: showcase ?? List.from(this.showcase),
      todayTrendId: todayTrendId ?? this.todayTrendId,
      trendMultiplier: trendMultiplier ?? this.trendMultiplier,
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
    );
  }

  void addGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
  }

  bool removeGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
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
  }

  void removeRawMaterial(String id, int count) {
    final updated = Map<String, int>.from(state.inventoryRaw);
    final current = updated[id] ?? 0;
    updated[id] = max(0, current - count);
    state = state.copyWith(inventoryRaw: updated);
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
  }

  // Selling logic
  int sellItem(int slotIdx) {
    final updatedShowcase = List<InventoryJewelry?>.from(state.showcase);
    if (slotIdx >= updatedShowcase.length || updatedShowcase[slotIdx] == null) return 0;

    final item = updatedShowcase[slotIdx]!;
    final recipe = recipes.firstWhere((r) => r.resultId == item.recipeId);

    // Calculate Price
    double price = recipe.baseValue * item.quality.multiplier;

    // Apply Trend
    if (state.todayTrendId == item.recipeId) {
      price *= state.trendMultiplier;
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
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);
