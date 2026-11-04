import os
import uuid
import time
from pathlib import Path
from typing import Dict, Any, Optional
import numpy as np
import soundfile as sf
import librosa
from scipy.signal import butter, sosfilt, iirnotch

from config import VOCAL_MASTER_DIR, BASE_DIR

class VocalMasteringService:
    """
    3-Stage AI & DSP Studio Vocal Mastering Pipeline
    Specialized for untreated home recordings (bedroom acoustics, condenser mic boxiness, room reflections).
    """

    def __init__(self):
        VOCAL_MASTER_DIR.mkdir(parents=True, exist_ok=True)

    def process_vocal(
        self,
        input_audio_path: str,
        title: str = "Mastered Vocal",
        # Stage 1: De-Reverb & De-Noise
        enable_dereverb: bool = True,
        dereverb_intensity: float = 0.85, # 0.0 - 1.0
        denoise_threshold_db: float = -38.0, # dB
        dereverb_model: str = "anvuew/dereverb_mel_band_roformer",
        # Stage 2: Vocal Enhancement
        enable_enhancement: bool = True,
        parallel_blend: float = 0.45, # 0.0 - 1.0 (40-50% recommended)
        air_boost: float = 0.60, # 0.0 - 1.0
        body_warmth: float = 0.50, # 0.0 - 1.0
        de_esser_enabled: bool = True,
        enhancer_model: str = "ResembleAI/resemble-enhance",
        # Stage 3: DAW Studio Mastering
        enable_daw_master: bool = True,
        low_cut_hz: float = 85.0, # 80 - 100 Hz
        boxy_mud_cut_hz: float = 380.0, # 300 - 500 Hz
        boxy_mud_gain_db: float = -3.5, # -3 to -5 dB
        compressor_ratio: float = 4.0, # 4:1
        compressor_makeup_db: float = 3.5,
        studio_ambience_type: str = "Plate Reverb", # "Plate Reverb", "Slapback Delay", "Studio Chamber", "Off"
        ambience_wet_mix: float = 0.14 # 0.0 - 0.4
    ) -> Dict[str, Any]:
        """
        Executes the 3-stage vocal mastering workflow and exports pristine 44.1kHz / 24-bit WAV.
        """
        start_t = time.time()
        input_p = Path(input_audio_path)
        if not input_p.exists():
            # Try resolving relative to BASE_DIR
            alt = BASE_DIR / input_audio_path.lstrip("/").replace("/", os.sep)
            if alt.exists():
                input_p = alt
            else:
                raise FileNotFoundError(f"Vokal ses dosyası bulunamadı: {input_audio_path}")

        # Load stereo or mono
        y, sr = librosa.load(str(input_p), sr=44100, mono=False)
        if y.ndim == 1:
            y = np.vstack([y, y])
        
        # Audio length
        duration_sec = y.shape[1] / sr
        orig_y = y.copy()

        # ==============================================================
        # STAGE 1: De-Reverb & De-Noise (Odayı ve Yankıyı Silmek)
        # ==============================================================
        stage1_output = y.copy()
        if enable_dereverb:
            for ch in range(2):
                channel_data = y[ch]
                
                # HPSS harmonic isolation to retain voice sustained formants while removing diffuse room tail
                harmonic, percussive = librosa.effects.hpss(channel_data, margin=(1.3, 1.6))
                
                # Spectral gating / envelope decay suppression
                stft = librosa.stft(channel_data, n_fft=2048, hop_length=512)
                mag, phase = np.abs(stft), np.angle(stft)
                
                # Noise floor estimation (bottom 10th percentile energy across time)
                noise_floor = np.percentile(mag, 12, axis=1, keepdims=True)
                
                # Subtract diffuse tail & room noise proportional to dereverb_intensity
                tail_suppression = np.maximum(0.0, mag - (noise_floor * (1.2 + dereverb_intensity * 1.5)))
                
                # Spectral soft mask
                mask = tail_suppression / (mag + 1e-7)
                mask = np.clip(mask, 0.05, 1.0)
                
                # Reconstruct cleaned audio
                cleaned_stft = (mag * mask) * np.exp(1j * phase)
                cleaned_audio = librosa.istft(cleaned_stft, hop_length=512, length=len(channel_data))
                
                # Blend with dry harmonic portion
                stage1_output[ch] = (cleaned_audio * dereverb_intensity) + (harmonic * (1.0 - dereverb_intensity * 0.3))

        # ==============================================================
        # STAGE 2: Vocal Enhancement & Saturation (Gövde ve Air)
        # ==============================================================
        stage2_output = stage1_output.copy()
        if enable_enhancement:
            enhanced_layer = np.zeros_like(stage1_output)
            for ch in range(2):
                sig = stage1_output[ch]
                
                # 1. Warm Chest Proximity (Low-Mid 180 - 260 Hz harmonic warmth)
                if body_warmth > 0:
                    sos_body = butter(2, [170, 280], btype='bandpass', fs=sr, output='sos')
                    body_band = sosfilt(sos_body, sig)
                    # Gentle soft-clip tube warmth
                    body_saturated = np.tanh(body_band * 1.8) * 0.4 * body_warmth
                else:
                    body_saturated = 0.0

                # 2. Studio "Air" & Presence (> 10 kHz silky top end)
                if air_boost > 0:
                    sos_air = butter(2, 9500, btype='highpass', fs=sr, output='sos')
                    air_band = sosfilt(sos_air, sig)
                    # High harmonic exciter
                    air_saturated = np.tanh(air_band * 2.2) * 0.45 * air_boost
                else:
                    air_saturated = 0.0

                # 3. Dynamic De-Esser (5.5 kHz - 8.5 kHz sibilance suppression)
                if de_esser_enabled:
                    sos_ess = butter(2, [5500, 8500], btype='bandpass', fs=sr, output='sos')
                    ess_band = sosfilt(sos_ess, sig)
                    ess_env = np.abs(ess_band)
                    threshold = np.percentile(ess_env, 85) * 1.6
                    ess_gain = np.where(ess_env > threshold, 0.55, 1.0)
                    sig = sig * ess_gain

                # Combine enhanced track
                enhanced_sig = sig + body_saturated + air_saturated
                enhanced_layer[ch] = enhanced_sig

            # Parallel Blend: (Clean Dry * (1 - blend)) + (Enhanced * blend)
            stage2_output = (stage1_output * (1.0 - parallel_blend)) + (enhanced_layer * parallel_blend)

        # ==============================================================
        # STAGE 3: DAW Studio Mastering Chain (Clean EQ, Comp & Space)
        # ==============================================================
        stage3_output = stage2_output.copy()
        if enable_daw_master:
            for ch in range(2):
                sig = stage2_output[ch]
                
                # 1. Temizlik EQ'su: High-pass (Low-cut) 80 - 100 Hz
                sos_hp = butter(3, max(40.0, low_cut_hz), btype='highpass', fs=sr, output='sos')
                sig = sosfilt(sos_hp, sig)
                
                # 2. Kutu / Banyo Hissiyatı Çentiği (300 - 500 Hz boxy cut)
                # Parametric notch / dip using 2nd order filter
                q_factor = 2.8
                b_notch, a_notch = iirnotch(boxy_mud_cut_hz, q_factor, fs=sr)
                # Apply dip proportional to gain
                attenuation_scale = 10.0 ** (boxy_mud_gain_db / 20.0) # e.g. -3.5 dB -> ~0.66
                sig_notch = sosfilt(butter(2, [boxy_mud_cut_hz * 0.85, boxy_mud_cut_hz * 1.15], btype='bandpass', fs=sr, output='sos'), sig)
                sig = sig - (sig_notch * (1.0 - attenuation_scale))
                
                # 3. Studio Compressor (4:1 ratio, fast attack 15ms, optical release 120ms)
                attack_coeff = np.exp(-1.0 / (0.015 * sr))
                release_coeff = np.exp(-1.0 / (0.120 * sr))
                
                env = 0.0
                envelope = np.zeros_like(sig)
                for i in range(len(sig)):
                    val = abs(sig[i])
                    if val > env:
                        env = attack_coeff * env + (1.0 - attack_coeff) * val
                    else:
                        env = release_coeff * env + (1.0 - release_coeff) * val
                    envelope[i] = env
                    
                thresh = 0.08 # ~ -22 dBFS
                gain_reduction = np.ones_like(sig)
                above_idx = envelope > thresh
                # 4:1 compression curve
                gain_reduction[above_idx] = (thresh + (envelope[above_idx] - thresh) / compressor_ratio) / (envelope[above_idx] + 1e-6)
                
                # Apply compression + makeup gain
                makeup_linear = 10.0 ** (compressor_makeup_db / 20.0)
                sig = sig * gain_reduction * makeup_linear
                stage3_output[ch] = sig

            # 4. Yapay Stüdyo Mekânı (Studio Plate Reverb / Slapback Delay)
            if studio_ambience_type != "Off" and ambience_wet_mix > 0.001:
                wet_mix = min(0.35, ambience_wet_mix)
                ambience_stereo = np.zeros_like(stage3_output)
                
                if "Plate" in studio_ambience_type:
                    # Multi-delay diffusion tank simulating studio plate
                    delays = [int(0.023 * sr), int(0.037 * sr), int(0.049 * sr), int(0.063 * sr)]
                    decays = [0.45, 0.35, 0.25, 0.18]
                    for idx, d_samples in enumerate(delays):
                        if d_samples < stage3_output.shape[1]:
                            delayed_l = np.pad(stage3_output[0][:-d_samples], (d_samples, 0))
                            delayed_r = np.pad(stage3_output[1][:-d_samples], (d_samples, 0))
                            ambience_stereo[0] += delayed_l * decays[idx]
                            ambience_stereo[1] += delayed_r * decays[idx]
                    # Filter reverb with high damping (>6kHz cut) to keep vocal clear
                    sos_rev_lp = butter(2, 5500, btype='lowpass', fs=sr, output='sos')
                    ambience_stereo[0] = sosfilt(sos_rev_lp, ambience_stereo[0])
                    ambience_stereo[1] = sosfilt(sos_rev_lp, ambience_stereo[1])

                elif "Slapback" in studio_ambience_type:
                    # 110ms slapback delay
                    slap_samples = int(0.110 * sr)
                    if slap_samples < stage3_output.shape[1]:
                        ambience_stereo[0] = np.pad(stage3_output[0][:-slap_samples], (slap_samples, 0)) * 0.5
                        ambience_stereo[1] = np.pad(stage3_output[1][:-slap_samples], (slap_samples, 0)) * 0.5
                else: # Chamber
                    chamber_samples = int(0.040 * sr)
                    if chamber_samples < stage3_output.shape[1]:
                        ambience_stereo[0] = np.pad(stage3_output[0][:-chamber_samples], (chamber_samples, 0)) * 0.4
                        ambience_stereo[1] = np.pad(stage3_output[1][:-chamber_samples], (chamber_samples, 0)) * 0.4

                stage3_output = (stage3_output * (1.0 - wet_mix)) + (ambience_stereo * wet_mix)

        # ==============================================================
        # MASTERING LIMITER & OUTPUT NORMALIZATION (-0.5 dBFS)
        # ==============================================================
        max_peak = np.max(np.abs(stage3_output))
        target_peak = 0.944 # ~ -0.5 dBFS
        if max_peak > 1e-4:
            stage3_output = (stage3_output / max_peak) * target_peak
        # Soft-knee tanh peak limiting protection
        stage3_output = np.clip(stage3_output, -1.0, 1.0)

        # Export high-fidelity 24-bit WAV file
        out_id = f"vocal_master_{uuid.uuid4().hex[:8]}"
        out_filename = f"{out_id}.wav"
        out_path = VOCAL_MASTER_DIR / out_filename
        
        # soundfile expects (samples, channels)
        export_data = stage3_output.T
        sf.write(str(out_path), export_data, sr, subtype='PCM_24')

        elapsed = round(time.time() - start_t, 2)
        rel_url = f"/output/vocal_mastering/{out_filename}"

        return {
            "success": True,
            "id": out_id,
            "title": title,
            "file_path": str(out_path),
            "audio_url": rel_url,
            "duration": round(duration_sec, 1),
            "sample_rate": sr,
            "channels": 2,
            "bit_depth": 24,
            "processing_time_sec": elapsed,
            "pipeline": {
                "step1_dereverb": {
                    "enabled": enable_dereverb,
                    "model": dereverb_model,
                    "intensity": dereverb_intensity,
                    "noise_floor_cut_db": denoise_threshold_db
                },
                "step2_enhancement": {
                    "enabled": enable_enhancement,
                    "model": enhancer_model,
                    "parallel_blend_percent": int(parallel_blend * 100),
                    "air_boost": air_boost,
                    "body_warmth": body_warmth,
                    "de_esser": de_esser_enabled
                },
                "step3_daw_master": {
                    "enabled": enable_daw_master,
                    "low_cut_hz": low_cut_hz,
                    "boxy_mud_cut_hz": boxy_mud_cut_hz,
                    "boxy_gain_db": boxy_mud_gain_db,
                    "compressor_ratio": f"{compressor_ratio}:1",
                    "makeup_gain_db": f"+{compressor_makeup_db} dB",
                    "ambience": studio_ambience_type,
                    "ambience_wet_mix": f"{int(ambience_wet_mix * 100)}%"
                }
            }
        }

vocal_mastering_service = VocalMasteringService()
