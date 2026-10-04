# glowai_backend/app/scoring.py
from typing import Dict
from app.config import OVERALL_PENALTY_WEIGHTS
from app.schemas import ConditionsResult

def compute_overall_scoring(conditions: ConditionsResult) -> Dict[str, any]:
    """
    Computes overall skin score (0..100), overall severity, risk level, see_doctor flag,
    and recommended specialty.
    """
    acne_score = conditions.acne.score
    redness_score = conditions.redness.score
    dark_spots_score = conditions.dark_spots.score
    pigmentation_score = conditions.pigmentation.score
    texture_score = conditions.texture.score

    weighted_penalty = (
        acne_score * OVERALL_PENALTY_WEIGHTS["acne"] +
        redness_score * OVERALL_PENALTY_WEIGHTS["redness"] +
        dark_spots_score * OVERALL_PENALTY_WEIGHTS["dark_spots"] +
        pigmentation_score * OVERALL_PENALTY_WEIGHTS["pigmentation"] +
        texture_score * OVERALL_PENALTY_WEIGHTS["texture"]
    )

    overall_score = int(max(0, min(100, 100 - weighted_penalty)))

    severities = [
        conditions.acne.severity,
        conditions.redness.severity,
        conditions.dark_spots.severity,
        conditions.pigmentation.severity,
        conditions.texture.severity,
    ]

    if "Severe" in severities:
        overall_severity = "Severe"
    elif "Moderate" in severities:
        overall_severity = "Moderate"
    elif "Mild" in severities:
        overall_severity = "Mild"
    else:
        overall_severity = "None"

    # Risk assessment
    if overall_severity == "Severe" or (conditions.acne.count and conditions.acne.count > 10):
        risk = "High"
    elif overall_severity == "Moderate":
        risk = "Medium"
    else:
        risk = "Low"

    # See doctor recommendation
    see_doctor = (
        conditions.acne.severity == "Severe" or
        conditions.redness.severity == "Severe" or
        (conditions.acne.count is not None and conditions.acne.count >= 8) or
        overall_score < 50
    )

    # Specialty recommendation
    if conditions.acne.score > 50:
        recommended_specialty = "Dermatologist (Acne & Inflamed Skin Specialist)"
    elif conditions.redness.score > 50:
        recommended_specialty = "Dermatologist (Rosacea & Vascular Specialist)"
    elif conditions.dark_spots.score > 50 or conditions.pigmentation.score > 50:
        recommended_specialty = "Dermatologist (Pigmentation Specialist)"
    else:
        recommended_specialty = "General Dermatologist"

    return {
        "overall_score": overall_score,
        "severity": overall_severity,
        "risk": risk,
        "see_doctor": see_doctor,
        "recommended_specialty": recommended_specialty,
    }
