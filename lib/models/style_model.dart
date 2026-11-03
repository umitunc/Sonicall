class StyleItem {
  final String id;
  final String title;
  final String prompt;
  final String category;
  final DateTime timestamp;
  final bool isFavorite;
  final bool isPreset;
  final int useCount;

  const StyleItem({
    required this.id,
    required this.title,
    required this.prompt,
    this.category = 'Genel',
    required this.timestamp,
    this.isFavorite = false,
    this.isPreset = false,
    this.useCount = 1,
  });

  StyleItem copyWith({
    String? id,
    String? title,
    String? prompt,
    String? category,
    DateTime? timestamp,
    bool? isFavorite,
    bool? isPreset,
    int? useCount,
  }) {
    return StyleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      isPreset: isPreset ?? this.isPreset,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
      'isPreset': isPreset,
      'useCount': useCount,
    };
  }

  factory StyleItem.fromJson(Map<String, dynamic> json) {
    return StyleItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'İsimsiz Tarz',
      prompt: json['prompt'] ?? '',
      category: json['category'] ?? 'Genel',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
      isPreset: json['isPreset'] ?? false,
      useCount: json['useCount'] ?? 1,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) {
      return 'şimdi';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}dk';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}sa';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}g';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}h';
    } else {
      return '${(diff.inDays / 30).floor()}a';
    }
  }
}
