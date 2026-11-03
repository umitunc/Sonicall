import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/style_model.dart';
import '../models/song_model.dart';

class StyleService extends ChangeNotifier {
  static const String _storageKey = 'sonicall_style_history_v1';
  static final StyleService instance = StyleService._internal();

  factory StyleService() => instance;
  StyleService._internal() {
    _initPresets();
    _loadFromStorage();
  }

  final List<StyleItem> _presets = [];
  final List<StyleItem> _history = [];
  bool _isLoaded = false;

  List<StyleItem> get presets => List.unmodifiable(_presets);
  List<StyleItem> get history => List.unmodifiable(_history);
  bool get isLoaded => _isLoaded;

  // Curated Preset Library
  void _initPresets() {
    _presets.clear();
    final rawPresets = [
      {
        'id': 'preset_alt_rock',
        'title': 'Alternative Rock',
        'category': 'Rock',
        'prompt': 'Alternative rock, overdrive crunch guitars, passionate male lead vocals, driving bassline, acoustic drums, dynamic chorus',
      },
      {
        'id': 'preset_synthwave',
        'title': 'Synthwave 80s',
        'category': 'Elektronik',
        'prompt': '80s synthwave, vintage analog Juno arpeggios, nostalgic gated reverb snare, glowing neon synth bass, lush dreamy pads',
      },
      {
        'id': 'preset_pop',
        'title': 'Modern Pop',
        'category': 'Pop',
        'prompt': 'Modern pop, catchy danceable rhythm, polished vocal hooks, bright acoustic guitar strumming, radio-friendly drop',
      },
      {
        'id': 'preset_anadolu_rock',
        'title': 'Anadolu Rock & Bağlama',
        'category': 'Geleneksel & Rock',
        'prompt': '70s Anatolian psychedelic rock, fuzz-pedal elektro bağlama solo, dynamic groove drums, gritty vintage Turkish vocal',
      },
      {
        'id': 'preset_akustik',
        'title': 'Akustik & Melodik',
        'category': 'Akustik',
        'prompt': 'Melodic acoustic ballad, warm fingerstyle guitar, intimate close-mic vocal, gentle cello backing, emotional atmosphere',
      },
      {
        'id': 'preset_oriental_ney',
        'title': 'Oryantal & Mistik Ney',
        'category': 'Geleneksel & Mistik',
        'prompt': 'Mystic Middle Eastern ambient, authentic wooden ney melody, soft kanun arpeggios, deep framedrum darbuka pulse',
      },
      {
        'id': 'preset_cinematic',
        'title': 'Epik Sinematik',
        'category': 'Sinematik',
        'prompt': 'Epic cinematic soundtrack, Hans Zimmer inspired brass swells, pounding taiko percussion, soaring string ensemble',
      },
      {
        'id': 'preset_lofi',
        'title': 'Lofi Hip-Hop & Beats',
        'category': 'Hip-Hop',
        'prompt': 'Chill lofi hip-hop beat, subtle vinyl dust crackle, smooth jazz Rhodes piano, relaxed boom bap drums, warm upright bass',
      },
      {
        'id': 'preset_cyberpunk',
        'title': 'Cyberpunk Dark EDM',
        'category': 'Elektronik',
        'prompt': 'Cyberpunk darksynth, heavy distorted reese bass, industrial glitch percussion, 140 BPM aggressive driving energy',
      },
      {
        'id': 'preset_metal',
        'title': 'Modern Heavy Metal',
        'category': 'Rock',
        'prompt': 'Modern heavy metal, downtuned 7-string chug guitars, double-bass blast beats, powerful gritty vocal delivery, guitar solo',
      },
      {
        'id': 'preset_rnb',
        'title': 'R&B & Soul Groove',
        'category': 'R&B & Caz',
        'prompt': '90s slow jam R&B, silky smooth falsetto vocal harmonies, vintage Rhodes chords, deep 808 sub bass, emotional groove',
      },
      {
        'id': 'preset_deephouse',
        'title': 'Deep Melodic House',
        'category': 'Elektronik',
        'prompt': 'Melodic deep house, hypnotic 4-on-the-floor kick, warm analog synth bassline, ethereal vocal chops, club ambiance',
      },
      {
        'id': 'preset_bossa',
        'title': 'Caz & Bossa Nova',
        'category': 'R&B & Caz',
        'prompt': 'Breezy bossa nova, warm nylon acoustic chords, gentle brushes on snare drum, smooth melodic saxophone, lounge vibe',
      },
      {
        'id': 'preset_piano_violin',
        'title': 'Neoklasik Piyano & Keman',
        'category': 'Akustik',
        'prompt': 'Neoclassical acoustic duet, emotional grand piano melody, weeping solo violin, subtle room reverb, contemplative mood',
      },
    ];

    for (final p in rawPresets) {
      _presets.add(StyleItem(
        id: p['id']!,
        title: p['title']!,
        category: p['category']!,
        prompt: p['prompt']!,
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
        isPreset: true,
      ));
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _history.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _history.add(StyleItem.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading style history: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('Error saving style history: $e');
    }
  }

  /// Automatically records a style to history without user intervention
  /// (Called automatically when generating songs or picking styles).
  void recordStyle({
    required String prompt,
    String? title,
    String? category,
  }) {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return;

    // Determine readable title if not supplied
    String finalTitle = title?.trim() ?? '';
    if (finalTitle.isEmpty) {
      final firstPart = cleanPrompt.split(',').first.trim();
      finalTitle = firstPart.length > 28 ? '${firstPart.substring(0, 26)}...' : firstPart;
    }

    // Check if this exact prompt already exists in history
    final existingIndex = _history.indexWhere(
      (h) => h.prompt.trim().toLowerCase() == cleanPrompt.toLowerCase(),
    );

    if (existingIndex >= 0) {
      // Move to top and update timestamp & count
      final existing = _history.removeAt(existingIndex);
      _history.insert(
        0,
        existing.copyWith(
          title: finalTitle.isNotEmpty && existing.title.startsWith('Untitled') ? finalTitle : existing.title,
          timestamp: DateTime.now(),
          useCount: existing.useCount + 1,
        ),
      );
    } else {
      // Prepend new history item
      final newItem = StyleItem(
        id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
        title: finalTitle.isNotEmpty ? finalTitle : 'Untitled Style',
        prompt: cleanPrompt,
        category: category ?? 'Özel',
        timestamp: DateTime.now(),
        isPreset: false,
        useCount: 1,
      );
      _history.insert(0, newItem);

      // Keep max 50 recent styles in history
      if (_history.length > 50) {
        _history.removeLast();
      }
    }

    notifyListeners();
    _saveToStorage();
  }

  /// Explicitly save a named custom style
  void saveCustomStyle({
    required String prompt,
    required String title,
    String category = 'Özel',
  }) {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return;

    final newItem = StyleItem(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'Kayıtlı Tarz' : title.trim(),
      prompt: cleanPrompt,
      category: category,
      timestamp: DateTime.now(),
      isFavorite: true,
      isPreset: false,
      useCount: 1,
    );

    // Remove if already exists with same prompt
    _history.removeWhere((h) => h.prompt.trim().toLowerCase() == cleanPrompt.toLowerCase());
    _history.insert(0, newItem);

    notifyListeners();
    _saveToStorage();
  }

  /// Delete a style from history
  void deleteStyle(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveToStorage();
  }

  /// Toggle favorite status of a style
  void toggleFavorite(String id) {
    final index = _history.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final current = _history[index];
      _history[index] = current.copyWith(isFavorite: !current.isFavorite);
      notifyListeners();
      _saveToStorage();
    }
  }

  /// Populate history automatically from existing songs in the library
  void syncFromSongs(List<Song> songs) {
    bool changed = false;
    for (final song in songs) {
      if (song.style.trim().isEmpty) continue;
      final clean = song.style.trim();
      final existsInHistory = _history.any((h) => h.prompt.toLowerCase() == clean.toLowerCase());
      if (!existsInHistory) {
        _history.add(StyleItem(
          id: 'song_${song.id}',
          title: song.title.isNotEmpty ? song.title : 'Şarkı Tarzı',
          prompt: clean,
          category: 'Kütüphaneden',
          timestamp: DateTime.tryParse(song.createdAt) ?? DateTime.now(),
          isPreset: false,
        ));
        changed = true;
      }
    }

    if (changed) {
      // Sort history by timestamp descending
      _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
      _saveToStorage();
    }
  }
}
