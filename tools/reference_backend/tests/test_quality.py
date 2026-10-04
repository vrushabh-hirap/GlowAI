# glowai_backend/tests/test_quality.py
import numpy as np
from app.quality import check_image_quality
from app.imaging import rgb_to_lab

def test_no_face_quality_check():
    rgb = np.zeros((400, 400, 3), dtype=np.uint8)
    lab = rgb_to_lab(rgb)
    result = check_image_quality(rgb, lab, 0, [], (0.0, 0.0, 0.0))
    assert not result.ok
    assert result.score == 0
    assert any("No face detected" in issue for issue in result.issues)

def test_dark_image_quality_check():
    rgb = np.full((400, 400, 3), 10, dtype=np.uint8)
    lab = rgb_to_lab(rgb)
    # Mock face landmarks spanning 200px (50% face height ratio)
    landmarks = [(100, 100) for _ in range(468)]
    landmarks[10] = (200, 100)
    landmarks[152] = (200, 300)
    
    result = check_image_quality(rgb, lab, 1, landmarks, (0.0, 0.0, 0.0))
    assert not result.ok
    assert any("too dark" in issue.lower() for issue in result.issues)

def test_tilted_pose_quality_check():
    rgb = np.full((400, 400, 3), 150, dtype=np.uint8)
    lab = rgb_to_lab(rgb)
    landmarks = [(100, 100) for _ in range(468)]
    landmarks[10] = (200, 100)
    landmarks[152] = (200, 300)
    
    # 25 degree yaw angle
    result = check_image_quality(rgb, lab, 1, landmarks, (25.0, 0.0, 0.0))
    assert not result.ok
    assert any("tilted" in issue.lower() for issue in result.issues)
