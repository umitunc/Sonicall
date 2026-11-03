class Song {
  final String id;
  final String title;
  final String style;
  final String lyrics;
  final bool isCover;
  final bool isInstrumental;
  final String model;
  final int durationSeconds;
  final String durationFormatted;
  final String audioUrl;
  final String coverUrl;
  bool liked;
  final String createdAt;
  final String dateGroup;
  final Map<String, String>? stems;
  final String? sheetMusicUrl;

  Song({
    required this.id,
    required this.title,
    required this.style,
    required this.lyrics,
    required this.isCover,
    required this.isInstrumental,
    required this.model,
    required this.durationSeconds,
    required this.durationFormatted,
    required this.audioUrl,
    required this.coverUrl,
    this.liked = false,
    required this.createdAt,
    required this.dateGroup,
    this.stems,
    this.sheetMusicUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    Map<String, String>? stemsMap;
    if (json['stems'] != null && json['stems'] is Map) {
      stemsMap = Map<String, String>.from(json['stems']);
    }

    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      style: json['style'] ?? '',
      lyrics: json['lyrics'] ?? '',
      isCover: json['is_cover'] ?? false,
      isInstrumental: json['is_instrumental'] ?? false,
      model: json['model'] ?? 'YuE2 3B',
      durationSeconds: json['duration_seconds'] ?? 45,
      durationFormatted: json['duration_formatted'] ?? '00:45',
      audioUrl: json['audio_url'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      liked: json['liked'] ?? false,
      createdAt: json['created_at'] ?? '',
      dateGroup: json['date_group'] ?? 'Bugün',
      stems: stemsMap,
      sheetMusicUrl: json['sheet_music_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'style': style,
      'lyrics': lyrics,
      'is_cover': isCover,
      'is_instrumental': isInstrumental,
      'model': model,
      'duration_seconds': durationSeconds,
      'duration_formatted': durationFormatted,
      'audio_url': audioUrl,
      'cover_url': coverUrl,
      'liked': liked,
      'created_at': createdAt,
      'date_group': dateGroup,
      'stems': stems,
      'sheet_music_url': sheetMusicUrl,
    };
  }
}

class ModelInfo {
  final String id;
  final String name;
  final String type;
  final bool installed;
  final String path;
  final String size;
  final String vramRequired;
  final String speed;
  final bool recommended;

  ModelInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.installed,
    required this.path,
    required this.size,
    required this.vramRequired,
    required this.speed,
    required this.recommended,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      installed: json['installed'] ?? false,
      path: json['path'] ?? '',
      size: json['size'] ?? '0 B',
      vramRequired: json['vram_required'] ?? '',
      speed: json['speed'] ?? '',
      recommended: json['recommended'] ?? false,
    );
  }
}

class GenerationProgressEvent {
  final String taskId;
  final String status;
  final int progress;
  final String message;
  final Song? song;

  GenerationProgressEvent({
    required this.taskId,
    required this.status,
    required this.progress,
    required this.message,
    this.song,
  });

  factory GenerationProgressEvent.fromJson(Map<String, dynamic> json) {
    return GenerationProgressEvent(
      taskId: json['task_id'] ?? '',
      status: json['status'] ?? 'processing',
      progress: json['progress'] ?? 0,
      message: json['message'] ?? '',
      song: json['song'] != null ? Song.fromJson(json['song']) : null,
    );
  }
}

class GenerationTask {
  String taskId;
  final String title;
  final String style;
  final String model;
  final bool isCover;
  final bool isInstrumental;
  int progress;
  String status; // 'queued', 'processing', 'completed', 'error'
  String message;
  final DateTime createdAt;

  GenerationTask({
    required this.taskId,
    required this.title,
    required this.style,
    required this.model,
    required this.isCover,
    required this.isInstrumental,
    this.progress = 5,
    this.status = 'processing',
    this.message = 'Sıraya alındı...',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
