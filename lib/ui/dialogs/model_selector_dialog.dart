import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/top_model_selector_bar.dart';
import 'model_hub_dialog.dart';

class ModelSelectorDialog extends StatelessWidget {
  const ModelSelectorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ModelSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF141419) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A38) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
          maxHeight: 520,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E3A), Color(0xFFFF2A68)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yapay Zeka Müzik Modeli',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Donanım gücünüze ve hız ihtiyacınıza göre modeli seçin.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Concise Model Cards List (ONLY Installed Models)
              Flexible(
                child: SingleChildScrollView(
                  child: Builder(
                    builder: (context) {
                      final installedList = state.models.where((m) => m.installed && m.id != 'sheetsage2_bf16').toList();
                      
                      // If no models loaded yet or list is empty, show default 3B INT8
                      if (installedList.isEmpty) {
                        return _buildConciseModelCard(
                          context: context,
                          isDark: isDark,
                          isSelected: true,
                          iconStr: '⚡',
                          title: 'YuE2 3B INT8 ConvRot',
                          badgeText: 'ÖNERİLEN • ULTRA HIZLI',
                          badgeColor: const Color(0xFFF59E0B),
                          vramText: '~6 GB VRAM',
                          vramColor: const Color(0xFF10B981),
                          quickSpecs: '⚡ ~15-20 sn • 44.1 kHz 24-bit • INT8 Dynamic',
                          description: 'Düşük gecikmeyle anlık taslaklar, vokal melodileri ve hızlı üretim.',
                          onSelect: () {
                            state.setSelectedModel('YuE2 3B INT8');
                            Navigator.of(context).pop();
                          },
                        );
                      }

                      return Column(
                        children: [
                          for (int i = 0; i < installedList.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _buildInstalledModelItem(
                              context: context,
                              model: installedList[i],
                              state: state,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Banner: Open Model Hub & BYOM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_special_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFFF9500) : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Model indirmek, BYOM veya ComfyUI modellerinizi yönetmek için Model Hub\'ı açabilirsiniz.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.hub_rounded, size: 14, color: AppColors.primary),
                      label: const Text(
                        'Model Hub',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => const ModelHubDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstalledModelItem({
    required BuildContext context,
    required ModelInfo model,
    required AppStateProvider state,
    required bool isDark,
  }) {
    final low = '${model.id} ${model.name}'.toLowerCase();
    String iconStr = '🎵';
    String title = model.name;
    String badgeText = model.recommended ? 'ÖNERİLEN' : 'YÜKLÜ';
    Color badgeColor = const Color(0xFF6366F1);
    String vramText = model.vramRequired.isNotEmpty ? model.vramRequired : '~6-8 GB VRAM';
    Color vramColor = const Color(0xFF10B981);
    String quickSpecs = '${model.speed} • ${model.size}';
    String description = model.description;

    if (low.contains('convrot') || low.contains('int8') || (low.contains('3b') && !low.contains('studio'))) {
      iconStr = '⚡';
      badgeText = 'ÖNERİLEN • ULTRA HIZLI';
      badgeColor = const Color(0xFFF59E0B);
      vramColor = const Color(0xFF10B981);
      quickSpecs = '⚡ ~15-20 sn • 44.1 kHz 24-bit • INT8 Dynamic';
    } else if (low.contains('7b')) {
      iconStr = '👑';
      badgeText = '7B TAM BOY • ÜSTÜN VOKAL';
      badgeColor = const Color(0xFF8B5CF6);
      vramColor = const Color(0xFFEC4899);
      quickSpecs = '👑 ~35-50 sn • Akıcı Türkçe & İngilizce • Zengin Armoni';
    } else if (low.contains('ace')) {
      iconStr = '🚀';
      badgeText = 'YENİ NESİL • VOKAL-BEAT UYUMU';
      badgeColor = const Color(0xFF10B981);
      vramColor = const Color(0xFF10B981);
      quickSpecs = '🚀 ~12 sn • Güçlü Loudness • Sıkı Beat Senkronu';
    } else if (low.contains('diff')) {
      iconStr = '🌊';
      badgeText = 'ARTIFACT-FREE • DİFÜZYON';
      badgeColor = const Color(0xFF06B6D4);
      vramColor = const Color(0xFF06B6D4);
      quickSpecs = '🌊 ~10 sn • Sıfır Dijital Gürültü • End-to-End';
    } else if (low.contains('studio') || low.contains('bf16')) {
      iconStr = '🎛️';
      badgeText = 'MASTERING KALİTE';
      badgeColor = const Color(0xFF3B82F6);
      vramColor = const Color(0xFF8B5CF6);
      quickSpecs = '🎛️ Geniş Dinamik Aralık • Saf BF16';
    }

    final isSelected = TopModelSelectorBar.isModelSelected(state.selectedModel, model.id) ||
        state.selectedModel.toLowerCase() == model.id.toLowerCase() ||
        state.selectedModel.toLowerCase() == model.name.toLowerCase();

    return _buildConciseModelCard(
      context: context,
      isDark: isDark,
      isSelected: isSelected,
      iconStr: iconStr,
      title: title,
      badgeText: badgeText,
      badgeColor: badgeColor,
      vramText: vramText,
      vramColor: vramColor,
      quickSpecs: quickSpecs,
      description: description,
      onSelect: () {
        state.setSelectedModel(model.name);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildConciseModelCard({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required String iconStr,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String vramText,
    required Color vramColor,
    required String quickSpecs,
    required String description,
    required VoidCallback onSelect,
  }) {
    final activeBorder = badgeColor;
    final inactiveBorder = isDark ? const Color(0xFF262634) : const Color(0xFFE2E8F0);
    final cardBg = isSelected
        ? (isDark ? badgeColor.withValues(alpha: 0.14) : badgeColor.withValues(alpha: 0.08))
        : (isDark ? const Color(0xFF181822) : const Color(0xFFFAFAFB));

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(iconStr, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: vramColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vramText,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: vramColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quickSpecs,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Radio Indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? badgeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? badgeColor : (isDark ? Colors.white24 : Colors.black26),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
