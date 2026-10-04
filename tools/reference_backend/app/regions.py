# glowai_backend/app/regions.py
import cv2
import numpy as np
from typing import Dict, List, Tuple

# MediaPipe 468 landmark index groups
FOREHEAD_INDICES = [10, 338, 297, 332, 284, 251, 21, 54, 103, 67, 109]
NOSE_INDICES = [168, 6, 197, 195, 5, 4, 1, 19, 94, 2, 98, 327]
LEFT_CHEEK_INDICES = [116, 123, 147, 213, 192, 214, 207, 205, 50, 117, 118, 101, 36, 203, 206]
RIGHT_CHEEK_INDICES = [345, 352, 376, 433, 416, 434, 427, 425, 280, 346, 347, 330, 266, 423, 426]
CHIN_INDICES = [152, 377, 400, 378, 379, 365, 140, 150, 136, 172, 58, 132]

LEFT_EYE_EXCLUSION = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
RIGHT_EYE_EXCLUSION = [362, 382, 381, 380, 374, 373, 390, 249, 263, 466, 388, 387, 386, 385, 384, 398]
LIPS_EXCLUSION = [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95]

def get_region_polygons(landmarks: List[Tuple[int, int]], img_shape: Tuple[int, int]) -> Dict[str, np.ndarray]:
    """
    Constructs binary masks (H, W uint8: 255 for region, 0 elsewhere) for face regions.
    """
    h, w = img_shape[:2]
    masks = {}

    def poly_mask(indices: List[int]) -> np.ndarray:
        mask = np.zeros((h, w), dtype=np.uint8)
        pts = np.array([landmarks[idx] for idx in indices if idx < len(landmarks)], dtype=np.int32)
        if len(pts) >= 3:
            hull = cv2.convexHull(pts)
            cv2.fillConvexPoly(mask, hull, 255)
        return mask

    # Base region masks
    masks['forehead'] = poly_mask(FOREHEAD_INDICES)
    masks['nose'] = poly_mask(NOSE_INDICES)
    masks['left_cheek'] = poly_mask(LEFT_CHEEK_INDICES)
    masks['right_cheek'] = poly_mask(RIGHT_CHEEK_INDICES)
    masks['chin'] = poly_mask(CHIN_INDICES)

    # Exclusions
    left_eye_mask = poly_mask(LEFT_EYE_EXCLUSION)
    right_eye_mask = poly_mask(RIGHT_EYE_EXCLUSION)
    lips_mask = poly_mask(LIPS_EXCLUSION)

    # Erode exclusions slightly for safety margin
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    exclusions = cv2.bitwise_or(left_eye_mask, right_eye_mask)
    exclusions = cv2.bitwise_or(exclusions, lips_mask)
    exclusions = cv2.dilate(exclusions, kernel, iterations=2)

    # Apply exclusions to all regions
    for name in masks:
        masks[name] = cv2.bitwise_and(masks[name], cv2.bitwise_not(exclusions))

    # T-Zone = forehead | nose | chin
    masks['t_zone'] = cv2.bitwise_or(masks['forehead'], masks['nose'])
    masks['t_zone'] = cv2.bitwise_or(masks['t_zone'], masks['chin'])

    # Cheeks combined
    masks['cheeks'] = cv2.bitwise_or(masks['left_cheek'], masks['right_cheek'])

    return masks

def get_region_coordinates(landmarks: List[Tuple[int, int]]) -> Dict[str, Dict[str, List[int]]]:
    """
    Returns polygon bounding box coordinate dicts for API response JSON.
    """
    coords = {}
    regions_idx = {
        "forehead": FOREHEAD_INDICES,
        "nose": NOSE_INDICES,
        "left_cheek": LEFT_CHEEK_INDICES,
        "right_cheek": RIGHT_CHEEK_INDICES,
        "chin": CHIN_INDICES,
    }
    for name, indices in regions_idx.items():
        pts = [landmarks[idx] for idx in indices if idx < len(landmarks)]
        if pts:
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            coords[name] = {"bbox": [min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys)]}
        else:
            coords[name] = {"bbox": [0, 0, 0, 0]}
    return coords
