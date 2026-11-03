import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sonicall/providers/app_state_provider.dart';
import 'package:sonicall/ui/studio/studio_panel.dart';

void main() {
  testWidgets('StudioPanel renders without overflow across all modes and states', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // ignore: avoid_print
      print('FLUTTER_ERROR: ${details.toString()}');
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    final appState = AppStateProvider();
    appState.setStyle('Alternative Rock, Melodic Reverb');
    appState.setSelectedModel('YuE2 Studio BF16');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                StudioPanel(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial State Check
    expect(find.text('Basit'), findsOneWidget);
    expect(find.text('Gelişmiş'), findsOneWidget);
    expect(find.text('MÜZİK TARZI & ENSTRÜMANLAR'), findsOneWidget);
    expect(find.text('Kütüphane & Geçmiş'), findsOneWidget);

    // 2. Open More Options Panel (Advanced settings accordion)
    appState.toggleMoreOptions();
    await tester.pumpAndSettle();

    // 3. Switch to Advanced Mode
    appState.setMode(StudioMode.advanced);
    await tester.pumpAndSettle();

    // 4. Switch Model to INT8
    appState.setSelectedModel('YuE2 3B INT8 ConvRot');
    await tester.pumpAndSettle();

    // 5. Test categories
    appState.setCategory(StudioCategory.speech);
    await tester.pumpAndSettle();

    appState.setCategory(StudioCategory.sounds);
    await tester.pumpAndSettle();

    appState.setCategory(StudioCategory.songs);
    await tester.pumpAndSettle();

    // 6. Test instrumental toggle
    appState.toggleInstrumental(true);
    await tester.pumpAndSettle();

    appState.toggleInstrumental(false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
