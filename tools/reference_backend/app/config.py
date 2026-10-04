# glowai_backend/app/config.py
"""
Central configuration for GlowAI backend.
All thresholds, parameters, and constants live here for transparent visual tuning.
"""

# Image Processing & Quality Gate Thresholds
MAX_IMAGE_SIDE = 1024               # Max side length in px for downscaling
MIN_FACE_HEIGHT_RATIO = 0.35        # Face height relative to image height
LAPLACIAN_BLUR_THRESHOLD = 40.0     # Variance of Laplacian on face crop below this is considered blurred
MIN_SKIN_LUMINANCE_L = 30.0         # Minimum acceptable median skin CIELAB L*
MAX_SKIN_LUMINANCE_L = 85.0         # Maximum acceptable median skin CIELAB L*
MAX_CLIPPED_PIXEL_FRACTION = 0.03   # Max fraction of skin pixels near 0 or 255
MAX_POSE_ANGLE_DEGREES = 18.0       # Max yaw, pitch, or roll angle allowed for quality pass

# Color Science & Skin Tone (ITA - Individual Typology Angle)
# ITA = atan((L* - 50) / b*) * (180 / pi)
ITA_BOUNDARIES = {
    "Very Light": 55.0,
    "Light": 41.0,
    "Intermediate": 28.0,
    "Tan": 10.0,
    "Brown": -30.0,
    # Below -30.0 is "Deep"
}

# Undertone ranges based on CIELAB hue angle atan2(b*, a*) in degrees
UNDERTONE_HUE_WARM_MIN = 35.0
UNDERTONE_HUE_WARM_MAX = 70.0

# Skin Type Detector (Shine Ratios: T-Zone vs Cheeks)
SPECULAR_SHINE_L_PERCENTILE = 88.0  # Percentile threshold for specular highlight candidate in L*
SPECULAR_SHINE_CHROMA_MAX = 20.0    # Specular highlights have low chroma sqrt(a*^2 + b*^2)
SHINE_RATIO_HIGH_THRESHOLD = 0.12    # Fraction of skin region pixels with shine to be considered high shine
DRY_TEXTURE_ENERGY_THRESHOLD = 18.0  # Texture roughness threshold for dry skin classification

# Acne Detector (Inflamed Lesions)
ACNE_A_STAR_EXCESS_MARGIN = 4.0      # Margin above median a* for red inflamed pixels
ACNE_MIN_DIAMETER_RATIO = 0.003      # Min blob diameter relative to face width
ACNE_MAX_DIAMETER_RATIO = 0.060      # Max blob diameter relative to face width
ACNE_MIN_CIRCULARITY = 0.35          # Min circularity (4*pi*area / perimeter^2)
ACNE_MIN_CONTRAST = 3.5              # Local contrast in a* channel vs background

# Dark Spot Detector
DARK_SPOT_L_DEFICIT_MARGIN = 6.0     # Margin below local background L*
DARK_SPOT_MIN_DIAMETER_RATIO = 0.003
DARK_SPOT_MAX_DIAMETER_RATIO = 0.050
DARK_SPOT_MIN_CIRCULARITY = 0.30
DARK_SPOT_MAX_RED_EXCESS = 4.0       # Dark spots shouldn't be inflamed red

# Redness Detector
REDNESS_A_STAR_EXCESS_MARGIN = 3.0   # Margin above median a*

# Texture Detector (DoG / Local Variance)
TEXTURE_DOG_SIGMA1 = 1.0
TEXTURE_DOG_SIGMA2 = 3.0

# Scoring & Severity Thresholds
CONDITION_SEVERITY_BANDS = {
    "None": 15,
    "Mild": 35,
    "Moderate": 65,
    "Severe": 100,
}

OVERALL_PENALTY_WEIGHTS = {
    "acne": 0.35,
    "redness": 0.20,
    "dark_spots": 0.20,
    "pigmentation": 0.15,
    "texture": 0.10,
}
