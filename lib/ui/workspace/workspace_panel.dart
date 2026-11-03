import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/legacy.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/stems_dialog.dart';
import '../widgets/window_controls.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({super.key});

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: panelBg,
      child: Column(
        children: [
          // Top Header & Breadcrumbs & In-App Window Controls
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 20, right: 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DragToMoveArea(
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          Icon(Icons.folder_shared_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Çalışma Alanı',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Kütüphanem (My Workspace)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  tooltip: 'Yenile',
                  onPressed: () => state.refreshSongs(),
                ),
                const SizedBox(width: 4),
                const WindowControlsWidget(height: 48),
              ],
            ),
          ),

          // Search & Filter Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => state.setSearchQuery(val),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Şarkı, tarz veya söz ara...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  state.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Filter Pills
                _buildFilterChip('Hepsi', LibraryFilter.all, state),
                const SizedBox(width: 6),
                _buildFilterChip('Cover', LibraryFilter.covers, state),
                const SizedBox(width: 6),
                _buildFilterChip('Beğenilenler', LibraryFilter.liked, state),
                const SizedBox(width: 6),
                _buildFilterChip('Enstrümantal', LibraryFilter.instrumental, state),
              ],
            ),
          ),

          // Songs List
          Expanded(
            child: (state.songs.isEmpty && state.activeTasks.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music_rounded, size: 52, color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Henüz şarkı bulunamadı',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sol stüdyo panelinden ilk şarkını veya cover parçanı üret!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: state.activeTasks.length + state.songs.length,
                    itemBuilder: (context, index) {
                      // 1. Show Active Queued/Processing Tasks at top (Suno Queue)
                      if (index < state.activeTasks.length) {
                        final task = state.activeTasks[index];
                        return _buildSkeletonCard(context, task, isDark);
                      }

                      // 2. Show Completed Songs
                      final songIndex = index - state.activeTasks.length;
                      final song = state.songs[songIndex];
                      final isCurrent = state.audio.currentSong?.id == song.id;
                      final isPlaying = isCurrent && state.audio.isPlaying;

                      return _buildSongCard(context, song, isCurrent, isPlaying, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, LibraryFilter filter, AppStateProvider state) {
    final selected = state.libraryFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => state.setLibraryFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context, GenerationTask task, bool isDark) {
    final cardBg = isDark ? const Color(0xFF181820) : const Color(0xFFF9FAFB);
    final isQueued = task.status == 'queued';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isQueued
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.primary.withValues(alpha: 0.65),
          width: isQueued ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isQueued
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Skeleton Cover with pulsing gradient and spinner
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isQueued
                      ? [const Color(0xFF2C2C34), const Color(0xFF1E1E24)]
                      : [const Color(0xFFFF6A00), const Color(0xFFEE0979)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: isQueued ? null : (task.progress > 5 ? task.progress / 100.0 : null),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Info & Realtime Progress Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isQueued
                              ? Colors.grey.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isQueued)
                              const Icon(Icons.sync_rounded, size: 11, color: AppColors.primary),
                            if (!isQueued) const SizedBox(width: 3),
                            Text(
                              isQueued ? 'SIRADA' : 'ÜRETİLİYOR',
                              style: TextStyle(
                                color: isQueued ? Colors.grey : AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.style} • ${task.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Suno Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isQueued ? null : (task.progress / 100.0).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: isDark ? Colors.black45 : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                      if (!isQueued)
                        Text(
                          '%${task.progress}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    Song song,
    bool isCurrent,
    bool isPlaying,
    AppStateProvider state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isCurrent
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          state.markSongRead(song.id);
          if (isCurrent) {
            state.audio.togglePlayPause();
          } else {
            state.audio.playSong(song);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Suno Pink "NEW" Dot Indicator (media_1793667497586_f75be0ec.png)
              if (state.isSongNew(song.id))
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEE0979),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xAAEE0979),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

              // Artwork Thumbnail with Play button overlay
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6A00), Color(0xFFEE0979)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        song.isCover ? Icons.graphic_eq_rounded : Icons.album_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.65),
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        song.durationFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (song.isCover) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'COVER',
                              style: TextStyle(
                                color: Color(0xFF60A5FA),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (song.isInstrumental) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'INST',
                              style: TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (song.stems != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'STEMS',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (song.sheetMusicUrl != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOTA PDF',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.memory_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            song.model,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.schedule_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          song.createdAt,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Row(
                children: [
                  // 1. Sheet Music (PDF) Button
                  IconButton(
                    icon: state.isGeneratingSheet(song.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B))),
                          )
                        : Icon(
                            Icons.picture_as_pdf_rounded,
                            color: song.sheetMusicUrl != null ? const Color(0xFFF59E0B) : Colors.grey,
                            size: 19,
                          ),
                    tooltip: song.sheetMusicUrl != null
                        ? 'SheetSage Nota Kağıdı (PDF) Aç'
                        : 'SheetSage Nota Kağıdı (PDF) Çıkar ve Aç',
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${song.title} için SheetSage nota kağıdı hazırlanıyor ve açılıyor...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      await state.openSheetMusic(song);
                    },
                  ),

                  // 2. Stems Extractor Button
                  IconButton(
                    icon: state.isExtractingStems(song.id)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary)),
                          )
                        : Icon(
                            Icons.layers_rounded,
                            color: song.stems != null ? AppColors.secondary : Colors.grey,
                            size: 19,
                          ),
                    tooltip: song.stems != null
                        ? 'Stemleri Dinle ve Yönet'
                        : 'Stemleri Ayrıştır (Vokal, Bas, Davul, Enstrüman)',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => StemsDialog(song: song),
                      );
                    },
                  ),

                  // 3. Like Button
                  IconButton(
                    icon: Icon(
                      song.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: song.liked ? const Color(0xFFEF4444) : Colors.grey,
                      size: 20,
                    ),
                    tooltip: 'Beğen',
                    onPressed: () => state.toggleSongLike(song),
                  ),

                  // 4. Copy Lyrics
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                    tooltip: 'Sözleri Kopyala',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: song.lyrics));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sözler panoya kopyalandı!')),
                      );
                    },
                  ),

                  // 5. Delete Button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Colors.grey),
                    tooltip: 'Sil',
                    onPressed: () => state.deleteSong(song),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
