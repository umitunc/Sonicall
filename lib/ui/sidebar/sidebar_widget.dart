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

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Header (Draggable Window Area)
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  const SonicallLogo(size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SONICALL',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'AI MUSIC STUDIO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Main Navigation Items
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            label: 'Ana Sayfa',
            id: 'home',
            isSelected: state.activeTab == 'home',
            onTap: () => state.setActiveTab('home'),
          ),
          _buildNavItem(
            context,
            icon: Icons.explore_rounded,
            label: 'Keşfet',
            id: 'explore',
            isSelected: state.activeTab == 'explore',
            onTap: () => state.setActiveTab('explore'),
          ),
          _buildNavItem(
            context,
            icon: Icons.add_circle_rounded,
            label: 'Üret (Create)',
            id: 'create',
            isSelected: state.activeTab == 'create',
            highlight: true,
            onTap: () => state.setActiveTab('create'),
          ),
          _buildNavItem(
            context,
            icon: Icons.tune_rounded,
            label: 'Stüdyo & Cover',
            id: 'studio',
            isSelected: state.activeTab == 'studio',
            onTap: () => state.setActiveTab('studio'),
          ),
          _buildNavItem(
            context,
            icon: Icons.library_music_rounded,
            label: 'Kütüphanem',
            id: 'library',
            isSelected: state.activeTab == 'library',
            onTap: () => state.setActiveTab('library'),
          ),

          const Spacer(),

          // GPU & Engine Status Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.isBackendOnline
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.isBackendOnline ? const Color(0xFF10B981) : Colors.red,
                        boxShadow: [
                          if (state.isBackendOnline)
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.6),
                              blurRadius: 6,
                            )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isBackendOnline ? 'Motor Hazır' : 'Motor Çevrimdışı',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: state.isBackendOnline ? const Color(0xFF10B981) : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.gpuName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              children: [
                _buildSmallAction(
                  context,
                  icon: Icons.hub_rounded,
                  label: 'Model Hub',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const ModelHubDialog(),
                  ),
                ),
                _buildSmallAction(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ),
                ),
                _buildSmallAction(
                  context,
                  icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  label: isDark ? 'Aydınlık Mod' : 'Karanlık Mod',
                  onTap: () => state.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String id,
    required bool isSelected,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = Colors.transparent;
    Color iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    if (isSelected) {
      bg = isDark ? const Color(0xFF23232A) : const Color(0xFFEDEFF2);
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          hoverColor: AppColors.primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
