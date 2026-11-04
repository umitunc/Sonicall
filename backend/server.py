import os
import sys
from pathlib import Path

# Ensure backend directory is in sys.path
backend_dir = str(Path(__file__).resolve().parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import time
import uuid
import shutil
import asyncio
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from config import (
    PORT, HOST, BASE_DIR, OUTPUT_DIR, UPLOADS_DIR, SONGS_DIR, COVERS_DIR, STEMS_DIR, SHEETS_DIR, VOCAL_MASTER_DIR,
    load_settings, save_settings
)
from model_manager import model_manager
from yue2_adapter import engine_adapter, get_db, save_db
from comfy_bridge import comfy_bridge
from audio_stems import extract_stems_for_song
from sheet_music_generator import generate_sheet_music_pdf
from audio_service import audio_service
from vocal_mastering_service import vocal_mastering_service

app = FastAPI(
    title="Sonicall AI Music Engine",
    description="Local YuE2 & SheetSage2 backend for Sonicall desktop and web",
    version="1.0.0"
)

# CORS enabled for Flutter Desktop and Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve generated songs, covers, and uploads
app.mount("/output", StaticFiles(directory=str(OUTPUT_DIR)), name="output")

@app.on_event("startup")
async def on_startup():
    asyncio.create_task(asyncio.to_thread(comfy_bridge.ensure_server))

class GenerateRequest(BaseModel):
    title: str = "Yeni Şarkı"
    lyrics: Optional[str] = ""
    style: str = "Pop, Melodic"
    is_cover: bool = False
    is_instrumental: bool = False
    ref_audio_path: Optional[str] = None
    model: str = "YuE2 3B INT8"
    bpm: int = 120
    custom_seed: Optional[int] = None
    duration: float = 45.0
    is_auto_duration: bool = False
    exclude_styles: Optional[str] = ""
    vocal_gender: Optional[str] = "Auto"
    max_mode: bool = False
    weirdness: int = 50
    style_influence: int = 50
    variety: int = 70

class SetModelDirRequest(BaseModel):
    path: str

class ModelDownloadRequest(BaseModel):
    model_id: str

class ModelImportRequest(BaseModel):
    model_id: str
    path: str

class SettingsUpdateRequest(BaseModel):
    models_dir: Optional[str] = None
    selected_model: Optional[str] = None
    theme: Optional[str] = None
    auto_play: Optional[bool] = None

class AudioAnalyzeRequest(BaseModel):
    file_path: str

class VocalMasterRequest(BaseModel):
    file_path: str
    title: Optional[str] = "Mastered Studio Vocal"
    save_to_library: bool = True
    # Step 1: De-Reverb & De-Noise
    enable_dereverb: bool = True
    dereverb_intensity: float = 0.85
    denoise_threshold_db: float = -38.0
    dereverb_model: str = "anvuew/dereverb_mel_band_roformer"
    # Step 2: Vocal Enhancement
    enable_enhancement: bool = True
    parallel_blend: float = 0.45
    air_boost: float = 0.60
    body_warmth: float = 0.50
    de_esser_enabled: bool = True
    enhancer_model: str = "ResembleAI/resemble-enhance"
    # Step 3: DAW Studio Mastering
    enable_daw_master: bool = True
    low_cut_hz: float = 85.0
    boxy_mud_cut_hz: float = 380.0
    boxy_mud_gain_db: float = -3.5
    compressor_ratio: float = 4.0
    compressor_makeup_db: float = 3.5
    studio_ambience_type: str = "Plate Reverb"
    ambience_wet_mix: float = 0.14

@app.get("/")
def root():
    return {
        "service": "Sonicall AI Music Studio Backend",
        "status": "online",
        "port": PORT
    }

@app.get("/api/status")
def get_system_status():
    models_info = model_manager.scan_models()
    return {
        "status": "ready",
        "gpu": models_info["gpu_detected"],
        "models_ready": models_info["all_ready"],
        "active_model": models_info["active_model"],
        "models_dir": models_info["models_dir"]
    }

@app.get("/api/models")
def get_models():
    return model_manager.scan_models()

@app.post("/api/models/path")
def set_models_path(req: SetModelDirRequest):
    res = model_manager.set_models_dir(req.path)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.post("/api/models/download")
def download_model(req: ModelDownloadRequest):
    res = model_manager.start_download(req.model_id)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.get("/api/models/download-status")
def get_download_status(model_id: Optional[str] = None):
    return model_manager.get_download_status(model_id)

@app.post("/api/models/cancel-download")
def cancel_download(req: ModelDownloadRequest):
    return model_manager.cancel_download(req.model_id)

@app.post("/api/models/import-local")
def import_local_model(req: ModelImportRequest):
    res = model_manager.import_local_file(req.model_id, req.path)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.get("/api/settings")
def get_settings():
    return load_settings()

@app.post("/api/settings")
def update_settings(req: SettingsUpdateRequest):
    cur = load_settings()
    if req.models_dir is not None:
        cur["models_dir"] = req.models_dir
        model_manager.set_models_dir(req.models_dir)
    if req.selected_model is not None:
        cur["selected_model"] = req.selected_model
    if req.theme is not None:
        cur["theme"] = req.theme
    if req.auto_play is not None:
        cur["auto_play"] = req.auto_play
    save_settings(cur)
    return cur

@app.get("/api/songs")
def list_songs():
    return get_db()

@app.get("/api/songs/{song_id}")
def get_song(song_id: str):
    db = get_db()
    for s in db:
        if s.get("id") == song_id:
            return s
    raise HTTPException(status_code=404, detail="Şarkı bulunamadı")

@app.post("/api/songs/{song_id}/favorite")
def toggle_favorite(song_id: str):
    db = get_db()
    updated = None
    for s in db:
        if s.get("id") == song_id:
            s["liked"] = not s.get("liked", False)
            updated = s
            break
    if not updated:
        raise HTTPException(status_code=404, detail="Şarkı bulunamadı")
    save_db(db)
    return updated

@app.delete("/api/songs/{song_id}")
def delete_song(song_id: str):
    db = get_db()
    filtered = [s for s in db if s.get("id") != song_id]
    if len(filtered) == len(db):
        raise HTTPException(status_code=404, detail="Şarkı bulunamadı")
    save_db(filtered)
    return {"success": True, "deleted_id": song_id}

@app.post("/api/songs/{song_id}/stems")
def extract_stems(song_id: str):
    db = get_db()
    target_song = None
    for s in db:
        if s.get("id") == song_id:
            target_song = s
            break
    if not target_song:
        raise HTTPException(status_code=404, detail="Şarkı bulunamadı")

    audio_rel = target_song.get("audio_url", "").lstrip("/").replace("/", os.sep)
    audio_full = BASE_DIR / audio_rel
    if not audio_full.exists():
        for ext in [".wav", ".flac", ".mp3"]:
            c = SONGS_DIR / f"{song_id}{ext}"
            if c.exists():
                audio_full = c
                break

    if not audio_full.exists():
        raise HTTPException(status_code=404, detail="Ses dosyası bulunamadı")

    res = extract_stems_for_song(song_id, str(audio_full), OUTPUT_DIR)
    target_song["stems"] = res["stems"]
    save_db(db)
    return {"success": True, "song_id": song_id, "stems": res["stems"]}

@app.post("/api/songs/{song_id}/sheet-music")
def create_sheet_music(song_id: str):
    db = get_db()
    target_song = None
    for s in db:
        if s.get("id") == song_id:
            target_song = s
            break
    if not target_song:
        raise HTTPException(status_code=404, detail="Şarkı bulunamadı")

    audio_rel = target_song.get("audio_url", "").lstrip("/").replace("/", os.sep)
    audio_full = BASE_DIR / audio_rel
    if not audio_full.exists():
        for ext in [".wav", ".flac", ".mp3"]:
            c = SONGS_DIR / f"{song_id}{ext}"
            if c.exists():
                audio_full = c
                break

    if not audio_full.exists():
        raise HTTPException(status_code=404, detail="Ses dosyası bulunamadı")

    pdf_out = SHEETS_DIR / f"{song_id}_sheet_music.pdf"
    generate_sheet_music_pdf(
        audio_path=str(audio_full),
        title=target_song.get("title", "Untitled"),
        style=target_song.get("style", "Melodic"),
        lyrics=target_song.get("lyrics", ""),
        output_pdf_path=str(pdf_out)
    )

    pdf_url = f"/output/sheets/{song_id}_sheet_music.pdf"
    target_song["sheet_music_url"] = pdf_url
    save_db(db)
    return {"success": True, "song_id": song_id, "sheet_music_url": pdf_url}

@app.post("/api/songs/{song_id}/open-sheet")
def open_sheet_music(song_id: str):
    pdf_out = SHEETS_DIR / f"{song_id}_sheet_music.pdf"
    if pdf_out.exists():
        os.startfile(str(pdf_out))
        return {"success": True, "opened": str(pdf_out)}
    raise HTTPException(status_code=404, detail="Nota PDF dosyası henüz oluşturulmadı")

@app.post("/api/songs/{song_id}/open-stems")
def open_stems_folder(song_id: str):
    folder = STEMS_DIR / song_id
    if folder.exists():
        os.startfile(str(folder))
        return {"success": True, "opened": str(folder)}
    raise HTTPException(status_code=404, detail="Stem klasörü bulunamadı")

@app.post("/api/upload")
async def upload_audio(file: UploadFile = File(...)):
    """Uploads reference audio for SheetSage2 Cover & Instrument generation."""
    file_ext = Path(file.filename).suffix
    saved_filename = f"ref_{uuid.uuid4().hex[:8]}{file_ext}"
    saved_path = UPLOADS_DIR / saved_filename
    
    with open(saved_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    analysis = audio_service.analyze_audio_file(str(saved_path))
    return {
        "success": True,
        "filename": file.filename,
        "saved_path": str(saved_path),
        "url": f"/output/uploads/{saved_filename}",
        "duration": analysis.get("duration", 0.0),
        "duration_formatted": analysis.get("duration_formatted", "00:00"),
        "bpm": analysis.get("bpm", 120)
    }

@app.post("/api/audio/analyze")
def analyze_audio(req: AudioAnalyzeRequest):
    res = audio_service.analyze_audio_file(req.file_path)
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.post("/api/record/start")
def start_mic_recording():
    res = audio_service.start_recording()
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.post("/api/record/stop")
def stop_mic_recording():
    res = audio_service.stop_recording()
    if not res.get("success"):
        raise HTTPException(status_code=400, detail=res.get("error"))
    return res

@app.get("/api/record/status")
def get_mic_recording_status():
    return audio_service.get_status()

@app.post("/api/vocal/master")
def master_vocal(req: VocalMasterRequest):
    try:
        res = vocal_mastering_service.process_vocal(
            input_audio_path=req.file_path,
            title=req.title or "Mastered Studio Vocal",
            enable_dereverb=req.enable_dereverb,
            dereverb_intensity=req.dereverb_intensity,
            denoise_threshold_db=req.denoise_threshold_db,
            dereverb_model=req.dereverb_model,
            enable_enhancement=req.enable_enhancement,
            parallel_blend=req.parallel_blend,
            air_boost=req.air_boost,
            body_warmth=req.body_warmth,
            de_esser_enabled=req.de_esser_enabled,
            enhancer_model=req.enhancer_model,
            enable_daw_master=req.enable_daw_master,
            low_cut_hz=req.low_cut_hz,
            boxy_mud_cut_hz=req.boxy_mud_cut_hz,
            boxy_mud_gain_db=req.boxy_mud_gain_db,
            compressor_ratio=req.compressor_ratio,
            compressor_makeup_db=req.compressor_makeup_db,
            studio_ambience_type=req.studio_ambience_type,
            ambience_wet_mix=req.ambience_wet_mix
        )

        if req.save_to_library and res.get("success"):
            # Add to data.json so it is accessible in Kütüphanem (Workspace)
            db = get_db()
            song_record = {
                "id": res["id"],
                "title": res["title"],
                "prompt": f"Vocal Mastering: {req.dereverb_model.split('/')[-1]} -> {req.enhancer_model.split('/')[-1]} -> 4:1 Comp + {req.studio_ambience_type}",
                "style": "Studio Vocal Master (De-Reverb + Enhance + DAW)",
                "lyrics": "[Vokal Mix & Mastering Stüdyo Çıktısı]\n• De-Reverb: %" + str(int(req.dereverb_intensity * 100)) + "\n• Parallel Blend: %" + str(int(req.parallel_blend * 100)) + "\n• Clean Low-Cut: " + str(int(req.low_cut_hz)) + "Hz\n• Boxy Cut: " + str(int(req.boxy_mud_cut_hz)) + "Hz (" + str(req.boxy_mud_gain_db) + "dB)\n• Compressor: " + str(req.compressor_ratio) + ":1\n• Ambience: " + req.studio_ambience_type,
                "audio_url": res["audio_url"],
                "cover_url": "",
                "duration": res["duration"],
                "duration_formatted": f"{int(res['duration']) // 60:02d}:{int(res['duration']) % 60:02d}",
                "liked": False,
                "is_instrumental": False,
                "is_cover": False,
                "is_vocal_master": True,
                "model": "MelBand-RoFormer + Resemble-Enhance",
                "created_at": time.strftime("%Y-%m-%d %H:%M:%S")
            }
            db.insert(0, song_record)
            save_db(db)
            res["song"] = song_record

        return res
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/vocal/open-folder")
def open_vocal_master_folder():
    if VOCAL_MASTER_DIR.exists():
        os.startfile(str(VOCAL_MASTER_DIR))
        return {"success": True, "opened": str(VOCAL_MASTER_DIR)}
    raise HTTPException(status_code=404, detail="Vokal master klasörü bulunamadı")

@app.post("/api/generate")
async def generate_song(req: GenerateRequest):
    task_id = f"sonic_{uuid.uuid4().hex[:8]}"
    # Trigger background generation
    asyncio.create_task(
        engine_adapter.run_generation_task(task_id, req.model_dump())
    )
    return {
        "task_id": task_id,
        "status": "started",
        "title": req.title
    }

@app.get("/api/tasks")
def get_all_tasks():
    return engine_adapter.active_tasks

@app.get("/api/tasks/{task_id}")
def get_task_by_id(task_id: str):
    task = engine_adapter.active_tasks.get(task_id)
    if not task:
        # Check if already completed in DB
        db = get_db()
        for s in db:
            if s.get("id") == task_id:
                return {
                    "task_id": task_id,
                    "status": "completed",
                    "progress": 100,
                    "message": "Şarkı hazır!",
                    "song": s
                }
        raise HTTPException(status_code=404, detail="Task not found")
    return task

@app.websocket("/ws/generation")
async def websocket_generation(websocket: WebSocket):
    await websocket.accept()
    q = asyncio.Queue()
    engine_adapter.subscribers.append(q)

    # Immediately push existing active or recent tasks to catching-up client
    try:
        for tid, tinfo in list(engine_adapter.active_tasks.items()):
            await websocket.send_json(tinfo)
    except Exception:
        pass

    try:
        while True:
            try:
                # Wait for queued updates with 10s timeout for heartbeat ping
                msg = await asyncio.wait_for(q.get(), timeout=10.0)
                await websocket.send_json(msg)
            except asyncio.TimeoutError:
                # Keepalive heartbeat ping
                await websocket.send_json({"type": "ping", "time": time.time()})
    except WebSocketDisconnect:
        pass
    except Exception:
        pass
    finally:
        if q in engine_adapter.subscribers:
            engine_adapter.subscribers.remove(q)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT)
