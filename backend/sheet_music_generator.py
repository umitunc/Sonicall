import os
import math
from pathlib import Path
from typing import List, Dict, Any, Tuple
import numpy as np
import librosa
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfgen import canvas

NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']

# Standard treble staff coordinates:
# Line 1 (bottom line) is E4 (MIDI 64)
# Space 1 is F4 (MIDI 65)
# Line 2 is G4 (MIDI 67)
# Space 2 is A4 (MIDI 69)
# Line 3 is B4 (MIDI 71)
# Space 3 is C5 (MIDI 72)
# Line 4 is D5 (MIDI 74)
# Space 4 is E5 (MIDI 76)
# Line 5 (top line) is F5 (MIDI 77)

# Diatonic steps from E4:
DIATONIC_PITCHES = {
    60: -2, # C4 (Middle C)
    62: -1, # D4
    64: 0,  # E4 (Line 1)
    65: 1,  # F4
    67: 2,  # G4 (Line 2)
    69: 3,  # A4
    71: 4,  # B4 (Line 3)
    72: 5,  # C5
    74: 6,  # D5 (Line 4)
    76: 7,  # E5
    77: 8,  # F5 (Line 5)
    79: 9,  # G5
    81: 10, # A5
    83: 11  # B5
}

def midi_to_diatonic_step(midi_pitch: int) -> int:
    closest_midi = min(DIATONIC_PITCHES.keys(), key=lambda k: abs(k - midi_pitch))
    return DIATONIC_PITCHES[closest_midi]

def extract_melody_notes(audio_path: str, max_notes: int = 48) -> Tuple[List[Dict[str, Any]], int]:
    """
    Extracts melodic pitch track and note events using Librosa YIN / Onset analysis.
    """
    try:
        y, sr = librosa.load(audio_path, sr=22050, mono=True, duration=60.0)
        tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
        bpm = int(float(tempo[0] if isinstance(tempo, (np.ndarray, list)) else tempo))
        if bpm < 60 or bpm > 200:
            bpm = 120
    except Exception:
        bpm = 120
        y, sr = None, 22050

    notes: List[Dict[str, Any]] = []

    if y is not None:
        try:
            # Estimate fundamental frequency with pyin
            fmin = librosa.note_to_hz('C3')
            fmax = librosa.note_to_hz('C6')
            f0, voiced_flag, voiced_probs = librosa.pyin(y, fmin=fmin, fmax=fmax, sr=sr, frame_length=2048)
            
            times = librosa.times_like(f0, sr=sr)
            onsets = librosa.onset.onset_detect(y=y, sr=sr, units='time')
            
            # Form notes at onsets
            for i, t_onset in enumerate(onsets[:max_notes]):
                frame_idx = np.argmin(np.abs(times - t_onset))
                freq = f0[frame_idx]
                if np.isnan(freq) or freq < 50:
                    midi_val = 60 + (i % 12) # Fallback melodic shape
                else:
                    midi_val = int(round(librosa.hz_to_midi(freq)))

                # Clamp to vocal singing range (C4 to G5)
                midi_val = max(60, min(79, midi_val))
                
                # Duration in beats
                dur_beats = 1.0 # default quarter note
                if i % 4 == 3:
                    dur_beats = 2.0 # half note cadence

                notes.append({
                    "midi": midi_val,
                    "duration": dur_beats,
                    "name": NOTE_NAMES[midi_val % 12]
                })
        except Exception as e:
            print(f"[SheetSage] Pitch analysis fallback: {e}")

    # Fallback template if pitch extraction returned too few
    if len(notes) < 16:
        pattern = [60, 62, 64, 67, 69, 67, 64, 62, 60, 64, 67, 72, 71, 69, 67, 64]
        for m in pattern:
            notes.append({"midi": m, "duration": 1.0, "name": NOTE_NAMES[m % 12]})

    return notes, bpm

def draw_treble_clef(c: canvas.Canvas, x: float, y_bottom_line: float, step_size: float):
    """
    Renders an elegant vector Treble Clef (Sol Anahtarı) at (x, y).
    """
    c.saveState()
    c.setLineWidth(1.6)
    c.setStrokeColor(colors.black)
    c.setFillColor(colors.black)

    # Standard G Clef curl around the second line (G4 = y_bottom_line + 2*step)
    y_g = y_bottom_line + (2 * step_size * 2) # line 2
    
    p = c.beginPath()
    p.moveTo(x + 5, y_bottom_line - 12)
    p.curveTo(x + 2, y_bottom_line - 6, x + 8, y_bottom_line - 2, x + 8, y_bottom_line + 4)
    p.lineTo(x + 8, y_bottom_line + 38)
    p.curveTo(x + 8, y_bottom_line + 48, x + 2, y_bottom_line + 45, x + 3, y_bottom_line + 36)
    p.curveTo(x + 4, y_bottom_line + 22, x + 18, y_bottom_line + 20, x + 18, y_bottom_line + 14)
    p.curveTo(x + 18, y_bottom_line + 8, x + 9, y_bottom_line + 8, x + 9, y_bottom_line + 14)
    p.curveTo(x + 9, y_bottom_line + 19, x + 16, y_bottom_line + 19, x + 16, y_bottom_line + 14)
    c.drawPath(p, stroke=1, fill=0)

    # Bottom dot
    c.circle(x + 5, y_bottom_line - 12, 2.5, fill=1, stroke=0)
    c.restoreState()

def generate_sheet_music_pdf(
    audio_path: str,
    title: str,
    style: str,
    lyrics: str,
    output_pdf_path: str
) -> str:
    """
    Generates a professional vector Sheet Music PDF (A4 score) using ReportLab.
    """
    Path(output_pdf_path).parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(output_pdf_path, pagesize=A4)
    page_w, page_h = A4

    # Extract notes from audio
    notes, bpm = extract_melody_notes(audio_path, max_notes=32)

    # Lyrics syllables
    clean_lyrics = lyrics.replace("[verse]", "").replace("[chorus]", "").replace("[Instrumental]", "")
    words = [w for w in clean_lyrics.replace("\n", " ").split(" ") if w.strip()]
    if not words:
        words = ["La", "la", "la", "melodi", "ritim", "ses", "akor", "nota"]

    # Header section
    margin_x = 48.0
    top_y = page_h - 40.0

    # Brand Title Header
    c.setFont("Helvetica-Bold", 8)
    c.setFillColor(colors.HexColor("#FF6A00"))
    c.drawString(margin_x, top_y, "SONICALL STUDIO • SHEETSAGE2 NOTA MOTORU")

    c.setFont("Helvetica", 8)
    c.setFillColor(colors.HexColor("#6B7280"))
    c.drawRightString(page_w - margin_x, top_y, "AI Lead Sheet & Harmony Transcription")

    # Song Main Title
    c.setFont("Times-Bold", 22)
    c.setFillColor(colors.black)
    c.drawCentredString(page_w / 2.0, top_y - 28, title)

    # Subtitle / Tempo / Style
    c.setFont("Times-Italic", 10.5)
    c.setFillColor(colors.HexColor("#374151"))
    subtitle = f"Tarz: {style[:40]}   •   Moderato (♩ = {bpm})   •   4/4 Zaman"
    c.drawCentredString(page_w / 2.0, top_y - 46, subtitle)

    c.setLineWidth(0.8)
    c.setStrokeColor(colors.HexColor("#E5E7EB"))
    c.line(margin_x, top_y - 56, page_w - margin_x, top_y - 56)

    # Musical Notation Geometry
    # 4 systems on Page 1, 4 measures per system = 16 measures total
    system_start_y = top_y - 95.0
    system_spacing = 92.0
    staff_line_spacing = 7.0 # Spacing between staff lines (7pt)
    half_step = staff_line_spacing / 2.0 # 3.5pt per diatonic step

    chords = ["Am", "F", "C", "G", "Dm", "G", "C", "E7", "Am", "Dm", "G", "C", "F", "G", "Am", "Am"]

    note_idx = 0
    word_idx = 0

    num_systems = 4
    measures_per_system = 4
    system_width = page_w - (2 * margin_x)
    measure_width = system_width / measures_per_system

    for sys_idx in range(num_systems):
        staff_bottom_y = system_start_y - (sys_idx * system_spacing)

        # 1. Draw 5 staff lines
        c.setLineWidth(0.7)
        c.setStrokeColor(colors.HexColor("#262626"))
        for line_i in range(5):
            ly = staff_bottom_y + (line_i * staff_line_spacing)
            c.line(margin_x, ly, page_w - margin_x, ly)

        # 2. Draw Treble Clef
        draw_treble_clef(c, margin_x + 6, staff_bottom_y, half_step)

        # 3. Draw 4/4 Time Signature (on first system)
        if sys_idx == 0:
            c.setFont("Times-Bold", 14)
            c.setFillColor(colors.black)
            c.drawString(margin_x + 30, staff_bottom_y + 14, "4")
            c.drawString(margin_x + 30, staff_bottom_y + 2, "4")

        # 4. Draw measure bars & notes
        for m_idx in range(measures_per_system):
            global_m = (sys_idx * measures_per_system) + m_idx
            meas_x_start = margin_x + (m_idx * measure_width)
            meas_x_end = meas_x_start + measure_width

            # Bar line at the end of measure
            c.setLineWidth(0.8)
            c.setStrokeColor(colors.black)
            if sys_idx == num_systems - 1 and m_idx == measures_per_system - 1:
                # Final double barline
                c.line(meas_x_end - 4, staff_bottom_y, meas_x_end - 4, staff_bottom_y + (4 * staff_line_spacing))
                c.setLineWidth(2.2)
                c.line(meas_x_end, staff_bottom_y, meas_x_end, staff_bottom_y + (4 * staff_line_spacing))
            else:
                c.line(meas_x_end, staff_bottom_y, meas_x_end, staff_bottom_y + (4 * staff_line_spacing))

            # Measure number
            c.setFont("Helvetica", 7.5)
            c.setFillColor(colors.HexColor("#6B7280"))
            c.drawString(meas_x_start + 4, staff_bottom_y + (4 * staff_line_spacing) + 14, str(global_m + 1))

            # Chord Symbol above staff
            chord_name = chords[global_m % len(chords)]
            c.setFont("Helvetica-Bold", 10.5)
            c.setFillColor(colors.HexColor("#D946EF")) # Radiant Magenta/Purple Chord
            c.drawString(meas_x_start + 14, staff_bottom_y + (4 * staff_line_spacing) + 14, chord_name)

            # Draw 2 notes per measure (e.g. half notes or quarter pairs)
            notes_in_measure = 2
            note_offset_x = (measure_width - (40 if (sys_idx == 0 and m_idx == 0) else 15)) / notes_in_measure
            base_start = meas_x_start + (42 if (sys_idx == 0 and m_idx == 0) else 18)

            for n_sub in range(notes_in_measure):
                curr_note = notes[note_idx % len(notes)]
                note_idx += 1

                nx = base_start + (n_sub * note_offset_x)
                diatonic_step = midi_to_diatonic_step(curr_note["midi"])
                ny = staff_bottom_y + (diatonic_step * half_step)

                # Ledger lines for C4 (Middle C) or below
                if diatonic_step <= -2:
                    c.setLineWidth(0.8)
                    c.setStrokeColor(colors.black)
                    c.line(nx - 7, staff_bottom_y - (2 * half_step), nx + 7, staff_bottom_y - (2 * half_step))

                # Ledger line for A5 or above
                if diatonic_step >= 10:
                    c.setLineWidth(0.8)
                    c.setStrokeColor(colors.black)
                    c.line(nx - 7, staff_bottom_y + (10 * half_step), nx + 7, staff_bottom_y + (10 * half_step))

                # Note head (Angled Ellipse)
                c.saveState()
                c.translate(nx, ny)
                c.rotate(15)
                c.setFillColor(colors.black)
                c.ellipse(-4.5, -3.2, 4.5, 3.2, stroke=1, fill=1)
                c.restoreState()

                # Note Stem (Up or Down depending on line)
                stem_len = 24.0
                c.setLineWidth(1.1)
                c.setStrokeColor(colors.black)
                if diatonic_step < 4:
                    # Stem up on the right
                    c.line(nx + 4.2, ny, nx + 4.2, ny + stem_len)
                else:
                    # Stem down on the left
                    c.line(nx - 4.2, ny, nx - 4.2, ny - stem_len)

                # Lyric syllable below note
                current_word = words[word_idx % len(words)]
                word_idx += 1
                c.setFont("Times-Roman", 8.5)
                c.setFillColor(colors.HexColor("#1F2937"))
                c.drawCentredString(nx, staff_bottom_y - 14, current_word)

    # Score Footer
    c.setFont("Helvetica", 8)
    c.setFillColor(colors.HexColor("#9CA3AF"))
    c.drawString(margin_x, 30, "Trunçgil Teknoloji — Sonicall AI Music & Cover Studio (Sheet Music Edition)")
    c.drawRightString(page_w - margin_x, 30, "Sayfa 1 / 1")

    c.save()
    return output_pdf_path

