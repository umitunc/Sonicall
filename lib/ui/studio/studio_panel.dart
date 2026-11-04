import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/style_library_dialog.dart';
import '../widgets/top_model_selector_bar.dart';

class StudioPanel extends StatefulWidget {
  const StudioPanel({super.key});

  @override
  State<StudioPanel> createState() => _StudioPanelState();
}

class _StudioPanelState extends State<StudioPanel> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();

  final List<String> _genrePills = [
    'Alternative Rock',
    'Synthwave 80s',
    'Modern Pop',
    'Akustik Melodik',
    'Oriental & Saz',
    'Epic Cinematic',
    'Lofi Hip-Hop',
    'Cyberpunk EDM',
    'Heavy Metal',
    'R&B Soul'
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _styleController.text = state.style;
    _lyricsController.text = state.lyrics;
    _titleController.text = state.title;
    _excludeController.text = state.excludeStyles;

    _titleController.addListener(() => state.setTitle(_titleController.text));
    _lyricsController.addListener(() => state.setLyrics(_lyricsController.text));
    _styleController.addListener(() => state.setStyle(_styleController.text));
    _excludeController.addListener(() => state.setExcludeStyles(_excludeController.text));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _styleController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
    final text = _lyricsController.text;
    final selection = _lyricsController.selection;
    final newText = text.replaceRange(
      selection.start < 0 ? text.length : selection.start,
      selection.end < 0 ? text.length : selection.end,
      '$tag\n',
    );
    _lyricsController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start < 0 ? text.length : selection.start) + tag.length + 1,
      ),
    );
  }

  String _formatDuration(double sec) {
    final m = sec.toInt() ~/ 60;
    final s = sec.toInt() % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Top Category Tabs: Songs | Speech | Sounds
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                _buildCategoryTab(
                  context,
                  label: '🎵 Şarkı',
                  selected: state.category == StudioCategory.songs,
                  onTap: () => state.setCategory(StudioCategory.songs),
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  context,
                  label: '🎻 Enstrüman',
                  selected: false,
                  onTap: () => state.setActiveTab('instrument'),
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  context,
                  label: '🎙️ Konuşma',
                  selected: state.category == StudioCategory.speech,
                  onTap: () => state.setCategory(StudioCategory.speech),
                ),
                const SizedBox(width: 6),
                _buildCategoryTab(
                  context,
                  label: '🔊 Efekt',
                  selected: state.category == StudioCategory.sounds,
                  onTap: () => state.setCategory(StudioCategory.sounds),
                ),
              ],
            ),
          ),

          // Top Compact Model Selector Bar (Side-by-side concise cards)
          const TopModelSelectorBar(),

          // Scrollable Form Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // Mode Toggle Header
                Row(
                  children: [
                    // Simple / Advanced Switch
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          _buildModeChip(
                            label: 'Basit',
                            selected: state.mode == StudioMode.simple,
                            onTap: () => state.setMode(StudioMode.simple),
                          ),
                          _buildModeChip(
                            label: 'Gelişmiş',
                            selected: state.mode == StudioMode.advanced,
                            onTap: () => state.setMode(StudioMode.advanced),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quick Action Chips: + Audio (Cover), 🎙️ Ses Kaydet, + Voice, + Inspo
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildActionChip(
                        icon: Icons.audio_file_rounded,
                        label: state.isCover ? 'Cover: ${state.refAudioName}' : '+ Audio (Cover)',
                        isActive: state.isCover,
                        onTap: () => state.pickReferenceAudio(),
                      ),
                      if (state.isCover) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: 'Cover Referansını Kaldır',
                          onPressed: () => state.clearReferenceAudio(),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Mikrofondan Ses Kaydetme Butonu (Enstrümana Dönüştür sayfasındaki gibi)
                      _buildActionChip(
                        icon: state.isStudioRecordingMic ? Icons.stop_rounded : Icons.mic_rounded,
                        label: state.isStudioRecordingMic
                            ? '⏹️ Kaydı Durdur (${_formatDuration(state.studioMicRecordElapsedSec)})'
                            : '🎙️ + Ses Kaydet',
                        isActive: state.isStudioRecordingMic,
                        activeColor: const Color(0xFFEF4444),
                        onTap: () {
                          if (state.isStudioRecordingMic) {
                            state.stopStudioMicRecording();
                          } else {
                            state.startStudioMicRecording();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.piano_rounded,
                        label: '🎻 Enstrümana Dönüştür',
                        isActive: false,
                        onTap: () => state.setActiveTab('instrument'),
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.mic_external_on_rounded,
                        label: '+ Vokal',
                        isActive: false,
                        onTap: () {
                          _styleController.text += ', Güçlü Kadın Vokal, Reverb';
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.auto_awesome_rounded,
                        label: '+ İlham',
                        isActive: false,
                        onTap: () {
                          _styleController.text = '80s Synthwave, Nostalgic Synth, Driving Bass, Analog Drums';
                          _titleController.text = 'Gece Sürüşü';
                          _lyricsController.text = '[Intro]\n(Sentezleyici dalgaları ve 120 BPM tempo)\n\n[Verse 1]\nNeon ışıklar altında bir şehir\nGecenin içinde kaybolan anılar...';
                        },
                      ),
                    ],
                  ),
                ),

                // Canlı Mikrofon Kayıt Durumu Paneli
                if (state.isStudioRecordingMic) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mikrofon Kaydediliyor: ${_formatDuration(state.studioMicRecordElapsedSec)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Melodiyi veya şarkıyı mikrofona seslendirin veya ıslık çalın.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => state.stopStudioMicRecording(),
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Kaydı Durdur ve Cover Olarak Kullan',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cover Referans Sesi Kartı (Ses Önizleme Oynatıcısı ile Birlikte)
                if (state.isCover && state.refAudioPath != null) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final isCurrentTrack = state.audio.currentSong?.audioUrl == state.refAudioPath;
                      final isPlaying = isCurrentTrack && state.audio.isPlaying;
                      final currentPosSec = isCurrentTrack ? state.audio.position.inMilliseconds / 1000.0 : 0.0;
                      final totalDurSec = state.refAudioDuration > 0 ? state.refAudioDuration : 1.0;
                      final progressRatio = (currentPosSec / totalDurSec).clamp(0.0, 1.0);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPlaying ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            width: isPlaying ? 1.8 : 1.0,
                          ),
                          boxShadow: isPlaying
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.20),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Play / Pause Önizleme Butonu
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (state.refAudioPath != null) {
                                        if (isCurrentTrack) {
                                          state.audio.togglePlayPause();
                                        } else {
                                          state.audio.playPathOrUrl(
                                            state.refAudioPath!,
                                            title: state.refAudioName ?? 'Cover Referans Ses',
                                            durationSeconds: state.refAudioDuration,
                                          );
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: isPlaying
                                            ? const LinearGradient(
                                                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : LinearGradient(
                                                colors: isDark
                                                    ? [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8)]
                                                    : [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: isPlaying ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E40AF)),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              state.refAudioName ?? 'Cover Referansı',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF3B82F6)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (isPlaying) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Önizleme Çalıyor',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            isCurrentTrack
                                                ? '${_formatDuration(currentPosSec)} / ${_formatDuration(totalDurSec)} | ${state.bpm} BPM'
                                                : 'Süre: ${_formatDuration(state.refAudioDuration)} | ${state.bpm} BPM',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Önizleme Durdur Butonu
                                if (isCurrentTrack && (isPlaying || state.audio.position > Duration.zero)) ...[
                                  IconButton(
                                    icon: const Icon(Icons.stop_rounded, size: 18),
                                    tooltip: 'Önizlemeyi Durdur',
                                    color: Colors.redAccent,
                                    onPressed: () => state.audio.stop(),
                                  ),
                                ],
                                // Mikrofonla Tekrar Kaydet
                                IconButton(
                                  icon: const Icon(Icons.mic_rounded, size: 18),
                                  tooltip: 'Mikrofonla Yeniden Kaydet',
                                  color: const Color(0xFFEC4899),
                                  onPressed: () {
                                    if (isCurrentTrack) state.audio.stop();
                                    state.startStudioMicRecording();
                                  },
                                ),
                                // Dosya Değiştir
                                IconButton(
                                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                                  tooltip: 'Başka Dosya Seç',
                                  color: const Color(0xFF3B82F6),
                                  onPressed: () {
                                    if (isCurrentTrack) state.audio.stop();
                                    state.pickReferenceAudio();
                                  },
                                ),
                                // Referansı Temizle
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  tooltip: 'Cover Referansını Kaldır',
                                  onPressed: () => state.clearReferenceAudio(),
                                ),
                              ],
                            ),
                            // İlerleme Çubuğu (Scrubber Slider)
                            if (isCurrentTrack) ...[
                              const SizedBox(height: 4),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: const Color(0xFF3B82F6),
                                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                                  thumbColor: const Color(0xFF3B82F6),
                                ),
                                child: Slider(
                                  value: progressRatio,
                                  onChanged: (val) {
                                    final targetMs = (val * totalDurSec * 1000).toInt();
                                    state.audio.seek(Duration(milliseconds: targetMs));
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.auto_mode_rounded, size: 13, color: Color(0xFF3B82F6)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'SheetSage2 melodi transferi aktif. Referans sesin melodisi birebir çıkarılarak yeni tarzda söylenecek.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 18),

                // Title Input
                Text(
                  'ŞARKI BAŞLIĞI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Şarkı adı (ör. Mevsimler, Gece Sürüşü)',
                  ),
                ),

                const SizedBox(height: 18),

                // Lyrics Header & Instrumental Switch
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ŞARKI SÖZLERİ (LYRICS)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enstrümantal',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: state.isInstrumental,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => state.toggleInstrumental(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tag helpers
                if (!state.isInstrumental) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTagHelper('[Intro]'),
                        _buildTagHelper('[Verse 1]'),
                        _buildTagHelper('[Chorus]'),
                        _buildTagHelper('[Verse 2]'),
                        _buildTagHelper('[Bridge]'),
                        _buildTagHelper('[Solo]'),
                        _buildTagHelper('[Outro]'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lyricsController,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Sözleri buraya yazın veya yapıştırın...\n[Intro]\n[Verse 1]\n[Chorus]',
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.music_note_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Enstrümantal Mod Seçildi (Vokal söylenmeyecek)',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Style of Music Header (with Suno-style Library & History Trigger)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MÜZİK TARZI & ENSTRÜMANLAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Müzik tarzı kütüphanesini ve otomatik geçmişi aç',
                      child: InkWell(
                        onTap: () {
                          StyleLibraryDialog.show(
                            context,
                            currentStyleText: _styleController.text,
                            onStyleSelected: (newStyle) {
                              setState(() {
                                _styleController.text = newStyle;
                              });
                              state.setStyle(newStyle);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.library_music_rounded, size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Kütüphane & Geçmiş',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _styleController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Synthwave, 80s drums, energetic electric guitar, melancholic piano...',
                  ),
                ),
                const SizedBox(height: 8),

                // Genre Pills & Explore Button
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Highlighted Library & History Pill
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        StyleLibraryDialog.show(
                          context,
                          currentStyleText: _styleController.text,
                          onStyleSelected: (newStyle) {
                            setState(() {
                              _styleController.text = newStyle;
                            });
                            state.setStyle(newStyle);
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5E3A), Color(0xFFFF2A68)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Tarzları Keşfet',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ..._genrePills.map((genre) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (_styleController.text.isEmpty) {
                            _styleController.text = genre;
                          } else if (!_styleController.text.contains(genre)) {
                            _styleController.text += ', $genre';
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            genre,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // SUNO-STYLE "MORE OPTIONS" PANEL
                _buildSunoMoreOptions(context, state, isDark, borderColor),

                // Advanced Controls (BPM)
                if (state.mode == StudioMode.advanced) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Tempo: ${state.bpm} BPM',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: state.bpm.toDouble(),
                          min: 60,
                          max: 180,
                          divisions: 24,
                          activeColor: AppColors.primary,
                          onChanged: (val) => state.setBpm(val.toInt()),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Create Button Bar with Live Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: panelBg,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Column(
              children: [
                if (state.isGenerating) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.generationMessage,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${state.generationProgress}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: state.generationProgress / 100.0,
                          backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ],

                // Action Create Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => state.startGeneration(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              state.isCover ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state.isGenerating
                                  ? '+ Sıraya Ekle (${state.activeTasks.length} Kuyrukta)'
                                  : (state.isCover
                                      ? 'Cover Şarkı Üret (${state.isAutoDuration ? "Auto" : _formatDuration(state.duration)})'
                                      : 'Şarkı Üret (${state.isAutoDuration ? "Auto" : _formatDuration(state.duration)})'),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunoMoreOptions(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    final cardBg = isDark ? const Color(0xFF16161A) : const Color(0xFFF3F4F6);
    const pinkAccent = Color(0xFFEE0979);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Header Toggle
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => state.toggleMoreOptions(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    state.isMoreOptionsOpen ? Icons.arrow_drop_down_rounded : Icons.arrow_right_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'More Options (İnce Ayarlar)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.isAutoDuration ? 'Süre: Auto' : 'Süre: ${_formatDuration(state.duration)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (state.isMoreOptionsOpen) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Exclude styles
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0E0E10) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _excludeController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Exclude styles (ör. screaming, noisy, low quality)',
                        prefixIcon: Icon(Icons.call_split_rounded, size: 16, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Vocal Gender
                  _buildOptionRow(
                    label: 'Vocal Gender',
                    tooltip: 'YuE2 vokal tarzı cinsiyeti',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentPill(
                          label: 'Male',
                          selected: state.vocalGender == 'Male',
                          onTap: () => state.setVocalGender(state.vocalGender == 'Male' ? 'Auto' : 'Male'),
                        ),
                        const SizedBox(width: 4),
                        _buildSegmentPill(
                          label: 'Female',
                          selected: state.vocalGender == 'Female',
                          onTap: () => state.setVocalGender(state.vocalGender == 'Female' ? 'Auto' : 'Female'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Duration
                  _buildOptionRow(
                    label: 'Duration',
                    tooltip: 'Şarkı maksimum üretim süresi (saniye)',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentPill(
                          label: 'Custom',
                          selected: !state.isAutoDuration,
                          onTap: () => state.toggleAutoDuration(false),
                        ),
                        const SizedBox(width: 4),
                        _buildSegmentPill(
                          label: 'Auto',
                          selected: state.isAutoDuration,
                          onTap: () => state.toggleAutoDuration(true),
                        ),
                      ],
                    ),
                  ),

                  // Duration Slider (When Custom)
                  if (!state.isAutoDuration) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                              thumbColor: AppColors.primary,
                            ),
                            child: Slider(
                              value: state.duration,
                              min: 15.0,
                              max: 240.0,
                              divisions: 15,
                              onChanged: (val) => state.setDuration(val),
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_formatDuration(state.duration)} (${state.duration.toInt()}s)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        'ℹ️ Süre sözlerin uzunluğuna göre otomatik hesaplanır.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 4. Max Mode
                  _buildOptionRow(
                    label: 'Max Mode',
                    tooltip: '36 Difüzyon adımı ile stüdyo kalitesinde maksimum çözünürlük',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentPill(
                          label: 'Off',
                          selected: !state.maxMode,
                          onTap: () => state.toggleMaxMode(false),
                        ),
                        const SizedBox(width: 4),
                        _buildSegmentPill(
                          label: 'On',
                          selected: state.maxMode,
                          onTap: () => state.toggleMaxMode(true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Weirdness (Temperature)
                  _buildOptionRow(
                    label: 'Weirdness',
                    tooltip: 'Yaratıcılık ve akustik sıradışılık (Model Temperature)',
                    trailing: SizedBox(
                      width: 170,
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: pinkAccent,
                                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                                thumbColor: pinkAccent,
                              ),
                              child: Slider(
                                value: state.weirdness.toDouble(),
                                min: 0,
                                max: 100,
                                onChanged: (val) => state.setWeirdness(val.toInt()),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 38,
                            child: Text(
                              '${state.weirdness}%',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Style Influence (CFG Scale)
                  _buildOptionRow(
                    label: 'Style Influence',
                    tooltip: 'Tarza ve enstrüman açıklamasına ne kadar sıkı uyulacağı (CFG Scale)',
                    trailing: SizedBox(
                      width: 170,
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: pinkAccent,
                                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                                thumbColor: pinkAccent,
                              ),
                              child: Slider(
                                value: state.styleInfluence.toDouble(),
                                min: 0,
                                max: 100,
                                onChanged: (val) => state.setStyleInfluence(val.toInt()),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 38,
                            child: Text(
                              '${state.styleInfluence}%',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 7. Variety
                  _buildOptionRow(
                    label: 'Variety',
                    tooltip: 'Akor ve ritim çeşitliliği (Token penalty & Top-P)',
                    trailing: SizedBox(
                      width: 170,
                      child: Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: pinkAccent,
                                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                                thumbColor: pinkAccent,
                              ),
                              child: Slider(
                                value: state.variety.toDouble(),
                                min: 0,
                                max: 100,
                                onChanged: (val) => state.setVariety(val.toInt()),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 38,
                            child: Text(
                              state.variety > 80 ? 'Extra' : '${state.variety}%',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 8. Personalize
                  _buildOptionRow(
                    label: 'Personalize',
                    tooltip: 'Kullanıcı zevkine göre profil adaptasyonu',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Taste',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 8),
                        _buildSegmentPill(label: 'Off', selected: true, onTap: () {}),
                        const SizedBox(width: 4),
                        _buildSegmentPill(label: 'On', selected: false, onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required String label,
    required String tooltip,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  Widget _buildSegmentPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF26262E) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF26262E) : const Color(0xFFE5E7EB))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = activeColor ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? color : Colors.grey),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? color : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagHelper(String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _insertTag(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
