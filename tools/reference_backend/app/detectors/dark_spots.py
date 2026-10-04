# glowai_backend/app/detectors/dark_spots.py
import cv2
import numpy as np
from typing import List, Tuple
from app.config import (
    DARK_SPOT_L_DEFICIT_MARGIN,
    DARK_SPOT_MIN_DIAMETER_RATIO,
    DARK_SPOT_MAX_DIAMETER_RATIO,
    DARK_SPOT_MIN_CIRCULARITY,
    DARK_SPOT_MAX_RED_EXCESS,
)
from app.schemas import ConditionResult

def detect_dark_spots(
    lab_image: np.ndarray,
    region_masks: dict,
    face_width: float,
    quality_score: float
) -> Tuple[ConditionResult, List[Tuple[int, int, int, int]]]:
    """
    Detects hyperpigmented dark spots (post-acne marks, sun spots).
    Finds blobs significantly darker in L* than local background that are NOT red inflamed.
    """
    combined_mask = np.zeros(lab_image.shape[:2], dtype=np.uint8)
    for k in ["forehead", "left_cheek", "right_cheek", "chin"]:
        if k in region_masks:
            combined_mask |= region_masks[k]

    L_chan = lab_image[:, :, 0]
    a_chan = lab_image[:, :, 1]
    if face_width <= 0:
        return ConditionResult(score=0, count=0, severity="None", confidence=0.5), []

    blur_kernel_size = int(face_width * 0.15) | 1
    bg_L = cv2.GaussianBlur(L_chan, (blur_kernel_size, blur_kernel_size), 0)
    deficit_L = bg_L - L_chan

    # Also compute local a* excess to exclude red pimples
    bg_a = cv2.GaussianBlur(a_chan, (blur_kernel_size, blur_kernel_size), 0)
    excess_a = a_chan - bg_a

    thresh_mask = (deficit_L > DARK_SPOT_L_DEFICIT_MARGIN) & (excess_a < DARK_SPOT_MAX_RED_EXCESS) & (combined_mask > 0)
    thresh_mask = (thresh_mask.astype(np.uint8) * 255)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    opened = cv2.morphologyEx(thresh_mask, cv2.MORPH_OPEN, kernel)

    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(opened)

    min_dia = face_width * DARK_SPOT_MIN_DIAMETER_RATIO
    max_dia = face_width * DARK_SPOT_MAX_DIAMETER_RATIO
    min_area = np.pi * (min_dia / 2.0) ** 2
    max_area = np.pi * (max_dia / 2.0) ** 2

    bboxes = []
    for i in range(1, num_labels):
        area = stats[i, cv2.CC_STAT_AREA]
        if min_area <= area <= max_area:
            x = stats[i, cv2.CC_STAT_LEFT]
            y = stats[i, cv2.CC_STAT_TOP]
            w = stats[i, cv2.CC_STAT_WIDTH]
            h = stats[i, cv2.CC_STAT_HEIGHT]

            contour_mask = (labels == i).astype(np.uint8) * 255
            contours, _ = cv2.findContours(contour_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            if contours:
                perimeter = cv2.arcLength(contours[0], True)
                if perimeter > 0:
                    circularity = (4.0 * np.pi * area) / (perimeter ** 2)
                    if circularity >= DARK_SPOT_MIN_CIRCULARITY:
                        bboxes.append((x, y, w, h))

    count = len(bboxes)
    score = int(min(100, count * 6 + (count ** 1.1)))

    if score < 15:
        severity = "None"
    elif score < 35:
        severity = "Mild"
    elif score < 65:
        severity = "Moderate"
    else:
        severity = "Severe"

    confidence = round(min(0.95, (quality_score / 100.0) * 0.85 + 0.10), 2)
    return ConditionResult(score=score, count=count, severity=severity, confidence=confidence), bboxes
