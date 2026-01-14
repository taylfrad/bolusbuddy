from __future__ import annotations

import gzip
import io
import json
from typing import Annotated

import numpy as np
from fastapi import FastAPI, File, Form, UploadFile

from .config import MEAL_CACHE_TTL_SECONDS
from .db import init_db
from .schemas import MealEstimate, MealItem, NutrientRange
from .services.cache import TTLCache
from .services.portion import (
    estimate_portions_with_depth,
    estimate_without_depth,
    parse_intrinsics,
)
from .services.recognition import recognize_foods
from .services.usda import lookup_food

app = FastAPI(title="BolusBuddy API", version="1.0.0")
meal_cache = TTLCache(ttl_seconds=MEAL_CACHE_TTL_SECONDS)


@app.on_event("startup")
def on_startup() -> None:
    init_db()


@app.post("/analyzeMeal", response_model=MealEstimate)
async def analyze_meal(
    image: Annotated[UploadFile, File(...)],
    image_hash: Annotated[str, Form(...)],
    mode: Annotated[str, Form(...)],
    width: Annotated[int, Form(...)],
    height: Annotated[int, Form(...)],
    depth_png16: Annotated[UploadFile | None, File(None)] = None,
    depth_f32: Annotated[UploadFile | None, File(None)] = None,
    depth_encoding: Annotated[str | None, Form(None)] = None,
    confidence_png: Annotated[UploadFile | None, File(None)] = None,
    intrinsics_json: Annotated[str | None, Form(None)] = None,
    extra_images: Annotated[list[UploadFile] | None, File(None)] = None,
) -> MealEstimate:
    cached = meal_cache.get(image_hash)
    if cached:
        return cached

    image_bytes = await image.read()
    extra_bytes = []
    if extra_images:
        for extra in extra_images:
            extra_bytes.append(await extra.read())

    recognized = recognize_foods(image_bytes, extra_bytes)
    depth_map = await _decode_depth(depth_png16, depth_f32, depth_encoding, width, height)
    intrinsics = parse_intrinsics(intrinsics_json)

    if depth_map is not None and intrinsics is not None:
        items = estimate_portions_with_depth(depth_map, intrinsics, recognized)
    else:
        items = estimate_without_depth(recognized)

    meal_items: list[MealItem] = []
    for item in items:
        nutrients = lookup_food(item["name"])["nutrients"]
        grams = float(item["grams"])
        factor = grams / 100.0
        carbs = nutrients["carbs"] * factor
        fiber = nutrients["fiber"] * factor
        net_carbs = max(0.0, carbs - fiber)
        protein = nutrients["protein"] * factor
        fat = nutrients["fat"] * factor
        calories = nutrients["calories"] * factor

        confidence = float(item["confidence"])
        meal_items.append(
            MealItem(
                id=item["id"],
                name=item["name"],
                grams=grams,
                unit="g",
                confidence=confidence,
                carbs=_range(carbs, confidence),
                netCarbs=_range(net_carbs, confidence),
                protein=_range(protein, confidence),
                fat=_range(fat, confidence),
                calories=_range(calories, confidence),
            )
        )

    totals = _sum_totals(meal_items)
    overall_confidence = float(np.mean([item.confidence for item in meal_items]))

    estimate = MealEstimate(
        imageHash=image_hash,
        items=meal_items,
        totalCarbs=totals["carbs"],
        totalNetCarbs=totals["net_carbs"],
        totalProtein=totals["protein"],
        totalFat=totals["fat"],
        totalCalories=totals["calories"],
        confidence=overall_confidence,
        mode=mode,
    )
    meal_cache.set(image_hash, estimate)
    return estimate


@app.post("/confirmCorrections")
async def confirm_corrections(payload: dict) -> dict:
    image_hash = payload.get("image_hash")
    items = payload.get("items", [])
    if image_hash:
        cached = meal_cache.get(image_hash)
        if cached:
            meal_cache.set(image_hash, cached)
    return {"status": "ok", "items": len(items)}


def _range(value: float, confidence: float) -> NutrientRange:
    spread = 0.15 + (1.0 - confidence) * 0.35
    min_val = max(0.0, value * (1 - spread))
    max_val = value * (1 + spread)
    return NutrientRange(value=value, min=min_val, max=max_val)


def _sum_totals(items: list[MealItem]) -> dict:
    def sum_range(selector) -> NutrientRange:
        value = sum(selector(item).value for item in items)
        min_val = sum(selector(item).min for item in items)
        max_val = sum(selector(item).max for item in items)
        return NutrientRange(value=value, min=min_val, max=max_val)

    return {
        "carbs": sum_range(lambda item: item.carbs),
        "net_carbs": sum_range(lambda item: item.netCarbs),
        "protein": sum_range(lambda item: item.protein),
        "fat": sum_range(lambda item: item.fat),
        "calories": sum_range(lambda item: item.calories),
    }


async def _decode_depth(
    depth_png16: UploadFile | None,
    depth_f32: UploadFile | None,
    depth_encoding: str | None,
    width: int,
    height: int,
) -> np.ndarray | None:
    if depth_png16 is not None:
        data = await depth_png16.read()
        image = _read_png16(data)
        return image
    if depth_f32 is not None and depth_encoding == "f32_gzip":
        data = await depth_f32.read()
        raw = gzip.decompress(data)
        depth = np.frombuffer(raw, dtype="<f4")
        if depth.size == width * height:
            return depth.reshape((height, width))
    return None


def _read_png16(data: bytes) -> np.ndarray:
    from PIL import Image

    image = Image.open(io.BytesIO(data))
    array = np.array(image).astype(np.float32)
    if array.max() > 10:
        array = array / 1000.0
    return array
