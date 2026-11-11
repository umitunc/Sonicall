import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/song_model.dart';
import '../../providers/app_state_provider.dart';

class VocalMasteringPanel extends StatefulWidget {
  const VocalMasteringPanel({super.key});

  @override
  State<VocalMasteringPanel> createState() => _VocalMasteringPanelState();
}

class _VocalMasteringPanelState extends State<VocalMasteringPanel> {
  final TextEditingController _titleController = TextEditingController();
  bool _isPlayingOriginal = false;
  bool _isPlayingMastered = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppStateProvider>();
    _titleController.text = state.vocalMasterTitle;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_titleController.text != state.vocalMasterTitle && !_titleController.selection.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _titleController.text != state.vocalMasterTitle) {
          _titleController.text = state.vocalMasterTitle;
        }
      });
    }

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Clean Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Vokal Miks & Master',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Stüdyo',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Settings
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _buildSourceVocalCard(context, state, isDark, borderColor, textMuted),
                const SizedBox(height: 12),
                _buildEngineAndBackingCard(context, state, isDark, borderColor, textMuted),
                const SizedBox(height: 12),
                _buildStep1DeReverbCard(context, state, isDark, borderColor),
                const SizedBox(height: 12),
                _buildStep2EnhanceCard(context, state, isDark, borderColor),
                const SizedBox(height: 12),
                _buildStep3DawMasterCard(context, state, isDark, borderColor),
                if (state.lastVocalMasterResult != null) ...[
                  const SizedBox(height: 14),
                  _buildResultCard(context, state, isDark, borderColor),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),

          // Sticky Bottom Action Bar + Studio Progress
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: panelBg,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: _buildActionButton(context, state, isDark),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 0. VOKAL KAYNAĞI
  // ==========================================
  Widget _buildSourceVocalCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
    Color textMuted,
  ) {
    final hasAudio = state.vocalMasterRefPath != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAudio ? const Color(0xFF6366F1).withValues(alpha: 0.5) : borderColor,
          width: hasAudio ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: Color(0xFF6366F1), size: 17),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Vokal Kaydı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (hasAudio)
                InkWell(
                  onTap: () => state.clearVocalMasterAudio(),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                        SizedBox(width: 3),
                        Text('Kaldır', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAudio)
            InkWell(
              onTap: () => state.pickVocalMasterAudio(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262A36) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file_rounded, size: 28, color: Color(0xFF6366F1)),
                    const SizedBox(height: 6),
                    const Text(
                      'Vokal Seç',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'WAV • MP3 • FLAC • M4A',
                      style: TextStyle(fontSize: 10.5, color: textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A36) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(
                        _isPlayingOriginal ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                      onPressed: () {
                        if (state.vocalMasterRefPath != null) {
                          if (_isPlayingOriginal) {
                            state.audio.pause();
                            setState(() => _isPlayingOriginal = false);
                          } else {
                            state.audio.playPathOrUrl(
                              state.vocalMasterRefPath!,
                              title: 'Ham Vokal',
                            );
                            setState(() {
                              _isPlayingOriginal = true;
                              _isPlayingMastered = false;
                            });
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.vocalMasterRefName ?? 'vokal.wav',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(state.vocalMasterDuration),
                          style: TextStyle(fontSize: 10.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.folder_open_rounded, size: 17, color: Color(0xFF6366F1)),
                    tooltip: 'Değiştir',
                    onPressed: () => state.pickVocalMasterAudio(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Kayıt adı',
                  prefixIcon: Icon(Icons.edit_rounded, size: 15),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                onChanged: (v) => state.setVocalMasterTitle(v),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // GENERATIVE MODEL TUNING & INSTRUMENTAL MIXDOWN
  // ==========================================
  Widget _buildEngineAndBackingCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
    Color textMuted,
  ) {
    final instSongs = state.instrumentalSongs;
    final allLibrary = state.allSongs.where((s) => !s.isVocalMaster).toList();
    final selectableSongs = instSongs.isNotEmpty ? instSongs : allLibrary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.equalizer_rounded, size: 17, color: Color(0xFF10B981)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Altyapı & Model Uyumu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Target Generative Engine Selector (Icon + Short Name)
          Row(
            children: [
              Expanded(
                child: _buildEnginePill(
                  icon: Icons.bolt_rounded,
                  label: 'ACE-Step 1.5 XL',
                  selected: state.vocalTargetEngine == 'ace_step_15_xl',
                  accent: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () => state.setVocalTargetEngine('ace_step_15_xl'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildEnginePill(
                  icon: Icons.music_note_rounded,
                  label: 'YuE2',
                  selected: state.vocalTargetEngine == 'yue2',
                  accent: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => state.setVocalTargetEngine('yue2'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildEnginePill(
                  icon: Icons.tune_rounded,
                  label: 'Evrensel',
                  selected: state.vocalTargetEngine == 'universal',
                  accent: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: () => state.setVocalTargetEngine('universal'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Optional Instrumental Backing Mixdown
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262A36) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_rounded, size: 15, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Enstrümantal ile Birleştir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (state.vocalBackingPath != null)
                      InkWell(
                        onTap: () => state.clearVocalBacking(),
                        child: const Icon(Icons.close_rounded, size: 15, color: Colors.redAccent),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<Song>(
                        tooltip: 'Kütüphaneden Seç',
                        onSelected: (song) => state.setVocalBackingFromSong(song),
                        itemBuilder: (ctx) {
                          if (selectableSongs.isEmpty) {
                            return const [
                              PopupMenuItem<Song>(
                                enabled: false,
                                child: Text('Kütüphanede altyapı yok', style: TextStyle(fontSize: 12)),
                              ),
                            ];
                          }
                          return selectableSongs.take(15).map((s) {
                            return PopupMenuItem<Song>(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(
                                    s.isInstrumental ? Icons.piano_rounded : Icons.music_note_rounded,
                                    size: 15,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.library_music_rounded, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  state.vocalBackingName ?? 'Sadece Vokal (Altyapı Seç)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: state.vocalBackingName != null ? FontWeight.w700 : FontWeight.w500,
                                    color: state.vocalBackingName != null ? const Color(0xFF10B981) : textMuted,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Dosyadan Altyapı Seç',
                      child: InkWell(
                        onTap: () => state.pickVocalBackingFile(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF10B981)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.vocalBackingPath != null) ...[
                  const SizedBox(height: 8),
                  _buildCompactSlider(
                    label: 'Altyapı Dengesi',
                    valueText: '%${(state.vocalBackingLevel * 100).toInt()}',
                    value: state.vocalBackingLevel.clamp(0.3, 1.1),
                    min: 0.3,
                    max: 1.1,
                    color: const Color(0xFF10B981),
                    onChanged: (v) => state.setVocalBackingLevel(v),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnginePill({
    required IconData icon,
    required String label,
    required bool selected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: isDark ? 0.20 : 0.12)
              : (isDark ? const Color(0xFF262A36) : Colors.white),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? accent : (isDark ? Colors.white12 : Colors.black12),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? accent : Colors.grey),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? (isDark ? Colors.white : accent) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. SES YALITIMI (DE-REVERB & DE-NOISE)
  // ==========================================
  Widget _buildStep1DeReverbCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    const accent = Color(0xFF3B82F6);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 17, color: accent),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '1. Ses Yalıtımı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: state.vocalEnableDereverb,
                  onChanged: (v) => state.setVocalEnableDereverb(v),
                  activeThumbColor: accent,
                ),
              ),
            ],
          ),
          if (state.vocalEnableDereverb) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildModeChoice(
                    label: 'Derin Yalıtım',
                    selected: state.vocalDereverbModel.contains('mel_band'),
                    color: accent,
                    isDark: isDark,
                    onTap: () => state.setVocalDereverbModel('anvuew/dereverb_mel_band_roformer'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildModeChoice(
                    label: 'Doğal Akustik',
                    selected: !state.vocalDereverbModel.contains('mel_band'),
                    color: accent,
                    isDark: isDark,
                    onTap: () => state.setVocalDereverbModel('anvuew/dereverb_bs_roformer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCompactSlider(
              label: 'Yankı Temizliği',
              valueText: '%${(state.vocalDereverbIntensity * 100).toInt()}',
              value: state.vocalDereverbIntensity,
              min: 0.2,
              max: 1.0,
              color: accent,
              onChanged: (v) => state.setVocalDereverbIntensity(v),
            ),
            _buildCompactSlider(
              label: 'Gürültü Kapısı',
              valueText: '${state.vocalDenoiseThresholdDb.toInt()} dB',
              value: state.vocalDenoiseThresholdDb,
              min: -55.0,
              max: -20.0,
              color: accent,
              onChanged: (v) => state.setVocalDenoiseThresholdDb(v),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 2. VOKAL GÖVDE & PARLAKLIK
  // ==========================================
  Widget _buildStep2EnhanceCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    const accent = Color(0xFFEC4899);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 17, color: accent),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '2. Gövde & Parlaklık',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: state.vocalEnableEnhancement,
                  onChanged: (v) => state.setVocalEnableEnhancement(v),
                  activeThumbColor: accent,
                ),
              ),
            ],
          ),
          if (state.vocalEnableEnhancement) ...[
            const SizedBox(height: 6),
            _buildCompactSlider(
              label: 'Paralel Denge',
              valueText: '%${(state.vocalParallelBlend * 100).toInt()}',
              value: state.vocalParallelBlend,
              min: 0.1,
              max: 0.9,
              color: accent,
              onChanged: (v) => state.setVocalParallelBlend(v),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildCompactSlider(
                    label: 'Parlaklık',
                    valueText: '%${(state.vocalAirBoost * 100).toInt()}',
                    value: state.vocalAirBoost,
                    min: 0.0,
                    max: 1.0,
                    color: accent,
                    onChanged: (v) => state.setVocalAirBoost(v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactSlider(
                    label: 'Gövde',
                    valueText: '%${(state.vocalBodyWarmth * 100).toInt()}',
                    value: state.vocalBodyWarmth,
                    min: 0.0,
                    max: 1.0,
                    color: accent,
                    onChanged: (v) => state.setVocalBodyWarmth(v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: state.vocalDeEsserEnabled,
                    onChanged: (v) => state.setVocalDeEsserEnabled(v ?? true),
                    activeColor: accent,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Sert Harf Yumuşatma (De-Esser)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 3. MİKS & MASTER ZİNCİRİ
  // ==========================================
  Widget _buildStep3DawMasterCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    const accent = Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 17, color: accent),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '3. Stüdyo Master & Mekân',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: state.vocalEnableDawMaster,
                  onChanged: (v) => state.setVocalEnableDawMaster(v),
                  activeThumbColor: accent,
                ),
              ),
            ],
          ),
          if (state.vocalEnableDawMaster) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildCompactSlider(
                    label: 'Alt Kesim',
                    valueText: '${state.vocalLowCutHz.toInt()} Hz',
                    value: state.vocalLowCutHz,
                    min: 60.0,
                    max: 130.0,
                    color: accent,
                    onChanged: (v) => state.setVocalLowCutHz(v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactSlider(
                    label: 'Kutu Kesimi',
                    valueText: '${state.vocalBoxyMudCutHz.toInt()} Hz',
                    value: state.vocalBoxyMudCutHz,
                    min: 260.0,
                    max: 520.0,
                    color: Colors.orangeAccent,
                    onChanged: (v) => state.setVocalBoxyMudCutHz(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildAmbienceChip('Plate Reverb', 'Plaka', Icons.blur_on_rounded, state, isDark),
                _buildAmbienceChip('Slapback Delay', 'Eko', Icons.repeat_rounded, state, isDark),
                _buildAmbienceChip('Chamber', 'Oda', Icons.meeting_room_rounded, state, isDark),
                _buildAmbienceChip('Off', 'Kuru', Icons.mic_off_rounded, state, isDark),
              ],
            ),
            if (state.vocalStudioAmbienceType != 'Off') ...[
              const SizedBox(height: 6),
              _buildCompactSlider(
                label: 'Mekân Derinliği',
                valueText: '%${(state.vocalAmbienceWetMix * 100).toInt()}',
                value: state.vocalAmbienceWetMix.clamp(0.05, 0.35),
                min: 0.05,
                max: 0.35,
                color: accent,
                onChanged: (v) => state.setVocalAmbienceWetMix(v),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildModeChoice({
    required String label,
    required bool selected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? const Color(0xFF262A36) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? (isDark ? Colors.white : color) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSlider({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              valueText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbienceChip(
    String type,
    String label,
    IconData icon,
    AppStateProvider state,
    bool isDark,
  ) {
    final isSel = state.vocalStudioAmbienceType == type;
    return InkWell(
      onTap: () => state.setVocalStudioAmbienceType(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF262A36) : Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RESULT CARD
  // ==========================================
  Widget _buildResultCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    final audioUrl = state.vocalMasterResultAudioUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241F) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Stüdyo Kaydı Hazır',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Klasörde Göster',
                onPressed: () => state.openVocalFolder(),
                icon: const Icon(Icons.folder_open_rounded, size: 17, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_isPlayingMastered) {
                      state.audio.pause();
                      setState(() => _isPlayingMastered = false);
                    } else {
                      state.audio.playPathOrUrl(audioUrl, title: state.vocalMasterTitle);
                      setState(() {
                        _isPlayingMastered = true;
                        _isPlayingOriginal = false;
                      });
                    }
                  },
                  icon: Icon(_isPlayingMastered ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 17),
                  label: Text(
                    _isPlayingMastered ? 'Durdur' : 'Dinle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (state.vocalMasterRefPath != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_isPlayingOriginal) {
                        state.audio.pause();
                        setState(() => _isPlayingOriginal = false);
                      } else {
                        state.audio.playPathOrUrl(state.vocalMasterRefPath!, title: 'Ham Vokal');
                        setState(() {
                          _isPlayingOriginal = true;
                          _isPlayingMastered = false;
                        });
                      }
                    },
                    icon: Icon(_isPlayingOriginal ? Icons.pause_rounded : Icons.compare_arrows_rounded, size: 16),
                    label: Text(
                      _isPlayingOriginal ? 'Durdur' : 'Kıyasla',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM ACTION / STUDIO PROGRESS BAR
  // ==========================================
  Widget _buildActionButton(BuildContext context, AppStateProvider state, bool isDark) {
    if (state.isVocalMasterProcessing) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.vocalMasterMessage.isNotEmpty
                        ? state.vocalMasterMessage
                        : 'Miks ve mastering yapılıyor...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.vocalMasterProgress,
                minHeight: 5,
                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ],
        ),
      );
    }

    final hasAudio = state.vocalMasterRefPath != null;
    final buttonText = !hasAudio
        ? 'Önce Vokal Seçin'
        : (state.vocalBackingPath != null ? 'Vokal & Altyapıyı Miksle' : 'Miks & Master Başlat');

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: hasAudio ? () => state.processVocalMastering() : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: hasAudio ? 4 : 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: hasAudio
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: hasAudio ? null : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: hasAudio ? Colors.white : Colors.grey,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: hasAudio ? Colors.white : Colors.grey,
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
}
