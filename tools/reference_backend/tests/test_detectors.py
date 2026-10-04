# glowai_backend/tests/test_detectors.py
import cv2
import numpy as np
from app.imaging import rgb_to_lab
from app.detectors.tone import detect_skin_tone
from app.detectors.redness import detect_redness
from app.detectors.acne import get_acne_detector
from app.detectors.dark_spots import detect_dark_spots

def test_skin_tone_detector_synthetic():
    # Intermediate skin color canvas (R=210, G=165, B=130)
    canvas = np.full((300, 300, 3), (210, 165, 130), dtype=np.uint8)
    lab = rgb_to_lab(canvas)
    mask = np.full((300, 300), 255, dtype=np.uint8)
    
    tone = detect_skin_tone(lab, mask, 95.0)
    assert 1 <= tone.level <= 6
    assert tone.hex.startswith("#")
    assert tone.confidence > 0.70

def test_acne_detector_synthetic():
    # Skin background with 3 distinct red spots
    canvas = np.full((400, 400, 3), (210, 165, 130), dtype=np.uint8)
    # Add 3 red inflamed spots (diameter ~15px)
    cv2.circle(canvas, (100, 100), 7, (255, 40, 40), -1)
    cv2.circle(canvas, (200, 150), 8, (255, 30, 30), -1)
    cv2.circle(canvas, (250, 250), 6, (255, 50, 50), -1)

    lab = rgb_to_lab(canvas)
    region_masks = {"left_cheek": np.full((400, 400), 255, dtype=np.uint8)}

    acne_detector = get_acne_detector()
    result, bboxes = acne_detector.detect(canvas, lab, region_masks, face_width=200.0, quality_score=95.0)

    assert result.count >= 2
    assert len(bboxes) >= 2
    assert result.score > 0

def test_dark_spots_detector_synthetic():
    canvas = np.full((400, 400, 3), (210, 165, 130), dtype=np.uint8)
    # Add 2 dark brown spots
    cv2.circle(canvas, (120, 120), 6, (90, 50, 30), -1)
    cv2.circle(canvas, (220, 220), 7, (80, 40, 20), -1)

    lab = rgb_to_lab(canvas)
    region_masks = {"left_cheek": np.full((400, 400), 255, dtype=np.uint8)}

    result, bboxes = detect_dark_spots(lab, region_masks, face_width=200.0, quality_score=95.0)
    assert result.count >= 2
    assert len(bboxes) >= 2
