import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonicall/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
  });

  group('Preference Persistence Tests', () {
    testWidgets('Selected model and preferences are loaded from SharedPreferences on init', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'pref_selected_model': 'YuE2 Studio BF16',
        'pref_studio_mode': 'advanced',
        'pref_vocal_gender': 'Female',
        'pref_duration': 180.0,
        'pref_is_auto_duration': true,
        'pref_max_mode': true,
        'pref_weirdness': 75,
        'pref_style_influence': 60,
        'pref_variety': 85,
        'pref_theme_mode': 'light',
      });

      final provider = AppStateProvider();
      await provider.init();

      expect(provider.selectedModel, 'YuE2 Studio BF16');
      expect(provider.mode, StudioMode.advanced);
      expect(provider.vocalGender, 'Female');
      expect(provider.duration, 180.0);
      expect(provider.isAutoDuration, true);
      expect(provider.maxMode, true);
      expect(provider.weirdness, 75);
      expect(provider.styleInfluence, 60);
      expect(provider.variety, 85);
    });

    testWidgets('Updating selectedModel writes to SharedPreferences', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = AppStateProvider();
      await provider.init();

      provider.setSelectedModel('YuE2 3B INT8 ConvRot');
      expect(provider.selectedModel, 'YuE2 3B INT8 ConvRot');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_selected_model'), 'YuE2 3B INT8 ConvRot');
    });
  });
}
