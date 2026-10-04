# GlowAI Real Skin Analysis Backend

FastAPI Python backend for **GlowAI**. Performs classical computer vision and color science analysis on facial photographs with MediaPipe, OpenCV, scikit-image, and NumPy.

## Architectural Goal & Zero Dummy Data Rule

This service contains **zero mock, random, or hardcoded scan numbers**. Every returned score, condition count, skin tone ITA angle, and insight is deterministically measured from the uploaded photograph.

## Quick Start

### 1. Environment Setup

```bash
cd glowai_backend
python3 -m venv venv
source venv/bin/activate    # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Download MediaPipe Models

```bash
python scripts/download_models.py
```
This downloads `face_landmarker.task` into `models/`.

### 3. Run the Server

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
- **Android Emulator**: Set Flutter app endpoint to `http://10.0.2.2:8000`
- **Real Phone on Wi-Fi**: Set Flutter app endpoint to `http://<YOUR_PC_LAN_IP>:8000`

### 4. Run Automated Tests

```bash
pytest
```

### 5. CLI Visual Tuning Tool

Run analysis on a local image to save overlay images (`cli_output/`) and print JSON metrics for visual tuning:

```bash
python tools/analyze_cli.py path/to/sample_face.jpg
```

---

## API Contract Summary

### `GET /health`
Returns `{ "status": "ok", "analysis_version": "1.0.0" }`.

### `POST /analyze`
Accepts multipart form:
- `image`: File (JPEG, PNG, WebP)
- `minutes_since_wash`: Optional integer
- `prepared`: boolean (`true`/`false`)

Returns JSON containing quality gate results, prep details, measured skin type, ITA skin tone, 5 condition indices (acne, redness, dark spots, pigmentation, texture), overall health score, 4 base64 overlay JPEGs, plain-language insights, and a medical disclaimer.

---

## Privacy Architecture

- Photos are processed **strictly in memory**.
- Photos are never written to disk, stored in database, or logged.
- Overlays are returned directly in the response payload.

---

## Honest Limitations

- This is an **informational screening estimate**, not a medical diagnosis.
- Analysis accuracy depends on photo lighting, camera quality, head angle, and skin prep.
- Beards, heavy makeup, filters, glasses, and strong shadows reduce measurement precision.
- Classical CV detects red inflamed spots and hyperpigmented marks; it cannot distinguish between complex dermatological conditions (e.g. cysts vs papules vs folliculitis).
