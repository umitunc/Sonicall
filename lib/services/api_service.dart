import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/song_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5824';
  static const String wsUrl = 'ws://127.0.0.1:5824/ws/generation';

  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  final StreamController<GenerationProgressEvent> _progressController =
      StreamController<GenerationProgressEvent>.broadcast();

  Stream<GenerationProgressEvent> get progressStream => _progressController.stream;

  ApiService() {
    _connectWebSocket();
  }

  void _connectWebSocket() {
    if (_isDisposed) return;
    try {
      _reconnectTimer?.cancel();
      _wsChannel?.sink.close();
    } catch (_) {}

    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsChannel = channel;

      // Handle connection error gracefully without unhandled VM exceptions
      channel.ready.then((_) {
        // Successfully connected to backend WebSocket
      }).catchError((_) {
        _scheduleReconnect();
      });

      channel.stream.listen(
        (data) {
          try {
            final jsonMap = jsonDecode(data);
            if (jsonMap is Map && jsonMap['type'] == 'ping') {
              return;
            }
            final event = GenerationProgressEvent.fromJson(jsonMap);
            _progressController.add(event);
          } catch (_) {}
        },
        onError: (_) {
          _scheduleReconnect();
        },
        onDone: () {
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _connectWebSocket();
    });
  }

  Future<Map<String, dynamic>?> checkStatus() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/status')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> fetchDiagnostics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/diagnostic')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> runDiagnostics() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/diagnostic/run'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> fetchModels() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/models'));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  Future<bool> startModelDownload(String modelId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/models/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model_id': modelId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchDownloadStatus([String? modelId]) async {
    try {
      final uri = modelId != null
          ? Uri.parse('$baseUrl/api/models/download-status?model_id=$modelId')
          : Uri.parse('$baseUrl/api/models/download-status');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  Future<bool> cancelModelDownload(String modelId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/models/cancel-download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model_id': modelId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchTaskById(String taskId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/tasks/$taskId')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> fetchAllTasks() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/tasks')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  Future<bool> importLocalModel(String modelId, String filePath) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/models/import-local'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model_id': modelId, 'path': filePath}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateModelsPath(String path) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/models/path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'path': path}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Song>> fetchSongs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/songs'));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(res.bodyBytes));
        return list.map((item) => Song.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> extractStems(String songId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/songs/$songId/stems'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<String?> generateSheetMusic(String songId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/songs/$songId/sheet-music'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['sheet_music_url'];
      }
    } catch (_) {}
    return null;
  }

  Future<bool> openSheetMusic(String songId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/songs/$songId/open-sheet'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openStemsFolder(String songId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/songs/$songId/open-stems'),
        headers: {'Content-Type': 'application/json'},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> generateSong({
    required String title,
    required String lyrics,
    required String style,
    required bool isCover,
    required bool isInstrumental,
    String? refAudioPath,
    required String model,
    int bpm = 120,
    int? customSeed,
    double duration = 45.0,
    bool isAutoDuration = false,
    String excludeStyles = '',
    String vocalGender = 'Auto',
    bool maxMode = false,
    int weirdness = 50,
    int styleInfluence = 50,
    int variety = 70,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'lyrics': lyrics,
          'style': style,
          'is_cover': isCover,
          'is_instrumental': isInstrumental,
          'ref_audio_path': refAudioPath,
          'model': model,
          'bpm': bpm,
          'custom_seed': customSeed,
          'duration': duration,
          'is_auto_duration': isAutoDuration,
          'exclude_styles': excludeStyles,
          'vocal_gender': vocalGender,
          'max_mode': maxMode,
          'weirdness': weirdness,
          'style_influence': styleInfluence,
          'variety': variety,
        }),
      );
      if (res.statusCode == 200) {
        final map = jsonDecode(utf8.decode(res.bodyBytes));
        return map['task_id'];
      }
    } catch (_) {}
    return null;
  }

  Future<bool> toggleFavorite(String songId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/songs/$songId/favorite'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSong(String songId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/api/songs/$songId'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadAudio(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> analyzeAudio(String filePath) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/audio/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_path': filePath}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> startMicRecording() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/record/start'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> stopMicRecording() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/record/stop'));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMicRecordingStatus() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/record/status'));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> masterVocal(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/vocal/master'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> openVocalMasterFolder() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/vocal/open-folder'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    _progressController.close();
  }
}
