import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/instrument_model.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../services/style_service.dart';

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

  // Instrument Transform State
  InstrumentModel _selectedInstrument = InstrumentCatalog.getDefault();
  String? _instrumentRefAudioPath;
  String? _instrumentRefAudioName;
  double _instrumentAudioDuration = 30.0;
  int _instrumentBpm = 120;
  int? _detectedBpm;
  bool _isDetectingBpm = false;
  bool _isRecordingMic = false;
  double _micRecordElapsedSec = 0.0;
  Timer? _micRecordTimer;
  String _instrumentTitle = '';
  bool _isCustomInstrumentTitle = false;
  String _instrumentPrompt = '';
  String _instrumentNegativePrompt = '';
  bool _pureSoloIsolation = true;

  InstrumentModel get selectedInstrument => _selectedInstrument;
  String? get instrumentRefAudioPath => _instrumentRefAudioPath;
  String? get instrumentRefAudioName => _instrumentRefAudioName;
  double get instrumentAudioDuration => _instrumentAudioDuration;
  int get instrumentBpm => _instrumentBpm;
  int? get detectedBpm => _detectedBpm;
  bool get isDetectingBpm => _isDetectingBpm;
  bool get isRecordingMic => _isRecordingMic;
  double get micRecordElapsedSec => _micRecordElapsedSec;
  String get instrumentTitle {
    if (_isCustomInstrumentTitle && _instrumentTitle.trim().isNotEmpty) {
      return _instrumentTitle.trim();
    }
    final instShort = _selectedInstrument.name.split('(').first.trim();
    if (_instrumentRefAudioName != null && _instrumentRefAudioName!.isNotEmpty) {
      final base = _instrumentRefAudioName!.split('.').first;
      return '$base - $instShort Solo';
    }
    return '';
  }
  String get instrumentPrompt =>
      _instrumentPrompt.isNotEmpty ? _instrumentPrompt : _selectedInstrument.promptStyle;
  String get instrumentNegativePrompt =>
      _instrumentNegativePrompt.isNotEmpty ? _instrumentNegativePrompt : _selectedInstrument.negativeStyle;
  bool get pureSoloIsolation => _pureSoloIsolation;

  // ==========================================
  // Vocal Mix & Mastering State
  // ==========================================
  String? _vocalMasterRefPath;
  String? _vocalMasterRefName;
  double _vocalMasterDuration = 0.0;
  String _vocalMasterTitle = '';

  // Step 1: De-Reverb & De-Noise
  bool _vocalEnableDereverb = true;
  String _vocalDereverbModel = 'anvuew/dereverb_mel_band_roformer';
  double _vocalDereverbIntensity = 0.85; // 0.0 - 1.0
  double _vocalDenoiseThresholdDb = -38.0; // dB

  // Step 2: Vocal Enhancement
  bool _vocalEnableEnhancement = true;
  String _vocalEnhancerModel = 'ResembleAI/resemble-enhance';
  double _vocalParallelBlend = 0.45; // 45% (Golden ratio: 40-50%)
  double _vocalAirBoost = 0.60;
  double _vocalBodyWarmth = 0.50;
  bool _vocalDeEsserEnabled = true;

  // Step 3: DAW Studio Master
  bool _vocalEnableDawMaster = true;
  double _vocalLowCutHz = 85.0; // 80 - 100 Hz
  double _vocalBoxyMudCutHz = 380.0; // 300 - 500 Hz
  double _vocalBoxyMudGainDb = -3.5; // -3 to -5 dB
  double _vocalCompressorRatio = 4.0; // 4:1
  double _vocalCompressorMakeupDb = 3.5;
  String _vocalStudioAmbienceType = 'Plate Reverb';
  double _vocalAmbienceWetMix = 0.14; // 14%

  // Vocal Master Process State
  bool _isVocalMasterProcessing = false;
  double _vocalMasterProgress = 0.0;
  String _vocalMasterMessage = '';
  Map<String, dynamic>? _lastVocalMasterResult;
  String? _vocalMasterResultAudioUrl;

  // Getters for Vocal Master
  String? get vocalMasterRefPath => _vocalMasterRefPath;
  String? get vocalMasterRefName => _vocalMasterRefName;
  double get vocalMasterDuration => _vocalMasterDuration;
  String get vocalMasterTitle => _vocalMasterTitle.isNotEmpty ? _vocalMasterTitle : (_vocalMasterRefName != null ? '${_vocalMasterRefName!.split('.').first} (Studio Master)' : 'Studio Vocal Master');
  bool get vocalEnableDereverb => _vocalEnableDereverb;
  String get vocalDereverbModel => _vocalDereverbModel;
  double get vocalDereverbIntensity => _vocalDereverbIntensity;
  double get vocalDenoiseThresholdDb => _vocalDenoiseThresholdDb;
  bool get vocalEnableEnhancement => _vocalEnableEnhancement;
  String get vocalEnhancerModel => _vocalEnhancerModel;
  double get vocalParallelBlend => _vocalParallelBlend;
  double get vocalAirBoost => _vocalAirBoost;
  double get vocalBodyWarmth => _vocalBodyWarmth;
  bool get vocalDeEsserEnabled => _vocalDeEsserEnabled;
  bool get vocalEnableDawMaster => _vocalEnableDawMaster;
  double get vocalLowCutHz => _vocalLowCutHz;
  double get vocalBoxyMudCutHz => _vocalBoxyMudCutHz;
  double get vocalBoxyMudGainDb => _vocalBoxyMudGainDb;
  double get vocalCompressorRatio => _vocalCompressorRatio;
  double get vocalCompressorMakeupDb => _vocalCompressorMakeupDb;
  String get vocalStudioAmbienceType => _vocalStudioAmbienceType;
  double get vocalAmbienceWetMix => _vocalAmbienceWetMix;
  bool get isVocalMasterProcessing => _isVocalMasterProcessing;
  double get vocalMasterProgress => _vocalMasterProgress;
  String get vocalMasterMessage => _vocalMasterMessage;
  Map<String, dynamic>? get lastVocalMasterResult => _lastVocalMasterResult;
  String? get vocalMasterResultAudioUrl => _vocalMasterResultAudioUrl;

  // Generation status
  // Multi-task generation queue & new songs
  final List<GenerationTask> _activeTasks = [];
  final Set<String> _newSongIds = {};
  Timer? _taskPollTimer;

  List<GenerationTask> get activeTasks => List.unmodifiable(_activeTasks);
  bool get isGenerating => _activeTasks.isNotEmpty;
  int get generationProgress => _activeTasks.isEmpty ? 0 : _activeTasks.first.progress;
  String get generationMessage => _activeTasks.isEmpty ? '' : _activeTasks.first.message;

  void cancelTask(String taskId) {
    _activeTasks.removeWhere((t) => t.taskId == taskId);
    if (_activeTasks.isEmpty) {
      _taskPollTimer?.cancel();
      _taskPollTimer = null;
    }
    notifyListeners();
  }

  void clearStuckTasks() {
    _activeTasks.clear();
    _taskPollTimer?.cancel();
    _taskPollTimer = null;
    notifyListeners();
  }

  void _ensureTaskPollTimer() {
    if (_taskPollTimer != null && _taskPollTimer!.isActive) return;
    _taskPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_activeTasks.isEmpty) {
        timer.cancel();
        _taskPollTimer = null;
        return;
      }
      await _checkAndReconcileTasks();
    });
  }

  Future<void> _checkAndReconcileTasks() async {
    try {
      final latestSongs = await api.fetchSongs();
      if (latestSongs.isNotEmpty) {
        _songs = latestSongs;
        StyleService.instance.syncFromSongs(_songs);
      }

      final serverTasks = await api.fetchAllTasks();
      final toRemove = <GenerationTask>[];

      for (final task in _activeTasks) {
        // 1. NEVER match by title! Matching by title causes existing songs to prematurely kill the active task.
        // ONLY match by exact taskId when taskId is not a tempId and exists in _songs.
        if (!task.taskId.startsWith('temp_')) {
          final foundSong = _songs.where((s) => s.id == task.taskId).firstOrNull;
          if (foundSong != null) {
            toRemove.add(task);
            _newSongIds.add(foundSong.id);
            continue;
          }
        }

        // 2. Check task status from server API
        if (serverTasks.containsKey(task.taskId)) {
          final sInfo = serverTasks[task.taskId];
          if (sInfo is Map) {
            final st = sInfo['status'];
            final prog = sInfo['progress'] is num ? (sInfo['progress'] as num).toInt() : task.progress;
            final msg = sInfo['message'] ?? task.message;

            task.progress = prog;
            task.message = msg;
            task.status = st ?? task.status;

            if (st == 'completed') {
              // Ensure song is safely in _songs before removing the task card
              if (sInfo['song'] is Map<String, dynamic>) {
                final song = Song.fromJson(sInfo['song'] as Map<String, dynamic>);
                _songs.removeWhere((s) => s.id == song.id);
                _songs.insert(0, song);
                _newSongIds.add(song.id);
              }
              toRemove.add(task);
            } else if (st == 'error') {
              task.status = 'error';
            }
          }
        }
      }

      if (toRemove.isNotEmpty) {
        _activeTasks.removeWhere((t) => toRemove.contains(t));
        if (_activeTasks.isEmpty) {
          _taskPollTimer?.cancel();
          _taskPollTimer = null;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  bool isSongNew(String songId) => _newSongIds.contains(songId);
  void markSongRead(String songId) {
    if (_newSongIds.remove(songId)) {
      notifyListeners();
    }
  }

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
    await _loadPreferences();
    await checkBackendStatus();
    await refreshModels();
    await refreshSongs();

    // Listen to live generation progress events from WebSocket
    api.progressStream.listen((event) {
      GenerationTask? task;
      try {
        task = _activeTasks.firstWhere((t) => t.taskId == event.taskId);
      } catch (_) {}

      // Fallback: If task was just started with tempId, link it to this event
      if (task == null) {
        try {
          task = _activeTasks.firstWhere((t) => t.taskId.startsWith('temp_'));
          if (task != null) {
            task.taskId = event.taskId;
          }
        } catch (_) {}
      }

      if (task != null) {
        task.progress = event.progress;
        task.status = event.status;
        task.message = event.message;

        if (event.status == 'completed') {
          // Seamless transition: insert song first before removing task card
          if (event.song != null) {
            _songs.removeWhere((s) => s.id == event.song!.id);
            _songs.insert(0, event.song!);
            _newSongIds.add(event.song!.id);
            audio.playSong(event.song!);
          }
          _activeTasks.remove(task);
          refreshSongs();
        } else if (event.status == 'error') {
          task.status = 'error';
          Future.delayed(const Duration(seconds: 4), () {
            _activeTasks.remove(task);
            notifyListeners();
          });
        }
      } else if (event.status == 'completed') {
        if (event.song != null) {
          _songs.removeWhere((s) => s.id == event.song!.id);
          _songs.insert(0, event.song!);
          _newSongIds.add(event.song!.id);
        }
        refreshSongs();
      }
      notifyListeners();
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModel = prefs.getString('pref_selected_model');
      if (savedModel != null && savedModel.isNotEmpty) {
        _selectedModel = savedModel;
      }
      final savedMode = prefs.getString('pref_studio_mode');
      if (savedMode != null) {
        _mode = savedMode == 'advanced' ? StudioMode.advanced : StudioMode.simple;
      }
      final savedVocalGender = prefs.getString('pref_vocal_gender');
      if (savedVocalGender != null) {
        _vocalGender = savedVocalGender;
      }
      final savedDuration = prefs.getDouble('pref_duration');
      if (savedDuration != null && savedDuration > 0) {
        _duration = savedDuration;
      }
      final savedAutoDuration = prefs.getBool('pref_is_auto_duration');
      if (savedAutoDuration != null) {
        _isAutoDuration = savedAutoDuration;
      }
      final savedMaxMode = prefs.getBool('pref_max_mode');
      if (savedMaxMode != null) {
        _maxMode = savedMaxMode;
      }
      final savedWeirdness = prefs.getInt('pref_weirdness');
      if (savedWeirdness != null) {
        _weirdness = savedWeirdness;
      }
      final savedStyleInfluence = prefs.getInt('pref_style_influence');
      if (savedStyleInfluence != null) {
        _styleInfluence = savedStyleInfluence;
      }
      final savedVariety = prefs.getInt('pref_variety');
      if (savedVariety != null) {
        _variety = savedVariety;
      }
      final savedTheme = prefs.getString('pref_theme_mode');
      if (savedTheme != null) {
        _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AppStateProvider] Error loading preferences: $e');
    }
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('pref_theme_mode', _themeMode == ThemeMode.light ? 'light' : 'dark'));
  }

  void setCategory(StudioCategory cat) {
    _category = cat;
    notifyListeners();
  }

  void setMode(StudioMode m) {
    _mode = m;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('pref_studio_mode', m == StudioMode.advanced ? 'advanced' : 'simple'));
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
    SharedPreferences.getInstance().then((p) => p.setString('pref_selected_model', model));
  }

  void setDuration(double val) {
    _duration = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setDouble('pref_duration', val));
  }

  void toggleAutoDuration(bool val) {
    _isAutoDuration = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('pref_is_auto_duration', val));
  }

  void setExcludeStyles(String val) {
    _excludeStyles = val;
    notifyListeners();
  }

  void setVocalGender(String val) {
    _vocalGender = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('pref_vocal_gender', val));
  }

  void toggleMaxMode(bool val) {
    _maxMode = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool('pref_max_mode', val));
  }

  void setWeirdness(int val) {
    _weirdness = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt('pref_weirdness', val));
  }

  void setStyleInfluence(int val) {
    _styleInfluence = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt('pref_style_influence', val));
  }

  void setVariety(int val) {
    _variety = val;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt('pref_variety', val));
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

  // ==========================================
  // Instrument Transform Methods
  // ==========================================

  void setInstrument(InstrumentModel inst) {
    _selectedInstrument = inst;
    _instrumentPrompt = inst.promptStyle;
    _instrumentNegativePrompt = inst.negativeStyle;
    _updateInstrumentAutoTitle();
    notifyListeners();
  }

  void setInstrumentPrompt(String val) {
    _instrumentPrompt = val;
    notifyListeners();
  }

  void setInstrumentNegativePrompt(String val) {
    _instrumentNegativePrompt = val;
    notifyListeners();
  }

  void resetInstrumentPromptsToDefault() {
    _instrumentPrompt = _selectedInstrument.promptStyle;
    _instrumentNegativePrompt = _selectedInstrument.negativeStyle;
    notifyListeners();
  }

  void setInstrumentBpm(int bpm) {
    _instrumentBpm = bpm;
    notifyListeners();
  }

  void setInstrumentTitle(String title) {
    _instrumentTitle = title;
    _isCustomInstrumentTitle = title.trim().isNotEmpty;
    notifyListeners();
  }

  void _updateInstrumentAutoTitle() {
    if (_isCustomInstrumentTitle) return;
    _instrumentTitle = '';
  }

  void clearInstrumentAudio() {
    _instrumentRefAudioPath = null;
    _instrumentRefAudioName = null;
    _instrumentAudioDuration = 30.0;
    _detectedBpm = null;
    _instrumentBpm = 120;
    _isCustomInstrumentTitle = false;
    _instrumentTitle = '';
    notifyListeners();
  }

  Future<void> pickInstrumentAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      _isDetectingBpm = true;
      notifyListeners();

      final file = File(result.first.path!);
      final uploadRes = await api.uploadAudio(file);

      _isDetectingBpm = false;
      if (uploadRes != null && uploadRes['success'] == true) {
        _instrumentRefAudioPath = uploadRes['saved_path'];
        _instrumentRefAudioName = result.first.name;
        _instrumentAudioDuration = (uploadRes['duration'] is num)
            ? (uploadRes['duration'] as num).toDouble()
            : 30.0;
        _detectedBpm = (uploadRes['bpm'] is num)
            ? (uploadRes['bpm'] as num).toInt()
            : 120;
        _instrumentBpm = _detectedBpm!;
        _isCustomInstrumentTitle = false;
        _updateInstrumentAutoTitle();
        notifyListeners();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> startMicRecording() async {
    if (_isRecordingMic) return;
    final ok = await api.startMicRecording();
    if (ok) {
      _isRecordingMic = true;
      _micRecordElapsedSec = 0.0;
      _micRecordTimer?.cancel();
      _micRecordTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        _micRecordElapsedSec += 0.2;
        notifyListeners();
      });
      notifyListeners();
    }
  }

  Future<void> stopMicRecording() async {
    if (!_isRecordingMic) return;
    _micRecordTimer?.cancel();
    _micRecordTimer = null;
    _isRecordingMic = false;
    _isDetectingBpm = true;
    notifyListeners();

    final res = await api.stopMicRecording();
    _isDetectingBpm = false;
    if (res != null && res['success'] == true) {
      _instrumentRefAudioPath = res['saved_path'];
      _instrumentRefAudioName = res['filename'];
      _instrumentAudioDuration = (res['duration'] is num)
          ? (res['duration'] as num).toDouble()
          : _micRecordElapsedSec;
      _detectedBpm = (res['bpm'] is num) ? (res['bpm'] as num).toInt() : 120;
      _instrumentBpm = _detectedBpm!;
      _isCustomInstrumentTitle = false;
      _updateInstrumentAutoTitle();
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> startInstrumentTransform() async {
    if (_instrumentRefAudioPath == null || _instrumentRefAudioPath!.isEmpty) {
      return;
    }

    final instTurkishName = _selectedInstrument.name.split('(').first.trim();
    final engName = _selectedInstrument.englishName.trim();
    final songTitle = instrumentTitle.isNotEmpty
        ? instrumentTitle
        : (_instrumentRefAudioName != null
            ? '${_instrumentRefAudioName!.split('.').first} - $instTurkishName Solo'
            : '$instTurkishName Solo');
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // High-precision English tag prompt for YuE2 conditioning:
    final specificStyle = _instrumentPrompt.trim().isNotEmpty
        ? _instrumentPrompt.trim()
        : _selectedInstrument.promptStyle;
    final effectivePrompt =
        'genre: solo instrumental, style: solo $engName, instrument: $engName, '
        'pure acoustic $engName solo, $specificStyle, '
        'single player unaccompanied solo, dry acoustic studio isolation booth, '
        'pristine acoustic resonance, zero vocals, no voice, no singer, no choir, no speech, no other instruments';

    final specificNegative = _instrumentNegativePrompt.trim().isNotEmpty
        ? _instrumentNegativePrompt.trim()
        : _selectedInstrument.negativeStyle;
    final effectiveNegative =
        'vocals, singing, singing voice, speech, voice, vocal, singer, humming, chanting, choir, spoken word, talking, '
        'backing band, drums, rhythm section, percussion, electric bass, chords, second instrument, $specificNegative';

    final task = GenerationTask(
      taskId: tempId,
      title: songTitle,
      style: effectivePrompt,
      model: _selectedModel,
      isCover: true,
      isInstrumental: true,
      progress: 5,
      status: 'processing',
      message: '$instTurkishName tek enstrüman solo izolasyonu işleniyor...',
    );
    _activeTasks.insert(0, task);
    notifyListeners();

    final taskId = await api.generateSong(
      title: songTitle,
      lyrics: '', // Empty lyrics ensures YuE2 never attempts vocalization
      style: effectivePrompt,
      isCover: true,
      isInstrumental: true,
      refAudioPath: _instrumentRefAudioPath,
      model: _selectedModel,
      bpm: _instrumentBpm,
      duration: _instrumentAudioDuration,
      isAutoDuration: true,
      excludeStyles: effectiveNegative,
      vocalGender: 'None',
      maxMode: _maxMode,
      weirdness: 20,
      styleInfluence: 95,
      variety: 25,
    );

    if (taskId != null) {
      task.taskId = taskId;
      _ensureTaskPollTimer();
    } else {
      task.status = 'error';
      task.message = 'Sunucuya bağlanılamadı.';
      Future.delayed(const Duration(seconds: 4), () {
        _activeTasks.remove(task);
        notifyListeners();
      });
    }
    notifyListeners();
  }

  // ==========================================
  // Vocal Mix & Mastering Methods
  // ==========================================
  void setVocalMasterTitle(String title) {
    _vocalMasterTitle = title;
    notifyListeners();
  }

  void setVocalEnableDereverb(bool val) {
    _vocalEnableDereverb = val;
    notifyListeners();
  }

  void setVocalDereverbModel(String val) {
    _vocalDereverbModel = val;
    notifyListeners();
  }

  void setVocalDereverbIntensity(double val) {
    _vocalDereverbIntensity = val;
    notifyListeners();
  }

  void setVocalDenoiseThresholdDb(double val) {
    _vocalDenoiseThresholdDb = val;
    notifyListeners();
  }

  void setVocalEnableEnhancement(bool val) {
    _vocalEnableEnhancement = val;
    notifyListeners();
  }

  void setVocalEnhancerModel(String val) {
    _vocalEnhancerModel = val;
    notifyListeners();
  }

  void setVocalParallelBlend(double val) {
    _vocalParallelBlend = val;
    notifyListeners();
  }

  void setVocalAirBoost(double val) {
    _vocalAirBoost = val;
    notifyListeners();
  }

  void setVocalBodyWarmth(double val) {
    _vocalBodyWarmth = val;
    notifyListeners();
  }

  void setVocalDeEsserEnabled(bool val) {
    _vocalDeEsserEnabled = val;
    notifyListeners();
  }

  void setVocalEnableDawMaster(bool val) {
    _vocalEnableDawMaster = val;
    notifyListeners();
  }

  void setVocalLowCutHz(double val) {
    _vocalLowCutHz = val;
    notifyListeners();
  }

  void setVocalBoxyMudCutHz(double val) {
    _vocalBoxyMudCutHz = val;
    notifyListeners();
  }

  void setVocalBoxyMudGainDb(double val) {
    _vocalBoxyMudGainDb = val;
    notifyListeners();
  }

  void setVocalCompressorRatio(double val) {
    _vocalCompressorRatio = val;
    notifyListeners();
  }

  void setVocalCompressorMakeupDb(double val) {
    _vocalCompressorMakeupDb = val;
    notifyListeners();
  }

  void setVocalStudioAmbienceType(String val) {
    _vocalStudioAmbienceType = val;
    notifyListeners();
  }

  void setVocalAmbienceWetMix(double val) {
    _vocalAmbienceWetMix = val;
    notifyListeners();
  }

  void clearVocalMasterAudio() {
    _vocalMasterRefPath = null;
    _vocalMasterRefName = null;
    _vocalMasterDuration = 0.0;
    _lastVocalMasterResult = null;
    _vocalMasterResultAudioUrl = null;
    notifyListeners();
  }

  Future<void> pickVocalMasterAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'flac'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final file = File(result.first.path!);
      final uploadRes = await api.uploadAudio(file);
      if (uploadRes != null && uploadRes['success'] == true) {
        _vocalMasterRefPath = uploadRes['saved_path'];
        _vocalMasterRefName = result.first.name;
        _vocalMasterDuration = (uploadRes['duration'] is num)
            ? (uploadRes['duration'] as num).toDouble()
            : 30.0;
        _vocalMasterTitle = '${result.first.name.split('.').first} (Studio Master)';
        _lastVocalMasterResult = null;
        _vocalMasterResultAudioUrl = null;
        notifyListeners();
      }
    }
  }

  void setVocalMasterFromSong(Song song) {
    _vocalMasterRefPath = song.audioUrl;
    _vocalMasterRefName = '${song.title}.wav';
    _vocalMasterDuration = song.durationSeconds.toDouble();
    _vocalMasterTitle = '${song.title} (Studio Master)';
    _lastVocalMasterResult = null;
    _vocalMasterResultAudioUrl = null;
    _activeTab = 'vocal_master';
    notifyListeners();
  }

  Future<void> processVocalMastering() async {
    if (_vocalMasterRefPath == null || _isVocalMasterProcessing) return;

    _isVocalMasterProcessing = true;
    _vocalMasterProgress = 0.15;
    _vocalMasterMessage = 'Adım 1: Mel-Band RoFormer ile oda yankısı ve dip gürültüsü siliniyor...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    _vocalMasterProgress = 0.45;
    _vocalMasterMessage = 'Adım 2: Resemble-Enhance ile gövde ve Air frekansları sentezleniyor (Paralel %${(_vocalParallelBlend * 100).toInt()})...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));
    _vocalMasterProgress = 0.75;
    _vocalMasterMessage = 'Adım 3: Temizlik EQ (${_vocalLowCutHz.toInt()}Hz Low-cut & ${_vocalBoxyMudCutHz.toInt()}Hz Boxy Dip) + 4:1 VCA Kompresör + $_vocalStudioAmbienceType uygulanıyor...';
    notifyListeners();

    final payload = {
      'file_path': _vocalMasterRefPath,
      'title': vocalMasterTitle,
      'save_to_library': true,
      'enable_dereverb': _vocalEnableDereverb,
      'dereverb_intensity': _vocalDereverbIntensity,
      'denoise_threshold_db': _vocalDenoiseThresholdDb,
      'dereverb_model': _vocalDereverbModel,
      'enable_enhancement': _vocalEnableEnhancement,
      'parallel_blend': _vocalParallelBlend,
      'air_boost': _vocalAirBoost,
      'body_warmth': _vocalBodyWarmth,
      'de_esser_enabled': _vocalDeEsserEnabled,
      'enhancer_model': _vocalEnhancerModel,
      'enable_daw_master': _vocalEnableDawMaster,
      'low_cut_hz': _vocalLowCutHz,
      'boxy_mud_cut_hz': _vocalBoxyMudCutHz,
      'boxy_mud_gain_db': _vocalBoxyMudGainDb,
      'compressor_ratio': _vocalCompressorRatio,
      'compressor_makeup_db': _vocalCompressorMakeupDb,
      'studio_ambience_type': _vocalStudioAmbienceType,
      'ambience_wet_mix': _vocalAmbienceWetMix,
    };

    final res = await api.masterVocal(payload);
    _isVocalMasterProcessing = false;

    if (res != null && res['success'] == true) {
      _vocalMasterProgress = 1.0;
      _vocalMasterMessage = 'Vokal stüdyo mastering tamamlandı! (${res['processing_time_sec']}s)';
      _lastVocalMasterResult = res;
      _vocalMasterResultAudioUrl = res['audio_url'];
      // Refresh song list so it appears in library
      await refreshSongs();
      notifyListeners();
    } else {
      _vocalMasterProgress = 0.0;
      _vocalMasterMessage = 'Hata: Vokal mastering gerçekleştirilemedi.';
      notifyListeners();
    }
  }

  Future<void> openVocalFolder() async {
    await api.openVocalMasterFolder();
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
      allowedExtensions: ['safetensors', 'bin', 'ckpt', 'pt', 'pth', 'SAFETENSORS', 'BIN', 'CKPT', 'PT'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      final ok = await api.importLocalModel(modelId, filePath);
      if (ok) {
        _startDownloadPolling();
        await refreshModels();
        return true;
      }
    }
    return false;
  }

  Future<void> pickNewModelsDir() async {
    final selectedDir = await FilePicker.getDirectoryPath();
    if (selectedDir != null && selectedDir.isNotEmpty) {
      final ok = await api.updateModelsPath(selectedDir);
      if (ok) {
        _modelsDir = selectedDir;
        await refreshModels();
        notifyListeners();
      }
    }
  }

  Future<void> refreshSongs() async {
    await _checkAndReconcileTasks();
  }

  Future<void> startGeneration() async {
    final songTitle = _title.trim().isEmpty ? 'Yeni Şarkı' : _title.trim();
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Auto-record style to history directly without user having to press save
    if (_style.trim().isNotEmpty) {
      StyleService.instance.recordStyle(
        prompt: _style,
        title: songTitle,
      );
    }

    final task = GenerationTask(
      taskId: tempId,
      title: songTitle,
      style: _style,
      model: _selectedModel,
      isCover: _isCover,
      isInstrumental: _isInstrumental,
      progress: 5,
      status: 'processing',
      message: 'Parametreler YuE2 motoruna iletiliyor...',
    );
    _activeTasks.insert(0, task);
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
      task.taskId = taskId;
      _ensureTaskPollTimer();
    } else {
      task.status = 'error';
      task.message = 'Sunucuya bağlanılamadı.';
      Future.delayed(const Duration(seconds: 4), () {
        _activeTasks.remove(task);
        notifyListeners();
      });
    }
    notifyListeners();
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
