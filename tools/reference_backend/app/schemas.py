# glowai_backend/app/schemas.py
from typing import Dict, List, Optional
from pydantic import BaseModel, Field

class QualityMetrics(BaseModel):
    blur: float = 0.0
    brightness_L: float = 0.0
    clipped_fraction: float = 0.0
    yaw: float = 0.0
    pitch: float = 0.0
    roll: float = 0.0
    face_height_ratio: float = 0.0

class QualityResult(BaseModel):
    ok: bool
    score: int
    issues: List[String] if False else List[str] = Field(default_factory=list)
    metrics: QualityMetrics

class PrepResult(BaseModel):
    minutes_since_wash: Optional[int] = None
    prepared: bool

class SkinTypeMetrics(BaseModel):
    tzone_shine: float
    cheek_shine: float

class SkinTypeResult(BaseModel):
    label: str
    confidence: float
    metrics: SkinTypeMetrics

class SkinToneResult(BaseModel):
    level: int
    label: str
    ita_degrees: float
    undertone: str
    hex: str
    confidence: float

class ConditionResult(BaseModel):
    score: int
    count: Optional[int] = None
    severity: str
    confidence: float

class ConditionsResult(BaseModel):
    acne: ConditionResult
    redness: ConditionResult
    dark_spots: ConditionResult
    pigmentation: ConditionResult
    texture: ConditionResult

class OverlayResult(BaseModel):
    regions_jpeg_base64: str = ""
    blemishes_jpeg_base64: str = ""
    dark_spots_jpeg_base64: str = ""
    redness_jpeg_base64: str = ""

class HealthResponse(BaseModel):
    status: str = "ok"
    analysis_version: str = "1.0.0"

class AnalyzeResponse(BaseModel):
    request_id: str
    analysis_version: str = "1.0.0"
    processing_ms: int
    face_detected: bool
    quality: QualityResult
    prep: PrepResult
    skin_type: Optional[SkinTypeResult] = None
    skin_tone: Optional[SkinToneResult] = None
    conditions: Optional[ConditionsResult] = None
    overall_score: int = 0
    severity: str = "None"
    risk: str = "Low"
    see_doctor: bool = False
    recommended_specialty: str = "Dermatologist"
    insights: List[str] = Field(default_factory=list)
    regions: Dict[str, Dict[str, List[int]]] = Field(default_factory=dict)
    overlay: OverlayResult = Field(default_factory=OverlayResult)
    disclaimer: str = "Informational screening only. Not a medical diagnosis."
