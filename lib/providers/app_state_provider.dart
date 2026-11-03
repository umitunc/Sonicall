import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';

enum StudioCategory { songs, speech, sounds }
enum StudioMode { simple, advanced }
enum LibraryFilter { all, covers, liked, instrumental }

class AppStateProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  final AudioPlayerService audio = AudioPlayerService();

  // Navigation
  String _activeTab = 'create';
  String get activeTab => _activeTab;

  // Theme
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // System & Models
  bool _isBackendOnline = false;
  String _gpuName = 'NVIDIA GPU Tespit Ediliyor...';
  bool _modelsReady = false;
  String _activeModel = 'yue2_convrot_int8';
  String _modelsDir = '';
  List<ModelInfo> _models = [];
  Map<String, dynamic> _downloads = {};
  Timer? _downloadPollTimer;

  bool get isBackendOnline => _isBackendOnline;
  String get gpuName => _gpuName;
  bool get modelsReady => _modelsReady;
  String get activeModel => _activeModel;
  String get modelsDir => _modelsDir;
  List<ModelInfo> get models => _models;
  Map<String, dynamic> get downloads => _downloads;

  // Studio Form State
  StudioCategory _category = StudioCategory.songs;
  StudioMode _mode = StudioMode.simple;
  String _title = '';
  String _lyrics = '';
  String _style = 'Alternative Rock, Melodic Reverb';
  bool _isInstrumental = false;
  bool _isCover = false;
  String? _refAudioPath;
  String? _refAudioName;
  int _bpm = 120;
  String _selectedModel = 'YuE2 3B INT8';

  // Suno-style "More Options" settings
  double _duration = 45.0;
  bool _isAutoDuration = false;
  String _excludeStyles = '';
  String _vocalGender = 'Auto'; // 'Male', 'Female', 'Auto'
  bool _maxMode = false;
  int _weirdness = 50; // 0-100%
  int _styleInfluence = 50; // 0-100%
  int _variety = 70; // 0-100%
  bool _isMoreOptionsOpen = false;

  StudioCategory get category => _category;
  StudioMode get mode => _mode;
  String get title => _title;
  String get lyrics => _lyrics;
  String get style => _style;
  bool get isInstrumental => _isInstrumental;
  bool get isCover => _isCover;
  String? get refAudioPath => _refAudioPath;
  String? get refAudioName => _refAudioName;
  int get bpm => _bpm;
  String get selectedModel => _selectedModel;

  double get duration => _duration;
  bool get isAutoDuration => _isAutoDuration;
  String get excludeStyles => _excludeStyles;
  String get vocalGender => _vocalGender;
  bool get maxMode => _maxMode;
  int get weirdness => _weirdness;
  int get styleInfluence => _styleInfluence;
  int get variety => _variety;
  bool get isMoreOptionsOpen => _isMoreOptionsOpen;

  // Generation status
  bool _isGenerating = false;
  int _generationProgress = 0;
  String _generationMessage = '';
  String? _activeTaskId;

  bool get isGenerating => _isGenerating;
  int get generationProgress => _generationProgress;
  String get generationMessage => _generationMessage;

  // Songs & Library
  List<Song> _songs = [];
  LibraryFilter _libraryFilter = LibraryFilter.all;
  String _searchQuery = '';
  final Set<String> _extractingStems = {};
  final Set<String> _generatingSheets = {};

  List<Song> get songs => _filteredSongs();
  LibraryFilter get libraryFilter => _libraryFilter;
  String get searchQuery => _searchQuery;

  bool isExtractingStems(String songId) => _extractingStems.contains(songId);
  bool isGeneratingSheet(String songId) => _generatingSheets.contains(songId);

  AppStateProvider() {
    audio.addListener(notifyListeners);
    init();
  }

  Future<void> init() async {
    await checkBackendStatus();
    await refreshModels();
    await refreshSongs();

    // Listen to live generation progress events from WebSocket
    api.progressStream.listen((event) {
      if (event.taskId == _activeTaskId) {
        _generationProgress = event.progress;
        _generationMessage = event.message;

        if (event.status == 'completed') {
          _isGenerating = false;
          _generationProgress = 100;
          if (event.song != null) {
            _songs.insert(0, event.song!);
            audio.playSong(event.song!);
          }
          refreshSongs();
        } else if (event.status == 'error') {
          _isGenerating = false;
        }
        notifyListeners();
      }
    });
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setCategory(StudioCategory cat) {
    _category = cat;
    notifyListeners();
  }

  void setMode(StudioMode m) {
    _mode = m;
    notifyListeners();
  }

  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }

  void setLyrics(String val) {
    _lyrics = val;
    notifyListeners();
  }

  void setStyle(String val) {
    _style = val;
    notifyListeners();
  }

  void appendLyricsTag(String tag) {
    if (_lyrics.isEmpty) {
      _lyrics = '$tag\n';
    } else {
      _lyrics = '$_lyrics\n\n$tag\n';
    }
    notifyListeners();
  }

  void toggleInstrumental(bool val) {
    _isInstrumental = val;
    notifyListeners();
  }

  void setBpm(int val) {
    _bpm = val;
    notifyListeners();
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  void setDuration(double val) {
    _duration = val;
    notifyListeners();
  }

  void toggleAutoDuration(bool val) {
    _isAutoDuration = val;
    notifyListeners();
  }

  void setExcludeStyles(String val) {
    _excludeStyles = val;
    notifyListeners();
  }

  void setVocalGender(String val) {
    _vocalGender = val;
    notifyListeners();
  }

  void toggleMaxMode(bool val) {
    _maxMode = val;
    notifyListeners();
  }

  void setWeirdness(int val) {
    _weirdness = val;
    notifyListeners();
  }

  void setStyleInfluence(int val) {
    _styleInfluence = val;
    notifyListeners();
  }

  void setVariety(int val) {
    _variety = val;
    notifyListeners();
  }

  void toggleMoreOptions() {
    _isMoreOptionsOpen = !_isMoreOptionsOpen;
    notifyListeners();
  }

  void clearReferenceAudio() {
    _refAudioPath = null;
    _refAudioName = null;
    _isCover = false;
    notifyListeners();
  }

  Future<void> pickReferenceAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final uploadRes = await api.uploadAudio(file);
      if (uploadRes != null && uploadRes['success'] == true) {
        _refAudioPath = uploadRes['saved_path'];
        _refAudioName = result.first.name;
        _isCover = true;
        if (_title.isEmpty) {
          _title = '${result.first.name.split('.').first} (Cover)';
        }
        notifyListeners();
      }
    }
  }

  Future<void> checkBackendStatus() async {
    final status = await api.checkStatus();
    if (status != null) {
      _isBackendOnline = true;
      _gpuName = status['gpu'] ?? 'NVIDIA GPU';
      _modelsReady = status['models_ready'] ?? false;
      _activeModel = status['active_model'] ?? 'yue2_convrot_int8';
      _modelsDir = status['models_dir'] ?? '';
    } else {
      _isBackendOnline = false;
    }
    notifyListeners();
  }

  Future<void> refreshModels() async {
    final data = await api.fetchModels();
    if (data.containsKey('models')) {
      final List<dynamic> list = data['models'];
      _models = list.map((m) => ModelInfo.fromJson(m)).toList();
      _modelsReady = data['all_ready'] ?? false;
      _modelsDir = data['models_dir'] ?? '';
      if (data.containsKey('downloads') && data['downloads'] is Map) {
        _downloads = Map<String, dynamic>.from(data['downloads']);
      }
    }
    notifyListeners();
  }

  void _startDownloadPolling() {
    _downloadPollTimer?.cancel();
    _downloadPollTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) async {
      final statusMap = await api.fetchDownloadStatus();
      if (statusMap.isNotEmpty) {
        _downloads = statusMap;
        notifyListeners();

        bool stillDownloading = false;
        for (final v in statusMap.values) {
          if (v is Map && v['status'] == 'downloading') {
            stillDownloading = true;
            break;
          }
        }

        if (!stillDownloading) {
          timer.cancel();
          _downloadPollTimer = null;
          await refreshModels();
        }
      }
    });
  }

  Future<void> startModelDownload(String modelId) async {
    final ok = await api.startModelDownload(modelId);
    if (ok) {
      _downloads[modelId] = {
        'status': 'downloading',
        'progress': 0.0,
        'speed': 'Hazırlanıyor...',
        'message': 'İndirme başlatılıyor...',
      };
      notifyListeners();
      _startDownloadPolling();
    }
  }

  Future<void> cancelModelDownload(String modelId) async {
    await api.cancelModelDownload(modelId);
    await refreshModels();
  }

  Future<bool> importLocalModelFile(String modelId) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['safetensors', 'bin', 'ckpt', 'pt'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      final ok = await api.importLocalModel(modelId, filePath);
      if (ok) {
        await refreshModels();
        return true;
      }
    }
    return false;
  }

  Future<void> refreshSongs() async {
    _songs = await api.fetchSongs();
    notifyListeners();
  }

  Future<void> startGeneration() async {
    if (_isGenerating) return;

    final songTitle = _title.trim().isEmpty ? 'Yeni Şarkı' : _title.trim();
    _isGenerating = true;
    _generationProgress = 5;
    _generationMessage = 'Parametreler YuE2 motoruna iletiliyor...';
    notifyListeners();

    final taskId = await api.generateSong(
      title: songTitle,
      lyrics: _lyrics,
      style: _style,
      isCover: _isCover,
      isInstrumental: _isInstrumental,
      refAudioPath: _refAudioPath,
      model: _selectedModel,
      bpm: _bpm,
      duration: _duration,
      isAutoDuration: _isAutoDuration,
      excludeStyles: _excludeStyles,
      vocalGender: _vocalGender,
      maxMode: _maxMode,
      weirdness: _weirdness,
      styleInfluence: _styleInfluence,
      variety: _variety,
    );

    if (taskId != null) {
      _activeTaskId = taskId;
    } else {
      _isGenerating = false;
      _generationMessage = 'Sunucuya bağlanılamadı.';
      notifyListeners();
    }
  }

  Future<void> toggleSongLike(Song song) async {
    song.liked = !song.liked;
    notifyListeners();
    await api.toggleFavorite(song.id);
  }

  Future<void> deleteSong(Song song) async {
    _songs.removeWhere((s) => s.id == song.id);
    notifyListeners();
    await api.deleteSong(song.id);
  }

  Future<bool> extractSongStems(Song song) async {
    _extractingStems.add(song.id);
    notifyListeners();

    final res = await api.extractStems(song.id);
    _extractingStems.remove(song.id);
    if (res != null && res['success'] == true) {
      await refreshSongs();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<String?> generateSongSheetMusic(Song song) async {
    _generatingSheets.add(song.id);
    notifyListeners();

    final url = await api.generateSheetMusic(song.id);
    _generatingSheets.remove(song.id);
    if (url != null) {
      await refreshSongs();
      notifyListeners();
    }
    return url;
  }

  Future<void> openSheetMusic(Song song) async {
    if (song.sheetMusicUrl == null) {
      await generateSongSheetMusic(song);
    }
    await api.openSheetMusic(song.id);
  }

  Future<void> openStemsFolder(Song song) async {
    await api.openStemsFolder(song.id);
  }

  void setLibraryFilter(LibraryFilter filter) {
    _libraryFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> updateModelsFolder(String newPath) async {
    final success = await api.updateModelsPath(newPath);
    if (success) {
      await refreshModels();
      await checkBackendStatus();
    }
  }

  List<Song> _filteredSongs() {
    return _songs.where((song) {
      // Filter by category
      if (_libraryFilter == LibraryFilter.covers && !song.isCover) return false;
      if (_libraryFilter == LibraryFilter.liked && !song.liked) return false;
      if (_libraryFilter == LibraryFilter.instrumental && !song.isInstrumental) return false;

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = song.title.toLowerCase().contains(q);
        final matchesStyle = song.style.toLowerCase().contains(q);
        final matchesLyrics = song.lyrics.toLowerCase().contains(q);
        return matchesTitle || matchesStyle || matchesLyrics;
      }
      return true;
    }).toList();
  }
}
