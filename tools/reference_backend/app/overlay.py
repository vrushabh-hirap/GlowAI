# glowai_backend/app/overlay.py
import base64
import cv2
import numpy as np
from typing import List, Tuple, Dict
from app.schemas import OverlayResult

def generate_overlays(
    rgb_image: np.ndarray,
    lab_image: np.ndarray,
    region_masks: Dict[str, np.ndarray],
    acne_bboxes: List[Tuple[int, int, int, int]],
    dark_spot_bboxes: List[Tuple[int, int, int, int]]
) -> OverlayResult:
    """
    Renders 4 separate base64 JPEG overlay images (regions, blemishes, dark spots, redness).
    """
    h, w, _ = rgb_image.shape

    def to_b64(img_bgr: np.ndarray) -> str:
        # Downscale max side to 800px for light base64 response
        max_side = 800
        if max(h, w) > max_side:
            scale = max_side / float(max(h, w))
            img_bgr = cv2.resize(img_bgr, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA)
        _, buffer = cv2.imencode('.jpg', img_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), 85])
        return base64.b64encode(buffer).decode('utf-8')

    bgr = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2BGR)

    # 1. Regions Overlay (Outlines around forehead, nose, cheeks, chin)
    regions_img = bgr.copy()
    colors = {
        "forehead": (255, 200, 100),
        "nose": (100, 255, 200),
        "left_cheek": (200, 100, 255),
        "right_cheek": (200, 100, 255),
        "chin": (255, 100, 200),
    }
    for name, mask in region_masks.items():
        if name in colors and np.sum(mask > 0) > 0:
            contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            cv2.drawContours(regions_img, contours, -1, colors[name], 2)

    # 2. Blemishes / Acne Overlay (Pink/red circles)
    blemishes_img = bgr.copy()
    for (x, y, bw, bh) in acne_bboxes:
        cx = x + bw // 2
        cy = y + bh // 2
        radius = max(bw, bh) // 2 + 3
        cv2.circle(blemishes_img, (cx, cy), radius, (50, 50, 255), 2)
        cv2.circle(blemishes_img, (cx, cy), 2, (0, 0, 255), -1)

    # 3. Dark Spots Overlay (Amber/blue circles)
    dark_spots_img = bgr.copy()
    for (x, y, bw, bh) in dark_spot_bboxes:
        cx = x + bw // 2
        cy = y + bh // 2
        radius = max(bw, bh) // 2 + 3
        cv2.circle(dark_spots_img, (cx, cy), radius, (0, 165, 255), 2)
        cv2.circle(dark_spots_img, (cx, cy), 2, (0, 140, 255), -1)

    # 4. Redness Heatmap Overlay
    redness_img = bgr.copy()
    a_chan = lab_image[:, :, 1]
    a_norm = cv2.normalize(a_chan, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
    heatmap = cv2.applyColorMap(a_norm, cv2.COLORMAP_JET)
    
    # Overlay heatmap only on skin areas
    cheek_nose_mask = np.zeros((h, w), dtype=np.uint8)
    for k in ["left_cheek", "right_cheek", "nose"]:
        if k in region_masks:
            cheek_nose_mask |= region_masks[k]

    mask_3ch = cv2.merge([cheek_nose_mask, cheek_nose_mask, cheek_nose_mask]) > 0
    blended = cv2.addWeighted(bgr, 0.6, heatmap, 0.4, 0)
    redness_img = np.where(mask_3ch, blended, bgr)

    return OverlayResult(
        regions_jpeg_base64=to_b64(regions_img),
        blemishes_jpeg_base64=to_b64(blemishes_img),
        dark_spots_jpeg_base64=to_b64(dark_spots_img),
        redness_jpeg_base64=to_b64(redness_img)
    )
