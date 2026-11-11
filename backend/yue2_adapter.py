import os
import json
import struct
import time
import uuid
import shutil
import random
import asyncio
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
import numpy as np

from config import SONGS_DIR, COVERS_DIR, DATA_FILE, UPLOADS_DIR, DEFAULT_COMFYUI_MODELS_PATH, load_settings
from comfy_bridge import comfy_bridge, COMFY_INPUT


def get_db() -> List[Dict[str, Any]]:
    if DATA_FILE.exists():
        try:
            with open(DATA_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return []


def save_db(data: List[Dict[str, Any]]):
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def generate_cover_image(song_id: str, title: str, style: str) -> str:
    """Generates an aesthetic SVG cover art based on genre colors."""
    filename = f"{song_id}.svg"
    filepath = COVERS_DIR / filename

    s_lower = style.lower()
    if "synth" in s_lower or "retro" in s_lower or "80s" in s_lower:
        c1, c2, c3 = "#8A2387", "#E94057", "#F27121"
    elif "rock" in s_lower or "metal" in s_lower:
        c1, c2, c3 = "#200122", "#6f0000", "#d12727"
    elif "pop" in s_lower or "dance" in s_lower:
        c1, c2, c3 = "#FF416C", "#FF4B2B", "#FFA07A"
    elif "jazz" in s_lower or "blues" in s_lower or "acoustic" in s_lower:
        c1, c2, c3 = "#1E3C72", "#2A5298", "#FDBB2D"
    elif "hip" in s_lower or "rap" in s_lower:
        c1, c2, c3 = "#0F2027", "#203A43", "#2C5364"
    else:
        c1, c2, c3 = "#FF6A00", "#EE0979", "#23074D"

    safe_title = (
        title[:24]
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
    safe_style = (
        style[:36]
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )

    svg_content = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" width="100%" height="100%">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{c1};stop-opacity:1" />
      <stop offset="50%" style="stop-color:{c2};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{c3};stop-opacity:1" />
    </linearGradient>
    <radialGradient id="glow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#ffffff;stop-opacity:0.3"/>
      <stop offset="100%" style="stop-color:#000000;stop-opacity:0.6"/>
    </radialGradient>
  </defs>
  <rect width="500" height="500" rx="24" fill="url(#grad)" />
  <rect width="500" height="500" rx="24" fill="url(#glow)" />
  
  <g transform="translate(50, 180)" fill="#ffffff" opacity="0.85">
    <rect x="20" y="40" width="12" height="60" rx="6" />
    <rect x="50" y="20" width="12" height="100" rx="6" />
    <rect x="80" y="5" width="12" height="130" rx="6" />
    <rect x="110" y="30" width="12" height="80" rx="6" />
    <rect x="140" y="10" width="12" height="120" rx="6" />
    <rect x="170" y="0" width="12" height="140" rx="6" />
    <rect x="200" y="25" width="12" height="90" rx="6" />
    <rect x="230" y="15" width="12" height="110" rx="6" />
    <rect x="260" y="45" width="12" height="50" rx="6" />
    <rect x="290" y="20" width="12" height="100" rx="6" />
    <rect x="320" y="5" width="12" height="130" rx="6" />
    <rect x="350" y="35" width="12" height="70" rx="6" />
  </g>

  <rect x="40" y="40" width="110" height="32" rx="16" fill="#000000" opacity="0.6"/>
  <text x="54" y="62" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="14" fill="#FF8A00" letter-spacing="2">SONICALL</text>

  <text x="40" y="410" font-family="system-ui, -apple-system, sans-serif" font-weight="800" font-size="28" fill="#ffffff">{safe_title}</text>
  <text x="40" y="445" font-family="system-ui, -apple-system, sans-serif" font-weight="500" font-size="16" fill="#ffffff" opacity="0.75">{safe_style}</text>
</svg>"""

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(svg_content)
    return f"/output/covers/{filename}"


def detect_lyrics_language(lyrics: str) -> str:
    """Detects language code ('tr' or 'en') for ACE-Step 1.5 XL phoneme tokenizer."""
    tr_chars = set("çğıöşüÇĞİÖŞÜ")
    if any(ch in tr_chars for ch in lyrics):
        return "tr"
    low = f" {lyrics.lower()} "
    tr_words = [" ve ", " bir ", " bu ", " için ", " gibi ", " gece ", " kalp ", " seni ", " beni "]
    if any(w in low for w in tr_words):
        return "tr"
    return "en"


def format_song_lyrics_with_intro_outro(raw_lyrics: str, style: str, is_instrumental: bool) -> str:
    """
    Ensures songs have proper structure. For instrumental / solo mode,
    strictly passes [instrumental] to suppress all vocal synthesis.
    """
    if is_instrumental:
        return "[instrumental]"

    text = raw_lyrics.strip()
    if not text:
        text = "Singing with passion and power\nEvery melody takes me higher"

    lower_text = text.lower()

    has_intro = "[intro]" in lower_text or "[instrumental intro]" in lower_text
    if not has_intro:
        intro_tag = "[Intro]\n[Catchy Melodic Intro]\n\n"
        if not text.startswith("["):
            text = f"{intro_tag}[Verse]\n{text}"
        else:
            text = f"{intro_tag}{text}"

    has_outro = any(tag in lower_text for tag in ["[outro]", "[fade out]", "[end]", "[instrumental outro]", "[fade]"])
    if not has_outro:
        outro_tag = "\n\n[Outro]\n[Melodic Vocal Cadence]\n[Fade Out]\n[End]"
        text = f"{text}{outro_tag}"

    return text


def apply_musical_fade_envelope(audio_data: np.ndarray, sample_rate: int, fade_out_sec: float = 4.5) -> np.ndarray:
    """
    Applies a smooth micro fade-in (40ms) and an organic cosine S-curve fade-out
    to eliminate abrupt endings and deliver a radio-ready natural outro.
    """
    if len(audio_data) == 0:
        return audio_data

    is_int16 = (audio_data.dtype == np.int16)
    if is_int16:
        audio = audio_data.astype(np.float32) / 32768.0
    else:
        audio = audio_data.astype(np.float32).copy()

    total_samples = len(audio)

    fade_in_samples = min(int(sample_rate * 0.04), total_samples // 10)
    if fade_in_samples > 0:
        curve_in = np.linspace(0.0, 1.0, fade_in_samples, dtype=np.float32)
        if audio.ndim == 2:
            curve_in = curve_in[:, np.newaxis]
        audio[:fade_in_samples] *= curve_in

    actual_fade_sec = min(fade_out_sec, (total_samples / sample_rate) * 0.20)
    fade_out_samples = int(sample_rate * actual_fade_sec)
    if fade_out_samples > 0:
        t = np.linspace(0, np.pi / 2, fade_out_samples, dtype=np.float32)
        curve_out = (np.cos(t) ** 2)
        if audio.ndim == 2:
            curve_out = curve_out[:, np.newaxis]
        audio[-fade_out_samples:] *= curve_out

    if is_int16:
        return np.clip(audio * 32767.0, -32768, 32767).astype(np.int16)
    return np.clip(audio, -1.0, 1.0)


def polish_generated_master(
    audio_data: np.ndarray,
    sample_rate: int,
    target_sr: int = 44100,
    is_instrumental: bool = False,
    fade_out_sec: float = 3.8
) -> Tuple[np.ndarray, int]:
    """
    Studio mastering polish tuned for YuE2 & ACE-Step 1.5 XL outputs:
    - Resamples cleanly to 44.1kHz stereo if generated at 48kHz (ACE-Step 1.5 XL)
    - Removes DC offset & sub-32Hz rumble
    - Carves subtle 340Hz mud pocket on instrumentals so vocals mix effortlessly on top
    - Applies smooth musical fade-in/out & -0.8 dBFS soft-knee true-peak limiting
    """
    if len(audio_data) == 0:
        return audio_data, sample_rate

    audio = audio_data.astype(np.float32).copy()
    if audio.ndim == 1:
        audio = np.column_stack([audio, audio])
    elif audio.shape[1] > 2:
        audio = audio[:, :2]

    # Resample to 44100 Hz if needed (e.g. ACE-Step 1.5 outputs 48000 Hz)
    if sample_rate != target_sr and len(audio) > 64:
        try:
            from scipy.signal import resample_poly
            import math
            g = math.gcd(sample_rate, target_sr)
            up = target_sr // g
            down = sample_rate // g
            ch0 = resample_poly(audio[:, 0], up, down)
            ch1 = resample_poly(audio[:, 1], up, down)
            audio = np.column_stack([ch0, ch1]).astype(np.float32)
            sample_rate = target_sr
        except Exception:
            pass

    # Remove DC offset & sub-32Hz rumble
    audio = audio - np.mean(audio, axis=0, keepdims=True)
    try:
        from scipy.signal import butter, sosfilt
        sos_sub = butter(3, 32.0, btype="highpass", fs=sample_rate, output="sos")
        audio[:, 0] = sosfilt(sos_sub, audio[:, 0])
        audio[:, 1] = sosfilt(sos_sub, audio[:, 1])

        if is_instrumental:
            # Gentle vocal-pocket cleanup around 300-420 Hz (-1.5 dB equivalent) + silky top sheen
            sos_mud = butter(2, [290.0, 430.0], btype="bandpass", fs=sample_rate, output="sos")
            mud_l = sosfilt(sos_mud, audio[:, 0])
            mud_r = sosfilt(sos_mud, audio[:, 1])
            audio[:, 0] = audio[:, 0] - 0.14 * mud_l
            audio[:, 1] = audio[:, 1] - 0.14 * mud_r

            sos_air = butter(2, 10500.0, btype="highpass", fs=sample_rate, output="sos")
            air_l = sosfilt(sos_air, audio[:, 0])
            air_r = sosfilt(sos_air, audio[:, 1])
            audio[:, 0] = audio[:, 0] + np.tanh(air_l * 1.4) * 0.08
            audio[:, 1] = audio[:, 1] + np.tanh(air_r * 1.4) * 0.08
    except Exception:
        pass

    audio = apply_musical_fade_envelope(audio, sample_rate, fade_out_sec=fade_out_sec)

    # True-peak normalization & soft-knee ceiling at -0.8 dBFS (0.912)
    peak = float(np.max(np.abs(audio)))
    if peak > 1e-4:
        audio = (audio / peak) * 0.912
    audio = np.clip(audio, -1.0, 1.0)
    return audio, sample_rate


class YuE2EngineAdapter:
    def __init__(self):
        self.active_tasks: Dict[str, Dict[str, Any]] = {}
        self.subscribers: List[asyncio.Queue] = []
        self.queue_lock = asyncio.Lock()

    async def broadcast_progress(self, message: Dict[str, Any]):
        tid = message.get("task_id")
        if tid:
            self.active_tasks[tid] = message
            if message.get("status") in ["completed", "error"]:
                import threading

                def _cleanup():
                    time.sleep(90)
                    self.active_tasks.pop(tid, None)

                threading.Thread(target=_cleanup, daemon=True).start()

        for q in list(self.subscribers):
            try:
                await q.put(message)
            except Exception:
                pass

    def _get_models_root(self) -> Path:
        try:
            st = load_settings()
            p = Path(st.get("models_dir", DEFAULT_COMFYUI_MODELS_PATH))
            if p.exists():
                return p
        except Exception:
            pass
        return Path(DEFAULT_COMFYUI_MODELS_PATH)

    def _inspect_safetensors_architecture(self, filepath: Path) -> str:
        """
        Reads safetensors JSON header in <0.5ms to distinguish:
        - 'ace15' (ACE-Step 1.5 / 1.5 XL)
        - 'ace10' (ACE-Step v1 3.5B)
        - 'yue2' (YuE2 3B / 7B)
        """
        if not filepath.exists() or filepath.suffix.lower() != ".safetensors":
            return "unknown"
        try:
            with open(filepath, "rb") as f:
                header_size = struct.unpack("<Q", f.read(8))[0]
                if header_size <= 0 or header_size > 64 * 1024 * 1024:
                    return "unknown"
                raw_json = f.read(header_size).decode("utf-8", errors="ignore")
            if "lyric_encoder." in raw_json or "refer_audio" in raw_json or "qwen" in raw_json.lower():
                return "ace15"
            if "genre_embedder." in raw_json or "speaker_embedder." in raw_json:
                return "ace10"
            if "yue" in raw_json.lower() or "codec_model" in raw_json:
                return "yue2"
        except Exception:
            pass
        name_low = filepath.name.lower()
        if "ace" in name_low and ("1.5" in name_low or "15" in name_low or "xl" in name_low):
            return "ace15"
        if "ace" in name_low:
            return "ace10"
        return "yue2"

    def _find_ace15_split_components(self) -> Optional[Dict[str, str]]:
        """Checks if split ACE-Step 1.5 XL components (UNET + DualCLIP + VAE) exist on disk."""
        root = self._get_models_root()
        diff_dir = root / "diffusion_models"
        te_dir = root / "text_encoders"
        vae_dir = root / "vae"
        if not (diff_dir.exists() and te_dir.exists() and vae_dir.exists()):
            return None

        unet_name = None
        for f in diff_dir.glob("*.safetensors"):
            fl = f.name.lower()
            if "ace" in fl or "step" in fl:
                unet_name = f.name
                if "xl" in fl or "1.5" in fl:
                    break

        clip1, clip2 = None, None
        for f in te_dir.glob("*.safetensors"):
            fl = f.name.lower()
            if "0.6b" in fl and "ace" in fl:
                clip1 = f.name
            elif ("4b" in fl or "xl" in fl or "1.7b" in fl) and "ace" in fl:
                clip2 = f.name

        vae_name = None
        for f in vae_dir.glob("*.safetensors"):
            fl = f.name.lower()
            if "ace" in fl and "vae" in fl:
                vae_name = f.name
                break

        if unet_name and clip1 and clip2 and vae_name:
            return {
                "unet_name": unet_name,
                "clip_name1": clip1,
                "clip_name2": clip2,
                "vae_name": vae_name,
            }
        return None

    # =========================================================================
    # YUE2 WORKFLOW BUILDERS (VOICE-TO-INSTRUMENTAL & FULL SONG TUNED)
    # =========================================================================
    def build_text_to_music_prompt(
        self,
        title: str,
        style: str,
        lyrics: str,
        seed: int,
        duration_sec: float,
        temperature: float = 0.85,
        cfg_scale: float = 1.2,
        steps: int = 30,
        top_p: float = 0.93,
        repetition_penalty: float = 1.12,
        negative_style: str = "",
        ckpt_name: str = "yue2_convrot_int8.safetensors",
        is_instrumental: bool = False
    ) -> Dict[str, Any]:
        if is_instrumental:
            effective_lyrics = ""
            effective_temp = min(temperature, 0.72)
            effective_style = (
                f"{style}, pure instrumental arrangement, rich studio acoustics, "
                f"balanced midrange pocket, crystal clear stereo separation, no vocals, no singing"
            )
        else:
            effective_lyrics = lyrics
            effective_temp = temperature
            effective_style = style

        safe_prefix = "".join(c if c.isalnum() else "_" for c in title[:14]) or "Track"

        return {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": ckpt_name
                }
            },
            "2": {
                "class_type": "YuE2GenerateABC",
                "inputs": {
                    "clip": ["1", 1],
                    "style": effective_style,
                    "lyrics": effective_lyrics,
                    "seed": seed,
                    "mode": "full",
                    "max_abc_tokens": 4096,
                    "temperature": effective_temp,
                    "top_p": top_p,
                    "top_k": 30,
                    "repetition_penalty": 1.005,
                    "penalty_window": 100
                }
            },
            "3": {
                "class_type": "YuE2GenerateMusic",
                "inputs": {
                    "clip": ["1", 1],
                    "style": effective_style,
                    "lyrics": effective_lyrics,
                    "abc": ["2", 0],
                    "seed": seed,
                    "mode": "full",
                    "max_duration": duration_sec,
                    "temperature": effective_temp,
                    "top_p": top_p,
                    "top_k": 80 if is_instrumental else 100,
                    "repetition_penalty": repetition_penalty,
                    "cfg_scale": cfg_scale
                }
            },
            "8": {
                "class_type": "ConditioningZeroOut",
                "inputs": {
                    "conditioning": ["3", 0]
                }
            },
            "4": {
                "class_type": "EmptyYuE2LatentAudio",
                "inputs": {
                    "seconds": ["3", 1],
                    "batch_size": 1
                }
            },
            "5": {
                "class_type": "KSampler",
                "inputs": {
                    "model": ["1", 0],
                    "seed": seed,
                    "steps": steps,
                    "cfg": 1.0,
                    "sampler_name": "dpm_2",
                    "scheduler": "sgm_uniform",
                    "positive": ["3", 0],
                    "negative": ["8", 0],
                    "latent_image": ["4", 0],
                    "denoise": 1.0
                }
            },
            "6": {
                "class_type": "VAEDecodeAudioTiled",
                "inputs": {
                    "samples": ["5", 0],
                    "vae": ["1", 2],
                    "tile_size": 1920,
                    "overlap": 256
                }
            },
            "7": {
                "class_type": "SaveAudioAdvanced",
                "inputs": {
                    "audio": ["6", 0],
                    "filename_prefix": f"audio/Sonicall_{safe_prefix}_{seed}",
                    "format": {"format": "flac"}
                }
            }
        }

    def build_cover_prompt(
        self,
        ref_filename: str,
        style: str,
        lyrics: str,
        seed: int,
        duration_sec: float,
        temperature: float = 0.85,
        cfg_scale: float = 1.2,
        steps: int = 32,
        top_p: float = 0.93,
        repetition_penalty: float = 1.12,
        negative_style: str = "",
        ckpt_name: str = "yue2_convrot_int8.safetensors",
        is_instrumental: bool = False
    ) -> Dict[str, Any]:
        if is_instrumental:
            effective_lyrics = ""
            # Tight temperature & top_k locks YuE2 onto SheetSage2's extracted vocal melody notes
            effective_temperature = 0.30
            effective_top_p = 0.84
            effective_top_k = 24
            effective_repetition = 1.02
            effective_cfg = max(1.25, cfg_scale)
            effective_style = (
                f"{style}, exact reference melody tracking, note for note reproduction, "
                f"identical melodic pitch contour, strictly follow reference melody line, "
                f"clean studio acoustic isolation, natural dynamic expression, zero vocals, no voice, no singing"
            )
        else:
            effective_lyrics = lyrics
            effective_temperature = temperature
            effective_top_p = top_p
            effective_top_k = 100
            effective_repetition = repetition_penalty
            effective_cfg = cfg_scale
            effective_style = style

        return {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": ckpt_name
                }
            },
            "10": {
                "class_type": "AudioEncoderLoader",
                "inputs": {
                    "audio_encoder_name": "sheetsage2_bf16.safetensors"
                }
            },
            "11": {
                "class_type": "LoadAudio",
                "inputs": {
                    "audio": ref_filename
                }
            },
            "12": {
                "class_type": "SheetSage2AudioToABC",
                "inputs": {
                    "audio_encoder": ["10", 0],
                    "audio": ["11", 0],
                    "mode": "melody"
                }
            },
            "3": {
                "class_type": "YuE2GenerateMusic",
                "inputs": {
                    "clip": ["1", 1],
                    "style": effective_style,
                    "lyrics": effective_lyrics,
                    "abc": ["12", 0],
                    "seed": seed,
                    "mode": "melody",
                    "max_duration": duration_sec,
                    "temperature": effective_temperature,
                    "top_p": effective_top_p,
                    "top_k": effective_top_k,
                    "repetition_penalty": effective_repetition,
                    "cfg_scale": effective_cfg
                }
            },
            "8": {
                "class_type": "ConditioningZeroOut",
                "inputs": {
                    "conditioning": ["3", 0]
                }
            },
            "4": {
                "class_type": "EmptyYuE2LatentAudio",
                "inputs": {
                    "seconds": ["3", 1],
                    "batch_size": 1
                }
            },
            "5": {
                "class_type": "KSampler",
                "inputs": {
                    "model": ["1", 0],
                    "seed": seed,
                    "steps": steps,
                    "cfg": 1.0,
                    "sampler_name": "dpm_2",
                    "scheduler": "sgm_uniform",
                    "positive": ["3", 0],
                    "negative": ["8", 0],
                    "latent_image": ["4", 0],
                    "denoise": 1.0
                }
            },
            "6": {
                "class_type": "VAEDecodeAudioTiled",
                "inputs": {
                    "samples": ["5", 0],
                    "vae": ["1", 2],
                    "tile_size": 1920,
                    "overlap": 256
                }
            },
            "7": {
                "class_type": "SaveAudioAdvanced",
                "inputs": {
                    "audio": ["6", 0],
                    "filename_prefix": f"audio/Sonicall_Cover_{seed}",
                    "format": {"format": "flac"}
                }
            }
        }

    # =========================================================================
    # ACE-STEP 1.5 XL & ACE-STEP NATIVE WORKFLOW BUILDERS
    # =========================================================================
    def build_ace_step_15_xl_prompt(
        self,
        title: str,
        style: str,
        lyrics: str,
        seed: int,
        duration_sec: float,
        bpm: int = 120,
        keyscale: str = "E minor",
        temperature: float = 0.85,
        cfg_scale: float = 2.0,
        steps: int = 16,
        top_p: float = 0.90,
        is_cover: bool = False,
        ref_filename: Optional[str] = None,
        ref_duration_sec: float = 0.0,
        is_instrumental: bool = False,
        ckpt_name: Optional[str] = None,
        split_components: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Builds optimized ComfyUI graph for ACE-Step 1.5 XL (supports both split UNET+DualCLIP+VAE
        and all-in-one safetensors checkpoints, plus ReferenceTimbreAudio & audio2audio melody transfer).
        """
        graph: Dict[str, Any] = {}

        if split_components:
            graph["101"] = {
                "class_type": "UNETLoader",
                "inputs": {
                    "unet_name": split_components["unet_name"],
                    "weight_dtype": "default"
                }
            }
            graph["102"] = {
                "class_type": "DualCLIPLoader",
                "inputs": {
                    "clip_name1": split_components["clip_name1"],
                    "clip_name2": split_components["clip_name2"],
                    "type": "ace",
                    "device": "default"
                }
            }
            graph["103"] = {
                "class_type": "VAELoader",
                "inputs": {
                    "vae_name": split_components["vae_name"]
                }
            }
            model_ref = ["101", 0]
            clip_ref = ["102", 0]
            vae_ref = ["103", 0]
            is_turbo = "turbo" in split_components["unet_name"].lower()
        else:
            graph["1"] = {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": ckpt_name or "ace_step_1.5_xl.safetensors"
                }
            }
            model_ref = ["1", 0]
            clip_ref = ["1", 1]
            vae_ref = ["1", 2]
            is_turbo = "turbo" in (ckpt_name or "").lower()

        effective_steps = 8 if (is_turbo and steps <= 24) else (20 if steps <= 24 else 28)
        language = "en" if is_instrumental else detect_lyrics_language(lyrics)
        effective_lyrics = "[instrumental]" if is_instrumental else lyrics

        if is_instrumental:
            tags = (
                f"{style}, instrumental studio arrangement, high dynamic range, "
                f"clean midrange pocket for vocal mix, tight rhythm, no vocals, no singing"
            )
        else:
            tags = f"{style}, studio mix, clear vocal pocket, balanced mastering"

        has_ref = bool(is_cover and ref_filename)

        graph["2"] = {
            "class_type": "ModelSamplingAuraFlow",
            "inputs": {
                "model": model_ref,
                "shift": 3.0
            }
        }

        graph["3"] = {
            "class_type": "TextEncodeAceStepAudio1.5",
            "inputs": {
                "clip": clip_ref,
                "tags": tags,
                "lyrics": effective_lyrics,
                "seed": seed,
                "bpm": max(40, min(240, int(bpm))),
                "duration": float(duration_sec),
                "timesignature": "4",
                "language": language,
                "keyscale": keyscale if keyscale else "E minor",
                "generate_audio_codes": not has_ref,
                "cfg_scale": max(1.5, min(3.5, cfg_scale + 0.6)),
                "temperature": 0.45 if (has_ref and is_instrumental) else temperature,
                "top_p": top_p,
                "top_k": 0,
                "min_p": 0.0
            }
        }

        positive_ref = ["3", 0]
        latent_ref = ["4", 0]
        denoise_val = 1.0

        graph["4"] = {
            "class_type": "EmptyAceStep1.5LatentAudio",
            "inputs": {
                "seconds": float(duration_sec),
                "batch_size": 1
            }
        }

        if has_ref:
            graph["11"] = {
                "class_type": "LoadAudio",
                "inputs": {
                    "audio": ref_filename
                }
            }
            graph["12"] = {
                "class_type": "VAEEncodeAudio",
                "inputs": {
                    "audio": ["11", 0],
                    "vae": vae_ref
                }
            }
            graph["13"] = {
                "class_type": "ReferenceTimbreAudio",
                "inputs": {
                    "conditioning": ["3", 0],
                    "latent": ["12", 0]
                }
            }
            positive_ref = ["13", 0]
            # When transforming voice/melody directly to instrumental of matching length,
            # conditioning latent_image with 0.72 denoise preserves exact melodic timing & phrasing.
            if is_instrumental and ref_duration_sec > 1.5 and abs(duration_sec - ref_duration_sec) <= 4.0:
                latent_ref = ["12", 0]
                denoise_val = 0.72

        graph["8"] = {
            "class_type": "ConditioningZeroOut",
            "inputs": {
                "conditioning": positive_ref
            }
        }

        graph["5"] = {
            "class_type": "KSampler",
            "inputs": {
                "model": ["2", 0],
                "seed": seed,
                "steps": effective_steps,
                "cfg": 1.0,
                "sampler_name": "euler",
                "scheduler": "simple",
                "positive": positive_ref,
                "negative": ["8", 0],
                "latent_image": latent_ref,
                "denoise": denoise_val
            }
        }

        graph["6"] = {
            "class_type": "VAEDecodeAudio",
            "inputs": {
                "samples": ["5", 0],
                "vae": vae_ref
            }
        }

        safe_prefix = "".join(c if c.isalnum() else "_" for c in title[:14]) or "ACEStep"
        graph["7"] = {
            "class_type": "SaveAudioAdvanced",
            "inputs": {
                "audio": ["6", 0],
                "filename_prefix": f"audio/Sonicall_ACE15_{safe_prefix}_{seed}",
                "format": {"format": "flac"}
            }
        }
        return graph

    def build_ace_step_v1_prompt(
        self,
        title: str,
        style: str,
        lyrics: str,
        seed: int,
        duration_sec: float,
        bpm: int = 120,
        cfg_scale: float = 4.0,
        steps: int = 28,
        is_cover: bool = False,
        ref_filename: Optional[str] = None,
        ref_duration_sec: float = 0.0,
        is_instrumental: bool = False,
        ckpt_name: str = "ace_step_v1_3.5b.safetensors",
    ) -> Dict[str, Any]:
        """
        Builds optimized ComfyUI graph for ACE-Step DiT Flow checkpoint (ace_step_v1_3.5b.safetensors),
        tuned for voice-to-instrumental latent melody transfer and clean vocal-mix backing tracks.
        """
        if is_instrumental:
            tags = (
                f"{style}, {bpm} bpm, pure instrumental, clean acoustic & studio mix, "
                f"high clarity, warm harmonic balance, no vocals, no voice"
            )
            effective_lyrics = "[instrumental]"
            lyrics_strength = 0.0
        else:
            tags = f"{style}, {bpm} bpm, studio quality, clear vocals, balanced arrangement"
            effective_lyrics = lyrics
            lyrics_strength = 1.0

        has_ref = bool(is_cover and ref_filename)
        effective_cfg = max(3.5, min(5.5, 3.2 + cfg_scale * 0.8))
        effective_steps = max(28, steps)

        graph: Dict[str, Any] = {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": ckpt_name
                }
            },
            "2": {
                "class_type": "ModelSamplingSD3",
                "inputs": {
                    "model": ["1", 0],
                    "shift": 5.0
                }
            },
            "3": {
                "class_type": "TextEncodeAceStepAudio",
                "inputs": {
                    "clip": ["1", 1],
                    "tags": tags,
                    "lyrics": effective_lyrics,
                    "lyrics_strength": lyrics_strength
                }
            },
            "8": {
                "class_type": "ConditioningZeroOut",
                "inputs": {
                    "conditioning": ["3", 0]
                }
            }
        }

        if has_ref:
            graph["11"] = {
                "class_type": "LoadAudio",
                "inputs": {
                    "audio": ref_filename
                }
            }
            graph["4"] = {
                "class_type": "VAEEncodeAudio",
                "inputs": {
                    "audio": ["11", 0],
                    "vae": ["1", 2]
                }
            }
            # Tuned denoise keeps vocal melody contour & rhythm while converting voice timbre to instruments
            denoise_val = 0.68 if is_instrumental else 0.76
        else:
            graph["4"] = {
                "class_type": "EmptyAceStepLatentAudio",
                "inputs": {
                    "seconds": float(duration_sec),
                    "batch_size": 1
                }
            }
            denoise_val = 1.0

        graph["5"] = {
            "class_type": "KSampler",
            "inputs": {
                "model": ["2", 0],
                "seed": seed,
                "steps": effective_steps,
                "cfg": round(effective_cfg, 2),
                "sampler_name": "euler",
                "scheduler": "simple",
                "positive": ["3", 0],
                "negative": ["8", 0],
                "latent_image": ["4", 0],
                "denoise": denoise_val
            }
        }
        graph["6"] = {
            "class_type": "VAEDecodeAudio",
            "inputs": {
                "samples": ["5", 0],
                "vae": ["1", 2]
            }
        }

        safe_prefix = "".join(c if c.isalnum() else "_" for c in title[:14]) or "ACEStep"
        graph["7"] = {
            "class_type": "SaveAudioAdvanced",
            "inputs": {
                "audio": ["6", 0],
                "filename_prefix": f"audio/Sonicall_ACE_{safe_prefix}_{seed}",
                "format": {"format": "flac"}
            }
        }
        return graph

    def resolve_checkpoint_name(self, model: str) -> str:
        """
        Dynamically inspects ComfyUI's active checkpoint inventory so that ckpt_name
        is 100% guaranteed to be in CheckpointLoaderSimple's allowed enum list.
        """
        allowed: List[str] = []
        try:
            import urllib.request
            req = urllib.request.Request("http://127.0.0.1:8188/object_info/CheckpointLoaderSimple")
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                data = json.loads(resp.read().decode())
                allowed = data["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
        except Exception:
            pass

        if not allowed:
            ck_dir = self._get_models_root() / "checkpoints"
            if ck_dir.exists():
                allowed = [f.name for f in ck_dir.glob("*.safetensors")]

        if not allowed:
            return "yue2_convrot_int8.safetensors"

        m_lower = model.lower()

        # 1. ACE-Step 1.5 XL / ACE-Step
        if "ace" in m_lower:
            # Prefer 1.5 / XL checkpoints first if installed
            for a in allowed:
                al = a.lower()
                if "ace" in al and ("1.5" in al or "15" in al or "xl" in al):
                    return a
            for a in allowed:
                if "ace" in a.lower() or "acestep" in a.lower():
                    return a

        # 2. YuE2 7B / Full / BF16 / Studio
        if "7b" in m_lower or "bf16" in m_lower or "studio" in m_lower:
            for cand in ["yue_7b_full_bf16.safetensors", "yue2_3b_bf16.safetensors", "yue2_studio_bf16.safetensors"]:
                if cand in allowed:
                    return cand
            for a in allowed:
                if "bf16" in a.lower():
                    return a

        # 3. DiffRhythm
        if "diff" in m_lower:
            for a in allowed:
                if "diff" in a.lower():
                    return a

        # 4. Default YuE2 INT8 / ConvRot
        for cand in ["yue2_convrot_int8.safetensors", "yue2_3b_int8_convrot.safetensors"]:
            if cand in allowed:
                return cand

        for a in allowed:
            if "int8" in a.lower() or "convrot" in a.lower():
                return a

        return allowed[0]

    async def run_generation_task(self, task_id: str, request_data: Dict[str, Any]):
        title = request_data.get("title", "").strip() or "Yeni Kayıt"
        lyrics = request_data.get("lyrics", "").strip() or "[verse]\nSinging with passion and power"
        style = request_data.get("style", "").strip() or "Pop Melodic"
        is_cover = bool(request_data.get("is_cover", False))
        is_instrumental = bool(request_data.get("is_instrumental", False))
        ref_audio_path = request_data.get("ref_audio_path")
        model = request_data.get("model", "YuE2 3B INT8")
        bpm = int(request_data.get("bpm") or 120)
        seed = int(request_data.get("custom_seed") or random.randint(1, 9999999))

        structured_lyrics = format_song_lyrics_with_intro_outro(lyrics, style, is_instrumental)

        is_auto_duration = bool(request_data.get("is_auto_duration", False))
        user_duration = float(request_data.get("duration", 45.0))
        detected_keyscale = "E minor"
        ref_duration_actual = 0.0

        if is_auto_duration:
            if ref_audio_path and Path(ref_audio_path).exists():
                try:
                    from audio_service import audio_service
                    analysis = audio_service.analyze_audio_file(ref_audio_path)
                    ref_dur = float(analysis.get("duration", 0.0))
                    detected_keyscale = str(analysis.get("keyscale", "E minor"))
                    if ref_dur > 1.5:
                        ref_duration_actual = ref_dur
                        duration_sec = max(5.0, min(360.0, ref_dur))
                    else:
                        duration_sec = user_duration
                except Exception:
                    duration_sec = user_duration
            else:
                clean_lines = [
                    l for l in structured_lyrics.split("\n")
                    if l.strip() and not (l.startswith("[") and l.endswith("]"))
                ]
                duration_sec = max(35.0, min(240.0, len(clean_lines) * 4.2 + 24.0))
        else:
            duration_sec = max(5.0, min(360.0, user_duration))

        vocal_gender = str(request_data.get("vocal_gender", "Auto"))
        if not is_instrumental:
            if vocal_gender == "Male" and "male" not in style.lower():
                style = f"{style}, rich male vocal"
            elif vocal_gender == "Female" and "female" not in style.lower():
                style = f"{style}, expressive female vocal"

        weirdness = int(request_data.get("weirdness", 50))
        temperature = round(0.45 + (weirdness / 100.0) * 0.75, 3)

        style_influence = int(request_data.get("style_influence", 50))
        cfg_scale = round(1.0 + (style_influence / 100.0) * 1.2, 3)

        max_mode = bool(request_data.get("max_mode", False))
        steps = 38 if max_mode else 30

        variety = int(request_data.get("variety", 70))
        top_p = round(0.85 + (variety / 100.0) * 0.13, 3)
        repetition_penalty = round(1.26 - (variety / 100.0) * 0.20, 3)

        exclude_styles = str(request_data.get("exclude_styles", "")).strip()
        ckpt_name = self.resolve_checkpoint_name(model)
        is_ace_requested = "ace" in model.lower() or "ace" in ckpt_name.lower()

        async def send_progress(pct: int, msg: str):
            await self.broadcast_progress({
                "task_id": task_id,
                "status": "processing",
                "progress": pct,
                "message": msg
            })

        if self.queue_lock.locked():
            await self.broadcast_progress({
                "task_id": task_id,
                "status": "queued",
                "progress": 0,
                "message": "Stüdyo sırası bekleniyor..."
            })

        async with self.queue_lock:
            solo_flag_file = COMFY_INPUT / "instrument_solo.flag"
            comfy_ref_dest: Optional[Path] = None
            try:
                if is_instrumental:
                    try:
                        COMFY_INPUT.mkdir(parents=True, exist_ok=True)
                        solo_flag_file.write_text("1")
                    except Exception:
                        pass
                else:
                    try:
                        solo_flag_file.unlink(missing_ok=True)
                    except Exception:
                        pass

                await send_progress(6, "Stüdyo hazırlanıyor, ses yalıtımı sağlanıyor...")

                ref_filename: Optional[str] = None
                if is_cover and ref_audio_path and Path(ref_audio_path).exists():
                    ref_filename = f"cover_ref_{task_id}.wav"
                    COMFY_INPUT.mkdir(parents=True, exist_ok=True)
                    comfy_ref_dest = COMFY_INPUT / ref_filename

                    await send_progress(10, "Referans kayıt temizleniyor, akustik denge kuruluyor...")
                    try:
                        from audio_service import audio_service
                        cond_info = audio_service.prepare_reference_for_conditioning(
                            src_path=str(ref_audio_path),
                            dest_path=str(comfy_ref_dest),
                            ensure_min_sec=4.5
                        )
                        detected_keyscale = str(cond_info.get("keyscale", detected_keyscale))
                        ref_duration_actual = float(cond_info.get("duration", ref_duration_actual))
                        if not request_data.get("bpm"):
                            bpm = int(cond_info.get("bpm", bpm))
                    except Exception as stg_err:
                        print(f"[EngineAdapter] Reference pre-conditioning fallback: {stg_err}")
                        ref_src = Path(ref_audio_path)
                        ref_filename = f"cover_ref_{task_id}{ref_src.suffix}"
                        comfy_ref_dest = COMFY_INPUT / ref_filename
                        shutil.copy(ref_src, comfy_ref_dest)

                # Select optimal engine graph (ACE-Step 1.5 XL vs ACE-Step Flow vs YuE2)
                if is_ace_requested:
                    split_ace15 = self._find_ace15_split_components()
                    ckpt_path = self._get_models_root() / "checkpoints" / ckpt_name
                    arch = "ace15" if split_ace15 else self._inspect_safetensors_architecture(ckpt_path)

                    await send_progress(16, "Müzisyenler yerleşiyor, tempo ve ton kilitleniyor...")
                    if arch == "ace15":
                        prompt_graph = self.build_ace_step_15_xl_prompt(
                            title=title,
                            style=style,
                            lyrics=structured_lyrics,
                            seed=seed,
                            duration_sec=duration_sec,
                            bpm=bpm,
                            keyscale=detected_keyscale,
                            temperature=temperature,
                            cfg_scale=cfg_scale,
                            steps=steps,
                            top_p=top_p,
                            is_cover=bool(ref_filename),
                            ref_filename=ref_filename,
                            ref_duration_sec=ref_duration_actual,
                            is_instrumental=is_instrumental,
                            ckpt_name=ckpt_name,
                            split_components=split_ace15,
                        )
                    else:
                        prompt_graph = self.build_ace_step_v1_prompt(
                            title=title,
                            style=style,
                            lyrics=structured_lyrics,
                            seed=seed,
                            duration_sec=duration_sec,
                            bpm=bpm,
                            cfg_scale=cfg_scale,
                            steps=steps,
                            is_cover=bool(ref_filename),
                            ref_filename=ref_filename,
                            ref_duration_sec=ref_duration_actual,
                            is_instrumental=is_instrumental,
                            ckpt_name=ckpt_name,
                        )
                else:
                    await send_progress(16, "Müzisyenler yerleşiyor, notalar sehpalara diziliyor...")
                    if ref_filename:
                        prompt_graph = self.build_cover_prompt(
                            ref_filename=ref_filename,
                            style=style,
                            lyrics=structured_lyrics,
                            seed=seed,
                            duration_sec=duration_sec,
                            temperature=temperature,
                            cfg_scale=cfg_scale,
                            steps=steps,
                            top_p=top_p,
                            repetition_penalty=repetition_penalty,
                            negative_style=exclude_styles,
                            ckpt_name=ckpt_name,
                            is_instrumental=is_instrumental
                        )
                    else:
                        prompt_graph = self.build_text_to_music_prompt(
                            title=title,
                            style=style,
                            lyrics=structured_lyrics,
                            seed=seed,
                            duration_sec=duration_sec,
                            temperature=temperature,
                            cfg_scale=cfg_scale,
                            steps=steps,
                            top_p=top_p,
                            repetition_penalty=repetition_penalty,
                            negative_style=exclude_styles,
                            ckpt_name=ckpt_name,
                            is_instrumental=is_instrumental
                        )

                saved_song_name = f"{task_id}.wav"
                dest_song_path = SONGS_DIR / saved_song_name

                generated_file = None
                try:
                    generated_file = await comfy_bridge.execute_workflow(
                        prompt_graph,
                        on_progress=send_progress
                    )
                except Exception as c_err:
                    print(f"[EngineAdapter] ComfyUI execution note: {c_err}")

                if not generated_file or not Path(generated_file).exists():
                    print("[EngineAdapter] Running harmonic solo acoustic engine fallback...")
                    await send_progress(75, "Müzisyenler solo performansını icra ediyor...")
                    from audio_service import audio_service
                    ok = audio_service.synthesize_melodic_instrument_fallback(
                        ref_audio_path=ref_audio_path,
                        style=style,
                        duration_sec=duration_sec,
                        bpm=bpm,
                        output_path=str(dest_song_path)
                    )
                    if not ok:
                        raise RuntimeError("Kayıt oluşturulamadı.")
                else:
                    await send_progress(95, "Miks ve mastering yapılıyor...")
                    gen_path = Path(generated_file)
                    try:
                        import soundfile as sf
                        audio_data, sample_rate = sf.read(str(gen_path))

                        polished_audio, final_sr = polish_generated_master(
                            audio_data=audio_data,
                            sample_rate=sample_rate,
                            target_sr=44100,
                            is_instrumental=is_instrumental,
                            fade_out_sec=min(4.0, duration_sec * 0.12)
                        )

                        target_samples = int(duration_sec * final_sr)
                        current_samples = len(polished_audio)
                        if current_samples > target_samples:
                            polished_audio = apply_musical_fade_envelope(
                                polished_audio[:target_samples],
                                final_sr,
                                fade_out_sec=min(3.5, duration_sec * 0.12)
                            )
                        elif current_samples < target_samples and current_samples > int(final_sr * 2.0) and not is_auto_duration:
                            repetitions = (target_samples // current_samples) + 1
                            polished_audio = np.tile(polished_audio, (repetitions, 1))[:target_samples]
                            polished_audio = apply_musical_fade_envelope(
                                polished_audio,
                                final_sr,
                                fade_out_sec=min(3.5, duration_sec * 0.12)
                            )
                        else:
                            duration_sec = round(len(polished_audio) / float(final_sr), 1)

                        sf.write(str(dest_song_path), polished_audio, final_sr, subtype="PCM_24")
                    except Exception as conv_err:
                        print(f"[EngineAdapter] Fallback copy without conversion: {conv_err}")
                        shutil.copy(gen_path, dest_song_path)

                await send_progress(98, "Son stüdyo kontrolleri tamamlanıyor...")
                cover_url = generate_cover_image(task_id, title, style)
                audio_url = f"/output/songs/{saved_song_name}"

                minutes = int(duration_sec) // 60
                seconds = int(duration_sec) % 60
                duration_formatted = f"{minutes:02d}:{seconds:02d}"

                song_record = {
                    "id": task_id,
                    "title": title,
                    "style": style,
                    "lyrics": structured_lyrics,
                    "is_cover": is_cover,
                    "is_instrumental": is_instrumental,
                    "model": model,
                    "duration_seconds": int(duration_sec),
                    "duration_formatted": duration_formatted,
                    "audio_url": audio_url,
                    "cover_url": cover_url,
                    "liked": False,
                    "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "date_group": "Bugün"
                }

                db = get_db()
                db.insert(0, song_record)
                save_db(db)

                await self.broadcast_progress({
                    "task_id": task_id,
                    "status": "completed",
                    "progress": 100,
                    "message": "Kayıt hazır, iyi dinlemeler!",
                    "song": song_record
                })
                print(f"[EngineAdapter] Song {task_id} successfully created and saved ({duration_formatted})!")

            except Exception as e:
                print(f"[EngineAdapter] Generation Error: {e}")
                await self.broadcast_progress({
                    "task_id": task_id,
                    "status": "error",
                    "progress": 0,
                    "message": f"Stüdyo kaydı tamamlanamadı: {str(e)}"
                })
            finally:
                try:
                    solo_flag_file.unlink(missing_ok=True)
                except Exception:
                    pass


engine_adapter = YuE2EngineAdapter()
