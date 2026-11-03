import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sonicall/providers/app_state_provider.dart';
import 'package:sonicall/ui/dialogs/model_selector_dialog.dart';

void main() {
  testWidgets('ModelSelectorDialog renders without overflow and displays technical specs', (WidgetTester tester) async {
    // Set a typical desktop test window size (1280x800)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppStateProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ModelSelectorDialog(),
            ),
          ),
        ),
      ),
    );

    // Ensure dialog content is displayed (only installed/available models are rendered)
    expect(find.text('Yapay Zeka Müzik Modeli'), findsOneWidget);
    expect(find.text('YuE2 3B INT8 ConvRot'), findsOneWidget);
    expect(find.text('~6 GB VRAM'), findsOneWidget);
    expect(find.text('Model Hub'), findsOneWidget);

    // Verify there are no overflow errors
    expect(tester.takeException(), isNull);
  });
}
