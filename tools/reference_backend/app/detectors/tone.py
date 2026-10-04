# glowai_backend/app/detectors/tone.py
import math
import numpy as np
from app.config import ITA_BOUNDARIES, UNDERTONE_HUE_WARM_MIN, UNDERTONE_HUE_WARM_MAX
from app.imaging import lab_to_srgb_hex
from app.schemas import SkinToneResult

def detect_skin_tone(lab_image: np.ndarray, cheek_mask: np.ndarray, quality_score: float) -> SkinToneResult:
    """
    Computes Individual Typology Angle (ITA) from median L* and b* of cheek skin.
    ITA = arctan((L* - 50) / b*) * (180 / pi)
    """
    valid_pixels = lab_image[cheek_mask > 0]
    if valid_pixels.size == 0:
        return SkinToneResult(
            level=3,
            label="Intermediate",
            ita_degrees=35.0,
            undertone="Neutral",
            hex="#d2a685",
            confidence=0.5
        )

    median_L = float(np.median(valid_pixels[:, 0]))
    median_a = float(np.median(valid_pixels[:, 1]))
    median_b = float(np.median(valid_pixels[:, 2]))

    # ITA formula
    ita = math.atan2((median_L - 50.0), max(0.1, median_b)) * (180.0 / math.pi)

    # Classification
    if ita > ITA_BOUNDARIES["Very Light"]:
        level = 1
        label = "Very Light"
    elif ita > ITA_BOUNDARIES["Light"]:
        level = 2
        label = "Light"
    elif ita > ITA_BOUNDARIES["Intermediate"]:
        level = 3
        label = "Intermediate"
    elif ita > ITA_BOUNDARIES["Tan"]:
        level = 4
        label = "Tan"
    elif ita > ITA_BOUNDARIES["Brown"]:
        level = 5
        label = "Brown"
    else:
        level = 6
        label = "Deep"

    # Undertone based on hue angle in CIELAB space: atan2(b*, a*) in degrees
    hue_deg = math.atan2(median_b, median_a) * (180.0 / math.pi)
    if hue_deg < 0:
        hue_deg += 360.0

    if UNDERTONE_HUE_WARM_MIN <= hue_deg <= UNDERTONE_HUE_WARM_MAX:
        undertone = "Warm"
    elif hue_deg > UNDERTONE_HUE_WARM_MAX and hue_deg <= 90.0:
        undertone = "Neutral"
    else:
        undertone = "Cool"

    hex_color = lab_to_srgb_hex(median_L, median_a, median_b)
    confidence = round(min(0.95, (quality_score / 100.0) * 0.90 + 0.10), 2)

    return SkinToneResult(
        level=level,
        label=label,
        ita_degrees=round(ita, 1),
        undertone=undertone,
        hex=hex_color,
        confidence=confidence
    )
