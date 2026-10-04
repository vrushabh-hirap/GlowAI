# glowai_backend/app/imaging.py
import io
import numpy as np
from PIL import Image, ImageOps
from skimage.color import rgb2lab, lab2rgb
from app.config import MAX_IMAGE_SIDE

def decode_and_normalize(image_bytes: bytes) -> np.ndarray:
    """
    Decodes raw image bytes, bakes EXIF rotation, downscales if necessary,
    and returns an RGB uint8 numpy array (H, W, 3).
    """
    img = Image.open(io.BytesIO(image_bytes))
    img = ImageOps.exif_transpose(img)
    img = img.convert("RGB")
    
    w, h = img.size
    max_side = MAX_IMAGE_SIDE
    if w > max_side or h > max_side:
        if w >= h:
            new_w = max_side
            new_h = int(h * (max_side / w))
        else:
            new_h = max_side
            new_w = int(w * (max_side / h))
        img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
    return np.array(img, dtype=np.uint8)

def rgb_to_lab(rgb_image: np.ndarray) -> np.ndarray:
    """
    Converts RGB uint8 array (0..255) to float CIELAB (L*: 0..100, a*: -128..127, b*: -128..127).
    Uses scikit-image's standard rgb2lab for precise color science.
    """
    rgb_normalized = rgb_image.astype(np.float64) / 255.0
    return rgb2lab(rgb_normalized)

def lab_to_srgb_hex(l: float, a: float, b: float) -> str:
    """
    Converts a single CIELAB tuple back to sRGB hex string (#RRGGBB).
    """
    lab_arr = np.array([[[l, a, b]]], dtype=np.float64)
    rgb_arr = lab2rgb(lab_arr)
    rgb_uint8 = (np.clip(rgb_arr[0, 0], 0, 1) * 255).astype(np.uint8)
    return f"#{rgb_uint8[0]:02x}{rgb_uint8[1]:02x}{rgb_uint8[2]:02x}"
