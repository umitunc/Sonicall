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
  final String emoji;
  final Color accentColor;

  const ModelCompactCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.emoji,
    required this.accentColor,
  });
}

class TopModelSelectorBar extends StatelessWidget {
  const TopModelSelectorBar({super.key});

  static const List<ModelCompactCardData> models = [
    ModelCompactCardData(
      id: 'YuE2 3B INT8',
      title: 'YuE 3B INT8',
      subtitle: '⚡ 15s • ~6GB',
      badge: 'Ultra Hızlı',
      emoji: '⚡',
      accentColor: Color(0xFFF59E0B),
    ),
    ModelCompactCardData(
      id: 'YuE 7B Full BF16',
      title: 'YuE 7B BF16',
      subtitle: '👑 Üstün • ~14GB',
      badge: 'Tam Boy',
      emoji: '👑',
      accentColor: Color(0xFF8B5CF6),
    ),
    ModelCompactCardData(
      id: 'ACE-Step',
      title: 'ACE-Step',
      subtitle: '🚀 12s • ~8GB',
      badge: 'Vokal-Beat',
      emoji: '🚀',
      accentColor: Color(0xFF10B981),
    ),
    ModelCompactCardData(
      id: 'DiffRhythm',
      title: 'DiffRhythm',
      subtitle: '🌊 Temiz • ~6GB',
      badge: 'Difüzyon',
      emoji: '🌊',
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

    // Filter to ONLY display models that are actually installed on disk
    final visibleModels = models.where((m) {
      if (state.models.isEmpty) {
        return m.id == 'YuE2 3B INT8';
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101018) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Horizontal concise side-by-side cards (Only installed models)
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

          const SizedBox(width: 8),

          // Hub shortcut button
          Tooltip(
            message: 'Model Hub & BYOM (Model İndir / Dosya Seç)',
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (context) => const ModelHubDialog(),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                      'Hub',
                      style: TextStyle(
                        fontSize: 11,
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? data.accentColor.withValues(alpha: 0.18)
                  : data.accentColor.withValues(alpha: 0.10))
              : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? data.accentColor : borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.accentColor.withValues(alpha: 0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 1.5),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
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
                        borderRadius: BorderRadius.circular(3),
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
                const SizedBox(height: 1.5),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 9.0,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: data.accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
