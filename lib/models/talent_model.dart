enum TalentCategory { diving, crafting, shop }

class TalentNode {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int cost;
  final TalentCategory category;
  final int row;
  final int col;
  final String? prerequisiteId;

  const TalentNode({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.cost,
    required this.category,
    required this.row,
    required this.col,
    this.prerequisiteId,
  });
}

const List<TalentNode> talentNodes = [
  // --- DIVING TALENTS (Category: diving, Col: 0, 1, 2) ---
  TalentNode(
    id: 'ox_1',
    name: '산소통 확장 I',
    description: '최대 산소량이 40% 증가합니다.',
    icon: '🤿',
    cost: 100,
    category: TalentCategory.diving,
    row: 0,
    col: 0,
  ),
  TalentNode(
    id: 'ox_2',
    name: '산소통 확장 II',
    description: '최대 산소량이 추가로 40% 증가합니다.',
    icon: '🧪',
    cost: 300,
    category: TalentCategory.diving,
    row: 1,
    col: 0,
    prerequisiteId: 'ox_1',
  ),
  TalentNode(
    id: 'fin_1',
    name: '최고급 오리발',
    description: '잠수 시 이동 속도가 30% 빨라집니다.',
    icon: '👣',
    cost: 200,
    category: TalentCategory.diving,
    row: 0,
    col: 1,
  ),
  TalentNode(
    id: 'double_gather',
    name: '채집의 달인',
    description: '잠수 중 자원을 채집할 때 15% 확률로 2배를 획득합니다.',
    icon: '🐚',
    cost: 400,
    category: TalentCategory.diving,
    row: 1,
    col: 1,
    prerequisiteId: 'fin_1',
  ),
  TalentNode(
    id: 'deep_lens',
    name: '심해 탐사 렌즈',
    description: '심해 유물과 희귀 진주가 탐색 범위에 나타납니다.',
    icon: '🔍',
    cost: 600,
    category: TalentCategory.diving,
    row: 2,
    col: 1,
    prerequisiteId: 'double_gather',
  ),

  // --- CRAFTING TALENTS (Category: crafting, Col: 3, 4, 5) ---
  TalentNode(
    id: 'craft_focus_1',
    name: '정밀 세공 I',
    description: '세공 미니게임의 완벽(Perfect) 판정 영역이 20% 넓어집니다.',
    icon: '🔨',
    cost: 150,
    category: TalentCategory.crafting,
    row: 0,
    col: 3,
  ),
  TalentNode(
    id: 'craft_focus_2',
    name: '정밀 세공 II',
    description: '완벽 판정 영역이 추가로 20% 넓어지고 실패 확률이 절반이 됩니다.',
    icon: '📐',
    cost: 350,
    category: TalentCategory.crafting,
    row: 1,
    col: 3,
    prerequisiteId: 'craft_focus_1',
  ),
  TalentNode(
    id: 'rare_senser',
    name: '장인의 육감',
    description: '세공 성공 시 15% 확률로 기본 등급이 희귀(Rare) 이상으로 업그레이드됩니다.',
    icon: '🔮',
    cost: 300,
    category: TalentCategory.crafting,
    row: 0,
    col: 4,
  ),
  TalentNode(
    id: 'luxury_craft',
    name: '왕실 납품서',
    description: '바다 왕관과 심해 아뮬렛 제작에 필요한 재료가 1개씩 감소합니다.',
    icon: '📜',
    cost: 800,
    category: TalentCategory.crafting,
    row: 2,
    col: 4,
    prerequisiteId: 'rare_senser',
  ),

  // --- SHOP TALENTS (Category: shop, Col: 6, 7, 8) ---
  TalentNode(
    id: 'shelf_1',
    name: '추가 진열대 I',
    description: '가게에 물건을 올릴 수 있는 슬롯이 4개로 증가합니다. (기본 2개)',
    icon: '🏪',
    cost: 150,
    category: TalentCategory.shop,
    row: 0,
    col: 6,
  ),
  TalentNode(
    id: 'shelf_2',
    name: '추가 진열대 II',
    description: '진열 슬롯이 6개로 증가합니다.',
    icon: '🏛️',
    cost: 400,
    category: TalentCategory.shop,
    row: 1,
    col: 6,
    prerequisiteId: 'shelf_1',
  ),
  TalentNode(
    id: 'sales_pitch',
    name: '세련된 협상력',
    description: '모든 보석과 장신구의 판매가가 20% 상승합니다.',
    icon: '💬',
    cost: 250,
    category: TalentCategory.shop,
    row: 0,
    col: 7,
  ),
  TalentNode(
    id: 'customer_visit',
    name: '황금 소문',
    description: '손님이 가게를 방문하는 속도가 30% 증가합니다.',
    icon: '📢',
    cost: 350,
    category: TalentCategory.shop,
    row: 1,
    col: 7,
    prerequisiteId: 'sales_pitch',
  ),
  TalentNode(
    id: 'auto_stocker',
    name: '자동 진열 조수',
    description: '진열대가 빌 때 인벤토리에 동일한 완성품이 있으면 자동으로 진열합니다.',
    icon: '🤖',
    cost: 700,
    category: TalentCategory.shop,
    row: 2,
    col: 7,
    prerequisiteId: 'customer_visit',
  ),
];
