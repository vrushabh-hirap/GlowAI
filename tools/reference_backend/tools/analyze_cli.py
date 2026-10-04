# glowai_backend/tools/analyze_cli.py
import sys
import os
import json
import base64

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.imaging import decode_and_normalize, rgb_to_lab
from app.landmarks import get_landmarks_wrapper
from app.regions import get_region_polygons, get_region_coordinates
from app.quality import check_image_quality
from app.skin_mask import filter_valid_skin_pixels
from app.detectors.tone import detect_skin_tone
from app.detectors.skin_type import detect_skin_type
from app.detectors.redness import detect_redness
from app.detectors.acne import get_acne_detector
from app.detectors.dark_spots import detect_dark_spots
from app.detectors.pigmentation import detect_pigmentation
from app.detectors.texture import detect_texture
from app.scoring import compute_overall_scoring
from app.insights import generate_insights
from app.overlay import generate_overlays
from app.schemas import PrepResult, ConditionsResult

def analyze_file(file_path: str, out_dir: str = "cli_output"):
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        sys.exit(1)

    os.makedirs(out_dir, exist_ok=True)
    with open(file_path, "rb") as f:
        content = f.read()

    print(f"Analyzing {file_path} ({len(content)} bytes)...")
    rgb_image = decode_and_normalize(content)
    h, w, _ = rgb_image.shape

    lm_wrapper = get_landmarks_wrapper()
    face_count, landmarks_list, poses_list = lm_wrapper.process(rgb_image)
    lab_image = rgb_to_lab(rgb_image)

    landmarks = landmarks_list[0] if face_count > 0 else []
    pose = poses_list[0] if face_count > 0 else (0.0, 0.0, 0.0)

    quality = check_image_quality(rgb_image, lab_image, face_count, landmarks, pose)
    prep = PrepResult(minutes_since_wash=30, prepared=True)

    if not face_count or not quality.ok:
        print(f"Quality Check Failed! Issues: {quality.issues}")
        return

    raw_masks = get_region_polygons(landmarks, (h, w))
    region_coords = get_region_coordinates(landmarks)

    xs = [p[0] for p in landmarks]
    face_width = float(max(xs) - min(xs))

    filtered_masks = {}
    for r_name, r_mask in raw_masks.items():
        filtered_masks[r_name] = filter_valid_skin_pixels(rgb_image, r_mask)

    tone_result = detect_skin_tone(lab_image, filtered_masks.get("left_cheek", raw_masks.get("left_cheek")), quality.score)
    texture_result = detect_texture(lab_image, filtered_masks, quality.score)
    skin_type_result = detect_skin_type(lab_image, filtered_masks, texture_result.score, True, quality.score)
    redness_result = detect_redness(lab_image, filtered_masks, quality.score)
    
    acne_detector = get_acne_detector()
    acne_result, acne_bboxes = acne_detector.detect(rgb_image, lab_image, filtered_masks, face_width, quality.score)

    dark_spots_result, dark_spot_bboxes = detect_dark_spots(lab_image, filtered_masks, face_width, quality.score)
    pigmentation_result = detect_pigmentation(lab_image, filtered_masks, quality.score)

    conditions = ConditionsResult(
        acne=acne_result,
        redness=redness_result,
        dark_spots=dark_spots_result,
        pigmentation=pigmentation_result,
        texture=texture_result
    )

    score_info = compute_overall_scoring(conditions)
    insights = generate_insights(skin_type_result, tone_result, conditions, quality, prep, score_info["overall_score"])
    overlay = generate_overlays(rgb_image, lab_image, filtered_masks, acne_bboxes, dark_spot_bboxes)

    # Save overlay JPEGs
    for name, b64_str in [
        ("overlay_regions.jpg", overlay.regions_jpeg_base64),
        ("overlay_blemishes.jpg", overlay.blemishes_jpeg_base64),
        ("overlay_dark_spots.jpg", overlay.dark_spots_jpeg_base64),
        ("overlay_redness.jpg", overlay.redness_jpeg_base64)
    ]:
        if b64_str:
            out_p = os.path.join(out_dir, name)
            with open(out_p, "wb") as f_out:
                f_out.write(base64.b64decode(b64_str))
            print(f"Saved overlay: {out_p}")

    res_summary = {
        "overall_score": score_info["overall_score"],
        "severity": score_info["severity"],
        "skin_type": skin_type_result.label,
        "skin_tone": f"Level {tone_result.level} ({tone_result.label}, {tone_result.undertone}, {tone_result.hex})",
        "acne_count": acne_result.count,
        "dark_spots_count": dark_spots_result.count,
        "insights": insights,
    }
    print("\n--- Analysis Result Summary ---")
    print(json.dumps(res_summary, indent=2))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python tools/analyze_cli.py <path_to_face_image.jpg>")
        sys.exit(1)
    analyze_file(sys.argv[1])
