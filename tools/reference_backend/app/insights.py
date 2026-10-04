# glowai_backend/app/insights.py
from typing import List
from app.schemas import SkinTypeResult, SkinToneResult, ConditionsResult, QualityResult, PrepResult

def generate_insights(
    skin_type: SkinTypeResult,
    skin_tone: SkinToneResult,
    conditions: ConditionsResult,
    quality: QualityResult,
    prep: PrepResult,
    overall_score: int
) -> List[str]:
    insights = []

    # 1. Skin Type & Shine Insight
    if skin_type.label == "Combination":
        insights.append(
            f"Your T-zone shows noticeably higher shine ({int(skin_type.metrics.tzone_shine*100)}%) than your cheeks "
            f"({int(skin_type.metrics.cheek_shine*100)}%), pointing to a classic combination skin pattern."
        )
    elif skin_type.label == "Oily":
        insights.append(
            f"High shine readings across both your T-zone ({int(skin_type.metrics.tzone_shine*100)}%) and cheeks "
            f"({int(skin_type.metrics.cheek_shine*100)}%) indicate active sebum production."
        )
    elif skin_type.label == "Dry":
        insights.append(
            "Low surface shine paired with micro-texture roughness suggests a dry or moisture-depleted skin barrier."
        )
    else:
        insights.append(
            "Balanced shine levels between your T-zone and cheeks indicate normal, well-hydrated skin."
        )

    # 2. Skin Tone Insight
    insights.append(
        f"Measured skin tone is Type {skin_tone.level} ({skin_tone.label}) with a {skin_tone.undertone.lower()} undertone "
        f"(ITA = {skin_tone.ita_degrees}°)."
    )

    # 3. Acne & Inflamed Lesion Insight
    acne = conditions.acne
    if acne.count and acne.count > 0:
        insights.append(
            f"Identified {acne.count} inflamed lesion{'' if acne.count == 1 else 's'} with {acne.severity.lower()} severity."
        )
    else:
        insights.append("No active inflamed acne lesions were detected in the analyzed regions.")

    # 4. Redness Insight
    redness = conditions.redness
    if redness.score > 25:
        insights.append(
            f"Facial redness index is {redness.score}/100 ({redness.severity.lower()}), indicating localized vascular sensitivity."
        )

    # 5. Dark Spots Insight
    dark_spots = conditions.dark_spots
    if dark_spots.count and dark_spots.count > 0:
        insights.append(
            f"Found {dark_spots.count} hyperpigmented mark{'' if dark_spots.count == 1 else 's'} across the cheeks and forehead."
        )

    # 6. Overall Summary
    insights.append(
        f"Overall skin health score is {overall_score}/100 based on composite screening parameters."
    )

    # Prep / Quality Caveats
    if not prep.prepared:
        insights.append(
            "Note: Scan was conducted before the 30-minute post-wash wait, so oil and skin-type confidence is reduced."
        )

    if quality.score < 80:
        insights.append(
            "Note: Image lighting or sharpness was non-ideal, which may slightly reduce measurement precision."
        )

    return insights
