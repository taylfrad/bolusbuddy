import gzip
from io import BytesIO

from fastapi.testclient import TestClient
import numpy as np
from PIL import Image

from app.main import app


client = TestClient(app)


def _make_jpeg(width: int = 64, height: int = 64) -> bytes:
    image = Image.new("RGB", (width, height), color=(120, 180, 200))
    buffer = BytesIO()
    image.save(buffer, format="JPEG", quality=80)
    return buffer.getvalue()


def test_analyze_meal_quick_photo():
    jpeg = _make_jpeg()
    files = {"image": ("image.jpg", jpeg, "image/jpeg")}
    data = {
        "image_hash": "testhash123",
        "mode": "quick_photo",
        "width": "64",
        "height": "64",
    }
    response = client.post("/analyzeMeal", files=files, data=data)
    assert response.status_code == 200
    payload = response.json()
    assert payload["imageHash"] == "testhash123"
    assert payload["items"]
    assert "totalCarbs" in payload


def test_analyze_meal_with_depth_f32():
    jpeg = _make_jpeg(2, 2)
    depth = np.array([[0.55, 0.62], [0.58, 0.6]], dtype="<f4")
    depth_bytes = gzip.compress(depth.tobytes())
    files = {
        "image": ("image.jpg", jpeg, "image/jpeg"),
        "depth_f32": ("depth.bin", depth_bytes, "application/octet-stream"),
    }
    data = {
        "image_hash": "depthhash456",
        "mode": "depth_capture",
        "width": "2",
        "height": "2",
        "depth_encoding": "f32_gzip",
        "intrinsics_json": '{"fx":600,"fy":600,"cx":1,"cy":1}',
    }
    response = client.post("/analyzeMeal", files=files, data=data)
    assert response.status_code == 200
    payload = response.json()
    assert payload["items"][0]["grams"] > 0


def test_analyze_meal_cache_by_image_hash():
    jpeg = _make_jpeg()
    files = {"image": ("image.jpg", jpeg, "image/jpeg")}
    data = {
        "image_hash": "cachehash789",
        "mode": "quick_photo",
        "width": "64",
        "height": "64",
    }
    first = client.post("/analyzeMeal", files=files, data=data)
    assert first.status_code == 200
    second = client.post(
        "/analyzeMeal",
        files=files,
        data={**data, "mode": "depth_capture"},
    )
    assert second.status_code == 200
    assert second.json()["mode"] == "quick_photo"


def test_confirm_corrections():
    payload = {"image_hash": "testhash123", "items": [{"id": "item_1", "grams": 120, "unit": "g"}]}
    response = client.post("/confirmCorrections", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
