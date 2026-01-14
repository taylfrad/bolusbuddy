from __future__ import annotations

import httpx

from ..config import USDA_API_KEY, USDA_BASE_URL
from ..db import db_session
from .cache import TTLCache

_food_cache = TTLCache(ttl_seconds=60 * 60 * 24)

_STATIC_FOODS = {
    "chicken breast": {"calories": 165, "carbs": 0, "protein": 31, "fat": 3.6, "fiber": 0},
    "white rice": {"calories": 130, "carbs": 28, "protein": 2.7, "fat": 0.3, "fiber": 0.4},
    "salad": {"calories": 33, "carbs": 3.6, "protein": 2.0, "fat": 0.4, "fiber": 1.6},
    "apple": {"calories": 52, "carbs": 13.8, "protein": 0.3, "fat": 0.2, "fiber": 2.4},
}


def lookup_food(query: str) -> dict:
    cached = _food_cache.get(query.lower())
    if cached:
        return cached

    if not USDA_API_KEY:
        fallback = _STATIC_FOODS.get(query.lower(), _STATIC_FOODS["salad"])
        result = {"description": query, "nutrients": fallback}
        _food_cache.set(query.lower(), result)
        return result

    params = {
        "api_key": USDA_API_KEY,
        "query": query,
        "pageSize": 1,
        "requireAllWords": True,
    }
    with httpx.Client(timeout=8.0) as client:
        response = client.get(f"{USDA_BASE_URL}/foods/search", params=params)
        response.raise_for_status()
        data = response.json()

    foods = data.get("foods", [])
    if not foods:
        fallback = _STATIC_FOODS.get(query.lower(), _STATIC_FOODS["salad"])
        result = {"description": query, "nutrients": fallback}
        _food_cache.set(query.lower(), result)
        return result

    food = foods[0]
    nutrients = _extract_nutrients(food.get("foodNutrients", []))
    result = {"description": food.get("description", query), "nutrients": nutrients}
    _food_cache.set(query.lower(), result)
    _store_food(result)
    return result


def _extract_nutrients(food_nutrients: list[dict]) -> dict:
    def get(nutrient_name: str) -> float:
        for entry in food_nutrients:
            if entry.get("nutrientName", "").lower() == nutrient_name.lower():
                return float(entry.get("value", 0))
        return 0.0

    return {
        "calories": get("Energy"),
        "carbs": get("Carbohydrate, by difference"),
        "protein": get("Protein"),
        "fat": get("Total lipid (fat)"),
        "fiber": get("Fiber, total dietary"),
    }


def _store_food(food: dict) -> None:
    with db_session() as conn:
        cursor = conn.execute(
            "INSERT INTO foods (description) VALUES (?)",
            (food["description"],),
        )
        food_id = cursor.lastrowid
        for nutrient_name, amount in food["nutrients"].items():
            conn.execute(
                """
                INSERT INTO nutrients (food_id, nutrient_name, unit, amount_per_100g)
                VALUES (?, ?, ?, ?)
                """,
                (food_id, nutrient_name, "g" if nutrient_name != "calories" else "kcal", amount),
            )
        conn.commit()
