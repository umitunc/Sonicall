import 'package:flutter_test/flutter_test.dart';
import 'package:sonicall/models/song_model.dart';

void main() {
  group('Sonicall Model & Data Tests', () {
    test('Song model deserialization', () {
      final json = {
        'id': 'test_123',
        'title': 'Mevsimler',
        'style': 'Rock',
        'lyrics': '[Intro]\nGitar sesi',
        'is_cover': true,
        'is_instrumental': false,
        'model': 'YuE2 3B INT8 + SheetSage2',
        'duration_seconds': 45,
        'duration_formatted': '00:45',
        'audio_url': '/output/songs/test_123.wav',
        'cover_url': '/output/covers/test_123.svg',
        'liked': true,
        'created_at': '2026-11-03 03:00:00',
        'date_group': 'Bugün',
      };

      final song = Song.fromJson(json);

      expect(song.id, 'test_123');
      expect(song.title, 'Mevsimler');
      expect(song.isCover, true);
      expect(song.durationSeconds, 45);
      expect(song.liked, true);
    });

    test('ModelInfo deserialization', () {
      final json = {
        'id': 'yue2_convrot_int8',
        'name': 'YuE2 3B INT8 ConvRot',
        'type': 'Checkpoint',
        'installed': true,
        'path': r'D:\Works\2026\AI FILMMAKING\ComfyUI\models\checkpoints\yue2_convrot_int8.safetensors',
        'size': '3.42 GB',
        'vram_required': '~6 GB VRAM',
        'speed': '⚡⚡⚡ Çok Hızlı',
        'recommended': true,
      };

      final model = ModelInfo.fromJson(json);

      expect(model.id, 'yue2_convrot_int8');
      expect(model.installed, true);
      expect(model.recommended, true);
    });
  });
}
