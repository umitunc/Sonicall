import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/lyrics_modal.dart';

class BottomPlayerWidget extends StatelessWidget {
  const BottomPlayerWidget({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  List<Color> _getThumbnailGradient({
    bool isVocalMaster = false,
    bool isInstrumental = false,
    bool isCover = false,
  }) {
    if (isVocalMaster) {
      return const [Color(0xFF059669), Color(0xFF06B6D4)];
    } else if (isInstrumental) {
      return const [Color(0xFF4F46E5), Color(0xFF8B5CF6)];
    } else if (isCover) {
      return const [Color(0xFF2563EB), Color(0xFF0284C7)];
    } else {
      return const [Color(0xFFFF6A00), Color(0xFFEE0979)];
    }
  }

  IconData _getThumbnailIcon({
    bool isVocalMaster = false,
    bool isInstrumental = false,
    bool isCover = false,
  }) {
    if (isVocalMaster) {
      return Icons.graphic_eq_rounded;
    } else if (isInstrumental) {
      return Icons.piano_rounded;
    } else if (isCover) {
      return Icons.album_rounded;
    } else {
      return Icons.music_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final audio = state.audio;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerBg = isDark ? AppColors.darkSidebar : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final song = audio.currentSong;

        return Container(
          height: 78,
          decoration: BoxDecoration(
            color: playerBg,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: song == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note_rounded, size: 20, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      'Çalmak için kütüphaneden bir şarkıya tıklayın',
                      style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.7)),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Left Track Info
                    SizedBox(
                      width: 260,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: _getThumbnailGradient(
                                  isVocalMaster: song.isVocalMaster,
                                  isInstrumental: song.isInstrumental,
                                  isCover: song.isCover,
                                ),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getThumbnailGradient(
                                    isVocalMaster: song.isVocalMaster,
                                    isInstrumental: song.isInstrumental,
                                    isCover: song.isCover,
                                  )[0].withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _getThumbnailIcon(
                                  isVocalMaster: song.isVocalMaster,
                                  isInstrumental: song.isInstrumental,
                                  isCover: song.isCover,
                                ),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  song.style,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              song.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: song.liked ? const Color(0xFFEF4444) : Colors.grey,
                              size: 18,
                            ),
                            onPressed: () => state.toggleSongLike(song),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Center Controls & Timeline
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Buttons: Rewind, Play/Pause, Forward
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded, size: 22),
                                tooltip: '10 saniye geri sar',
                                onPressed: () => audio.seekRelative(-10),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary],
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  onPressed: () => audio.togglePlayPause(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded, size: 22),
                                tooltip: '10 saniye ileri sar',
                                onPressed: () => audio.seekRelative(10),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // Slider & Timers
                          Builder(builder: (context) {
                            final totalSeconds = audio.duration.inSeconds > 0
                                ? audio.duration.inSeconds
                                : (song.durationSeconds > 0 ? song.durationSeconds : 30);
                            final maxVal = totalSeconds.toDouble();
                            final currentVal = audio.position.inSeconds.toDouble().clamp(0.0, maxVal);

                            return Row(
                              children: [
                                Text(
                                  _formatDuration(audio.position),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 4.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor: Colors.grey.withOpacity(0.25),
                                      thumbColor: AppColors.primary,
                                    ),
                                    child: Slider(
                                      value: currentVal,
                                      min: 0.0,
                                      max: maxVal > 0 ? maxVal : 1.0,
                                      onChangeStart: (val) {
                                        audio.startDragging();
                                      },
                                      onChanged: (val) {
                                        audio.updateDragging(Duration(seconds: val.toInt()));
                                      },
                                      onChangeEnd: (val) {
                                        audio.seek(Duration(seconds: val.toInt()));
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(Duration(seconds: totalSeconds)),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Right Options: Volume, Loop, Lyrics
                    SizedBox(
                      width: 230,
                      child: Row(
                        children: [
                          // Loop Toggle
                          IconButton(
                            icon: Icon(
                              Icons.repeat_rounded,
                              size: 20,
                              color: audio.isLooping ? AppColors.primary : Colors.grey,
                            ),
                            tooltip: audio.isLooping ? 'Döngü Açık' : 'Döngü Kapalı',
                            onPressed: () => audio.toggleLoop(),
                          ),

                          // Lyrics Modal Button
                          IconButton(
                            icon: const Icon(Icons.lyrics_rounded, size: 20, color: Colors.grey),
                            tooltip: 'Şarkı Sözleri',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => LyricsModal(song: song),
                              );
                            },
                          ),

                          const SizedBox(width: 6),

                          // Volume Icon & Slider
                          Icon(
                            audio.volume == 0
                                ? Icons.volume_off_rounded
                                : (audio.volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                            size: 19,
                            color: Colors.grey,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.5,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.grey.withOpacity(0.25),
                                thumbColor: AppColors.primary,
                              ),
                              child: Slider(
                                value: audio.volume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) => audio.setVolume(val),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
