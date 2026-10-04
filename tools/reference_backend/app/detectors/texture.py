# glowai_backend/app/detectors/texture.py
import cv2
import numpy as np
from app.config import TEXTURE_DOG_SIGMA1, TEXTURE_DOG_SIGMA2
from app.schemas import ConditionResult

def detect_texture(lab_image: np.ndarray, region_masks: dict, quality_score: float) -> ConditionResult:
    """
    Measures skin texture roughness / pores / fine lines using Difference of Gaussians (DoG).
    """
    combined_mask = np.zeros(lab_image.shape[:2], dtype=np.uint8)
    for k in ["forehead", "left_cheek", "right_cheek", "chin"]:
        if k in region_masks:
            combined_mask |= region_masks[k]

    L_chan = lab_image[:, :, 0]
    if np.sum(combined_mask > 0) == 0:
        return ConditionResult(score=0, severity="None", confidence=0.5)

    g1 = cv2.GaussianBlur(L_chan, (0, 0), TEXTURE_DOG_SIGMA1)
    g2 = cv2.GaussianBlur(L_chan, (0, 0), TEXTURE_DOG_SIGMA2)
    dog = np.abs(g1 - g2)

    valid_dog = dog[combined_mask > 0]
    energy = float(np.mean(valid_dog))

    score = int(min(100, energy * 25.0))

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
