from __future__ import annotations

import hashlib


FOOD_LABELS = [
    "chicken breast",
    "white rice",
    "salad",
    "steamed broccoli",
    "apple slices",
    "pasta",
    "salmon",
    "potatoes",
]


def recognize_foods(image_bytes: bytes, extra_images: list[bytes]) -> list[dict]:
    seed = hashlib.sha256(image_bytes).hexdigest()
    start = int(seed[:2], 16) % len(FOOD_LABELS)
    count = 2 if extra_images else 1
    items = []
    for i in range(count):
        label = FOOD_LABELS[(start + i) % len(FOOD_LABELS)]
        confidence = 0.78 - (i * 0.08)
        items.append(
            {
                "id": f"item_{i+1}",
                "name": label,
                "confidence": max(0.45, confidence),
            }
        )
    return items
