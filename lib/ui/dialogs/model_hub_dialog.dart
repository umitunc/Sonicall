import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import 'diagnostic_dialog.dart';

class ModelHubDialog extends StatelessWidget {
  const ModelHubDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        height: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stüdyo Modelleri',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Müzik ve melodi motorları',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.healing_rounded, size: 20),
                  tooltip: 'Model & Sentez Diagnostik Kayıtları',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const DiagnosticDialog(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Yeniden Tara',
                  onPressed: () => state.refreshModels(),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Models Directory Path Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bağlı Klasör: ${state.modelsDir}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_outlined, size: 13),
                    label: const Text('Klasör Değiştir', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => state.pickNewModelsDir(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Model List
            Expanded(
              child: state.models.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: state.models.length,
                      itemBuilder: (context, index) {
                        final m = state.models[index];
                        final downloadInfo = state.downloads[m.id];
                        final isDownloading = downloadInfo != null && downloadInfo['status'] == 'downloading';
                        final isFailed = downloadInfo != null && downloadInfo['status'] == 'failed';
                        final double progress = (downloadInfo != null && downloadInfo['progress'] != null)
                            ? (downloadInfo['progress'] as num).toDouble()
                            : 0.0;
                        final String speed = downloadInfo != null ? (downloadInfo['speed'] ?? '') : '';
                        final String message = downloadInfo != null ? (downloadInfo['message'] ?? '') : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: m.installed
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : isDownloading
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : Colors.grey.withValues(alpha: 0.2),
                              width: isDownloading ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Left Status Icon / Button
                                  Tooltip(
                                    message: m.installed
                                        ? 'Model Yüklü ve Hazır'
                                        : isDownloading
                                            ? 'İndirme Sürüyor'
                                            : 'İndirmeyi Başlatmak İçin Tıklayın',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: (!m.installed && !isDownloading)
                                          ? () => state.startModelDownload(m.id)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: m.installed
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                              : isDownloading
                                                  ? AppColors.primary.withValues(alpha: 0.2)
                                                  : AppColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: isDownloading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                ),
                                              )
                                            : Icon(
                                                m.installed
                                                    ? Icons.check_circle_rounded
                                                    : Icons.cloud_download_rounded,
                                                color: m.installed
                                                    ? const Color(0xFF10B981)
                                                    : AppColors.primary,
                                                size: 20,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Middle Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                m.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (m.recommended) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'ÖNERİLEN',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${m.type} • ${m.vramRequired} • ${m.speed}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                        if (m.description.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            m.description,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        if (m.installed)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'Boyut: ${m.size} • Dosya bulundu',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xFF10B981),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Right Action Buttons
                                  if (m.installed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Yüklü',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isDownloading)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '%${progress.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                                          tooltip: 'İndirmeyi İptal Et',
                                          onPressed: () => state.cancelModelDownload(m.id),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Pick Local File Button (BYOM)
                                        Tooltip(
                                          message: 'Bilgisayarımdan Yerel Dosya Seç (.safetensors)',
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.folder_open_rounded, size: 14),
                                            label: const Text('Dosya Seç', style: TextStyle(fontSize: 11)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              side: BorderSide(
                                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                              ),
                                            ),
                                            onPressed: () async {
                                              final success = await state.importLocalModelFile(m.id);
                                              if (context.mounted && success) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${m.name} başarıyla aktarıldı!'),
                                                    backgroundColor: const Color(0xFF10B981),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Primary Download Button
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.download_rounded, size: 15, color: Colors.white),
                                          label: const Text(
                                            'İndir',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            elevation: 2,
                                          ),
                                          onPressed: () => state.startModelDownload(m.id),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              // Live Download Progress Bar (When Downloading)
                              if (isDownloading) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress > 0 ? (progress / 100).clamp(0.0, 1.0) : null,
                                    minHeight: 5,
                                    backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message.isNotEmpty ? message : 'Model ağırlıkları indiriliyor...',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (speed.isNotEmpty)
                                      Text(
                                        speed,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ],

                              // Real Download Failure Banner
                              if (isFailed) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          message.isNotEmpty ? message : 'İndirme tamamlanamadı.',
                                          style: const TextStyle(fontSize: 10.5, color: Colors.redAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
