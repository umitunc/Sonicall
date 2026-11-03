# Sonicall: AI Music & Cover Studio
**Şirket:** Trunçgil Teknoloji  
**Motor:** YuE2 (3B INT8 ConvRot / BF16) & SheetSage2  
**Platform:** Windows Desktop & Web  

---

## 🎵 Genel Bakış

**Sonicall**, yerel GPU gücünüzü kullanarak Suno ve Udio kalitesinde tam uzunlukta şarkılar ve cover parçalar üretmenizi sağlayan masaüstü AI ses iş istasyonudur.

- **3 Panelli Suno Deneyimi:** Sol Menü (Sidebar), Orta Stüdyo (Lyrics, Style, +Audio Cover), Sağ Çalışma Alanı (Kütüphane & Geçmiş) ve Altta Sabit Oynatıcı.
- **Şarkı Cover Modu:** `SheetSage2` ile referans ses dosyasından vokal ve melodi konturlarını çıkararak YuE2 ile yeni vokal tarzında cover üretme.
- **BYOM (Kendi Modelini Getir):** `D:\Works\2026\AI FILMMAKING\ComfyUI\models` klasörünü otomatik olarak bağlar. Kurulum paketine devasa model ağırlıkları dahil edilmez; Microsoft Store uyumludur.
- **Karanlık & Aydınlık Tema:** Suno stüdyo karanlık modu (`#0E0E10`) ve modern aydınlık tema.

---

## 🚀 Hızlı Başlangıç

### Tek Tıkla Başlatma:
Proje ana dizinindeki `run_sonicall.bat` dosyasını çalıştırın. Bu komut:
1. Python FastAPI yerel motorunu arka planda başlatır (`http://127.0.0.1:5824`).
2. Flutter Masaüstü uygulamasını açar.

### Manuel Başlatma:

#### 1. Backend:
```bash
python backend/server.py
```

#### 2. Frontend (Flutter Desktop):
```bash
flutter run -d windows
```
veya Web için:
```bash
flutter run -d chrome
```

---

## 🏗️ Proje Yapısı

```text
Sonicall/
├── docs/                      # Mimari ve plan dokümantasyonu
│   └── implementation-plan.md
├── backend/                   # Python FastAPI & YuE2 / SheetSage2 Motoru
│   ├── server.py              # REST & WebSocket API (Port 5824)
│   ├── config.py              # Dizin ve ComfyUI model yolları
│   ├── model_manager.py       # Checkpoint ve audio encoder tarayıcısı
│   ├── yue2_adapter.py        # Şarkı ve Cover sentezi motoru
│   └── requirements.txt
├── lib/                       # Flutter İstemcisi
│   ├── main.dart              # Masaüstü pencere ve uygulama başlatıcı
│   ├── core/theme/            # Dark & Light Suno temaları
│   ├── models/                # Song, ModelInfo, Progress veri modelleri
│   ├── services/              # ApiService & AudioPlayerService
│   ├── providers/             # AppStateProvider
│   └── ui/
│       ├── shell/             # 3 Panelli Ana Kabuk
│       ├── sidebar/           # Sol Gezinme ve GPU/Model durum paneli
│       ├── studio/            # Orta Üretim Stüdyosu (+Audio Cover, Lyrics, Style)
│       ├── workspace/         # Sağ Şarkı Listesi & Filtreler
│       ├── player/            # Alt Sabit Müzik Çalar
│       └── dialogs/           # Model Hub, Ayarlar ve Şarkı Sözleri Modalı
└── run_sonicall.bat           # Çift tıklamalı başlatıcı
```
