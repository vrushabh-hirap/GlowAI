# glowai_backend/app/main.py
import time
import uuid
from typing import Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware

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
from app.routers_appointments import router as appointments_router
from app.routers_auth import router as auth_router
from app.routers_doctors import router as doctors_router
from app.routers_prescriptions import router as prescriptions_router
from app.schemas import (
    HealthResponse,
    AnalyzeResponse,
    PrepResult,
    ConditionsResult,
)

app = FastAPI(
    title="GlowAI Face Analysis API",
    description="Real classical computer vision & color science analysis for GlowAI face scan.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(doctors_router)
app.include_router(appointments_router)
app.include_router(prescriptions_router)

@app.get("/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse(status="ok", analysis_version="1.0.0")

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze_photo(
    image: UploadFile = File(...),
    minutes_since_wash: Optional[int] = Form(None),
    prepared: bool = Form(True)
):
    start_t = time.time()
    req_id = str(uuid.uuid4())

    # Limit file size to 10 MB
    content = await image.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File size exceeds 10 MB limit.")

    # Accept JPEG/PNG/WebP
    if image.content_type and not any(t in image.content_type.lower() for t in ["jpeg", "jpg", "png", "webp"]):
        raise HTTPException(status_code=400, detail="Invalid image format. Supported formats: JPEG, PNG, WebP.")

    # 1. Decode & normalize
    try:
        rgb_image = decode_and_normalize(content)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Cannot decode image file: {str(e)}")

    h, w, _ = rgb_image.shape

    # 2. Landmarks & pose
    lm_wrapper = get_landmarks_wrapper()
    face_count, landmarks_list, poses_list = lm_wrapper.process(rgb_image)

    # Convert to CIELAB once
    lab_image = rgb_to_lab(rgb_image)

    landmarks = landmarks_list[0] if face_count > 0 else []
    pose = poses_list[0] if face_count > 0 else (0.0, 0.0, 0.0)

    # 3. Quality gate check
    quality = check_image_quality(rgb_image, lab_image, face_count, landmarks, pose)
    prep = PrepResult(minutes_since_wash=minutes_since_wash, prepared=prepared)

    if not face_count or not quality.ok:
        elapsed_ms = int((time.time() - start_t) * 1000)
        return AnalyzeResponse(
            request_id=req_id,
            analysis_version="1.0.0",
            processing_ms=elapsed_ms,
            face_detected=(face_count > 0),
            quality=quality,
            prep=prep,
            overall_score=0,
            severity="None",
            risk="Low",
            see_doctor=False,
            recommended_specialty="Dermatologist",
            insights=quality.issues,
        )

    # 4. Regions
    raw_masks = get_region_polygons(landmarks, (h, w))
    region_coords = get_region_coordinates(landmarks)

    # Face width in pixels
    xs = [p[0] for p in landmarks]
    face_width = float(max(xs) - min(xs))

    # 5. Skin pixel filtering per region
    filtered_masks = {}
    for r_name, r_mask in raw_masks.items():
        filtered_masks[r_name] = filter_valid_skin_pixels(rgb_image, r_mask)

    # 6. Run Detectors
    tone_result = detect_skin_tone(lab_image, filtered_masks.get("left_cheek", raw_masks.get("left_cheek")), quality.score)
    texture_result = detect_texture(lab_image, filtered_masks, quality.score)
    skin_type_result = detect_skin_type(lab_image, filtered_masks, texture_result.score, prepared, quality.score)

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

    # 7. Scoring
    score_info = compute_overall_scoring(conditions)

    # 8. Insights
    insights = generate_insights(
        skin_type=skin_type_result,
        skin_tone=tone_result,
        conditions=conditions,
        quality=quality,
        prep=prep,
        overall_score=score_info["overall_score"]
    )

    # 9. Overlays
    overlay = generate_overlays(rgb_image, lab_image, filtered_masks, acne_bboxes, dark_spot_bboxes)

    elapsed_ms = int((time.time() - start_t) * 1000)

    return AnalyzeResponse(
        request_id=req_id,
        analysis_version="1.0.0",
        processing_ms=elapsed_ms,
        face_detected=True,
        quality=quality,
        prep=prep,
        skin_type=skin_type_result,
        skin_tone=tone_result,
        conditions=conditions,
        overall_score=score_info["overall_score"],
        severity=score_info["severity"],
        risk=score_info["risk"],
        see_doctor=score_info["see_doctor"],
        recommended_specialty=score_info["recommended_specialty"],
        insights=insights,
        regions=region_coords,
        overlay=overlay,
        disclaimer="Informational screening only. Not a medical diagnosis."
    )
