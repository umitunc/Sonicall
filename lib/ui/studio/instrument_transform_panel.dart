import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/instrument_model.dart';
import '../../models/song_model.dart';
import '../../providers/app_state_provider.dart';
import '../dialogs/model_hub_dialog.dart';
import '../widgets/top_model_selector_bar.dart';

class InstrumentTransformPanel extends StatefulWidget {
  const InstrumentTransformPanel({super.key});

  @override
  State<InstrumentTransformPanel> createState() => _InstrumentTransformPanelState();
}

class _InstrumentTransformPanelState extends State<InstrumentTransformPanel> {
  int _currentStep = 0; // 0: Model Seçimi, 1: Referans Ses ve BPM, 2: Enstrüman Seçimi ve Dönüştür
  InstrumentCategory _selectedCategory = InstrumentCategory.all;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _promptCtrl = TextEditingController();
  final TextEditingController _negativeCtrl = TextEditingController();
  String _searchFilter = '';
  bool _showPromptEditor = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _titleCtrl.text = state.instrumentTitle;
    _promptCtrl.text = state.instrumentPrompt;
    _negativeCtrl.text = state.instrumentNegativePrompt;
    _searchCtrl.addListener(() {
      setState(() {
        _searchFilter = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _promptCtrl.dispose();
    _negativeCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(double sec) {
    final m = sec.toInt() ~/ 60;
    final s = sec.toInt() % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDark ? AppColors.darkCard : const Color(0xFFF9FAFB);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (_titleCtrl.text != state.instrumentTitle && !_titleCtrl.selection.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _titleCtrl.text != state.instrumentTitle) {
          _titleCtrl.text = state.instrumentTitle;
        }
      });
    }

    if (_promptCtrl.text != state.instrumentPrompt && !_promptCtrl.selection.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _promptCtrl.text != state.instrumentPrompt) {
          _promptCtrl.text = state.instrumentPrompt;
        }
      });
    }

    if (_negativeCtrl.text != state.instrumentNegativePrompt && !_negativeCtrl.selection.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _negativeCtrl.text != state.instrumentNegativePrompt) {
          _negativeCtrl.text = state.instrumentNegativePrompt;
        }
      });
    }

    final filteredInstruments = InstrumentCatalog.instruments.where((inst) {
      final matchesCategory = _selectedCategory == InstrumentCategory.all ||
          inst.category == _selectedCategory;
      if (!matchesCategory) return false;
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter;
      return inst.name.toLowerCase().contains(q) ||
          inst.englishName.toLowerCase().contains(q) ||
          inst.description.toLowerCase().contains(q);
    }).toList();

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header (Clean, overflow-safe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B).withValues(alpha: 0.35), Colors.transparent]
                    : [const Color(0xFFEEF2FF), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.piano_rounded, color: Colors.white, size: 19),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Sesi Enstrümana Dönüştür',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Solo Studio',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step-by-step: Model, referans ses ve enstrüman seçimi.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Wizard Stepper Tab Bar (Adım 1, Adım 2, Adım 3)
          _buildWizardTabBar(state, isDark, borderColor),

          // Active Wizard Step Content
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep0ModelList(state, isDark, cardBg, borderColor),
                _buildStep1AudioAndBpm(state, isDark, cardBg, borderColor),
                _buildStep2InstrumentSelection(state, isDark, cardBg, borderColor, filteredInstruments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WIZARD STEPPER TAB BAR
  // -------------------------------------------------------------
  Widget _buildWizardTabBar(AppStateProvider state, bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F17) : const Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Step 1: Model
          Expanded(
            child: _buildWizardTabItem(
              stepIndex: 0,
              icon: Icons.memory_rounded,
              title: '1. Model',
              subtitle: _getShortModelName(state.selectedModel),
              isSelected: _currentStep == 0,
              isCompleted: true,
              isDark: isDark,
              onTap: () => setState(() => _currentStep = 0),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 4),
          // Step 2: Ses & BPM
          Expanded(
            child: _buildWizardTabItem(
              stepIndex: 1,
              icon: Icons.graphic_eq_rounded,
              title: '2. Ses & BPM',
              subtitle: state.instrumentRefAudioPath != null ? '${state.instrumentBpm} BPM' : 'Ses Yükle',
              isSelected: _currentStep == 1,
              isCompleted: state.instrumentRefAudioPath != null,
              isDark: isDark,
              onTap: () => setState(() => _currentStep = 1),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 4),
          // Step 3: Enstrüman
          Expanded(
            child: _buildWizardTabItem(
              stepIndex: 2,
              icon: Icons.piano_rounded,
              title: '3. Enstrüman',
              subtitle: '${state.selectedInstrument.emoji} ${state.selectedInstrument.name.split('(').first.trim()}',
              isSelected: _currentStep == 2,
              isCompleted: state.instrumentRefAudioPath != null,
              isDark: isDark,
              onTap: () => setState(() => _currentStep = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardTabItem({
    required int stepIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isCompleted,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF6366F1);
    final activeBg = isDark
        ? const Color(0xFF6366F1).withValues(alpha: 0.20)
        : const Color(0xFFEEF2FF);
    final idleBg = isDark ? const Color(0xFF161622) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : idleBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black12)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? activeColor
                      : (isCompleted ? const Color(0xFF10B981) : (isDark ? Colors.grey : Colors.black54)),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : activeColor)
                          : (isDark ? Colors.grey.shade300 : Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1.5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getShortModelName(String model) {
    if (model.toLowerCase().contains('7b')) return 'YuE 7B BF16';
    if (model.toLowerCase().contains('ace')) return 'ACE-Step';
    if (model.toLowerCase().contains('diff')) return 'DiffRhythm';
    if (model.toLowerCase().contains('studio')) return 'YuE2 Studio';
    return 'YuE 3B INT8';
  }

  // -------------------------------------------------------------
  // STEP 0: MODEL SEÇİMİ (LİSTE ŞEKLİNDE - YALNIZCA İNEN MODELLER)
  // -------------------------------------------------------------
  Widget _buildStep0ModelList(AppStateProvider state, bool isDark, Color cardBg, Color borderColor) {
    // ONLY display models that are actually installed on disk (and not sheetsage audio encoder)
    final installedList = state.models
        .where((m) => m.installed && m.id != 'sheetsage2_bf16')
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(
                number: '1',
                title: 'YAPAY ZEKA MÜZİK MODELİ (LİSTE)',
                subtitle: 'Yalnızca sisteminizde yüklü ve kullanıma hazır modeller listelenir.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              if (installedList.isEmpty) ...[
                // Default pre-packaged fallback model card
                _buildInstalledModelListCard(
                  title: 'YuE2 3B INT8 ConvRot',
                  badgeText: 'ÖNERİLEN • ULTRA HIZLI',
                  badgeColor: const Color(0xFFF59E0B),
                  vramText: '~6 GB VRAM',
                  speedText: '⚡ ~15-20 sn (Çok Hızlı)',
                  specsText: '44.1 kHz 24-bit Stereo • INT8 Dynamic Weights',
                  description:
                      'Optimize edilmiş INT8 kuantizasyonu ve döner konvolüsyonel dikkat mimarisi. Düşük gecikmeyle anlık solo ve vokal dönüştürme için idealdir.',
                  sizeText: '3.69 GB',
                  emoji: '⚡',
                  isSelected: true,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  onSelect: () => state.setSelectedModel('YuE2 3B INT8'),
                ),
              ] else ...[
                for (int i = 0; i < installedList.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildDynamicModelListCard(
                    model: installedList[i],
                    state: state,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                  ),
                ],
              ],

              const SizedBox(height: 18),

              // Model Hub Info & BYOM Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.25) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_download_rounded, size: 20, color: Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Model İndir veya Ekle (BYOM)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF312E81),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'YuE 7B, ACE-Step veya ComfyUI modellerinizi yönetmek için Model Hub\'ı açabilirsiniz.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.hub_rounded, size: 14),
                      label: const Text('Model Hub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ModelHubDialog(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Next Step Button
        _buildWizardBottomBar(
          isDark: isDark,
          borderColor: borderColor,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Sonraki Adım: Referans Ses ve BPM (${_getShortModelName(state.selectedModel)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicModelListCard({
    required ModelInfo model,
    required AppStateProvider state,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final low = '${model.id} ${model.name}'.toLowerCase();
    String emoji = '🎵';
    String badgeText = model.recommended ? 'ÖNERİLEN' : 'YÜKLÜ';
    Color badgeColor = const Color(0xFF6366F1);
    String vramText = model.vramRequired.isNotEmpty ? model.vramRequired : '~6-8 GB VRAM';
    String speedText = model.speed.isNotEmpty ? model.speed : '⚡ Normal';
    String specsText = 'Saf Model Ağırlığı • ${model.size}';
    String description = model.description;

    if (low.contains('convrot') || low.contains('int8') || (low.contains('3b') && !low.contains('studio'))) {
      emoji = '⚡';
      badgeText = 'ÖNERİLEN • ULTRA HIZLI';
      badgeColor = const Color(0xFFF59E0B);
      vramText = '~6 GB VRAM';
      speedText = '⚡ ~15-20 sn (Çok Hızlı)';
      specsText = '44.1 kHz 24-bit Stereo • INT8 Dynamic Weights';
    } else if (low.contains('7b')) {
      emoji = '👑';
      badgeText = '7B TAM BOY • ÜSTÜN VOKAL';
      badgeColor = const Color(0xFF8B5CF6);
      vramText = '~12-16 GB VRAM';
      speedText = '⚡⚡ ~35-50 sn (Üstün Kalite)';
      specsText = 'Akıcı Türkçe & İngilizce • Zengin Armoni Katmanları';
    } else if (low.contains('ace')) {
      emoji = '🚀';
      badgeText = 'YENİ NESİL • VOKAL-BEAT UYUMU';
      badgeColor = const Color(0xFF10B981);
      vramText = '~8 GB VRAM';
      speedText = '🚀 ~12 sn (Ultra Hızlı)';
      specsText = 'Güçlü Loudness • Sıkı Beat Senkronu • Transformer Trafo';
    } else if (low.contains('diff')) {
      emoji = '🌊';
      badgeText = 'ARTIFACT-FREE • DİFÜZYON';
      badgeColor = const Color(0xFF06B6D4);
      vramText = '~6-8 GB VRAM';
      speedText = '🌊 ~10 sn (Anlık Sentez)';
      specsText = 'Saf Difüzyon Mimarisi • Sıfır Dijital Gürültü';
    } else if (low.contains('studio') || low.contains('bf16')) {
      emoji = '🎛️';
      badgeText = 'MASTERING KALİTE';
      badgeColor = const Color(0xFF3B82F6);
      vramText = '~12 GB VRAM';
      speedText = '⚡⚡ Orta (Stüdyo Miksajı)';
      specsText = 'Geniş Dinamik Aralık • Saf BF16';
    }

    final isSelected = TopModelSelectorBar.isModelSelected(state.selectedModel, model.id) ||
        state.selectedModel.toLowerCase() == model.id.toLowerCase() ||
        state.selectedModel.toLowerCase() == model.name.toLowerCase();

    return _buildInstalledModelListCard(
      title: model.name,
      badgeText: badgeText,
      badgeColor: badgeColor,
      vramText: vramText,
      speedText: speedText,
      specsText: specsText,
      description: description,
      sizeText: model.size,
      emoji: emoji,
      isSelected: isSelected,
      isDark: isDark,
      cardBg: cardBg,
      borderColor: borderColor,
      onSelect: () => state.setSelectedModel(model.name),
    );
  }

  Widget _buildInstalledModelListCard({
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String vramText,
    required String speedText,
    required String specsText,
    required String description,
    required String sizeText,
    required String emoji,
    required bool isSelected,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? badgeColor.withValues(alpha: 0.12) : badgeColor.withValues(alpha: 0.08))
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? badgeColor : borderColor,
            width: isSelected ? 1.8 : 1.0,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              vramText,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            speedText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade400 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Radio Circle Indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? badgeColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? badgeColor : (isDark ? Colors.white24 : Colors.black26),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    specsText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: badgeColor.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  sizeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: REFERANS SES VE BPM SENKRONİZASYONU
  // -------------------------------------------------------------
  Widget _buildStep1AudioAndBpm(AppStateProvider state, bool isDark, Color cardBg, Color borderColor) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              _buildSectionHeader(
                number: '2',
                title: 'REFERANS SES VE TEMPO (BPM)',
                subtitle: 'Melodiyi seslendirerek kaydedin veya herhangi bir ses dosyası yükleyin.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Audio Source Selection or Active Recording
              if (state.instrumentRefAudioPath == null) ...[
                if (state.isRecordingMic) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Kayıt Yapılıyor: ${_formatDuration(state.micRecordElapsedSec)}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Melodiyi mikrofona söyleyin, ıslık çalın veya çalın.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => state.stopMicRecording(),
                          icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Kaydı Durdur ve BPM Algıla',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      // Upload File Button
                      Expanded(
                        child: InkWell(
                          onTap: () => state.pickInstrumentAudioFile(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.upload_file_rounded, size: 30, color: Color(0xFF6366F1)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ses Dosyası Yükle',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'WAV, MP3, M4A, FLAC',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Record Mic Button
                      Expanded(
                        child: InkWell(
                          onTap: () => state.startMicRecording(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.mic_rounded, size: 30, color: Color(0xFFEC4899)),
                                SizedBox(height: 8),
                                Text(
                                  'Mikrofondan Kaydet',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Doğrudan ses veya ıslık',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // Audio Loaded Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.audio_file_rounded, color: Color(0xFF10B981), size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    state.instrumentRefAudioName ?? 'Referans Ses',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Süre: ${_formatDuration(state.instrumentAudioDuration)} | ${state.instrumentBpm} BPM',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF047857),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22),
                        tooltip: 'Başka Ses Seç / Yenile',
                        onPressed: () => state.clearInstrumentAudio(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // BPM VE SÜRE SENKRONİZASYONU
              _buildSectionHeader(
                number: 'BPM',
                title: 'BPM VE SÜRE SENKRONİZASYONU',
                subtitle: 'BPM otomatik tespit edilir ve çıktı boyutu dosyanıza eşitlenir.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Tempo: ${state.instrumentBpm} BPM',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              if (state.isDetectingBpm) ...[
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 6),
                                const Text('Algılanıyor...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ] else if (state.detectedBpm != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF10B981)),
                                      Text(
                                        'Otomatik Algılandı (${state.detectedBpm})',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Süre: ${_formatDuration(state.instrumentAudioDuration)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                          onPressed: state.instrumentBpm > 60
                              ? () => state.setInstrumentBpm(state.instrumentBpm - 2)
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: state.instrumentBpm.toDouble().clamp(60.0, 180.0),
                            min: 60,
                            max: 180,
                            divisions: 24,
                            activeColor: AppColors.primary,
                            onChanged: (val) => state.setInstrumentBpm(val.toInt()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          onPressed: state.instrumentBpm < 180
                              ? () => state.setInstrumentBpm(state.instrumentBpm + 2)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Navigation Bar (Back to Step 0, Forward to Step 2)
        _buildWizardBottomBar(
          isDark: isDark,
          borderColor: borderColor,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Model Seçimi', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.instrumentRefAudioPath != null
                      ? () => setState(() => _currentStep = 2)
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    state.instrumentRefAudioPath != null
                        ? 'Sonraki: Enstrüman Seç'
                        : 'Önce Ses Yükleyin veya Kaydedin',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: ENSTRÜMAN SEÇİMİ VE DÖNÜŞTÜR
  // -------------------------------------------------------------
  Widget _buildStep2InstrumentSelection(
    AppStateProvider state,
    bool isDark,
    Color cardBg,
    Color borderColor,
    List<InstrumentModel> filteredInstruments,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              _buildSectionHeader(
                number: '3',
                title: 'DÜNYA ENSTRÜMANI SEÇ (YUE2 KATALOĞU)',
                subtitle: 'Referans melodiyi çalacak tek solo enstrümanı seçin.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // Category Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('Hepsi (${InstrumentCatalog.instruments.length})', InstrumentCategory.all),
                    const SizedBox(width: 6),
                    _buildCategoryChip('🪈 Üflemeli', InstrumentCategory.woodwinds),
                    const SizedBox(width: 6),
                    _buildCategoryChip('🎸 Telli', InstrumentCategory.plucked),
                    const SizedBox(width: 6),
                    _buildCategoryChip('🎻 Yaylı', InstrumentCategory.bowed),
                    const SizedBox(width: 6),
                    _buildCategoryChip('🎹 Tuşlu', InstrumentCategory.keyboards),
                    const SizedBox(width: 6),
                    _buildCategoryChip('🥁 Vurmalı', InstrumentCategory.percussion),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Search field
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Enstrüman ara: Ney, Keman, Bağlama, Piyano...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 16),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Instruments in 2-column flex rows
              Column(
                children: [
                  for (int i = 0; i < filteredInstruments.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInstrumentCard(
                              filteredInstruments[i],
                              state,
                              isDark,
                              cardBg,
                              borderColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (i + 1 < filteredInstruments.length)
                            Expanded(
                              child: _buildInstrumentCard(
                                filteredInstruments[i + 1],
                                state,
                                isDark,
                                cardBg,
                                borderColor,
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              // PROMPT & TEK ENSTRÜMAN İZOLASYONU
              _buildSectionHeader(
                number: '!',
                title: 'PROMPT & SAF SOLO İZOLASYONU',
                subtitle: 'Yalnızca seçilen solo enstrümanın çalması için izole prompt filtresi.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1B4B).withValues(alpha: 0.35) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saf Solo İzolasyon: Yalnızca ${state.selectedInstrument.name.split('(').first.trim()}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Davul, bas, ritim, vokal ve diğer tüm enstrümanlar filtrelenir.',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: Icon(
                            _showPromptEditor ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded,
                            size: 16,
                            color: const Color(0xFF6366F1),
                          ),
                          label: Text(
                            _showPromptEditor ? 'Gizle' : 'Promptu Gör',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1)),
                          ),
                          onPressed: () {
                            setState(() {
                              _showPromptEditor = !_showPromptEditor;
                            });
                          },
                        ),
                      ],
                    ),

                    if (_showPromptEditor) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pozitif Prompt (Yalnızca Solo Enstrüman):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          InkWell(
                            onTap: () {
                              state.resetInstrumentPromptsToDefault();
                              _promptCtrl.text = state.instrumentPrompt;
                              _negativeCtrl.text = state.instrumentNegativePrompt;
                            },
                            child: const Text(
                              'Varsayılana Dön',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF6366F1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _promptCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => state.setInstrumentPrompt(val),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Negatif Filtre (Engellenen Diğer Tüm Sesler):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _negativeCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 10.5),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                          fillColor: isDark ? AppColors.darkCard : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) => state.setInstrumentNegativePrompt(val),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // OTOMATİK İSİMLENDİRME
              _buildSectionHeader(
                number: 'T',
                title: 'OTOMATİK İSİMLENDİRME',
                subtitle: 'İsim otomatik oluşturulur, dilerseniz değiştirebilirsiniz.',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: state.instrumentTitle.isNotEmpty ? state.instrumentTitle : 'Örn: Melodi - Solo',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 18),
                ),
                onChanged: (val) => state.setInstrumentTitle(val),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Action & Convert Button
        _buildWizardBottomBar(
          isDark: isDark,
          borderColor: borderColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isGenerating) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.generationMessage,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${state.generationProgress}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: Colors.grey,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      tooltip: 'İptal Et / Temizle',
                      onPressed: () => state.clearStuckTasks(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.generationProgress / 100.0,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep = 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Ses & BPM', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (state.instrumentRefAudioPath == null || state.isGenerating)
                            ? null
                            : () => state.startInstrumentTransform(),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: (state.instrumentRefAudioPath != null && !state.isGenerating) ? 4 : 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: (state.instrumentRefAudioPath != null && !state.isGenerating)
                                ? const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: (state.instrumentRefAudioPath == null || state.isGenerating)
                                ? Colors.grey.withValues(alpha: 0.25)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (state.isGenerating) ...[
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dönüştürülüyor... (%${state.generationProgress})',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    state.selectedInstrument.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      state.instrumentRefAudioPath == null
                                          ? 'Önce Ses Yükleyin veya Kaydedin'
                                          : '${state.selectedInstrument.name.split('(').first.trim()} ile Dönüştür (${_formatDuration(state.instrumentAudioDuration)})',
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w700,
                                        color: state.instrumentRefAudioPath != null ? Colors.white : Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS
  // -------------------------------------------------------------
  Widget _buildWizardBottomBar({
    required bool isDark,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121A) : Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, InstrumentCategory category) {
    final isSelected = _selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? AppColors.darkCard : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildInstrumentCard(
    InstrumentModel inst,
    AppStateProvider state,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    final isSelected = state.selectedInstrument.id == inst.id;

    return InkWell(
      onTap: () {
        state.setInstrument(inst);
        if (_titleCtrl.text != state.instrumentTitle) {
          _titleCtrl.text = state.instrumentTitle;
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF))
              : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(inst.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inst.name,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF4338CA))
                          : (isDark ? Colors.white : AppColors.lightTextPrimary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inst.categoryLabel,
                    style: TextStyle(
                      fontSize: 9.0,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }
}
