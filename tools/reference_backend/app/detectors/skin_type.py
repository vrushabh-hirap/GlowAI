# glowai_backend/app/detectors/skin_type.py
import numpy as np
from app.skin_mask import get_specular_highlight_mask
from app.schemas import SkinTypeResult, SkinTypeMetrics

def detect_skin_type(
    lab_image: np.ndarray,
    region_masks: dict,
    texture_roughness: float,
    prepared: bool,
    quality_score: float
) -> SkinTypeResult:
    """
    Measures shine ratio (specular highlights / valid region pixels) in T-zone vs Cheeks.
    """
    t_mask = region_masks.get("t_zone", np.zeros(lab_image.shape[:2], dtype=np.uint8))
    c_mask = region_masks.get("cheeks", np.zeros(lab_image.shape[:2], dtype=np.uint8))

    t_shine_mask = get_specular_highlight_mask(lab_image, t_mask)
    c_shine_mask = get_specular_highlight_mask(lab_image, c_mask)

    t_total = float(np.sum(t_mask > 0))
    c_total = float(np.sum(c_mask > 0))

    t_shine_ratio = float(np.sum(t_shine_mask > 0)) / max(1.0, t_total)
    c_shine_ratio = float(np.sum(c_shine_mask > 0)) / max(1.0, c_total)

    # Decision tree
    if t_shine_ratio > 0.12 and c_shine_ratio > 0.10:
        label = "Oily"
    elif t_shine_ratio > 0.08 and c_shine_ratio <= 0.08:
        label = "Combination"
    elif t_shine_ratio <= 0.05 and c_shine_ratio <= 0.05 and texture_roughness > 20.0:
        label = "Dry"
    else:
        label = "Normal"

    # Base confidence
    confidence = (quality_score / 100.0) * 0.85
    if not prepared:
        confidence *= 0.70  # Cap confidence if non-prepared 30min wash

    return SkinTypeResult(
        label=label,
        confidence=round(confidence, 2),
        metrics=SkinTypeMetrics(
            tzone_shine=round(t_shine_ratio, 3),
            cheek_shine=round(c_shine_ratio, 3)
        )
    )
