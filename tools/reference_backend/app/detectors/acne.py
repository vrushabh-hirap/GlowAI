# glowai_backend/app/detectors/acne.py
import cv2
import numpy as np
from typing import List, Tuple, Dict, Any
from app.config import (
    ACNE_A_STAR_EXCESS_MARGIN,
    ACNE_MIN_DIAMETER_RATIO,
    ACNE_MAX_DIAMETER_RATIO,
    ACNE_MIN_CIRCULARITY,
    ACNE_MIN_CONTRAST,
)
from app.schemas import ConditionResult

class BaseAcneDetector:
    """Pluggable base interface for acne lesion detection."""
    def detect(
        self,
        rgb_image: np.ndarray,
        lab_image: np.ndarray,
        region_masks: Dict[str, np.ndarray],
        face_width: float,
        quality_score: float
    ) -> Tuple[ConditionResult, List[Tuple[int, int, int, int]]]:
        raise NotImplementedError

class ClassicalAcneDetector(BaseAcneDetector):
    def detect(
        self,
        rgb_image: np.ndarray,
        lab_image: np.ndarray,
        region_masks: Dict[str, np.ndarray],
        face_width: float,
        quality_score: float
    ) -> Tuple[ConditionResult, List[Tuple[int, int, int, int]]]:
        """
        Classical CV detector for red inflamed lesions.
        Subtracts local Gaussian background from a* channel, thresholds, runs connected components,
        filters by lesion size, circularity, and contrast.
        """
        combined_mask = np.zeros(rgb_image.shape[:2], dtype=np.uint8)
        for k in ["forehead", "nose", "left_cheek", "right_cheek", "chin"]:
            if k in region_masks:
                combined_mask |= region_masks[k]

        a_chan = lab_image[:, :, 1]
        valid_a = a_chan[combined_mask > 0]
        if valid_a.size == 0 or face_width <= 0:
            return ConditionResult(score=0, count=0, severity="None", confidence=0.5), []

        # Local background subtraction
        blur_kernel_size = int(face_width * 0.15) | 1  # ensure odd
        bg_a = cv2.GaussianBlur(a_chan, (blur_kernel_size, blur_kernel_size), 0)
        excess_a = a_chan - bg_a

        # Thresholding
        thresh_mask = (excess_a > ACNE_MIN_CONTRAST) & (combined_mask > 0)
        thresh_mask = (thresh_mask.astype(np.uint8) * 255)

        # Morphology open to separate close blobs
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        opened = cv2.morphologyEx(thresh_mask, cv2.MORPH_OPEN, kernel)

        num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(opened)

        min_dia = face_width * ACNE_MIN_DIAMETER_RATIO
        max_dia = face_width * ACNE_MAX_DIAMETER_RATIO
        min_area = np.pi * (min_dia / 2.0) ** 2
        max_area = np.pi * (max_dia / 2.0) ** 2

        bboxes = []

        for i in range(1, num_labels):
            area = stats[i, cv2.CC_STAT_AREA]
            if min_area <= area <= max_area:
                x = stats[i, cv2.CC_STAT_WALK_LEFT if hasattr(cv2, 'CC_STAT_WALK_LEFT') else cv2.CC_STAT_LEFT]
                y = stats[i, cv2.CC_STAT_TOP]
                w = stats[i, cv2.CC_STAT_WIDTH]
                h = stats[i, cv2.CC_STAT_HEIGHT]

                # Circularity check
                contour_mask = (labels == i).astype(np.uint8) * 255
                contours, _ = cv2.findContours(contour_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                if contours:
                    perimeter = cv2.arcLength(contours[0], True)
                    if perimeter > 0:
                        circularity = (4.0 * np.pi * area) / (perimeter ** 2)
                        if circularity >= ACNE_MIN_CIRCULARITY:
                            bboxes.append((x, y, w, h))

        count = len(bboxes)
        score = int(min(100, count * 7 + (count ** 1.2)))

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

# Default instance
_acne_detector_instance = ClassicalAcneDetector()

def get_acne_detector() -> BaseAcneDetector:
    return _acne_detector_instance
