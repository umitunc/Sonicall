import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/top_model_selector_bar.dart';

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

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Vokal Mix & Mastering',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'AI + DAW DSP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Oda yankısı, dip gürültü ve çamurlu kutu frekanslarını silip stüdyo vokal zincirine oturtun',
                        style: TextStyle(fontSize: 10.5, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Settings & Workflow Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // STEP 0: VOKAL KAYNAĞI SEÇİMİ
                _buildSourceVocalCard(context, state, isDark, borderColor, textMuted),

                const SizedBox(height: 16),

                // STEP 1 CARD: DE-REVERB & DE-NOISE
                _buildStep1DeReverbCard(context, state, isDark, borderColor, textMuted),

                const SizedBox(height: 16),

                // STEP 2 CARD: VOCAL ENHANCEMENT (PARALLEL BLEND)
                _buildStep2EnhanceCard(context, state, isDark, borderColor, textMuted),

                const SizedBox(height: 16),

                // STEP 3 CARD: DAW MIX & MASTERING CHAIN
                _buildStep3DawMasterCard(context, state, isDark, borderColor, textMuted),

                const SizedBox(height: 20),

                // MASTERED RESULT CARD (IF READY)
                if (state.lastVocalMasterResult != null) ...[
                  _buildResultCard(context, state, isDark, borderColor),
                  const SizedBox(height: 16),
                ],

                // PROCESSING BAR / ACTION BUTTON
                _buildActionButton(context, state),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 0: REFERANS VOKAL SEÇİMİ
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAudio ? const Color(0xFF6366F1).withOpacity(0.5) : borderColor,
          width: hasAudio ? 1.5 : 1,
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
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.mic_none_rounded, color: Color(0xFF6366F1), size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ham Vokal Kaydı (Dry Vocal Input)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (hasAudio)
                TextButton.icon(
                  onPressed: () => state.clearVocalMasterAudio(),
                  icon: const Icon(Icons.close_rounded, size: 14, color: Colors.redAccent),
                  label: const Text('Kaldır', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAudio) ...[
            InkWell(
              onTap: () => state.pickVocalMasterAudio(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262A36) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 34, color: Color(0xFF6366F1)),
                    const SizedBox(height: 8),
                    const Text(
                      'Vokal Ses Dosyası Yükle (WAV, MP3, FLAC)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yalıtımsız oda veya ev mikrofonuyla kaydedilmiş ham vokali seçin',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A36) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isPlayingOriginal ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF6366F1),
                        size: 22,
                      ),
                      onPressed: () {
                        if (state.vocalMasterRefPath != null) {
                          if (_isPlayingOriginal) {
                            state.audio.pause();
                            setState(() => _isPlayingOriginal = false);
                          } else {
                            state.audio.playPathOrUrl(state.vocalMasterRefPath!, title: 'Ham Vokal Kaydı (Dry)');
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
                          state.vocalMasterRefName ?? 'vokal_kayit.wav',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Süre: ${_formatDuration(state.vocalMasterDuration)}',
                              style: TextStyle(fontSize: 10.5, color: textMuted),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ham Kayıt (Oda Reverb + Dip Gürültü Var)',
                                style: TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // ADIM 1: ODAYI VE YANKIYI SİLMEK (DE-REVERB)
  // ==========================================
  Widget _buildStep1DeReverbCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ADIM 1',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Odayı ve Yankıyı Silmek (De-Reverb & De-Noise)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: state.vocalEnableDereverb,
                onChanged: (v) => state.setVocalEnableDereverb(v),
                activeColor: const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Konuşma modelleri yerine müzik modeli kullanarak şarkı söylerken uzayan notaları ve nefes tınısını bozmadan oda duvar yankısını bıçak gibi keser.',
            style: TextStyle(fontSize: 10.5, color: textMuted),
          ),
          const SizedBox(height: 10),

          // En İyi Model Seçimi
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
                    const Icon(Icons.auto_awesome, color: Color(0xFF3B82F6), size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'En İyi Model (Altın Standart):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '#1 Dünyanın En İyisi',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildModelRadioOption(
                  title: 'anvuew/dereverb_mel_band_roformer',
                  subtitle: 'Mel-Band RoFormer: Doğal vokal tınısını korur, tüm oda yankısını yok eder.',
                  selected: state.vocalDereverbModel == 'anvuew/dereverb_mel_band_roformer',
                  onTap: () => state.setVocalDereverbModel('anvuew/dereverb_mel_band_roformer'),
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _buildModelRadioOption(
                  title: 'anvuew/dereverb_bs_roformer',
                  subtitle: 'BS-RoFormer: Hızlı bant ayrıştırma mimarisi, alternatif yüksek performans.',
                  selected: state.vocalDereverbModel == 'anvuew/dereverb_bs_roformer',
                  onTap: () => state.setVocalDereverbModel('anvuew/dereverb_bs_roformer'),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Sliders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('De-Reverb Yoğunluğu:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('%${(state.vocalDereverbIntensity * 100).toInt()}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
            ],
          ),
          Slider(
            value: state.vocalDereverbIntensity,
            min: 0.2,
            max: 1.0,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (v) => state.setVocalDereverbIntensity(v),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Dip Gürültü Eşiği (Fan / Ortam Sesi):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('${state.vocalDenoiseThresholdDb.toInt()} dB',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
            ],
          ),
          Slider(
            value: state.vocalDenoiseThresholdDb,
            min: -55.0,
            max: -20.0,
            activeColor: const Color(0xFF3B82F6),
            onChanged: (v) => state.setVocalDenoiseThresholdDb(v),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADIM 2: VOCAL ENHANCEMENT (PARALLEL BLEND)
  // ==========================================
  Widget _buildStep2EnhanceCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ADIM 2',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEC4899)),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mikrofon Kalitesi & Gövdeyi Artırmak (Enhancement)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: state.vocalEnableEnhancement,
                onChanged: (v) => state.setVocalEnableEnhancement(v),
                activeColor: const Color(0xFFEC4899),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Oda yankısı silindikten sonra cılızlaşan sese stüdyo gövdesi (body) ve üst frekans parlaklığı (Air) katar.',
            style: TextStyle(fontSize: 10.5, color: textMuted),
          ),
          const SizedBox(height: 10),

          // En İyi Model Seçimi
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
                _buildModelRadioOption(
                  title: 'ResembleAI/resemble-enhance',
                  subtitle: 'CFM Tabanlı En İyi Enhancer: Stüdyo kondenser mikrofon derinliği ve hava katar.',
                  selected: state.vocalEnhancerModel == 'ResembleAI/resemble-enhance',
                  onTap: () => state.setVocalEnhancerModel('ResembleAI/resemble-enhance'),
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _buildModelRadioOption(
                  title: 'haoheliu/voicefixer',
                  subtitle: 'VoiceFixer: Bozuk ve dar bantlı vokalleri 44.1kHz stüdyo genişliğine rekonstrükte eder.',
                  selected: state.vocalEnhancerModel == 'haoheliu/voicefixer',
                  onTap: () => state.setVocalEnhancerModel('haoheliu/voicefixer'),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // PARALLEL PROCESSING GOLDEN RATIO SLIDER
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899).withOpacity(0.12),
                  const Color(0xFF8B5CF6).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers_rounded, size: 14, color: Color(0xFFEC4899)),
                        SizedBox(width: 6),
                        Text(
                          'Paralel Miks (Parallel Wet/Dry):',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Text(
                      '%${(state.vocalParallelBlend * 100).toInt()} (Önerilen: %40 - %50)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: state.vocalParallelBlend,
                  min: 0.1,
                  max: 0.9,
                  activeColor: const Color(0xFFEC4899),
                  onChanged: (v) => state.setVocalParallelBlend(v),
                ),
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Kritik Stüdyo İpucu: Kuru vokal ile AI çıktısını %45 oranında karıştırmak "s/ş" seslerinin yapaylaşmasını önler, sesi doğal tutar.',
                        style: TextStyle(fontSize: 10, color: textMuted, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Air & Body Sliders
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Air (>10kHz):', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                        Text('%${(state.vocalAirBoost * 100).toInt()}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: state.vocalAirBoost,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFFEC4899),
                      onChanged: (v) => state.setVocalAirBoost(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gövde (~200Hz):', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                        Text('%${(state.vocalBodyWarmth * 100).toInt()}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Slider(
                      value: state.vocalBodyWarmth,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFFEC4899),
                      onChanged: (v) => state.setVocalBodyWarmth(v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            children: [
              Checkbox(
                value: state.vocalDeEsserEnabled,
                onChanged: (v) => state.setVocalDeEsserEnabled(v ?? true),
                activeColor: const Color(0xFFEC4899),
              ),
              const Text(
                'Akıllı De-Esser Koruması (5.5kHz - 8.5kHz sibilance bastırma)',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ADIM 3: DAW İÇİNDE MIX & MASTERING ZİNCİRİ
  // ==========================================
  Widget _buildStep3DawMasterCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ADIM 3',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'DAW Mix & Master Zinciri (Final Dokunuş)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: state.vocalEnableDawMaster,
                onChanged: (v) => state.setVocalEnableDawMaster(v),
                activeColor: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Temizlik EQ\'su, 4:1 stüdyo kompresörü ve temiz yapay plate reverb ile vokali profesyonel prodüksiyon standartlarına oturtur.',
            style: TextStyle(fontSize: 10.5, color: textMuted),
          ),
          const SizedBox(height: 12),

          // 1. Temizlik EQ'su
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
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text('1. Temizlik EQ\'su (Sub & Kutu/Banyo Kesimi):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Low-Cut (Sub Rumble Temizliği):', style: TextStyle(fontSize: 10.5)),
                    Text('${state.vocalLowCutHz.toInt()} Hz',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                  ],
                ),
                Slider(
                  value: state.vocalLowCutHz,
                  min: 60.0,
                  max: 130.0,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (v) => state.setVocalLowCutHz(v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kutu / Banyo Çamurlu Rezonans Kesimi:', style: TextStyle(fontSize: 10.5)),
                    Text('${state.vocalBoxyMudCutHz.toInt()} Hz (${state.vocalBoxyMudGainDb} dB)',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.orangeAccent)),
                  ],
                ),
                Slider(
                  value: state.vocalBoxyMudCutHz,
                  min: 280.0,
                  max: 520.0,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) => state.setVocalBoxyMudCutHz(v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. Stüdyo Kompresörü (4:1)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262A36) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.compress_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('2. VCA / Optik Kompresör (4:1 Oran):',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      Text('Hızlı attack, orta release, +3.5 dB otomatik kazanç ile dinamik dengeleme',
                          style: TextStyle(fontSize: 9.5, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('4:1 Aktif',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Yapay Stüdyo Mekânı (Plate Reverb & Slapback)
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
                const Row(
                  children: [
                    Icon(Icons.surround_sound_rounded, size: 15, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Text('3. Yapay Stüdyo Mekânı (Ambience):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAmbienceChip('Plate Reverb', state, isDark),
                    const SizedBox(width: 6),
                    _buildAmbienceChip('Slapback Delay', state, isDark),
                    const SizedBox(width: 6),
                    _buildAmbienceChip('Chamber', state, isDark),
                    const SizedBox(width: 6),
                    _buildAmbienceChip('Off', state, isDark),
                  ],
                ),
                if (state.vocalStudioAmbienceType != 'Off') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mekân Islaklığı (Wet Mix):', style: TextStyle(fontSize: 10.5)),
                      Text('%${(state.vocalAmbienceWetMix * 100).toInt()}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ],
                  ),
                  Slider(
                    value: state.vocalAmbienceWetMix,
                    min: 0.05,
                    max: 0.35,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => state.setVocalAmbienceWetMix(v),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbienceChip(String type, AppStateProvider state, bool isDark) {
    final isSel = state.vocalStudioAmbienceType == type;
    return InkWell(
      onTap: () => state.setVocalStudioAmbienceType(type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF10B981) : (isDark ? const Color(0xFF1F232E) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type == 'Off' ? 'Kuru (Dry)' : type,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildModelRadioOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2C3246) : const Color(0xFFEFF6FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? const Color(0xFF3B82F6) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? const Color(0xFF3B82F6) : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RESULT CARD (MASTERED AUDIO)
  // ==========================================
  Widget _buildResultCard(
    BuildContext context,
    AppStateProvider state,
    bool isDark,
    Color borderColor,
  ) {
    final res = state.lastVocalMasterResult!;
    final audioUrl = state.vocalMasterResultAudioUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14241F) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stüdyo Mastering Hazır!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                    Text('24-Bit / 44.1kHz Stüdyo Çıktısı oluşturuldu ve Kütüphaneye eklendi',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // A/B Playback Comparison Buttons
          Row(
            children: [
              // Play Mastered
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_isPlayingMastered) {
                      state.audio.pause();
                      setState(() => _isPlayingMastered = false);
                    } else {
                      state.audio.playPathOrUrl(audioUrl, title: 'Mastered Stüdyo Vokali (Wet)');
                      setState(() {
                        _isPlayingMastered = true;
                        _isPlayingOriginal = false;
                      });
                    }
                  },
                  icon: Icon(_isPlayingMastered ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                  label: Text(_isPlayingMastered ? 'Durdur' : 'Stüdyo Master Dinle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // A/B Dry Compare
              if (state.vocalMasterRefPath != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_isPlayingOriginal) {
                        state.audio.pause();
                        setState(() => _isPlayingOriginal = false);
                      } else {
                        state.audio.playPathOrUrl(state.vocalMasterRefPath!, title: 'Ham Vokal Kaydı (Dry)');
                        setState(() {
                          _isPlayingOriginal = true;
                          _isPlayingMastered = false;
                        });
                      }
                    },
                    icon: Icon(_isPlayingOriginal ? Icons.pause_rounded : Icons.compare_arrows_rounded, size: 16),
                    label: Text(_isPlayingOriginal ? 'Durdur' : 'Ham Kayıtla Kıyasla'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => state.openVocalFolder(),
                icon: const Icon(Icons.folder_open_rounded, size: 14),
                label: const Text('Klasörde Göster', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION / PROCESS BUTTON
  // ==========================================
  Widget _buildActionButton(BuildContext context, AppStateProvider state) {
    if (state.isVocalMasterProcessing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: state.vocalMasterProgress,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 10),
            Text(
              state.vocalMasterMessage,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final hasAudio = state.vocalMasterRefPath != null;

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: hasAudio
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: hasAudio ? null : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasAudio
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: hasAudio ? () => state.processVocalMastering() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              hasAudio ? '3 Adımlı Vokal Stüdyo Mastering\'i Başlat' : 'Önce Vokal Dosyası Yükleyin',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
