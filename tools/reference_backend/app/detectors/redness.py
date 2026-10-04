# glowai_backend/app/detectors/redness.py
import numpy as np
from app.config import REDNESS_A_STAR_EXCESS_MARGIN
from app.schemas import ConditionResult

def detect_redness(lab_image: np.ndarray, region_masks: dict, quality_score: float) -> ConditionResult:
    """
    Measures facial redness relative to the person's baseline median a*.
    """
    cheek_nose_mask = np.zeros(lab_image.shape[:2], dtype=np.uint8)
    for k in ["left_cheek", "right_cheek", "nose"]:
        if k in region_masks:
            cheek_nose_mask |= region_masks[k]

    a_chan = lab_image[:, :, 1]
    valid_a = a_chan[cheek_nose_mask > 0]
    if valid_a.size == 0:
        return ConditionResult(score=0, severity="None", confidence=0.5)

    baseline_a = float(np.median(valid_a))
    threshold_a = baseline_a + REDNESS_A_STAR_EXCESS_MARGIN

    red_pixels = (a_chan > threshold_a) & (cheek_nose_mask > 0)
    red_count = np.sum(red_pixels)
    total_count = float(valid_a.size)

    area_ratio = float(red_count) / max(1.0, total_count)
    excess_a = float(np.mean(a_chan[red_pixels] - baseline_a)) if red_count > 0 else 0.0

    # Composite score 0..100
    score = int(min(100, (area_ratio * 300.0) + (excess_a * 8.0)))

    if score < 15:
        severity = "None"
    elif score < 35:
        severity = "Mild"
    elif score < 65:
        severity = "Moderate"
    else:
        severity = "Severe"

    confidence = round(min(0.95, (quality_score / 100.0) * 0.85 + 0.10), 2)
    return ConditionResult(score=score, severity=severity, confidence=confidence)
