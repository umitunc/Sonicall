import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/model_hub_dialog.dart';

class ModelCompactCardData {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;

  const ModelCompactCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
  });
}

class TopModelSelectorBar extends StatelessWidget {
  const TopModelSelectorBar({super.key});

  static const List<ModelCompactCardData> models = [
    ModelCompactCardData(
      id: 'ACE-Step 1.5 XL',
      title: 'ACE-Step 1.5 XL',
      subtitle: 'Enstrümantal & Miks',
      badge: 'XL',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFF10B981),
    ),
    ModelCompactCardData(
      id: 'YuE2 3B INT8',
      title: 'YuE2 3B',
      subtitle: 'Hızlı Akustik',
      badge: 'Hızlı',
      icon: Icons.flash_on_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    ModelCompactCardData(
      id: 'YuE 7B Full BF16',
      title: 'YuE2 7B',
      subtitle: 'Zengin Orkestra',
      badge: 'Pro',
      icon: Icons.workspace_premium_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    ModelCompactCardData(
      id: 'DiffRhythm',
      title: 'DiffRhythm',
      subtitle: 'Ritim & Armoni',
      badge: 'Ritim',
      icon: Icons.waves_rounded,
      accentColor: Color(0xFF06B6D4),
    ),
  ];

  static bool isModelSelected(String currentModel, String targetId) {
    final cur = currentModel.toLowerCase();
    final tgt = targetId.toLowerCase();
    if (tgt.contains('7b')) return cur.contains('7b');
    if (tgt.contains('ace')) return cur.contains('ace');
    if (tgt.contains('diff')) return cur.contains('diff');
    return cur.contains('int8') || cur.contains('3b') || (!cur.contains('7b') && !cur.contains('ace') && !cur.contains('diff'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardBg = isDark ? const Color(0xFF181824) : Colors.white;

    final visibleModels = models.where((m) {
      if (state.models.isEmpty) {
        return m.id == 'ACE-Step 1.5 XL' || m.id == 'YuE2 3B INT8';
      }
      final low = m.id.toLowerCase();
      return state.models.any((srvM) {
        if (!srvM.installed) return false;
        final sLow = '${srvM.id} ${srvM.name}'.toLowerCase();
        if (low.contains('7b') && sLow.contains('7b') && !sLow.contains('3b')) return true;
        if (low.contains('ace') && sLow.contains('ace')) return true;
        if (low.contains('diff') && sLow.contains('diff')) return true;
        if ((low.contains('3b') || low.contains('int8')) && (sLow.contains('3b') || sLow.contains('int8'))) return true;
        return false;
      });
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101018) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final m in visibleModels) ...[
                    _buildCompactCard(
                      data: m,
                      isSelected: isModelSelected(state.selectedModel, m.id),
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      onTap: () => state.setSelectedModel(m.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Modeller',
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (context) => const ModelHubDialog(),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C28) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333346) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Modeller',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({
    required ModelCompactCardData data,
    required bool isSelected,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? data.accentColor.withValues(alpha: 0.18)
                  : data.accentColor.withValues(alpha: 0.10))
              : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? data.accentColor : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 15, color: data.accentColor),
            const SizedBox(width: 6),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? (isDark ? Colors.white : data.accentColor)
                    : (isDark ? Colors.white : AppColors.lightTextPrimary),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: isSelected ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data.badge,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: data.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
