import os
import sys
from pathlib import Path

# Ensure backend directory is in sys.path
backend_dir = str(Path(__file__).resolve().parent)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import uuid
import shutil
import asyncio
from typing import Optional, Dict, Any

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

from config import (
    PORT, HOST, BASE_DIR, OUTPUT_DIR, UPLOADS_DIR, SONGS_DIR, COVERS_DIR, STEMS_DIR, SHEETS_DIR,
    load_settings, save_settings
)
from model_manager import model_manager
from yue2_adapter import engine_adapter, get_db, save_db
from comfy_bridge import comfy_bridge
from audio_stems import extract_stems_for_song
from sheet_music_generator import generate_sheet_music_pdf

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
    """Uploads reference audio for SheetSage2 Cover generation."""
    file_ext = Path(file.filename).suffix
    saved_filename = f"ref_{uuid.uuid4().hex[:8]}{file_ext}"
    saved_path = UPLOADS_DIR / saved_filename
    
    with open(saved_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {
        "success": True,
        "filename": file.filename,
        "saved_path": str(saved_path),
        "url": f"/output/uploads/{saved_filename}"
    }

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

@app.websocket("/ws/generation")
async def websocket_generation(websocket: WebSocket):
    await websocket.accept()
    q = asyncio.Queue()
    engine_adapter.subscribers.append(q)
    try:
        while True:
            # Send queued updates
            msg = await q.get()
            await websocket.send_json(msg)
    except WebSocketDisconnect:
        if q in engine_adapter.subscribers:
            engine_adapter.subscribers.remove(q)
    except Exception:
        if q in engine_adapter.subscribers:
            engine_adapter.subscribers.remove(q)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=HOST, port=PORT)
