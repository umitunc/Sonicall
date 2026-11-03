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

        # Submit prompt to ComfyUI
        try:
            res = requests.post(f"{COMFY_HTTP}/prompt", json={"prompt": prompt_graph, "client_id": client_id}, timeout=10)
            if res.status_code != 200:
                print(f"[ComfyBridge] Prompt error: {res.text}")
                return None
            res_data = res.json()
            prompt_id = res_data.get("prompt_id")
        except Exception as e:
            print(f"[ComfyBridge] Failed to post prompt: {e}")
            return None

        # Connect WebSocket to monitor real execution
        loop = asyncio.get_running_loop()
        output_filename = None

        def monitor_ws():
            nonlocal output_filename
            try:
                ws = websocket.WebSocket()
                ws.connect(ws_url, timeout=120)

                current_node_type = ""
                total_steps = 24

                while True:
                    raw = ws.recv()
                    if not raw or not isinstance(raw, str):
                        continue
                    msg = json.loads(raw)
                    mtype = msg.get("type")
                    data = msg.get("data", {})

                    if mtype == "executing":
                        node_id = data.get("node")
                        if node_id is None:
                            # Finished
                            break
                        # Find node class
                        node_info = prompt_graph.get(str(node_id), {})
                        ctype = node_info.get("class_type", "")
                        current_node_type = ctype

                        if ctype == "SheetSage2AudioToABC":
                            asyncio.run_coroutine_threadsafe(
                                on_progress(15, "SheetSage2: Şarkıdan vokal ve melodi konturları çıkarılıyor..."),
                                loop
                            )
                        elif ctype == "YuE2GenerateABC":
                            asyncio.run_coroutine_threadsafe(
                                on_progress(20, "YuE2: ABC armonisi ve akor yapısı örülüyor..."),
                                loop
                            )
                        elif ctype == "YuE2GenerateMusic":
                            asyncio.run_coroutine_threadsafe(
                                on_progress(35, "YuE2: Vokal ve müzik tokenleri latent uzayda sentezleniyor..."),
                                loop
                            )
                        elif ctype == "KSampler":
                            asyncio.run_coroutine_threadsafe(
                                on_progress(50, "KSampler: Difüzyon modelleme adımları işleniyor (RTX GPU)..."),
                                loop
                            )
                        elif ctype in ["VAEDecodeAudio", "VAEDecodeAudioTiled"]:
                            asyncio.run_coroutine_threadsafe(
                                on_progress(88, "VAE Decode: 44.1kHz stüdyo sesine dönüştürülüyor..."),
                                loop
                            )

                    elif mtype == "progress":
                        val = data.get("value", 0)
                        mx = data.get("max", 1)
                        pct = int(50 + (val / max(1, mx)) * 35)
                        asyncio.run_coroutine_threadsafe(
                            on_progress(pct, f"Difüzyon Sentezi: {val}/{mx} adım işlendi"),
                            loop
                        )

                    elif mtype == "executed":
                        # Node finished, check for audio output
                        node_output = data.get("output", {})
                        if "audio" in node_output:
                            audio_list = node_output["audio"]
                            if audio_list and len(audio_list) > 0:
                                output_filename = audio_list[0].get("filename")

                    elif mtype == "execution_error":
                        err = data.get("exception_message", "Unknown execution error")
                        print(f"[ComfyBridge] ComfyUI Error: {err}")
                        break

                ws.close()
            except Exception as e:
                print(f"[ComfyBridge] WebSocket monitoring exception: {e}")

        # Run WS monitoring thread
        await loop.run_in_executor(None, monitor_ws)

        # If output filename not parsed from WS, find latest file in output folder
        if not output_filename:
            files = list(COMFY_OUTPUT.glob("*.flac")) + list(COMFY_OUTPUT.glob("*.wav"))
            if files:
                files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
                output_filename = files[0].name

        if output_filename:
            full_path = COMFY_OUTPUT / output_filename
            if full_path.exists():
                return str(full_path)

        return None

comfy_bridge = ComfyUIBridge()

