# glowai_backend/tests/test_api.py
import io
import numpy as np
import cv2
from PIL import Image
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "analysis_version" in data

def test_analyze_endpoint_no_face_rejection():
    # Create plain black image (no face)
    img = Image.new("RGB", (300, 300), color="black")
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    buf.seek(0)

    files = {"image": ("test.jpg", buf, "image/jpeg")}
    data = {"prepared": "true", "minutes_since_wash": "30"}
    
    response = client.post("/analyze", files=files, data=data)
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["face_detected"] is False
    assert res_json["quality"]["ok"] is False
    assert len(res_json["quality"]["issues"]) > 0
