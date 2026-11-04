import os
import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
OUTPUT_DIR = BASE_DIR / "output"
SONGS_DIR = OUTPUT_DIR / "songs"
COVERS_DIR = OUTPUT_DIR / "covers"
UPLOADS_DIR = OUTPUT_DIR / "uploads"
STEMS_DIR = OUTPUT_DIR / "stems"
SHEETS_DIR = OUTPUT_DIR / "sheets"
VOCAL_MASTER_DIR = OUTPUT_DIR / "vocal_mastering"
DATA_FILE = BASE_DIR / "backend" / "data.json"
SETTINGS_FILE = BASE_DIR / "backend" / "settings.json"

for d in [OUTPUT_DIR, SONGS_DIR, COVERS_DIR, UPLOADS_DIR, STEMS_DIR, SHEETS_DIR, VOCAL_MASTER_DIR]:
    d.mkdir(parents=True, exist_ok=True)

candidate_model_dirs = [
    Path(r"D:\Works\2026\ComfyUI\ComfyUI\models"),
    Path(r"D:\Works\2026\ComfyUI\models"),
]
DEFAULT_COMFYUI_MODELS_PATH = str(candidate_model_dirs[0])
for d in candidate_model_dirs:
    if d.exists():
        DEFAULT_COMFYUI_MODELS_PATH = str(d)
        break
PORT = 5824
HOST = "127.0.0.1"

def load_settings():
    if SETTINGS_FILE.exists():
        try:
            with open(SETTINGS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "models_dir": DEFAULT_COMFYUI_MODELS_PATH,
        "selected_model": "yue2_convrot_int8",
        "output_format": "wav",
        "theme": "dark",
        "auto_play": True
    }

def save_settings(settings: dict):
    with open(SETTINGS_FILE, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
