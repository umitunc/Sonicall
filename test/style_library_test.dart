import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonicall/models/song_model.dart';
import 'package:sonicall/services/style_service.dart';
import 'package:sonicall/ui/dialogs/style_library_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StyleService Auto-History Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('StyleService has curated presets and auto-records history', () {
      final service = StyleService.instance;
      expect(service.presets.isNotEmpty, true);

      // Record a new style automatically
      service.recordStyle(
        prompt: 'Alternative rock, driving bass, raw acoustic drums',
        title: 'Gece Rüzgarı',
      );

      expect(service.history.isNotEmpty, true);
      expect(service.history.first.prompt, contains('Alternative rock'));
      expect(service.history.first.title, 'Gece Rüzgarı');

      // Recording the same style again moves it to top and updates count
      service.recordStyle(
        prompt: 'Alternative rock, driving bass, raw acoustic drums',
        title: 'Gece Rüzgarı 2',
      );

      expect(service.history.first.useCount, 2);
    });

    test('StyleService syncs history from existing library songs automatically', () {
      final service = StyleService.instance;
      final mockSongs = [
        Song(
          id: 'song_test_1',
          title: 'Kelebek Etkisi',
          style: 'Alternative hip-hop, light agile tenor lead, gang-vocals',
          lyrics: '',
          isCover: false,
          isInstrumental: false,
          model: 'YuE2 3B INT8',
          durationSeconds: 45,
          durationFormatted: '00:45',
          audioUrl: '/audio.wav',
          coverUrl: '/cover.svg',
          createdAt: DateTime.now().toIso8601String(),
          dateGroup: 'Bugün',
        ),
      ];

      service.syncFromSongs(mockSongs);
      expect(service.history.any((h) => h.title == 'Kelebek Etkisi'), true);
    });
  });

  testWidgets('StyleLibraryDialog renders search, tabs, and styles without overflow', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String selectedStyle = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StyleLibraryDialog(
            currentStyleText: 'Synthwave 80s',
            onStyleSelected: (val) {
              selectedStyle = val;
            },
          ),
        ),
      ),
    );

    // Verify search bar and tabs
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
    expect(find.text('Favoriler'), findsOneWidget);

    // Switch to Presets tab
    await tester.tap(find.byIcon(Icons.library_music_rounded));
    await tester.pumpAndSettle();

    // Verify presets are displayed
    expect(find.text('Alternative Rock'), findsOneWidget);
    expect(find.text('Synthwave 80s'), findsOneWidget);

    // Tap on a preset to select it
    await tester.tap(find.text('Alternative Rock'));
    await tester.pumpAndSettle();

    expect(selectedStyle, contains('Alternative rock'));
    expect(tester.takeException(), isNull);
  });
}
