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
          // Top Header & Window Controls
          Container(
            height: 46,
            padding: const EdgeInsets.only(left: 18, right: 0),
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
                          const Icon(Icons.library_music_rounded, size: 17, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Kütüphane',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${state.songs.length}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Yenile',
                  onPressed: () => state.refreshSongs(),
                ),
                const SizedBox(width: 4),
                const WindowControlsWidget(height: 46),
              ],
            ),
          ),

          // Responsive Search & Scrollable Filter Toolbar (Zero horizontal overflow)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 680;
                final searchBox = SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => state.setSearchQuery(val),
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Kütüphanede ara...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 17),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 15),
                              onPressed: () {
                                _searchCtrl.clear();
                                state.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                  ),
                );

                final filtersScroll = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(Icons.grid_view_rounded, 'Tümü', LibraryFilter.all, state),
                      const SizedBox(width: 6),
                      _buildFilterChip(Icons.album_rounded, 'Cover', LibraryFilter.covers, state,
                          accentColor: const Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      _buildFilterChip(Icons.piano_rounded, 'Enstrüman', LibraryFilter.instrumental, state,
                          accentColor: const Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      _buildFilterChip(Icons.graphic_eq_rounded, 'Vokal Miks', LibraryFilter.vocalMaster, state,
                          accentColor: const Color(0xFF059669)),
                      const SizedBox(width: 6),
                      _buildFilterChip(Icons.favorite_rounded, 'Favori', LibraryFilter.liked, state,
                          accentColor: const Color(0xFFEF4444)),
                    ],
                  ),
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchBox,
                      const SizedBox(height: 8),
                      filtersScroll,
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(width: 220, child: searchBox),
                    const SizedBox(width: 12),
                    Expanded(child: filtersScroll),
                  ],
                );
              },
            ),
          ),

          // Songs List
          Expanded(
            child: Builder(
              builder: (context) {
                final activeTasksList = state.activeTasks.where((t) {
                  if (state.songs.any((s) => s.id == t.taskId)) return false;
                  if (state.libraryFilter == LibraryFilter.covers && !t.isCover) return false;
                  if (state.libraryFilter == LibraryFilter.instrumental && !t.isInstrumental) return false;
                  if (state.libraryFilter == LibraryFilter.vocalMaster && !t.isVocalMaster) return false;
                  return true;
                }).toList();

                if (state.songs.isEmpty && activeTasksList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 46, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'Henüz kayıt yok',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  itemCount: activeTasksList.length + state.songs.length,
                  itemBuilder: (context, index) {
                    if (index < activeTasksList.length) {
                      final task = activeTasksList[index];
                      return _buildSkeletonCard(context, task, isDark);
                    }

                    final songIndex = index - activeTasksList.length;
                    final song = state.songs[songIndex];
                    final isCurrent = state.audio.currentSong?.id == song.id;
                    final isPlaying = isCurrent && state.audio.isPlaying;

                    return _buildSongCard(context, song, isCurrent, isPlaying, state);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> getThumbnailGradient({
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

  static IconData getThumbnailIcon({
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

  Widget _buildFilterChip(
    IconData icon,
    String label,
    LibraryFilter filter,
    AppStateProvider state, {
    Color? accentColor,
  }) {
    final selected = state.libraryFilter == filter;
    final color = accentColor ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => state.setLibraryFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context, GenerationTask task, bool isDark) {
    final cardBg = isDark ? const Color(0xFF181820) : const Color(0xFFF9FAFB);
    final isQueued = task.status == 'queued';
    final studioMsg = task.message.isNotEmpty ? task.message : 'Stüdyo hazırlanıyor...';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isQueued
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.primary.withValues(alpha: 0.65),
          width: isQueued ? 1.0 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isQueued
                      ? [const Color(0xFF2C2C34), const Color(0xFF1E1E24)]
                      : getThumbnailGradient(
                          isVocalMaster: task.isVocalMaster,
                          isInstrumental: task.isInstrumental,
                          isCover: task.isCover,
                        ),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: isQueued ? null : (task.progress > 5 ? task.progress / 100.0 : null),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isQueued
                              ? Colors.grey.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isQueued ? 'Sırada' : 'Kayıtta',
                          style: TextStyle(
                            color: isQueued ? Colors.grey : AppColors.primary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => context.read<AppStateProvider>().cancelTask(task.taskId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                    children: [
                      Expanded(
                        child: Text(
                          studioMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

    String? primaryBadge;
    Color primaryBadgeColor = AppColors.primary;
    if (song.isVocalMaster) {
      primaryBadge = 'MİKS';
      primaryBadgeColor = const Color(0xFF10B981);
    } else if (song.isInstrumental) {
      primaryBadge = 'ENSTRÜMAN';
      primaryBadgeColor = const Color(0xFF8B5CF6);
    } else if (song.isCover) {
      primaryBadge = 'COVER';
      primaryBadgeColor = const Color(0xFF3B82F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
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
          padding: const EdgeInsets.all(11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (state.isSongNew(song.id))
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEE0979),
                    shape: BoxShape.circle,
                  ),
                ),

              // Artwork Thumbnail
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: getThumbnailGradient(
                          isVocalMaster: song.isVocalMaster,
                          isInstrumental: song.isInstrumental,
                          isCover: song.isCover,
                        ),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        getThumbnailIcon(
                          isVocalMaster: song.isVocalMaster,
                          isInstrumental: song.isInstrumental,
                          isCover: song.isCover,
                        ),
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.62),
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        song.durationFormatted,
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Song Info (Protected against overflow)
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (primaryBadge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryBadgeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              primaryBadge,
                              style: TextStyle(
                                color: primaryBadgeColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.album_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            song.cleanModelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Compact Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.graphic_eq_rounded, size: 18, color: Color(0xFF10B981)),
                    tooltip: song.isInstrumental ? 'Vokal Miks Altyapısı Yap' : 'Vokal Miks\'e Gönder',
                    onPressed: () => state.setVocalMasterFromSong(song),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: state.isExtractingStems(song.id)
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                            ),
                          )
                        : Icon(
                            Icons.layers_rounded,
                            color: song.stems != null ? AppColors.secondary : Colors.grey,
                            size: 18,
                          ),
                    tooltip: 'Kanalları Ayır',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => StemsDialog(song: song),
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      song.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: song.liked ? const Color(0xFFEF4444) : Colors.grey,
                      size: 18,
                    ),
                    tooltip: 'Favori',
                    onPressed: () => state.toggleSongLike(song),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Diğer İşlemler',
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 160),
                    onSelected: (action) async {
                      if (action == 'sheet') {
                        await state.openSheetMusic(song);
                      } else if (action == 'copy') {
                        Clipboard.setData(ClipboardData(text: song.lyrics));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sözler kopyalandı')),
                          );
                        }
                      } else if (action == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: const Text('Kaydı Sil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            content: Text('"${song.title}" silinsin mi?', style: const TextStyle(fontSize: 13)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Vazgeç'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await state.deleteSong(song);
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'sheet',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFF59E0B)),
                            SizedBox(width: 8),
                            Text('Nota PDF Aç', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Sözleri Kopyala', style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(fontSize: 12.5, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
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
