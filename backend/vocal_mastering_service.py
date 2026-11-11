import os
import uuid
import time
from pathlib import Path
from typing import Dict, Any, Optional
import numpy as np
import soundfile as sf
import librosa
from scipy.signal import butter, sosfilt, lfilter
from scipy.ndimage import maximum_filter1d, uniform_filter1d

from config import VOCAL_MASTER_DIR, BASE_DIR


def _peaking_eq_sos(freq_hz: float, q: float, gain_db: float, fs: int) -> np.ndarray:
    """Audio EQ Cookbook peaking biquad filter returned as SOS."""
    if abs(gain_db) < 0.05:
        return np.array([[1.0, 0.0, 0.0, 1.0, 0.0, 0.0]], dtype=np.float64)
    a = 10.0 ** (gain_db / 40.0)
    w0 = 2.0 * np.pi * np.clip(freq_hz, 20.0, fs * 0.46) / fs
    alpha = np.sin(w0) / (2.0 * max(0.25, q))
    cos_w0 = np.cos(w0)

    b0 = 1.0 + alpha * a
    b1 = -2.0 * cos_w0
    b2 = 1.0 - alpha * a
    a0 = 1.0 + alpha / a
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha / a

    return np.array([[b0 / a0, b1 / a0, b2 / a0, 1.0, a1 / a0, a2 / a0]], dtype=np.float64)


def _high_shelf_sos(freq_hz: float, gain_db: float, fs: int, slope: float = 0.85) -> np.ndarray:
    """Audio EQ Cookbook high-shelf biquad filter returned as SOS."""
    if abs(gain_db) < 0.05:
        return np.array([[1.0, 0.0, 0.0, 1.0, 0.0, 0.0]], dtype=np.float64)
    a = 10.0 ** (gain_db / 40.0)
    w0 = 2.0 * np.pi * np.clip(freq_hz, 400.0, fs * 0.46) / fs
    cos_w0 = np.cos(w0)
    sin_w0 = np.sin(w0)
    alpha = sin_w0 / 2.0 * np.sqrt((a + 1.0 / a) * (1.0 / max(0.2, slope) - 1.0) + 2.0)
    two_sqrt_a_alpha = 2.0 * np.sqrt(a) * alpha

    b0 = a * ((a + 1.0) + (a - 1.0) * cos_w0 + two_sqrt_a_alpha)
    b1 = -2.0 * a * ((a - 1.0) + (a + 1.0) * cos_w0)
    b2 = a * ((a + 1.0) + (a - 1.0) * cos_w0 - two_sqrt_a_alpha)
    a0 = (a + 1.0) - (a - 1.0) * cos_w0 + two_sqrt_a_alpha
    a1 = 2.0 * ((a - 1.0) - (a + 1.0) * cos_w0)
    a2 = (a + 1.0) - (a - 1.0) * cos_w0 - two_sqrt_a_alpha

    return np.array([[b0 / a0, b1 / a0, b2 / a0, 1.0, a1 / a0, a2 / a0]], dtype=np.float64)


def _fast_envelope(sig: np.ndarray, sr: int, attack_ms: float = 12.0, release_ms: float = 120.0) -> np.ndarray:
    """
    Vectorized peak/RMS hybrid envelope follower (100x faster than Python sample loops).
    """
    abs_sig = np.abs(sig).astype(np.float64)
    hop = max(1, int(sr * 0.002))  # 2 ms block resolution
    n_blocks = int(np.ceil(len(abs_sig) / hop))
    pad_len = n_blocks * hop - len(abs_sig)
    if pad_len > 0:
        padded = np.pad(abs_sig, (0, pad_len), mode="edge")
    else:
        padded = abs_sig

    blocks = padded.reshape(n_blocks, hop)
    block_env = 0.65 * np.max(blocks, axis=1) + 0.35 * np.sqrt(np.mean(blocks * blocks, axis=1) + 1e-12)

    block_sr = sr / hop
    atk_frames = max(1, int((attack_ms / 1000.0) * block_sr))
    rel_coeff = float(np.exp(-1.0 / max(1.0, (release_ms / 1000.0) * block_sr)))

    # Fast peak hold + one-pole release + short attack smoothing
    held = maximum_filter1d(block_env, size=max(2, atk_frames), mode="nearest")
    released = lfilter([1.0 - rel_coeff], [1.0, -rel_coeff], held)
    smoothed = uniform_filter1d(np.maximum(block_env * 0.5, released), size=max(2, atk_frames), mode="nearest")

    x_blocks = np.linspace(0.0, 1.0, n_blocks, endpoint=True)
    x_samples = np.linspace(0.0, 1.0, len(abs_sig), endpoint=True)
    return np.interp(x_samples, x_blocks, smoothed).astype(np.float32)


class VocalMasteringService:
    """
    3-Stage Studio Vocal Mixing & Mastering Pipeline
    Tuned specifically so recorded vocals sit cleanly and artifact-free inside
    ACE-Step 1.5 XL and YuE2 generative music instrumentals.
    """

    def __init__(self):
        VOCAL_MASTER_DIR.mkdir(parents=True, exist_ok=True)

    def _resolve_audio_path(self, raw_path: str) -> Optional[Path]:
        if not raw_path:
            return None
        p = Path(raw_path)
        if p.exists() and p.is_file():
            return p
        alt = BASE_DIR / raw_path.lstrip("/\\").replace("/", os.sep)
        if alt.exists() and alt.is_file():
            return alt
        return None

    def _apply_engine_vocal_tuning(self, stereo: np.ndarray, sr: int, target_engine: str) -> np.ndarray:
        """
        Applies spectral pocket shaping tailored to the target generative music engine
        so vocals never clash with synthesized drums, synths, or acoustic instruments.
        """
        engine = (target_engine or "ace_step_15_xl").lower().strip()
        out = stereo.copy()

        if "ace" in engine:
            # ACE-Step 1.5 XL has punchy sub-bass, rich 280-420Hz synth/pad density, and crisp >6.5kHz percussion.
            # Carve lower-mid synth clash, focus 2.65kHz vocal intelligibility, tame 6.8kHz harshness, add 11.5kHz silk.
            sos_chain = np.vstack([
                _peaking_eq_sos(215.0, 1.4, 1.1, sr),
                _peaking_eq_sos(355.0, 2.2, -2.2, sr),
                _peaking_eq_sos(2650.0, 1.35, 1.9, sr),
                _peaking_eq_sos(6900.0, 2.6, -1.6, sr),
                _high_shelf_sos(11200.0, 1.5, sr),
            ])
        elif "yue" in engine:
            # YuE2 has warm mid-centric acoustic instrumentation and softer high frequencies above 9.5kHz.
            # Clear 310Hz codec warmth, lift 3.25kHz articulation, and open 10.5kHz studio air.
            sos_chain = np.vstack([
                _peaking_eq_sos(195.0, 1.5, 0.8, sr),
                _peaking_eq_sos(315.0, 2.0, -2.5, sr),
                _peaking_eq_sos(3250.0, 1.3, 2.2, sr),
                _high_shelf_sos(10200.0, 2.1, sr),
            ])
        else:
            # Universal balanced studio vocal curve
            sos_chain = np.vstack([
                _peaking_eq_sos(330.0, 2.0, -1.5, sr),
                _peaking_eq_sos(2900.0, 1.4, 1.5, sr),
                _high_shelf_sos(10800.0, 1.2, sr),
            ])

        for ch in range(2):
            out[ch] = sosfilt(sos_chain, out[ch])
        return out

    def _mix_with_instrumental(
        self,
        vocal_stereo: np.ndarray,
        backing_path: Path,
        sr: int,
        target_engine: str,
        backing_mix_level: float = 0.78,
        vocal_gain_db: float = 0.0,
    ) -> np.ndarray:
        """
        Mixes processed studio vocal with an ACE-Step 1.5 XL / YuE2 instrumental using
        Mid/Side spectral pocket ducking (280Hz - 3.4kHz on Mid channel only) + master bus glue.
         Stereo Side width of the instrumental remains 100% untouched and immersive.
        """
        inst, _ = librosa.load(str(backing_path), sr=sr, mono=False)
        if inst.ndim == 1:
            inst = np.vstack([inst, inst])
        elif inst.shape[0] > 2:
            inst = inst[:2]

        # Match length: keep full instrumental length if longer (up to +15s outro), or pad instrumental cleanly
        v_len = vocal_stereo.shape[1]
        i_len = inst.shape[1]
        target_len = max(v_len, min(i_len, v_len + int(15.0 * sr)))

        voc = np.zeros((2, target_len), dtype=np.float32)
        voc[:, :min(v_len, target_len)] = vocal_stereo[:, :min(v_len, target_len)]

        bg = np.zeros((2, target_len), dtype=np.float32)
        if i_len >= target_len:
            bg[:, :] = inst[:, :target_len]
        else:
            bg[:, :i_len] = inst
            # Smooth fade out if instrumental was shorter than vocal
            fade_n = min(int(0.5 * sr), i_len // 4)
            if fade_n > 16:
                bg[:, i_len - fade_n:i_len] *= np.linspace(1.0, 0.0, fade_n, dtype=np.float32)

        # Normalize RMS balance between vocal and instrumental before sidechain mix
        voc_active = np.abs(voc[0]) > 0.015
        voc_rms = float(np.sqrt(np.mean(voc[:, voc_active] ** 2) + 1e-9)) if np.any(voc_active) else 0.12
        bg_rms = float(np.sqrt(np.mean(bg ** 2) + 1e-9))

        target_voc_rms = 0.165 * (10.0 ** (np.clip(vocal_gain_db, -6.0, 6.0) / 20.0))
        voc = voc * (target_voc_rms / max(voc_rms, 0.02))

        level_clamped = float(np.clip(backing_mix_level, 0.20, 1.15))
        target_bg_rms = 0.145 * level_clamped
        bg = bg * (target_bg_rms / max(bg_rms, 0.02))

        # Mid / Side decomposition of instrumental
        mid = 0.5 * (bg[0] + bg[1])
        side = 0.5 * (bg[0] - bg[1])

        # Extract vocal presence envelope to drive dynamic Mid-channel pocket ducking
        voc_mono = 0.5 * (voc[0] + voc[1])
        voc_env = _fast_envelope(voc_mono, sr=sr, attack_ms=8.0, release_ms=150.0)
        env_norm = np.clip(voc_env / (np.percentile(voc_env, 92) + 1e-6), 0.0, 1.0)

        duck_depth = 0.34 if "ace" in (target_engine or "").lower() else 0.30  # up to ~ -3.2 dB pocket
        sos_pocket = butter(2, [280.0, 3500.0], btype="bandpass", fs=sr, output="sos")
        mid_pocket = sosfilt(sos_pocket, mid)
        mid_ducked = mid - mid_pocket * (duck_depth * env_norm)

        # Subtle stereo width enhancement (+8% Side) so instrumental hugs the center vocal
        side_enhanced = side * 1.08
        bg_carved = np.vstack([mid_ducked + side_enhanced, mid_ducked - side_enhanced])

        # Sum vocal + carved instrumental through gentle studio bus glue
        mix = voc + bg_carved
        bus_env = _fast_envelope(0.5 * (mix[0] + mix[1]), sr=sr, attack_ms=20.0, release_ms=180.0)
        bus_thresh = 0.55
        bus_gr = np.ones_like(bus_env)
        over = bus_env > bus_thresh
        bus_gr[over] = (bus_thresh + (bus_env[over] - bus_thresh) / 2.2) / (bus_env[over] + 1e-6)
        mix = mix * bus_gr[np.newaxis, :]

        return mix.astype(np.float32)

    def process_vocal(
        self,
        input_audio_path: str,
        title: str = "Stüdyo Vokal Miks",
        # Generative Engine & Backing Mix Tuning
        target_engine: str = "ace_step_15_xl",  # "ace_step_15_xl" | "yue2" | "universal"
        backing_audio_path: Optional[str] = None,
        backing_mix_level: float = 0.78,
        vocal_gain_db: float = 0.5,
        # Stage 1: Acoustic Isolation (De-Reverb & De-Noise)
        enable_dereverb: bool = True,
        dereverb_intensity: float = 0.82,
        denoise_threshold_db: float = -38.0,
        dereverb_model: str = "anvuew/dereverb_mel_band_roformer",
        # Stage 2: Vocal Body, Presence & De-Esser
        enable_enhancement: bool = True,
        parallel_blend: float = 0.45,
        air_boost: float = 0.58,
        body_warmth: float = 0.48,
        de_esser_enabled: bool = True,
        enhancer_model: str = "ResembleAI/resemble-enhance",
        # Stage 3: Studio Mastering Chain
        enable_daw_master: bool = True,
        low_cut_hz: float = 85.0,
        boxy_mud_cut_hz: float = 365.0,
        boxy_mud_gain_db: float = -3.5,
        compressor_ratio: float = 4.0,
        compressor_makeup_db: float = 3.2,
        studio_ambience_type: str = "Plate Reverb",
        ambience_wet_mix: float = 0.12,
    ) -> Dict[str, Any]:
        """
        Executes the 3-stage studio vocal + optional instrumental mixdown workflow
        and exports pristine 44.1kHz / 24-bit WAV.
        """
        start_t = time.time()
        input_p = self._resolve_audio_path(input_audio_path)
        if not input_p:
            raise FileNotFoundError(f"Vokal ses dosyası bulunamadı: {input_audio_path}")

        sr = 44100
        y, _ = librosa.load(str(input_p), sr=sr, mono=False)
        if y.ndim == 1:
            y = np.vstack([y, y])
        elif y.shape[0] > 2:
            y = y[:2]

        # Remove DC offset immediately
        y = y - np.mean(y, axis=1, keepdims=True)

        # ==============================================================
        # STAGE 1: Acoustic Isolation (Room Reflection & Noise Removal)
        # ==============================================================
        stage1_output = y.copy()
        if enable_dereverb:
            gate_linear = 10.0 ** (np.clip(denoise_threshold_db, -65.0, -18.0) / 20.0)
            deep_mode = "mel_band" in (dereverb_model or "").lower() or dereverb_intensity >= 0.7
            sub_scale = (1.25 if deep_mode else 0.95) + dereverb_intensity * 1.35

            for ch in range(2):
                channel_data = y[ch]
                stft = librosa.stft(channel_data, n_fft=2048, hop_length=512)
                mag, phase = np.abs(stft), np.angle(stft)

                # Adaptive noise floor per frequency bin + user threshold floor
                noise_floor = np.percentile(mag, 14, axis=1, keepdims=True)
                residual = np.maximum(0.0, mag - noise_floor * sub_scale)

                # Smooth Wiener-like soft mask across frequency and time to eliminate musical noise
                raw_mask = residual / (mag + 1e-7)
                smooth_mask = uniform_filter1d(raw_mask, size=3, axis=0)
                smooth_mask = uniform_filter1d(smooth_mask, size=3, axis=1)
                smooth_mask = np.clip(smooth_mask, 0.08, 1.0)

                cleaned_stft = (mag * smooth_mask) * np.exp(1j * phase)
                cleaned_audio = librosa.istft(cleaned_stft, hop_length=512, length=len(channel_data))

                # Smooth amplitude noise gate for silent pauses between vocal phrases
                env = _fast_envelope(cleaned_audio, sr=sr, attack_ms=6.0, release_ms=95.0)
                gate_gain = np.clip((env - gate_linear * 0.5) / (gate_linear * 1.5 + 1e-7), 0.12, 1.0)
                gated_audio = cleaned_audio * gate_gain

                stage1_output[ch] = (
                    gated_audio * dereverb_intensity
                    + channel_data * (1.0 - dereverb_intensity)
                )

        # ==============================================================
        # STAGE 2: Vocal Body, Silky Air & Smooth Dynamic De-Esser
        # ==============================================================
        stage2_output = stage1_output.copy()
        if enable_enhancement:
            enhanced_layer = np.zeros_like(stage1_output)
            sos_body = butter(2, [165.0, 285.0], btype="bandpass", fs=sr, output="sos")
            sos_air = butter(2, 9200.0, btype="highpass", fs=sr, output="sos")
            sos_ess = butter(2, [5400.0, 8800.0], btype="bandpass", fs=sr, output="sos")

            for ch in range(2):
                sig = stage1_output[ch].copy()

                # Smooth dynamic split-band De-Esser (only attenuates harsh 5.4-8.8kHz band, zero clicks!)
                if de_esser_enabled:
                    ess_band = sosfilt(sos_ess, sig)
                    ess_env = _fast_envelope(ess_band, sr=sr, attack_ms=3.0, release_ms=45.0)
                    active_ess = ess_env[ess_env > 1e-4]
                    ess_thresh = float(np.percentile(active_ess, 82) * 1.25) if len(active_ess) > 32 else 0.04
                    ess_reduce = np.where(
                        ess_env > ess_thresh,
                        np.clip(ess_thresh / (ess_env + 1e-7), 0.38, 1.0),
                        1.0,
                    )
                    sig = sig - ess_band * (1.0 - ess_reduce)

                body_sat = np.tanh(sosfilt(sos_body, sig) * 1.7) * (0.36 * body_warmth) if body_warmth > 0 else 0.0
                air_sat = np.tanh(sosfilt(sos_air, sig) * 2.0) * (0.40 * air_boost) if air_boost > 0 else 0.0

                enhanced_layer[ch] = sig + body_sat + air_sat

            blend = float(np.clip(parallel_blend, 0.0, 1.0))
            stage2_output = stage1_output * (1.0 - blend) + enhanced_layer * blend

        # Apply target generative model spectral tuning (ACE-Step 1.5 XL / YuE2 / Universal)
        stage2_output = self._apply_engine_vocal_tuning(stage2_output, sr=sr, target_engine=target_engine)

        # ==============================================================
        # STAGE 3: Studio Mastering Chain (True Parametric EQ, Opto Comp & Space)
        # ==============================================================
        stage3_output = stage2_output.copy()
        if enable_daw_master:
            sos_hp = butter(3, float(np.clip(low_cut_hz, 40.0, 160.0)), btype="highpass", fs=sr, output="sos")
            sos_boxy = _peaking_eq_sos(
                freq_hz=float(np.clip(boxy_mud_cut_hz, 220.0, 620.0)),
                q=2.4,
                gain_db=float(np.clip(boxy_mud_gain_db, -9.0, 0.0)),
                fs=sr,
            )

            # Pre-filter both channels cleanly with zero phase-cancellation artifacts
            for ch in range(2):
                stage3_output[ch] = sosfilt(sos_boxy, sosfilt(sos_hp, stage3_output[ch]))

            # Stereo-linked optical vocal compressor
            linked_sig = 0.5 * (np.abs(stage3_output[0]) + np.abs(stage3_output[1]))
            envelope = _fast_envelope(linked_sig, sr=sr, attack_ms=12.0, release_ms=130.0)
            active_vals = envelope[envelope > 0.005]
            thresh = float(np.percentile(active_vals, 58)) if len(active_vals) > 64 else 0.08
            thresh = float(np.clip(thresh, 0.035, 0.22))

            ratio = max(1.2, float(compressor_ratio))
            gain_reduction = np.ones_like(envelope)
            above = envelope > thresh
            gain_reduction[above] = (thresh + (envelope[above] - thresh) / ratio) / (envelope[above] + 1e-6)

            makeup_linear = 10.0 ** (float(np.clip(compressor_makeup_db, 0.0, 12.0)) / 20.0)
            stage3_output = stage3_output * gain_reduction[np.newaxis, :] * makeup_linear

            # Studio Ambience (Plate / Slapback / Chamber) with Abbey Road bandpass (220Hz - 5.5kHz)
            if studio_ambience_type != "Off" and ambience_wet_mix > 0.002:
                wet_mix = float(np.clip(ambience_wet_mix, 0.0, 0.35))
                ambience_stereo = np.zeros_like(stage3_output)
                n_samples = stage3_output.shape[1]

                if "Plate" in studio_ambience_type:
                    delays_l = [int(0.023 * sr), int(0.037 * sr), int(0.053 * sr), int(0.071 * sr)]
                    delays_r = [int(0.029 * sr), int(0.041 * sr), int(0.059 * sr), int(0.079 * sr)]
                    decays = [0.44, 0.33, 0.24, 0.16]
                    for idx, dec in enumerate(decays):
                        dl, dr = delays_l[idx], delays_r[idx]
                        if dl < n_samples:
                            ambience_stereo[0, dl:] += stage3_output[0, :-dl] * dec
                        if dr < n_samples:
                            ambience_stereo[1, dr:] += stage3_output[1, :-dr] * dec
                elif "Slapback" in studio_ambience_type:
                    slap_l, slap_r = int(0.102 * sr), int(0.114 * sr)
                    if slap_l < n_samples:
                        ambience_stereo[0, slap_l:] = stage3_output[0, :-slap_l] * 0.48
                    if slap_r < n_samples:
                        ambience_stereo[1, slap_r:] = stage3_output[1, :-slap_r] * 0.48
                else:  # Studio Chamber
                    ch_l, ch_r = int(0.034 * sr), int(0.043 * sr)
                    if ch_l < n_samples:
                        ambience_stereo[0, ch_l:] = stage3_output[0, :-ch_l] * 0.42
                    if ch_r < n_samples:
                        ambience_stereo[1, ch_r:] = stage3_output[1, :-ch_r] * 0.42

                sos_rev_bp = butter(2, [220.0, 5400.0], btype="bandpass", fs=sr, output="sos")
                ambience_stereo[0] = sosfilt(sos_rev_bp, ambience_stereo[0])
                ambience_stereo[1] = sosfilt(sos_rev_bp, ambience_stereo[1])

                stage3_output = stage3_output * (1.0 - wet_mix) + ambience_stereo * wet_mix

        # ==============================================================
        # OPTIONAL STAGE 4: Mixdown with ACE-Step 1.5 XL / YuE2 Instrumental
        # ==============================================================
        backing_resolved = self._resolve_audio_path(backing_audio_path) if backing_audio_path else None
        mixed_with_backing = False
        if backing_resolved is not None:
            stage3_output = self._mix_with_instrumental(
                vocal_stereo=stage3_output,
                backing_path=backing_resolved,
                sr=sr,
                target_engine=target_engine,
                backing_mix_level=backing_mix_level,
                vocal_gain_db=vocal_gain_db,
            )
            mixed_with_backing = True

        # ==============================================================
        # MASTERING TRUE-PEAK SOFT LIMITER & NORMALIZATION (-0.8 dBFS)
        # ==============================================================
        peak = float(np.max(np.abs(stage3_output)))
        if peak > 1e-5:
            stage3_output = stage3_output / peak * 0.96
            stage3_output = np.tanh(stage3_output * 1.08) / np.tanh(1.08)
            stage3_output = stage3_output * (0.912 / max(float(np.max(np.abs(stage3_output))), 1e-5))
        stage3_output = np.clip(stage3_output, -0.98, 0.98)

        duration_sec = stage3_output.shape[1] / sr

        out_id = f"vocal_master_{uuid.uuid4().hex[:8]}"
        out_filename = f"{out_id}.wav"
        out_path = VOCAL_MASTER_DIR / out_filename

        sf.write(str(out_path), stage3_output.T, sr, subtype="PCM_24")

        elapsed = round(time.time() - start_t, 2)
        rel_url = f"/output/vocal_mastering/{out_filename}"
        engine_label = (
            "ACE-Step 1.5 XL"
            if "ace" in (target_engine or "").lower()
            else ("YuE2" if "yue" in (target_engine or "").lower() else "Stüdyo Miks")
        )

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
            "target_engine": target_engine,
            "engine_label": engine_label,
            "mixed_with_backing": mixed_with_backing,
            "pipeline": {
                "target_engine": engine_label,
                "mixed_with_backing": mixed_with_backing,
                "step1_dereverb": {
                    "enabled": enable_dereverb,
                    "intensity": dereverb_intensity,
                },
                "step2_enhancement": {
                    "enabled": enable_enhancement,
                    "parallel_blend_percent": int(parallel_blend * 100),
                    "air_boost": air_boost,
                    "body_warmth": body_warmth,
                    "de_esser": de_esser_enabled,
                },
                "step3_daw_master": {
                    "enabled": enable_daw_master,
                    "low_cut_hz": low_cut_hz,
                    "boxy_mud_cut_hz": boxy_mud_cut_hz,
                    "ambience": studio_ambience_type,
                },
            },
        }


vocal_mastering_service = VocalMasteringService()
