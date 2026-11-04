import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song_model.dart';
import 'api_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Song? _currentSong;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.85;
  bool _isLooping = false;
  bool _isDragging = false;

  Song? get currentSong => _currentSong;
  PlayerState get state => _state;
  bool get isPlaying => _state == PlayerState.playing;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isLooping => _isLooping;
  bool get isDragging => _isDragging;

  AudioPlayerService() {
    _init();
  }

  void _init() {
    _player.onPlayerStateChanged.listen((s) {
      _state = s;
      notifyListeners();
    });

    _player.onPositionChanged.listen((p) {
      if (!_isDragging) {
        _position = p;
        notifyListeners();
      }
    });

    _player.onDurationChanged.listen((d) {
      if (d > Duration.zero) {
        _duration = d;
        notifyListeners();
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (_isLooping && _currentSong != null) {
        seek(Duration.zero);
        resume();
      } else {
        _state = PlayerState.completed;
        _position = Duration.zero;
        notifyListeners();
      }
    });

    _player.setVolume(_volume);
  }

  Future<void> playSong(Song song) async {
    _currentSong = song;
    _position = Duration.zero;
    _duration = Duration(seconds: song.durationSeconds);
    notifyListeners();

    try {
      await _player.stop();

      Source source;
      String rawUrl = song.audioUrl;

      // On desktop, check if the file exists directly on local disk for instant playback
      if (!kIsWeb) {
        String cleanPath = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
        File localFile = File(cleanPath);

        // Also check if relative to project root
        if (!localFile.existsSync()) {
          localFile = File('D:/Works/2026/Sonicall/$cleanPath');
        }

        if (localFile.existsSync()) {
          source = DeviceFileSource(localFile.path);
        } else {
          String fullUrl = rawUrl.startsWith('/') ? '${ApiService.baseUrl}$rawUrl' : rawUrl;
          source = UrlSource(fullUrl);
        }
      } else {
        String fullUrl = rawUrl.startsWith('/') ? '${ApiService.baseUrl}$rawUrl' : rawUrl;
        source = UrlSource(fullUrl);
      }

      await _player.play(source);
    } catch (e) {
      print('Audio playback error: $e');
    }
    notifyListeners();
  }

  Future<void> playPathOrUrl(String pathOrUrl, {String? title}) async {
    _position = Duration.zero;
    _currentSong = Song(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Vokal Önizleme',
      style: 'Vocal Mastering Preview',
      lyrics: '',
      isCover: false,
      isInstrumental: false,
      model: 'Vocal Mastering',
      durationSeconds: 30,
      durationFormatted: '00:30',
      audioUrl: pathOrUrl,
      coverUrl: '',
      createdAt: '',
      dateGroup: 'Bugün',
    );
    notifyListeners();

    try {
      await _player.stop();
      Source source;
      if (!kIsWeb) {
        String cleanPath = pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl;
        File localFile = File(cleanPath);
        if (!localFile.existsSync()) {
          localFile = File('D:/Works/2026/Sonicall/$cleanPath');
        }
        if (localFile.existsSync()) {
          source = DeviceFileSource(localFile.path);
        } else {
          String fullUrl = pathOrUrl.startsWith('/') ? '${ApiService.baseUrl}$pathOrUrl' : pathOrUrl;
          source = UrlSource(fullUrl);
        }
      } else {
        String fullUrl = pathOrUrl.startsWith('/') ? '${ApiService.baseUrl}$pathOrUrl' : pathOrUrl;
        source = UrlSource(fullUrl);
      }
      await _player.play(source);
    } catch (e) {
      print('playPathOrUrl error: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    try {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else {
        if (_currentSong != null) {
          if (_state == PlayerState.completed) {
            await seek(Duration.zero);
          }
          await _player.resume();
        }
      }
    } catch (e) {
      print('togglePlayPause error: $e');
    }
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.resume();
    notifyListeners();
  }

  void startDragging() {
    _isDragging = true;
  }

  void updateDragging(Duration pos) {
    _position = pos;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    _isDragging = false;
    _position = position;
    notifyListeners();
    try {
      await _player.seek(position);
    } catch (e) {
      print('seek error: $e');
    }
  }

  Future<void> seekRelative(int seconds) async {
    final maxSec = _duration.inSeconds > 0 ? _duration.inSeconds : (_currentSong?.durationSeconds ?? 60);
    final targetSec = (_position.inSeconds + seconds).clamp(0, maxSec);
    await seek(Duration(seconds: targetSec));
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    notifyListeners();
    await _player.setVolume(_volume);
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
