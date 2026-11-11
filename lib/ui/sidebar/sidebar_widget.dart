import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/legacy.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/model_hub_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../widgets/sonicall_logo.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = isDark ? AppColors.darkSidebar : AppColors.lightSidebar;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isCreateSelected = state.activeTab != 'instrument' &&
        state.activeTab != 'vocal_master' &&
        state.activeTab != 'library';

    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Compact Brand Header (Draggable Window Area)
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SonicallLogo(size: 34),
                  const SizedBox(height: 6),
                  Text(
                    'SONICALL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Main Navigation (Icon + Short Label underneath — zero overflow)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _buildRailItem(
                    context,
                    icon: Icons.music_note_rounded,
                    label: 'Stüdyo',
                    isSelected: isCreateSelected,
                    onTap: () => state.setActiveTab('create'),
                  ),
                  const SizedBox(height: 6),
                  _buildRailItem(
                    context,
                    icon: Icons.piano_rounded,
                    label: 'Enstrüman',
                    isSelected: state.activeTab == 'instrument',
                    onTap: () => state.setActiveTab('instrument'),
                  ),
                  const SizedBox(height: 6),
                  _buildRailItem(
                    context,
                    icon: Icons.graphic_eq_rounded,
                    label: 'Vokal Miks',
                    isSelected: state.activeTab == 'vocal_master',
                    onTap: () => state.setActiveTab('vocal_master'),
                  ),
                  const SizedBox(height: 6),
                  _buildRailItem(
                    context,
                    icon: Icons.library_music_rounded,
                    label: 'Kütüphane',
                    isSelected: state.activeTab == 'library',
                    onTap: () {
                      state.setLibraryFilter(LibraryFilter.all);
                      state.setActiveTab('library');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Concise Studio Status Pill
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.isBackendOnline
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isBackendOnline ? const Color(0xFF10B981) : Colors.red,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    state.isBackendOnline ? 'Hazır' : 'Kapalı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: state.isBackendOnline ? const Color(0xFF10B981) : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom Compact Actions (Icon + Short Label)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              children: [
                _buildBottomAction(
                  context,
                  icon: Icons.hub_rounded,
                  label: 'Modeller',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const ModelHubDialog(),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniIconAction(
                      context,
                      icon: Icons.settings_rounded,
                      tooltip: 'Ayarlar',
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                    ),
                    _buildMiniIconAction(
                      context,
                      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      tooltip: isDark ? 'Aydınlık Tema' : 'Karanlık Tema',
                      onTap: () => state.toggleTheme(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? (isDark ? AppColors.primary.withValues(alpha: 0.16) : AppColors.primary.withValues(alpha: 0.12))
        : Colors.transparent;
    final iconColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);
    final textColor = isSelected
        ? (isDark ? Colors.white : AppColors.primary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIconAction(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }
}
