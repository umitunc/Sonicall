import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/app_state_provider.dart';

class StemsDialog extends StatefulWidget {
  final Song song;
  const StemsDialog({super.key, required this.song});

  @override
  State<StemsDialog> createState() => _StemsDialogState();
}

class _StemsDialogState extends State<StemsDialog> {
  String? _currentlyPlayingStem;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
    final isExtracting = state.isExtractingStems(widget.song.id);

    // Current song from state if updated
    final currentSong = state.songs.firstWhere(
      (s) => s.id == widget.song.id,
      orElse: () => widget.song,
    );
    final stems = currentSong.stems;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.layers_rounded, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stem Ayırıcı (Kanal İzolasyonu)',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Şarkı: ${currentSong.title}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isExtracting) ...[
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Stemler Ayrıştırılıyor...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vokal, Enstrümantal, Bas ve Davul kanalları izole ediliyor (DSP/HPSS Engine)...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (stems == null || stems.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu şarkı için henüz stemler ayrıştırılmadı',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Şarkıyı 4 bağımsız kanala (Vokal, Altyapı, Davul ve Bas) ayırarak ayrı ayrı dinleyebilir ve WAV olarak indirebilirsiniz.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                      label: const Text('Stemleri Şimdi Ayrıştır', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        await state.extractSongStems(currentSong);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Stem Track List
              _buildStemRow(
                context,
                title: 'Vokal (Vocals)',
                subtitle: 'İzole edilmiş şan ve vokal kanalı',
                icon: Icons.mic_rounded,
                color: const Color(0xFFEC4899),
                stemKey: 'vocals',
                stemUrl: stems['vocals'],
                currentSong: currentSong,
                state: state,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStemRow(
                context,
                title: 'Enstrümantal (Karaoke / Backing)',
                subtitle: 'Vokalsiz müzik altyapısı',
                icon: Icons.music_note_rounded,
                color: const Color(0xFF3B82F6),
                stemKey: 'instrumental',
                stemUrl: stems['instrumental'],
                currentSong: currentSong,
                state: state,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStemRow(
                context,
                title: 'Davul & Perküsyon (Drums)',
                subtitle: 'Ritim, vuruşlar ve perküsyon vuruşları',
                icon: Icons.radio_rounded,
                color: const Color(0xFFF59E0B),
                stemKey: 'drums',
                stemUrl: stems['drums'],
                currentSong: currentSong,
                state: state,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildStemRow(
                context,
                title: 'Bas Gitar & Sub (Bass)',
                subtitle: 'Sub-bass ve bas armonileri',
                icon: Icons.speaker_rounded,
                color: const Color(0xFF10B981),
                stemKey: 'bass',
                stemUrl: stems['bass'],
                currentSong: currentSong,
                state: state,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Bottom Actions
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Stem Klasörünü Aç (Windows Gezgini)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () => state.openStemsFolder(currentSong),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kapat'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStemRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String stemKey,
    required String? stemUrl,
    required Song currentSong,
    required AppStateProvider state,
    required bool isDark,
  }) {
    final isPlaying = _currentlyPlayingStem == stemKey && state.audio.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlaying ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (stemUrl != null) ...[
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: color,
                size: 32,
              ),
              tooltip: isPlaying ? 'Durdur' : 'Oynat',
              onPressed: () {
                if (isPlaying) {
                  state.audio.pause();
                  setState(() => _currentlyPlayingStem = null);
                } else {
                  state.audio.playSong(
                    Song(
                      id: '${currentSong.id}_$stemKey',
                      title: '${currentSong.title} ($title)',
                      style: currentSong.style,
                      lyrics: '',
                      isCover: false,
                      isInstrumental: true,
                      model: 'Stem: $title',
                      durationSeconds: currentSong.durationSeconds,
                      durationFormatted: currentSong.durationFormatted,
                      audioUrl: stemUrl,
                      coverUrl: currentSong.coverUrl,
                      createdAt: currentSong.createdAt,
                      dateGroup: currentSong.dateGroup,
                    ),
                  );
                  setState(() => _currentlyPlayingStem = stemKey);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
