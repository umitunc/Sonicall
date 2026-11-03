import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
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
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 680,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5E3A), Color(0xFFFF2A68)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yapay Zeka Müzik Modeli',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Donanım gücünüze ve istediğiniz akustik detay seviyesine göre modeli seçin.',
                          style: TextStyle(
                            fontSize: 12,
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

              const SizedBox(height: 20),

              // Scrollable Model List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Model 1: YuE2 3B INT8 ConvRot
                      _buildModelCard(
                        context: context,
                        isDark: isDark,
                        isSelected: state.selectedModel == 'YuE2 3B INT8',
                        modelKey: 'YuE2 3B INT8',
                        iconStr: '⚡',
                        iconColor: const Color(0xFFFF9500),
                        title: 'YuE2 3B INT8 ConvRot',
                        badgeText: 'ÖNERİLEN • ULTRA HIZLI',
                        badgeColor: const Color(0xFF10B981),
                        vramText: '~6 GB VRAM',
                        vramColor: const Color(0xFF10B981),
                        description:
                            'Optimize edilmiş INT8 kuantizasyonu ve döner konvolüsyonel dikkat mimarisi. Düşük gecikmeyle anlık taslaklar, vokal melodileri ve hızlı parça üretimi için idealdir.',
                        specs: [
                          _SpecItem(label: 'Üretim Hızı', value: '⚡⚡⚡ ~15-20 sn (Çok Hızlı)'),
                          _SpecItem(label: 'Minimum VRAM', value: '5.8 GB (RTX 3060/4060+)'),
                          _SpecItem(label: 'Örnekleme', value: '44.1 kHz / 24-bit Stereo'),
                          _SpecItem(label: 'Kuantizasyon', value: 'INT8 Dynamic Weights'),
                        ],
                        onSelect: () {
                          state.setSelectedModel('YuE2 3B INT8');
                          Navigator.of(context).pop();
                        },
                      ),

                      const SizedBox(height: 14),

                      // Model 2: YuE2 Studio BF16
                      _buildModelCard(
                        context: context,
                        isDark: isDark,
                        isSelected: state.selectedModel == 'YuE2 Studio BF16',
                        modelKey: 'YuE2 Studio BF16',
                        iconStr: '💎',
                        iconColor: const Color(0xFF3B82F6),
                        title: 'YuE2 Studio BF16 (Mastering Quality)',
                        badgeText: 'STUDIO MASTERING',
                        badgeColor: const Color(0xFF3B82F6),
                        vramText: '~12 GB VRAM',
                        vramColor: const Color(0xFFF59E0B),
                        description:
                            'Sıkıştırmasız 16-bit Bfloat16 saf ağırlıklar ile profesyonel stüdyo miksajı kalitesinde geniş harmonik aralık, zengin enstrüman ayrışması ve kristal berraklığında vokaller.',
                        specs: [
                          _SpecItem(label: 'Üretim Hızı', value: '⚡⚡ ~45-60 sn (Yüksek Hassasiyet)'),
                          _SpecItem(label: 'Minimum VRAM', value: '11.5 GB (RTX 3080/4080/4090)'),
                          _SpecItem(label: 'Örnekleme', value: '48.0 kHz / 32-bit Studio Master'),
                          _SpecItem(label: 'Kuantizasyon', value: 'BF16 Native (Kayıpsız)'),
                        ],
                        onSelect: () {
                          state.setSelectedModel('YuE2 Studio BF16');
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Footer: Link to Model Hub
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
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

  Widget _buildModelCard({
    required BuildContext context,
    required bool isDark,
    required bool isSelected,
    required String modelKey,
    required String iconStr,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String vramText,
    required Color vramColor,
    required String description,
    required List<_SpecItem> specs,
    required VoidCallback onSelect,
  }) {
    final activeBorder = AppColors.primary;
    final inactiveBorder = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE2E8F0);
    final cardBg = isSelected
        ? (isDark ? const Color(0xFF1E1A29) : const Color(0xFFFFF7F2))
        : (isDark ? const Color(0xFF1A1A22) : const Color(0xFFFAFAFB));

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorder : inactiveBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Title + Badges + Selection Check
            Row(
              children: [
                Text(iconStr, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: vramColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    vramText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: vramColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white24 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // Technical Specs Grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13131A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSpecChip(specs[0], isDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSpecChip(specs[1], isDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: _buildSpecChip(specs[2], isDark)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSpecChip(specs[3], isDark)),
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

  Widget _buildSpecChip(_SpecItem item, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${item.label}: ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            item.value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecItem {
  final String label;
  final String value;
  const _SpecItem({required this.label, required this.value});
}
