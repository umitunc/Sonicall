import os
import sys
import time
import json
import uuid
import shutil
import asyncio
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any, Callable, Coroutine
import requests
import websocket

candidate_dirs = [
    Path(r"D:\Works\2026\ComfyUI\ComfyUI"),
    Path(r"D:\Works\2026\ComfyUI"),
    Path(r"D:\Works\2026\AI FILMMAKING\ComfyUI")
]
COMFY_DIR = candidate_dirs[0]
for d in candidate_dirs:
    if d.exists():
        COMFY_DIR = d
        break

COMFY_PYTHON = COMFY_DIR / ".venv" / "Scripts" / "python.exe"
if not COMFY_PYTHON.exists():
    COMFY_PYTHON = Path(sys.executable)

COMFY_INPUT = COMFY_DIR / "input"
COMFY_OUTPUT = COMFY_DIR / "output" / "audio"
try:
    COMFY_INPUT.mkdir(parents=True, exist_ok=True)
    COMFY_OUTPUT.mkdir(parents=True, exist_ok=True)
except Exception:
    pass

COMFY_HTTP = "http://127.0.0.1:8188"
COMFY_WS = "ws://127.0.0.1:8188/ws"

class ComfyUIBridge:
    def __init__(self):
        self.process: Optional[subprocess.Popen] = None

    def is_running(self) -> bool:
        try:
            r = requests.get(f"{COMFY_HTTP}/system_stats", timeout=1.5)
            return r.status_code == 200
        except Exception:
            return False

    def ensure_server(self):
        if self.is_running():
            print("[Sonicall ComfyBridge] ComfyUI server is already running on port 8188.")
            return True

        print("[Sonicall ComfyBridge] Starting ComfyUI server in background...")
        if not COMFY_PYTHON.exists():
            print(f"[Sonicall ComfyBridge] ERROR: Python not found at {COMFY_PYTHON}")
            return False

        cmd = [
            str(COMFY_PYTHON),
            str(COMFY_DIR / "main.py"),
            "--listen", "127.0.0.1",
            "--port", "8188",
            "--disable-auto-launch"
        ]
        self.process = subprocess.Popen(
            cmd,
            cwd=str(COMFY_DIR),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
        )

        # Wait for ComfyUI to come online
        for _ in range(30):
            time.sleep(1)
            if self.is_running():
                print("[Sonicall ComfyBridge] ComfyUI server successfully started!")
                return True
        return False

    async def execute_workflow(
        self,
        prompt_graph: Dict[str, Any],
        on_progress: Optional[Callable[[int, str], Coroutine[Any, Any, None]]] = None
    ) -> Optional[str]:
        """
        Submits prompt to ComfyUI, monitors WebSocket progress,
        and returns the generated audio file path.
        """
        self.ensure_server()

        client_id = f"sonicall_{uuid.uuid4().hex[:8]}"
        ws_url = f"{COMFY_WS}?clientId={client_id}"
        start_ts = time.time()

        # Connect WebSocket BEFORE posting prompt so fast executions never miss events
        ws = None
        try:
            ws = websocket.WebSocket()
            ws.connect(ws_url, timeout=180)
        except Exception as ws_err:
            print(f"[ComfyBridge] WebSocket pre-connect note: {ws_err}")
            ws = None

        # Submit prompt to ComfyUI
        try:
            res = requests.post(f"{COMFY_HTTP}/prompt", json={"prompt": prompt_graph, "client_id": client_id}, timeout=10)
            if res.status_code != 200:
                print(f"[ComfyBridge] Prompt error: {res.text}")
                if ws:
                    try:
                        ws.close()
                    except Exception:
                        pass
                return None
            res_data = res.json()
            prompt_id = res_data.get("prompt_id")
        except Exception as e:
            print(f"[ComfyBridge] Failed to post prompt: {e}")
            if ws:
                try:
                    ws.close()
                except Exception:
                    pass
            return None

        # Monitor real execution over WebSocket
        loop = asyncio.get_running_loop()
        output_filename = None
        output_subfolder = ""
        had_error = False

        def emit_stage(pct: int, msg: str):
            if on_progress is not None:
                try:
                    asyncio.run_coroutine_threadsafe(on_progress(pct, msg), loop)
                except Exception:
                    pass

        def monitor_ws():
            nonlocal output_filename, output_subfolder, ws, had_error
            try:
                if ws is None:
                    ws = websocket.WebSocket()
                    ws.connect(ws_url, timeout=180)

                while True:
                    raw = ws.recv()
                    if not raw or not isinstance(raw, str):
                        continue
                    msg = json.loads(raw)
                    mtype = msg.get("type")
                    data = msg.get("data", {})

                    msg_pid = data.get("prompt_id")
                    if msg_pid and prompt_id and msg_pid != prompt_id:
                        continue

                    if mtype == "executing":
                        node_id = data.get("node")
                        if node_id is None:
                            break
                        node_info = prompt_graph.get(str(node_id), {})
                        ctype = node_info.get("class_type", "")

                        if ctype in ["CheckpointLoaderSimple", "UNETLoader", "DualCLIPLoader", "VAELoader"]:
                            emit_stage(14, "Ses yalıtımı sağlanıyor, akustik sahne hazırlanıyor...")
                        elif ctype in ["SheetSage2AudioToABC", "LoadAudio", "VAEEncodeAudio", "ReferenceTimbreAudio"]:
                            emit_stage(22, "Notalar sehpalara diziliyor, melodi analiz ediliyor...")
                        elif ctype in ["YuE2GenerateABC", "TextEncodeAceStepAudio", "TextEncodeAceStepAudio1.5"]:
                            emit_stage(30, "Müzisyenler yerleşiyor, enstrümanlar akort ediliyor...")
                        elif ctype == "YuE2GenerateMusic":
                            emit_stage(40, "Orkestra hazır, partisyonlar düzenleniyor...")
                        elif ctype == "KSampler":
                            emit_stage(52, "Kayıt başladı, müzisyenler eserini icra ediyor...")
                        elif ctype in ["VAEDecodeAudio", "VAEDecodeAudioTiled"]:
                            emit_stage(88, "Kayıt tamamlandı, kanal dengeleri ayarlanıyor...")
                        elif ctype in ["SaveAudio", "SaveAudioAdvanced"]:
                            emit_stage(93, "Miks ve mastering yapılıyor...")

                    elif mtype == "progress":
                        val = data.get("value", 0)
                        mx = max(1, data.get("max", 1))
                        ratio = min(1.0, max(0.0, val / mx))
                        pct = int(52 + ratio * 34)
                        if ratio < 0.35:
                            stage_text = "Kayıt sürüyor, müzisyenler eserini icra ediyor..."
                        elif ratio < 0.72:
                            stage_text = "Melodi ve armoniler stüdyoda yükseliyor..."
                        else:
                            stage_text = "Son nüanslar ve enstrüman katmanları kaydediliyor..."
                        emit_stage(pct, stage_text)

                    elif mtype == "executed":
                        node_output = data.get("output", {})
                        if "audio" in node_output:
                            audio_list = node_output["audio"]
                            if audio_list and len(audio_list) > 0:
                                output_filename = audio_list[0].get("filename")
                                output_subfolder = audio_list[0].get("subfolder", "")

                    elif mtype == "execution_error":
                        had_error = True
                        err = data.get("exception_message", "Unknown execution error")
                        print(f"[ComfyBridge] ComfyUI Error: {err}")
                        break

                ws.close()
            except Exception as e:
                print(f"[ComfyBridge] WebSocket monitoring exception: {e}")
                if ws:
                    try:
                        ws.close()
                    except Exception:
                        pass

        # Run WS monitoring thread
        await loop.run_in_executor(None, monitor_ws)

        if had_error:
            return None

        # Also check ComfyUI /history/{prompt_id} if WS missed executed event
        if not output_filename and prompt_id:
            try:
                hr = requests.get(f"{COMFY_HTTP}/history/{prompt_id}", timeout=3)
                if hr.status_code == 200:
                    hdata = hr.json().get(prompt_id, {})
                    outputs = hdata.get("outputs", {})
                    for _, nout in outputs.items():
                        if "audio" in nout and nout["audio"]:
                            output_filename = nout["audio"][0].get("filename")
                            output_subfolder = nout["audio"][0].get("subfolder", "")
                            break
            except Exception:
                pass

        if output_filename:
            base_out = COMFY_DIR / "output"
            cand1 = (base_out / output_subfolder / output_filename) if output_subfolder else (base_out / output_filename)
            if cand1.exists():
                return str(cand1)
            cand2 = COMFY_OUTPUT / output_filename
            if cand2.exists():
                return str(cand2)

        # Fallback: ONLY pick files newly written during this run
        files = [
            f for f in (list(COMFY_OUTPUT.glob("*.flac")) + list(COMFY_OUTPUT.glob("*.wav")))
            if f.stat().st_mtime >= (start_ts - 1.0)
        ]
        if files:
            files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
            return str(files[0])

        return None

comfy_bridge = ComfyUIBridge()

