# glowai_backend/app/quality.py
import cv2
import numpy as np
from typing import List, Tuple
from app.config import (
    MIN_FACE_HEIGHT_RATIO,
    LAPLACIAN_BLUR_THRESHOLD,
    MIN_SKIN_LUMINANCE_L,
    MAX_SKIN_LUMINANCE_L,
    MAX_CLIPPED_PIXEL_FRACTION,
    MAX_POSE_ANGLE_DEGREES,
)
from app.schemas import QualityResult, QualityMetrics

def check_image_quality(
    rgb_image: np.ndarray,
    lab_image: np.ndarray,
    face_count: int,
    landmarks: List[Tuple[int, int]],
    pose: Tuple[float, float, float],
) -> QualityResult:
    issues = []
    h, w, _ = rgb_image.shape

    if face_count == 0:
        return QualityResult(
            ok=False,
            score=0,
            issues=["No face detected in the photo. Please center your face in good lighting."],
            metrics=QualityMetrics()
        )

    if face_count > 1:
        issues.append(f"Multiple faces detected ({face_count}). Please make sure only one face is in the photo.")

    yaw, pitch, roll = pose

    # Calculate face height ratio from landmarks (chin landmark 152 vs top forehead landmark 10)
    face_height_ratio = 0.0
    if len(landmarks) >= 468:
        top_y = landmarks[10][1]
        bottom_y = landmarks[152][1]
        face_height_ratio = abs(bottom_y - top_y) / float(h)
        if face_height_ratio < MIN_FACE_HEIGHT_RATIO:
            issues.append(f"Face is too far away ({int(face_height_ratio*100)}% of preview height). Move closer.")

    # Blur check (Variance of Laplacian inside face bounding box)
    blur_score = 0.0
    if len(landmarks) >= 468:
        xs = [p[0] for p in landmarks]
        ys = [p[1] for p in landmarks]
        xmin, xmax = max(0, min(xs)), min(w, max(xs))
        ymin, ymax = max(0, min(ys)), min(h, max(ys))
        
        face_crop = cv2.cvtColor(rgb_image[ymin:ymax, xmin:xmax], cv2.COLOR_RGB2GRAY)
        if face_crop.size > 0:
            blur_score = float(cv2.Laplacian(face_crop, cv2.CV_64F).var())
            if blur_score < LAPLACIAN_BLUR_THRESHOLD:
                issues.append("Photo is blurry. Hold your phone steady and ensure clear focus.")

    # Exposure & Clipping check inside face crop
    brightness_L = 50.0
    clipped_frac = 0.0
    if len(landmarks) >= 468:
        L_chan = lab_image[ymin:ymax, xmin:xmax, 0]
        brightness_L = float(np.median(L_chan)) if L_chan.size > 0 else 50.0
        
        # Check clipping in gray channel
        gray_crop = cv2.cvtColor(rgb_image[ymin:ymax, xmin:xmax], cv2.COLOR_RGB2GRAY)
        if gray_crop.size > 0:
            clipped_pixels = np.sum((gray_crop < 10) | (gray_crop > 245))
            clipped_frac = float(clipped_pixels) / float(gray_crop.size)
            if clipped_frac > MAX_CLIPPED_PIXEL_FRACTION:
                issues.append("Harsh lighting or shadows detected. Face a soft, even light source.")

        if brightness_L < MIN_SKIN_LUMINANCE_L:
            issues.append("Photo is too dark. Move to a well-lit room or face a window.")
        elif brightness_L > MAX_SKIN_LUMINANCE_L:
            issues.append("Photo is overexposed. Avoid direct harsh sunlight.")

    # Pose angle check
    if abs(yaw) > MAX_POSE_ANGLE_DEGREES or abs(pitch) > MAX_POSE_ANGLE_DEGREES or abs(roll) > MAX_POSE_ANGLE_DEGREES:
        issues.append(f"Head is tilted (yaw: {int(yaw)}°, pitch: {int(pitch)}°). Look straight at the camera.")

    # Overall quality score (0..100)
    quality_score = 100
    quality_score -= len(issues) * 20
    if blur_score < LAPLACIAN_BLUR_THRESHOLD:
        quality_score -= 25
    quality_score = max(0, min(100, quality_score))

    ok = len(issues) == 0

    return QualityResult(
        ok=ok,
        score=quality_score,
        issues=issues,
        metrics=QualityMetrics(
            blur=round(blur_score, 2),
            brightness_L=round(brightness_L, 2),
            clipped_fraction=round(clipped_frac, 4),
            yaw=round(yaw, 2),
            pitch=round(pitch, 2),
            roll=round(roll, 2),
            face_height_ratio=round(face_height_ratio, 2)
        )
    )
