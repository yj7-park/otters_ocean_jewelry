# 🌊 수달의 바다 보석상 (Otter's Ocean Jewelry) 개발 완료 보고서

"Budgie's Bug Shop"의 유쾌하고 중독성 있는 게임 루프를 바탕으로, 해저 테마와 세련된 디자인을 결합한 **Flutter Web** 기반의 게임 개발을 성공적으로 마쳤습니다.

---

## 🛠️ 기술적 구현 사항 (Technical Achievements)

1.  **현대적인 상태 관리 (Riverpod v3 Notifier)**
    *   글로벌 게임 상태(`GameState`), 인벤토리(원자재/장신구), 진열 매대 슬롯, 해금된 특성 연구 등을 관리합니다.
    *   Riverpod 2.0+ 및 3.0+의 권장 방식인 `Notifier`를 도입하여 보일러플레이트를 줄이고 컴파일 안전성을 확보했습니다.
2.  **동적 해저 백그라운드 (Custom-drawn Particles & Light rays)**
    *   `CustomPainter`와 `AnimationController`를 결합하여 수면에서 부드럽게 비치는 햇살 레이저와 랜덤하게 솟아오르는 기포(Bubble)들을 60FPS 벡터 드로잉으로 연출했습니다.
3.  **액티브 잠수 미니게임 (Interactive 2D Canvas Game)**
    *   마우스 및 터치 드래그 물리 엔진(속도 댐핑 및 타겟 완충 연동)으로 수달 캐릭터를 제어합니다.
    *   **장애물**: 해파리(바운싱 및 O2 데미지), 성게(바닥 고정형 데미지).
    *   **아이템**: 조개껍데기, 바다유리, 진주, 산호 채집. 가방 한도(10개) 초과 시 알림.
    *   **성공 조건**: 산소가 고갈되기 전에 화면 상단(수면)으로 돌아오면 채집된 아이템이 인벤토리에 안전하게 가산됩니다.
4.  **세밀 타이밍 세공소 (Precision Crafting Mini-game)**
    *   수집한 원자재로 6가지 고부가가치 장신구를 세공합니다.
    *   슬라이더의 최적 지점(Perfect, Rare, Normal)에 맞춰 멈추는 리듬 게이지 미니게임을 도입하여 품질에 따라 판매가에 최대 **2.0배 배율**이 적용되도록 세공의 조작감을 살렸습니다.
5.  **자동화 매장 경영 및 손님 NPC (NPC Shopping Loop)**
    *   문어, 거북이, 꽃게 등 아기자기한 바다 생물 손님 NPC들이 주기적으로 상점에 걸어 들어옵니다.
    *   진열대에 세공품이 올려져 있으면 구매를 진행하며 골드를 획득하고, 동적인 말풍선 대화 및 🪙 골드 상승 플로팅 애니메이션 효과를 보여줍니다.
6.  **RPG 스타일 특성 연구 (RPG Talent Tree)**
    *   **잠수(산소통, 속도, 더블 채집, 렌즈)**, **세공(판정범위, 특급세공, 재료감소)**, **경영(진열대 확장, 판매가 상승, 자동 진열)**에 연관된 10개의 특성 노드를 지원합니다.

---

## 📂 파일 구조 및 컴포넌트

*   [item_model.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/models/item_model.dart): 원자재 및 장신구 레시피 정의
*   [talent_model.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/models/talent_model.dart): 특성 연구 노드 정보
*   [game_state.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/models/game_state.dart): Riverpod Notifier를 활용한 전역 비즈니스 로직
*   [underwater_background.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/widgets/underwater_background.dart): 애니메이션 캔버스 배경화면
*   [diving_game_widget.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/game/diving_game_widget.dart): 2D 잠수 게임 화면 및 수달 물리 연동
*   [shop_view.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/ui/shop_view.dart): 상점 매대 진열 및 쇼핑 NPC 이벤트 화면
*   [crafting_view.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/ui/crafting_view.dart): 세공 제작소 및 타이밍 미니게임 화면
*   [talent_tree_view.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/ui/talent_tree_view.dart): 특성 해금 연구 화면
*   [main_game_screen.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/ui/main_game_screen.dart): 3개의 메인 탭 및 풀스크롤 게임 오버레이 라우팅
*   [main.dart](file:///C:/Workspace/otters_ocean_jewelry/lib/main.dart): 앱 초기 시작 타이틀 스크린 구성

---

## 🧪 빌드 및 검증 완료 (Validation)

-   **정적 분석**: `flutter analyze` 결과 에러 개수 **0개**로 안정성 확인 완료.
-   **웹 컴파일 빌드**: `flutter build web` 명령어로 프로덕션 빌드 완료 (`✓ Built build\web`).
