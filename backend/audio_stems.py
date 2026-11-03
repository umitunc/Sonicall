import os
from pathlib import Path
from typing import Dict, Any
import numpy as np
import soundfile as sf
import librosa
from scipy.signal import butter, sosfilt

def butter_bandpass(lowcut, highcut, fs, order=4):
    nyq = 0.5 * fs
    low = max(0.001, lowcut / nyq)
    high = min(0.999, highcut / nyq)
    sos = butter(order, [low, high], btype='band', output='sos')
    return sos

def butter_lowpass(cutoff, fs, order=4):
    nyq = 0.5 * fs
    normal_cutoff = min(0.999, cutoff / nyq)
    sos = butter(order, normal_cutoff, btype='low', output='sos')
    return sos

def butter_highpass(cutoff, fs, order=4):
    nyq = 0.5 * fs
    normal_cutoff = max(0.001, cutoff / nyq)
    sos = butter(order, normal_cutoff, btype='high', output='sos')
    return sos

def separate_stems_dsp(audio_path: str, output_folder: Path) -> Dict[str, str]:
    """
    High-fidelity 4-stem audio separation:
    - Vocals (Center vocal harmonic separation)
    - Instrumental (Music backing track without vocal)
    - Bass (Sub & Bass harmonics < 250 Hz)
    - Drums (Percussive transients & beat)
    """
    output_folder.mkdir(parents=True, exist_ok=True)
    
    # Load audio in stereo
    y, sr = librosa.load(audio_path, sr=44100, mono=False)
    if y.ndim == 1:
        y = np.vstack([y, y])
    
    left = y[0]
    right = y[1]
    
    # Mid (center) and Side channels
    mid = 0.5 * (left + right)
    side = 0.5 * (left - right)
    
    # 1. Harmonic / Percussive Separation on Mid
    harmonic, percussive = librosa.effects.hpss(mid, margin=(1.2, 1.8))
    
    # 2. Vocal Extraction: Center vocal harmonic presence (300 Hz - 4000 Hz)
    sos_vocal = butter_bandpass(280, 4200, sr, order=4)
    vocal_mid = sosfilt(sos_vocal, harmonic)
    
    # Expand vocals slightly to stereo
    vocals_left = np.clip(vocal_mid * 0.9 + side * 0.1, -1.0, 1.0)
    vocals_right = np.clip(vocal_mid * 0.9 - side * 0.1, -1.0, 1.0)
    vocals_stereo = np.vstack([vocals_left, vocals_right]).T
    
    # 3. Instrumental: Original minus center vocal presence
    inst_left = np.clip(left - (vocal_mid * 0.82), -1.0, 1.0)
    inst_right = np.clip(right - (vocal_mid * 0.82), -1.0, 1.0)
    inst_stereo = np.vstack([inst_left, inst_right]).T
    
    # 4. Bass: Low-frequency harmonic content (< 220 Hz)
    sos_bass = butter_lowpass(220, sr, order=5)
    bass_mono = sosfilt(sos_bass, harmonic)
    bass_stereo = np.vstack([bass_mono, bass_mono]).T
    
    # 5. Drums: Percussive transients with body (60 Hz - 8000 Hz)
    sos_drums = butter_bandpass(60, 9000, sr, order=4)
    drums_mono = sosfilt(sos_drums, percussive)
    drums_stereo = np.vstack([drums_mono * 1.1, drums_mono * 1.1]).T
    
    # Write WAV files
    vocals_path = output_folder / "vocals.wav"
    inst_path = output_folder / "instrumental.wav"
    bass_path = output_folder / "bass.wav"
    drums_path = output_folder / "drums.wav"
    
    sf.write(str(vocals_path), vocals_stereo, sr, subtype='PCM_16')
    sf.write(str(inst_path), inst_stereo, sr, subtype='PCM_16')
    sf.write(str(bass_path), bass_stereo, sr, subtype='PCM_16')
    sf.write(str(drums_path), drums_stereo, sr, subtype='PCM_16')
    
    rel_base = f"/output/stems/{output_folder.name}"
    return {
        "vocals": f"{rel_base}/vocals.wav",
        "instrumental": f"{rel_base}/instrumental.wav",
        "bass": f"{rel_base}/bass.wav",
        "drums": f"{rel_base}/drums.wav"
    }

def extract_stems_for_song(song_id: str, audio_file_path: str, base_output_dir: Path) -> Dict[str, Any]:
    stems_dir = base_output_dir / "stems" / song_id
    stems_map = separate_stems_dsp(audio_file_path, stems_dir)
    return {
        "song_id": song_id,
        "stems": stems_map,
        "local_dir": str(stems_dir)
    }

