from io import BytesIO

from fastapi.testclient import TestClient
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


def test_confirm_corrections():
    payload = {"image_hash": "testhash123", "items": [{"id": "item_1", "grams": 120, "unit": "g"}]}
    response = client.post("/confirmCorrections", json=payload)
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
