import 'package:flutter_test/flutter_test.dart';
import 'package:otters_ocean_jewelry/main.dart';

void main() {
  testWidgets('App title screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OceanJewelryApp());

    // Verify that the title screen renders
    expect(find.text("Otter's Ocean Jewelry"), findsOneWidget);
    expect(find.text("게임 시작하기"), findsOneWidget);
  });
}
