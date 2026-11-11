import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';

class DiagnosticDialog extends StatefulWidget {
  const DiagnosticDialog({super.key});

  @override
  State<DiagnosticDialog> createState() => _DiagnosticDialogState();
}

class _DiagnosticDialogState extends State<DiagnosticDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().fetchDiagnostics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
    final report = state.diagnosticReport;

    final bool isHealthy = report['overall_healthy'] == true;
    final String timestamp = report['timestamp'] ?? 'Henüz yapılmadı';
    final String summary = report['summary'] ?? 'Diagnostik verisi yükleniyor...';
    final List checks = (report['checks'] as List?) ?? [];
    final List models = (report['models_status'] as List?) ?? [];
    final List logs = (report['logs'] as List?) ?? [];

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 620,
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
                    color: (isHealthy ? const Color(0xFF10B981) : Colors.amber).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isHealthy ? Icons.verified_rounded : Icons.healing_rounded,
                    color: isHealthy ? const Color(0xFF10B981) : Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Model & Sentez Diagnostik Kayıtları',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Python backend & ComfyUI ses motoru bütünlük denetimi • Son test: $timestamp',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: state.isRunningDiagnostics
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    state.isRunningDiagnostics ? 'Denetleniyor...' : 'Testi Çalıştır',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: state.isRunningDiagnostics ? null : () => state.runDiagnostics(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isHealthy ? const Color(0xFF10B981) : Colors.amber.shade800).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isHealthy ? const Color(0xFF10B981) : Colors.amber.shade800).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: isHealthy ? const Color(0xFF10B981) : Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isHealthy
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabbed / Section view of checks, models, and real-time logs
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      labelColor: isDark ? Colors.white : AppColors.primary,
                      unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(text: 'Sistem Kontrolleri (${checks.length})'),
                        Tab(text: 'Model Dosyaları (${models.length})'),
                        Tab(text: 'Diagnostik Logları (${logs.length})'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: System Checks
                          ListView.builder(
                            itemCount: checks.length,
                            itemBuilder: (context, index) {
                              final c = checks[index];
                              final bool passed = c['passed'] == true;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: passed
                                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                        : Colors.red.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      passed ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                                      color: passed ? const Color(0xFF10B981) : Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c['name'] ?? '',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c['details'] ?? '',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: passed
                                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                            : Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        passed ? 'BAŞARILI' : 'BAŞARISIZ',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: passed ? const Color(0xFF10B981) : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Tab 2: Model Files & Architecture
                          ListView.builder(
                            itemCount: models.length,
                            itemBuilder: (context, index) {
                              final m = models[index];
                              final bool installed = m['installed'] == true;
                              final bool healthy = m['size_healthy'] == true && m['header_valid'] == true;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      installed
                                          ? (healthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded)
                                          : Icons.cloud_off_rounded,
                                      color: installed
                                          ? (healthy ? const Color(0xFF10B981) : Colors.amber)
                                          : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${m['name']} (${m['filename']})',
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Mimari: ${m['detected_arch']} • Boyut: ${(m['actual_size_bytes'] / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB • Başlık: ${m['header_valid'] ? 'Geçerli' : 'Hatalı'}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      installed ? (healthy ? 'Sağlıklı' : 'Uyumsuz Boyut') : 'Eksik',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: installed
                                            ? (healthy ? const Color(0xFF10B981) : Colors.amber.shade700)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Tab 3: Detailed Diagnostic Logs
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black38 : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: ListView.builder(
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Text(
                                    logs[index].toString(),
                                    style: TextStyle(
                                      fontFamily: 'Consolas',
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF10B981) : const Color(0xFF065F46),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

