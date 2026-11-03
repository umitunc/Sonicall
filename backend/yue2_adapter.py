import os
import json
import time
import uuid
import shutil
import random
import asyncio
from pathlib import Path
from typing import Dict, Any, List, Optional

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

class YuE2EngineAdapter:
    def __init__(self):
        self.active_tasks: Dict[str, Dict[str, Any]] = {}
        self.subscribers: List[asyncio.Queue] = []

    async def broadcast_progress(self, message: Dict[str, Any]):
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
        steps: int = 24
    ) -> Dict[str, Any]:
        return {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": "yue2_convrot_int8.safetensors"
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
                    "top_p": 0.9,
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
                    "lyrics": lyrics,
                    "abc": ["2", 0],
                    "seed": seed,
                    "mode": "full",
                    "max_duration": duration_sec,
                    "temperature": temperature,
                    "top_p": 0.95,
                    "top_k": 100,
                    "repetition_penalty": 1.2,
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
        steps: int = 24
    ) -> Dict[str, Any]:
        return {
            "1": {
                "class_type": "CheckpointLoaderSimple",
                "inputs": {
                    "ckpt_name": "yue2_convrot_int8.safetensors"
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
                    "style": style,
                    "lyrics": lyrics,
                    "abc": ["12", 0],
                    "seed": seed,
                    "mode": "melody",
                    "max_duration": duration_sec,
                    "temperature": temperature,
                    "top_p": 0.95,
                    "top_k": 100,
                    "repetition_penalty": 1.2,
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

    async def run_generation_task(self, task_id: str, request_data: Dict[str, Any]):
        title = request_data.get("title", "").strip() or "Untitled Track"
        lyrics = request_data.get("lyrics", "").strip() or "[verse]\nSinging with passion and power"
        style = request_data.get("style", "").strip() or "Pop Melodic"
        is_cover = bool(request_data.get("is_cover", False))
        is_instrumental = bool(request_data.get("is_instrumental", False))
        ref_audio_path = request_data.get("ref_audio_path")
        model = request_data.get("model", "YuE2 3B INT8")
        seed = int(request_data.get("custom_seed") or random.randint(1, 9999999))

        # Advanced options mapping
        is_auto_duration = bool(request_data.get("is_auto_duration", False))
        if is_auto_duration:
            clean_lines = [l for l in lyrics.split('\n') if l.strip() and not (l.startswith('[') and l.endswith(']'))]
            calculated_sec = max(30.0, min(240.0, len(clean_lines) * 4.2 + 18.0))
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

        async def send_progress(pct: int, msg: str):
            await self.broadcast_progress({
                "task_id": task_id,
                "status": "processing",
                "progress": pct,
                "message": msg
            })

        try:
            await send_progress(5, f"YuE2 Motoru ve GPU belleği hazırlanıyor (Hedef Süre: {int(duration_sec)}s)...")

            if is_cover and ref_audio_path and Path(ref_audio_path).exists():
                ref_src = Path(ref_audio_path)
                ref_filename = f"cover_ref_{task_id}{ref_src.suffix}"
                comfy_ref_dest = COMFY_INPUT / ref_filename
                shutil.copy(ref_src, comfy_ref_dest)
                print(f"[YuE2Engine] Staged cover reference audio to {comfy_ref_dest}")

                await send_progress(10, "SheetSage2: Şarkıdan melodi ve vokal çıkarılıyor...")
                prompt_graph = self.build_cover_prompt(
                    ref_filename=ref_filename,
                    style=style,
                    lyrics=lyrics if not is_instrumental else "[instrumental]",
                    seed=seed,
                    duration_sec=duration_sec,
                    temperature=temperature,
                    cfg_scale=cfg_scale,
                    steps=steps
                )
            else:
                prompt_graph = self.build_text_to_music_prompt(
                    title=title,
                    style=style,
                    lyrics=lyrics if not is_instrumental else "[instrumental]",
                    seed=seed,
                    duration_sec=duration_sec,
                    temperature=temperature,
                    cfg_scale=cfg_scale,
                    steps=steps
                )

            # Execute real workflow via ComfyUI Bridge on RTX GPU
            generated_file = await comfy_bridge.execute_workflow(
                prompt_graph,
                on_progress=send_progress
            )

            if not generated_file or not Path(generated_file).exists():
                raise RuntimeError("ComfyUI ses dosyası oluşturulamadı.")

            await send_progress(95, "Ses dosyası 44.1kHz stüdyo WAV formatına dönüştürülüyor...")

            # Convert/Copy generated audio into Sonicall output directory as standard WAV
            gen_path = Path(generated_file)
            saved_song_name = f"{task_id}.wav"
            dest_song_path = SONGS_DIR / saved_song_name

            try:
                import soundfile as sf
                audio_data, sample_rate = sf.read(str(gen_path))
                sf.write(str(dest_song_path), audio_data, sample_rate, subtype='PCM_16')
            except Exception as conv_err:
                print(f"[YuE2Engine] Fallback copy without conversion: {conv_err}")
                shutil.copy(gen_path, dest_song_path)

            cover_url = generate_cover_image(task_id, title, style)
            audio_url = f"/output/songs/{saved_song_name}"

            minutes = int(duration_sec) // 60
            seconds = int(duration_sec) % 60
            duration_formatted = f"{minutes:02d}:{seconds:02d}"

            song_record = {
                "id": task_id,
                "title": title,
                "style": style,
                "lyrics": lyrics if not is_instrumental else "[Instrumental]",
                "is_cover": is_cover,
                "is_instrumental": is_instrumental,
                "model": f"{model} + SheetSage2" if is_cover else model,
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

engine_adapter = YuE2EngineAdapter()
