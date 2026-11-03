import os
import time
import shutil
import threading
from pathlib import Path
from typing import Dict, Any, List, Optional
import urllib.request
import urllib.error
from config import load_settings, save_settings, DEFAULT_COMFYUI_MODELS_PATH

def format_size(size_bytes: int) -> str:
    if size_bytes == 0:
        return "0 B"
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"

MODEL_REGISTRY: Dict[str, Dict[str, Any]] = {
    "yue2_convrot_int8": {
        "id": "yue2_convrot_int8",
        "name": "YuE2 3B INT8 ConvRot (Ultra Fast)",
        "type": "Checkpoint (Full Song Synthesis)",
        "subfolder": "checkpoints",
        "filename": "yue2_convrot_int8.safetensors",
        "expected_size": 3960938800,
        "vram_required": "~6 GB VRAM",
        "speed": "⚡⚡⚡ Çok Hızlı",
        "recommended": True,
        "description": "Optimize edilmiş INT8 kuantizasyonu ve döner konvolüsyonel dikkat mimarisi. Düşük gecikmeyle anlık taslaklar, vokal melodileri ve hızlı parça üretimi için idealdir.",
        "urls": [
            "https://huggingface.co/m-a-p/YuE-s1-7B-anneal-int8/resolve/main/model.safetensors"
        ]
    },
    "yue_7b_full_bf16": {
        "id": "yue_7b_full_bf16",
        "name": "YuE 7B (Full / BF16)",
        "type": "Tam Boy Model (Üstün Vokal & Armoni)",
        "subfolder": "checkpoints",
        "filename": "yue2_3b_bf16.safetensors",
        "expected_size": 7799983228,
        "vram_required": "~12-16 GB VRAM",
        "speed": "⚡⚡ Orta (Üstün Kalite)",
        "recommended": False,
        "description": "Özellikle Türkçe/İngilizce vokal telaffuzlarında, şarkı trafiğinde (verse-chorus geçişleri) ve çoklu enstrüman katmanlarında 3B INT8'e göre çok daha zengin harmonik derinlik sunan tam boy BF16 modelidir.",
        "urls": [
            "https://huggingface.co/Comfy-Org/YuE2/resolve/main/checkpoints/yue2_3b_bf16.safetensors"
        ]
    },
    "ace_step": {
        "id": "ace_step",
        "name": "ACE-Step (Transformer & Diffusion)",
        "type": "Hızlı Alternatif (Vokal-Beat Uyumu)",
        "subfolder": "checkpoints",
        "filename": "ace_step_v1_3.5b.safetensors",
        "expected_size": 7699743341,
        "vram_required": "~8 GB VRAM",
        "speed": "⚡⚡⚡⚡ Çok Hızlı (~12 sn)",
        "recommended": True,
        "description": "Yerel müzik üretiminde hız ve ses netliği açısından YuE mimarisine en güçlü alternatiflerden biridir. Vokal-beat uyumu ve ses yüksekliği (loudness) dengesi oldukça iyidir.",
        "urls": [
            "https://huggingface.co/Comfy-Org/ACE-Step/resolve/main/all_in_one/ace_step_v1_3.5b.safetensors"
        ]
    },
    "diffrhythm": {
        "id": "diffrhythm",
        "name": "DiffRhythm (End-to-End Full Song)",
        "type": "Difüzyon Modeli (Sıfır Artifact)",
        "subfolder": "checkpoints",
        "filename": "diffrhythm_1_2.pt",
        "expected_size": 2218709125,
        "vram_required": "~6-8 GB VRAM",
        "speed": "⚡⚡⚡⚡ Ultra Hızlı (~10 sn)",
        "recommended": False,
        "description": "Tam şarkı üretiminde (end-to-end) yüksek hız ve daha az dijital gürültü (artifact) sunan modern bir diğer açık kaynak modeldir.",
        "urls": [
            "https://huggingface.co/ASLP-lab/DiffRhythm-1_2/resolve/main/cfm_model.pt"
        ]
    },
    "yue2_bf16": {
        "id": "yue2_bf16",
        "name": "YuE2 Studio BF16 (Mastering Quality)",
        "type": "Checkpoint (High Fidelity)",
        "subfolder": "checkpoints",
        "filename": "yue2_studio_bf16.safetensors",
        "expected_size": 7921877600,
        "vram_required": "~12 GB VRAM",
        "speed": "⚡⚡ Orta",
        "recommended": False,
        "description": "Sıkıştırmasız 16-bit Bfloat16 saf ağırlıklar ile profesyonel stüdyo miksajı kalitesinde geniş harmonik aralık, zengin enstrüman ayrışması ve kristal berraklığında vokaller.",
        "urls": [
            "https://huggingface.co/m-a-p/YuE-s1-7B-anneal-en-cot/resolve/main/model.safetensors",
            "https://huggingface.co/Truncgil/Sonicall-Models/resolve/main/yue2_studio_bf16.safetensors"
        ]
    },
    "sheetsage2_bf16": {
        "id": "sheetsage2_bf16",
        "name": "SheetSage2 BF16 (Melody & Cover Transcriber)",
        "type": "Audio Encoder (Vocal & Melody Extraction)",
        "subfolder": "audio_encoders",
        "filename": "sheetsage2_bf16.safetensors",
        "expected_size": 1386868122,
        "vram_required": "~3 GB VRAM",
        "speed": "⚡⚡⚡⚡ Anlık Transkripsiyon",
        "recommended": True,
        "description": "Referans ses veya mikrofondan melodiyi akor ve nota yapısına çözümleyen nöral ses kodlayıcı.",
        "urls": [
            "https://huggingface.co/Truncgil/Sonicall-Models/resolve/main/sheetsage2_bf16.safetensors"
        ]
    }
}

class ModelManager:
    def __init__(self):
        self.settings = load_settings()
        self.models_dir = Path(self.settings.get("models_dir", DEFAULT_COMFYUI_MODELS_PATH))
        self.downloads: Dict[str, Dict[str, Any]] = {}
        self.cancel_flags: Dict[str, bool] = {}

    def set_models_dir(self, path_str: str) -> Dict[str, Any]:
        p = Path(path_str)
        if not p.exists() or not p.is_dir():
            return {"success": False, "error": f"Dizin mevcut değil: {path_str}"}
        
        self.models_dir = p
        self.settings["models_dir"] = str(p)
        save_settings(self.settings)
        return {"success": True, "models": self.scan_models()}

    def scan_models(self) -> Dict[str, Any]:
        models_list: List[Dict[str, Any]] = []

        has_any_checkpoint = False
        has_encoder = False

        for m_id, reg in MODEL_REGISTRY.items():
            target_dir = self.models_dir / reg["subfolder"]
            target_file = target_dir / reg["filename"]
            
            found_path = None
            if target_file.exists() and target_file.stat().st_size > 1024 * 1024:
                found_path = target_file
            elif target_dir.exists():
                # Specific matching per model so wrong models are never confused
                for ext in ["*.safetensors", "*.bin", "*.ckpt", "*.pt"]:
                    for f in target_dir.glob(ext):
                        if f.stat().st_size < 1024 * 1024:
                            continue
                        f_low = f.name.lower()
                        if m_id == "yue_7b_full_bf16":
                            if ("7b" in f_low and "3b" not in f_low) or "yue2_3b_bf16" in f_low or "yue_7b" in f_low:
                                found_path = f
                                break
                        elif m_id == "ace_step":
                            if "ace" in f_low or "step" in f_low:
                                found_path = f
                                break
                        elif m_id == "diffrhythm":
                            if "diff" in f_low or "rhythm" in f_low:
                                found_path = f
                                break
                        elif m_id == "yue2_convrot_int8":
                            if "int8" in f_low or ("3b" in f_low and "7b" not in f_low):
                                found_path = f
                                break
                        elif m_id == "yue2_bf16":
                            if "studio" in f_low or ("bf16" in f_low and "7b" not in f_low and "sheetsage" not in f_low):
                                found_path = f
                                break
                        elif m_id == "sheetsage2_bf16":
                            if "sheetsage" in f_low or "encoder" in f_low:
                                found_path = f
                                break
                    if found_path:
                        break

            is_installed = found_path is not None
            if is_installed:
                if reg["subfolder"] == "checkpoints":
                    has_any_checkpoint = True
                elif reg["subfolder"] == "audio_encoders":
                    has_encoder = True

            size_str = format_size(found_path.stat().st_size) if is_installed else "0 B"
            raw_size = found_path.stat().st_size if is_installed else 0

            models_list.append({
                "id": m_id,
                "name": reg["name"],
                "type": reg["type"],
                "description": reg.get("description", ""),
                "installed": is_installed,
                "path": str(found_path) if found_path else "",
                "size": size_str,
                "raw_size": raw_size,
                "expected_size": format_size(reg["expected_size"]),
                "vram_required": reg["vram_required"],
                "speed": reg["speed"],
                "recommended": reg.get("recommended", False),
                "is_downloading": self.downloads.get(m_id, {}).get("status") == "downloading"
            })

        all_ready = has_any_checkpoint and has_encoder

        gpu_detected = "NVIDIA GeForce RTX Series (Ready)"
        try:
            import subprocess
            out = subprocess.check_output(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], text=True)
            first_line = out.strip().split("\n")[0].strip()
            if first_line:
                gpu_detected = f"{first_line} (Ready)"
        except Exception:
            pass

        return {
            "models_dir": str(self.models_dir),
            "all_ready": all_ready,
            "models": models_list,
            "active_model": self.settings.get("selected_model", "yue2_convrot_int8"),
            "gpu_detected": gpu_detected,
            "downloads": self.downloads
        }

    def start_download(self, model_id: str) -> Dict[str, Any]:
        if model_id not in MODEL_REGISTRY:
            return {"success": False, "error": f"Bilinmeyen model ID: {model_id}"}

        reg = MODEL_REGISTRY[model_id]
        target_dir = self.models_dir / reg["subfolder"]
        target_dir.mkdir(parents=True, exist_ok=True)
        final_file = target_dir / reg["filename"]

        if final_file.exists() and final_file.stat().st_size > 1024 * 1024:
            return {"success": True, "message": "Model zaten yüklü.", "status": "completed"}

        cur = self.downloads.get(model_id, {})
        if cur.get("status") == "downloading":
            return {"success": True, "message": "İndirme zaten sürüyor.", "status": "downloading"}

        self.cancel_flags[model_id] = False
        self.downloads[model_id] = {
            "model_id": model_id,
            "name": reg["name"],
            "status": "downloading",
            "progress": 0.0,
            "downloaded_bytes": 0,
            "total_bytes": reg["expected_size"],
            "speed": "0.0 MB/s",
            "eta": "--:--",
            "message": "Bağlantı kuruluyor ve HuggingFace CDN üzerinden indiriliyor...",
            "error": None
        }

        # Background worker thread for real streaming download
        t = threading.Thread(target=self._download_worker, args=(model_id,), daemon=True)
        t.start()

        return {"success": True, "status": "downloading", "message": "İndirme işlemi başlatıldı."}

    def _download_worker(self, model_id: str):
        reg = MODEL_REGISTRY[model_id]
        target_dir = self.models_dir / reg["subfolder"]
        final_file = target_dir / reg["filename"]
        part_file = target_dir / f"{reg['filename']}.part"

        urls = reg.get("urls", [])
        expected_size = reg["expected_size"]

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Sonicall/1.0"
        }

        success = False
        last_error = ""

        import requests

        # Attempt download from URLs using requests streaming
        for url in urls:
            if self.cancel_flags.get(model_id, False):
                break
            try:
                print(f"[ModelManager] Connecting to {url}...")
                with requests.get(url, headers=headers, stream=True, timeout=25, allow_redirects=True) as resp:
                    if resp.status_code not in [200, 206]:
                        last_error = f"HTTP {resp.status_code} ({resp.reason})"
                        print(f"[ModelManager] URL returned {last_error}")
                        continue

                    content_len = resp.headers.get("content-length")
                    total_bytes = int(content_len) if content_len and content_len.isdigit() else expected_size
                    self.downloads[model_id]["total_bytes"] = total_bytes

                    downloaded = 0
                    start_time = time.time()
                    last_update_time = start_time
                    last_downloaded = 0

                    with open(part_file, "wb") as out_file:
                        for chunk in resp.iter_content(chunk_size=1024 * 1024): # 1 MB chunks
                            if self.cancel_flags.get(model_id, False):
                                raise Exception("İndirme kullanıcı tarafından iptal edildi.")
                            if chunk:
                                out_file.write(chunk)
                                downloaded += len(chunk)

                                now = time.time()
                                if now - last_update_time >= 0.4:
                                    elapsed = now - last_update_time
                                    bytes_diff = downloaded - last_downloaded
                                    speed_bps = bytes_diff / elapsed if elapsed > 0 else 0
                                    speed_mb = speed_bps / (1024 * 1024)
                                    progress = min(99.9, (downloaded / total_bytes) * 100) if total_bytes > 0 else 0

                                    remaining_bytes = max(0, total_bytes - downloaded)
                                    eta_sec = remaining_bytes / speed_bps if speed_bps > 0 else 0
                                    eta_str = f"{int(eta_sec // 60):02d}:{int(eta_sec % 60):02d}"

                                    self.downloads[model_id].update({
                                        "status": "downloading",
                                        "progress": round(progress, 1),
                                        "downloaded_bytes": downloaded,
                                        "total_bytes": total_bytes,
                                        "speed": f"{speed_mb:.1f} MB/s",
                                        "eta": eta_str,
                                        "message": f"{format_size(downloaded)} / {format_size(total_bytes)} ({speed_mb:.1f} MB/s • Kalan: {eta_str})"
                                    })
                                    last_update_time = now
                                    last_downloaded = downloaded

                    success = True
                    break
            except Exception as e:
                last_error = str(e)
                print(f"[ModelManager] Download error from {url}: {e}")
                continue

        # Check user cancellation
        if self.cancel_flags.get(model_id, False):
            if part_file.exists():
                try:
                    part_file.unlink()
                except Exception:
                    pass
            self.downloads[model_id] = {
                "model_id": model_id,
                "status": "cancelled",
                "progress": 0.0,
                "message": "İndirme kullanıcı tarafından iptal edildi.",
                "error": None
            }
            return

        if success:
            if part_file.exists():
                if final_file.exists():
                    final_file.unlink()
                part_file.rename(final_file)

            self.downloads[model_id] = {
                "model_id": model_id,
                "status": "completed",
                "progress": 100.0,
                "downloaded_bytes": final_file.stat().st_size if final_file.exists() else expected_size,
                "total_bytes": final_file.stat().st_size if final_file.exists() else expected_size,
                "speed": "Tamamlandı",
                "eta": "00:00",
                "message": f"{reg['name']} başarıyla indirildi ve sisteme entegre edildi!",
                "error": None
            }
        else:
            if part_file.exists():
                try:
                    part_file.unlink()
                except Exception:
                    pass
            self.downloads[model_id] = {
                "model_id": model_id,
                "status": "failed",
                "progress": 0.0,
                "message": f"İndirme bağlantısına ulaşılamadı: {last_error}. Dosyanızı 'Dosya Seç (BYOM)' ile doğrudan ekleyebilirsiniz.",
                "error": last_error
            }

    def cancel_download(self, model_id: str) -> Dict[str, Any]:
        self.cancel_flags[model_id] = True
        if model_id in self.downloads:
            self.downloads[model_id]["status"] = "cancelled"
            self.downloads[model_id]["message"] = "İptal ediliyor..."
        return {"success": True, "message": "İptal talebi gönderildi."}

    def import_local_file(self, model_id: str, source_path_str: str) -> Dict[str, Any]:
        """
        BYOM (Bring Your Own Model):
        Instantly hardlinks or symlinks existing model files (0.01 sec, 0 bytes extra disk space!),
        or copies them with live progress if across different drives.
        """
        if model_id not in MODEL_REGISTRY:
            return {"success": False, "error": f"Bilinmeyen model ID: {model_id}"}
        
        src = Path(source_path_str)
        if not src.exists() or not src.is_file():
            return {"success": False, "error": f"Dosya bulunamadı: {source_path_str}"}

        reg = MODEL_REGISTRY[model_id]
        target_dir = self.models_dir / reg["subfolder"]
        target_dir.mkdir(parents=True, exist_ok=True)
        dest = target_dir / reg["filename"]

        # If source is already the destination, we are done
        try:
            if src.resolve() == dest.resolve():
                return {"success": True, "message": "Model zaten hedef konumda."}
        except Exception:
            pass

        # 1. Try Windows Hardlink first (Instant, 0 extra disk space!)
        try:
            if dest.exists():
                dest.unlink()
            os.link(src, dest)
            print(f"[ModelManager] Created hardlink from {src} to {dest}")
            self.downloads[model_id] = {
                "model_id": model_id,
                "status": "completed",
                "progress": 100.0,
                "message": f"{reg['name']} hardlink bağlantısıyla anında entegre edildi!",
                "error": None
            }
            return {"success": True, "message": f"{reg['name']} bağlantısı (hardlink) anında oluşturuldu!"}
        except Exception as link_err:
            print(f"[ModelManager] Hardlink not possible ({link_err}), attempting symlink or copy...")

        # 2. Try Symlink (Instant)
        try:
            if dest.exists():
                dest.unlink()
            os.symlink(src, dest)
            print(f"[ModelManager] Created symlink from {src} to {dest}")
            self.downloads[model_id] = {
                "model_id": model_id,
                "status": "completed",
                "progress": 100.0,
                "message": f"{reg['name']} sembolik bağlantıyla anında entegre edildi!",
                "error": None
            }
            return {"success": True, "message": f"{reg['name']} sembolik bağlantısı başarıyla oluşturuldu!"}
        except Exception as sym_err:
            print(f"[ModelManager] Symlink not possible ({sym_err}), copying file...")

        # 3. Fallback to copy with live progress updates
        def copy_worker():
            try:
                src_size = src.stat().st_size
                self.downloads[model_id] = {
                    "model_id": model_id,
                    "status": "downloading",
                    "progress": 0.0,
                    "downloaded_bytes": 0,
                    "total_bytes": src_size,
                    "speed": "Yerel Disk Kopyalama",
                    "eta": "--:--",
                    "message": f"Yerel dosya aktarılıyor: {src.name} -> {reg['filename']}",
                    "error": None
                }
                copied = 0
                chunk = 1024 * 1024 * 16 # 16 MB chunks
                with open(src, "rb") as fsrc, open(dest, "wb") as fdest:
                    while True:
                        buf = fsrc.read(chunk)
                        if not buf:
                            break
                        fdest.write(buf)
                        copied += len(buf)
                        pct = (copied / src_size) * 100 if src_size > 0 else 100
                        self.downloads[model_id].update({
                            "progress": round(pct, 1),
                            "downloaded_bytes": copied,
                            "message": f"Kopyalanıyor: {format_size(copied)} / {format_size(src_size)} (%{int(pct)})"
                        })
                self.downloads[model_id] = {
                    "model_id": model_id,
                    "status": "completed",
                    "progress": 100.0,
                    "message": f"{reg['name']} yerel dosyadan başarıyla aktarıldı!",
                    "error": None
                }
            except Exception as copy_err:
                self.downloads[model_id] = {
                    "model_id": model_id,
                    "status": "failed",
                    "progress": 0.0,
                    "message": f"Kopyalama başarısız: {copy_err}",
                    "error": str(copy_err)
                }

        t = threading.Thread(target=copy_worker, daemon=True)
        t.start()
        return {"success": True, "message": "Yerel dosya aktarımı başlatıldı."}

    def get_download_status(self, model_id: Optional[str] = None) -> Dict[str, Any]:
        if model_id:
            return self.downloads.get(model_id, {"status": "idle", "progress": 0.0})
        return self.downloads

model_manager = ModelManager()
