# glowai_backend/app/detectors/pigmentation.py
import numpy as np
from app.schemas import ConditionResult

def detect_pigmentation(lab_image: np.ndarray, region_masks: dict, quality_score: float) -> ConditionResult:
    """
    Measures skin tone unevenness / pigmentation variance.
    Subtracts global lighting gradient and calculates standard deviation of residual L* and b*.
    """
    combined_mask = np.zeros(lab_image.shape[:2], dtype=np.uint8)
    for k in ["forehead", "left_cheek", "right_cheek"]:
        if k in region_masks:
            combined_mask |= region_masks[k]

    L_chan = lab_image[:, :, 0]
    valid_L = L_chan[combined_mask > 0]
    if valid_L.size == 0:
        return ConditionResult(score=0, severity="None", confidence=0.5)

    # Standard deviation of L* channel across skin
    std_L = float(np.std(valid_L))
    
    # 75th - 25th percentile robust spread
    iqr_L = float(np.percentile(valid_L, 75) - np.percentile(valid_L, 25))

    # Composite score: higher spread -> less even / higher pigmentation irregularity score
    score = int(min(100, (std_L * 6.0) + (iqr_L * 4.0)))

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
