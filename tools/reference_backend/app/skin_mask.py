# glowai_backend/app/skin_mask.py
import cv2
import numpy as np

def filter_valid_skin_pixels(rgb_image: np.ndarray, region_mask: np.ndarray) -> np.ndarray:
    """
    Returns a binary mask (H, W uint8) containing valid skin pixels inside [region_mask].
    Filters out hair, shadows, and non-skin areas using YCrCb color thresholding.
    """
    ycrcb = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2YCrCb)
    cr = ycrcb[:, :, 1]
    cb = ycrcb[:, :, 2]

    # Standard YCrCb skin chrominance bounds
    skin_color_mask = (cr >= 133) & (cr <= 173) & (cb >= 77) & (cb <= 127)
    skin_color_mask = skin_color_mask.astype(np.uint8) * 255

    # Combine with region polygon
    valid_skin = cv2.bitwise_and(region_mask, skin_color_mask)
    
    # Erode slightly to remove boundary effects
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    valid_skin = cv2.erode(valid_skin, kernel, iterations=1)
    
    return valid_skin

def get_specular_highlight_mask(lab_image: np.ndarray, skin_mask: np.ndarray) -> np.ndarray:
    """
    Identifies specular highlights / oily shine patches inside valid skin pixels.
    Uses a robust, absolute-aware rule: L* >= max(median + 2.5*MAD, 68.0) and low chroma.
    """
    L = lab_image[:, :, 0]
    a = lab_image[:, :, 1]
    b = lab_image[:, :, 2]
    chroma = np.sqrt(a**2 + b**2)

    skin_pixels_L = L[skin_mask > 0]
    if skin_pixels_L.size == 0:
        return np.zeros_like(skin_mask)

    med = float(np.median(skin_pixels_L))
    mad = float(np.median(np.abs(skin_pixels_L - med)))
    l_thresh = max(med + 2.5 * mad, 68.0)
    shine_pixels = (L >= l_thresh) & (chroma < 20.0) & (skin_mask > 0)
    
    return (shine_pixels.astype(np.uint8) * 255)
