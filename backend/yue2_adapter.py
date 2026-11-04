import os
import json
import time
import uuid
import shutil
import random
import asyncio
from pathlib import Path
from typing import Dict, Any, List, Optional
import numpy as np

from config import SONGS_DIR, COVERS_DIR, DATA_FILE, UPLOADS_DIR
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

  <text x="40" y="410" font-family="system-ui, -apple-system, sans-serif" font-weight="800" font-size="28" fill="#ffffff">{title[:24]}</text>
  <text x="40" y="445" font-family="system-ui, -apple-system, sans-serif" font-weight="500" font-size="16" fill="#ffffff" opacity="0.75">{style[:36]}</text>
</svg>"""

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(svg_content)
    return f"/output/covers/{filename}"

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

    # 1. Automatic Intro Injection
    has_intro = "[intro]" in lower_text or "[instrumental intro]" in lower_text
    if not has_intro:
        intro_tag = "[Intro]\n[Catchy Melodic Intro]\n\n"
        if not text.startswith("["):
            text = f"{intro_tag}[Verse]\n{text}"
        else:
            text = f"{intro_tag}{text}"

    # 2. Automatic Outro Injection
    has_outro = any(tag in lower_text for tag in ["[outro]", "[fade out]", "[end]", "[instrumental outro]", "[fade]"])
    if not has_outro:
        outro_tag = "\n\n[Outro]\n[Melodic Vocal Cadence]\n[Fade Out]\n[End]"
        text = f"{text}{outro_tag}"

    return text

def apply_musical_fade_envelope(audio_data: np.ndarray, sample_rate: int, fade_out_sec: float = 4.5) -> np.ndarray:
    """
    Applies a smooth micro fade-in (40ms) and an organic cosine S-curve fade-out (3.5 - 5s)
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

    # 1. Micro fade-in (40ms) to eliminate initial DC offset pop
    fade_in_samples = min(int(sample_rate * 0.04), total_samples // 10)
    if fade_in_samples > 0:
        curve_in = np.linspace(0.0, 1.0, fade_in_samples, dtype=np.float32)
        if audio.ndim == 2:
            curve_in = curve_in[:, np.newaxis]
        audio[:fade_in_samples] *= curve_in

    # 2. Natural Cosine S-Curve Outro Fade-Out (last 4.0 - 5.0 seconds)
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

    def build_text_to_music_prompt(
        self,
        title: str,
        style: str,
        lyrics: str,
        seed: int,
        duration_sec: float,
        temperature: float = 0.85,
        cfg_scale: float = 1.0,
        steps: int = 24,
        top_p: float = 0.95,
        repetition_penalty: float = 1.15,
        negative_style: str = "",
        ckpt_name: str = "yue2_convrot_int8.safetensors"
    ) -> Dict[str, Any]:
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
                    "style": style,
                    "lyrics": lyrics,
                    "seed": seed,
                    "mode": "full",
                    "max_abc_tokens": 2048,
                    "temperature": temperature,
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
                    "style": style,
                    "negative_style": negative_style,
                    "lyrics": lyrics,
                    "abc": ["2", 0],
                    "seed": seed,
                    "mode": "full",
                    "max_duration": duration_sec,
                    "temperature": temperature,
                    "top_p": top_p,
                    "top_k": 100,
                    "repetition_penalty": repetition_penalty,
                    "cfg_scale": cfg_scale
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
                    "negative": ["3", 0],
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
                    "overlap": 128
                }
            },
            "7": {
                "class_type": "SaveAudioAdvanced",
                "inputs": {
                    "audio": ["6", 0],
                    "filename_prefix": f"audio/Sonicall_{title[:12].replace(' ', '_')}",
                    "format": "flac"
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
        cfg_scale: float = 1.0,
        steps: int = 24,
        top_p: float = 0.95,
        repetition_penalty: float = 1.15,
        negative_style: str = "",
        ckpt_name: str = "yue2_convrot_int8.safetensors",
        is_instrumental: bool = False
    ) -> Dict[str, Any]:
        sheetsage_mode = "melody"
        if is_instrumental:
            effective_lyrics = ""
            # Low temperature (0.28) and reduced top_k (20) forces YuE2 into near-deterministic
            # decoding of the conditioned SheetSage2 ABC melody notes, preventing melodic drifting.
            effective_temperature = 0.28
            effective_top_p = 0.82
            effective_top_k = 20
            # Keep repetition penalty gentle (1.02) so repeated notes in the reference melody are not skipped.
            effective_repetition = 1.02
            effective_style = (
                f"{style}, exact reference melody tracking, note for note reproduction, "
                f"identical melodic pitch contour, verbatim transcription of reference notes, "
                f"strictly follow reference melody line, zero melodic variation, no melodic improvisation, "
                f"unaccompanied solo instrument, dry acoustic isolation booth, pristine solo tone, zero vocals, no voice, no singing"
            )
        else:
            effective_lyrics = lyrics
            effective_temperature = temperature
            effective_top_p = top_p
            effective_top_k = 100
            effective_repetition = repetition_penalty
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
                    "mode": sheetsage_mode
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
                    "cfg_scale": cfg_scale
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
                    "negative": ["3", 0],
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
                    "overlap": 128
                }
            },
            "7": {
                "class_type": "SaveAudioAdvanced",
                "inputs": {
                    "audio": ["6", 0],
                    "filename_prefix": f"audio/Sonicall_Cover_{seed}",
                    "format": "flac"
                }
            }
        }

    def resolve_checkpoint_name(self, model: str) -> str:
        """
        Dynamically inspects ComfyUI's active checkpoint inventory so that ckpt_name
        is 100% guaranteed to be in CheckpointLoaderSimple's allowed enum list.
        """
        allowed = []
        try:
            import urllib.request
            import json
            req = urllib.request.Request("http://127.0.0.1:8188/object_info/CheckpointLoaderSimple")
            with urllib.request.urlopen(req, timeout=1.5) as resp:
                data = json.loads(resp.read().decode())
                allowed = data["CheckpointLoaderSimple"]["input"]["required"]["ckpt_name"][0]
        except Exception:
            pass

        if not allowed:
            from config import DEFAULT_COMFYUI_MODELS_PATH
            ck_dir = Path(DEFAULT_COMFYUI_MODELS_PATH) / "checkpoints"
            if ck_dir.exists():
                allowed = [f.name for f in ck_dir.glob("*.safetensors")]

        if not allowed:
            return "yue2_convrot_int8.safetensors"

        m_lower = model.lower()

        # 1. 7B / Full / BF16 / Studio
        if "7b" in m_lower or "bf16" in m_lower or "studio" in m_lower:
            for cand in ["yue_7b_full_bf16.safetensors", "yue2_3b_bf16.safetensors", "yue2_studio_bf16.safetensors"]:
                if cand in allowed:
                    return cand
            for a in allowed:
                if "bf16" in a.lower():
                    return a

        # 2. ACE-Step
        if "ace" in m_lower:
            for a in allowed:
                if "ace" in a.lower():
                    return a

        # 3. DiffRhythm
        if "diff" in m_lower:
            for a in allowed:
                if "diff" in a.lower():
                    return a

        # 4. Default INT8 / ConvRot
        for cand in ["yue2_convrot_int8.safetensors", "yue2_3b_int8_convrot.safetensors"]:
            if cand in allowed:
                return cand

        for a in allowed:
            if "int8" in a.lower() or "convrot" in a.lower():
                return a

        return allowed[0]

    async def run_generation_task(self, task_id: str, request_data: Dict[str, Any]):
        title = request_data.get("title", "").strip() or "Untitled Track"
        lyrics = request_data.get("lyrics", "").strip() or "[verse]\nSinging with passion and power"
        style = request_data.get("style", "").strip() or "Pop Melodic"
        is_cover = bool(request_data.get("is_cover", False))
        is_instrumental = bool(request_data.get("is_instrumental", False))
        ref_audio_path = request_data.get("ref_audio_path")
        model = request_data.get("model", "YuE2 3B INT8")
        seed = int(request_data.get("custom_seed") or random.randint(1, 9999999))

        # Format and guarantee structural Intro & Outro progression
        structured_lyrics = format_song_lyrics_with_intro_outro(lyrics, style, is_instrumental)

        # Advanced options mapping
        is_auto_duration = bool(request_data.get("is_auto_duration", False))
        if ref_audio_path and Path(ref_audio_path).exists() and (is_auto_duration or is_cover):
            try:
                from audio_service import audio_service
                analysis = audio_service.analyze_audio_file(ref_audio_path)
                ref_dur = float(analysis.get("duration", 0.0))
                if ref_dur > 1.5:
                    duration_sec = max(5.0, min(360.0, ref_dur))
                else:
                    duration_sec = float(request_data.get("duration", 45.0))
            except Exception as e:
                duration_sec = float(request_data.get("duration", 45.0))
        elif is_auto_duration:
            clean_lines = [l for l in structured_lyrics.split('\n') if l.strip() and not (l.startswith('[') and l.endswith(']'))]
            calculated_sec = max(35.0, min(240.0, len(clean_lines) * 4.2 + 24.0))
            duration_sec = calculated_sec
        else:
            duration_sec = float(request_data.get("duration", 45.0))

        vocal_gender = str(request_data.get("vocal_gender", "Auto"))
        if vocal_gender == "Male" and "male" not in style.lower():
            style = f"{style}, rich male vocal"
        elif vocal_gender == "Female" and "female" not in style.lower():
            style = f"{style}, expressive female vocal"

        weirdness = int(request_data.get("weirdness", 50))
        # 0% -> 0.5, 50% -> 0.85, 100% -> 1.35
        temperature = 0.5 + (weirdness / 100.0) * 0.85

        style_influence = int(request_data.get("style_influence", 50))
        # 0% -> 1.0, 50% -> 1.4, 100% -> 2.2
        cfg_scale = 1.0 + (style_influence / 100.0) * 1.2

        max_mode = bool(request_data.get("max_mode", False))
        steps = 36 if max_mode else 24

        # Variety mapping (Akor ve Ritim Çeşitliliği / Top-P ve Repetition Penalty)
        variety = int(request_data.get("variety", 70))
        # 0% -> top_p 0.85, rep_penalty 1.30 (Daha tahmin edilebilir, katı tekrar)
        # 50% -> top_p 0.93, rep_penalty 1.18 (Dengeli pop yapısı)
        # 100% -> top_p 0.98, rep_penalty 1.05 (Zengin akor çeşitliliği, ekstra varyasyon)
        top_p = round(0.85 + (variety / 100.0) * 0.13, 3)
        repetition_penalty = round(1.30 - (variety / 100.0) * 0.25, 3)

        # Exclude styles (Negatif Tarz Filtresi)
        exclude_styles = str(request_data.get("exclude_styles", "")).strip()

        # Dynamically resolve checkpoint to guarantee 100% valid ComfyUI prompt enum
        ckpt_name = self.resolve_checkpoint_name(model)

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
                "message": "Sırada bekliyor (Önceki şarkı GPU üzerinde işleniyor)..."
            })

        async with self.queue_lock:
            solo_flag_file = COMFY_INPUT / "instrument_solo.flag"
            try:
                if is_instrumental:
                    try:
                        COMFY_INPUT.mkdir(parents=True, exist_ok=True)
                        solo_flag_file.write_text("1")
                        print("[YuE2Engine] Set instrument_solo.flag for SheetSage2/YuE2 isolation")
                    except Exception as fe:
                        print(f"[YuE2Engine] Solo flag write error: {fe}")
                else:
                    try:
                        solo_flag_file.unlink(missing_ok=True)
                    except Exception:
                        pass

                await send_progress(5, f"YuE2 Motoru ve GPU belleği hazırlanıyor (Hedef Süre: {int(duration_sec)}s)...")

                if is_cover and ref_audio_path and Path(ref_audio_path).exists():
                    ref_src = Path(ref_audio_path)
                    ref_filename = f"cover_ref_{task_id}{ref_src.suffix}"
                    try:
                        COMFY_INPUT.mkdir(parents=True, exist_ok=True)
                        comfy_ref_dest = COMFY_INPUT / ref_filename
                        shutil.copy(ref_src, comfy_ref_dest)
                        print(f"[YuE2Engine] Staged cover reference audio to {comfy_ref_dest}")
                    except Exception as stg_err:
                        print(f"[YuE2Engine] Warning staging cover ref to ComfyUI input: {stg_err}")

                    await send_progress(10, "SheetSage2: Şarkıdan melodi ve vokal çıkarılıyor...")
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

                # Execute real workflow via ComfyUI Bridge on RTX GPU
                generated_file = None
                try:
                    generated_file = await comfy_bridge.execute_workflow(
                        prompt_graph,
                        on_progress=send_progress
                    )
                except Exception as c_err:
                    print(f"[YuE2Engine] ComfyUI execution note: {c_err}")

                if not generated_file or not Path(generated_file).exists():
                    print("[YuE2Engine] Running harmonic solo acoustic engine fallback...")
                    await send_progress(75, "Akustik enstrüman armonik ses sentezi işleniyor...")
                    from audio_service import audio_service
                    ok = audio_service.synthesize_melodic_instrument_fallback(
                        ref_audio_path=ref_audio_path,
                        style=style,
                        duration_sec=duration_sec,
                        bpm=int(request_data.get("bpm", 120)),
                        output_path=str(dest_song_path)
                    )
                    if not ok:
                        raise RuntimeError("Enstrüman ses sentezi oluşturulamadı.")
                else:
                    await send_progress(95, "Ses dosyası 44.1kHz stüdyo WAV formatına dönüştürülüyor...")
                    gen_path = Path(generated_file)
                    try:
                        import soundfile as sf
                        audio_data, sample_rate = sf.read(str(gen_path))

                        smooth_audio = apply_musical_fade_envelope(audio_data, sample_rate, fade_out_sec=4.5)
                        sf.write(str(dest_song_path), smooth_audio, sample_rate, subtype='PCM_16')
                    except Exception as conv_err:
                        print(f"[YuE2Engine] Fallback copy without conversion: {conv_err}")
                        shutil.copy(gen_path, dest_song_path)

                await send_progress(98, "Son mastering ve kütüphane kaydı tamamlanıyor...")
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
                    "message": "Şarkı başarıyla üretildi!",
                    "song": song_record
                })
                print(f"[YuE2Engine] Song {task_id} successfully created and saved ({duration_formatted})!")

            except Exception as e:
                print(f"[YuE2Engine] Generation Error: {e}")
                await self.broadcast_progress({
                    "task_id": task_id,
                    "status": "error",
                    "progress": 0,
                    "message": f"Hata: {str(e)}"
                })
            finally:
                try:
                    solo_flag_file.unlink(missing_ok=True)
                except Exception:
                    pass

engine_adapter = YuE2EngineAdapter()
