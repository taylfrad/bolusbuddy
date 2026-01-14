from __future__ import annotations

from pydantic import BaseModel, Field


class NutrientRange(BaseModel):
    value: float
    min: float
    max: float


class MealItem(BaseModel):
    id: str
    name: str
    grams: float
    unit: str
    confidence: float
    carbs: NutrientRange
    netCarbs: NutrientRange
    protein: NutrientRange
    fat: NutrientRange
    calories: NutrientRange


class MealEstimate(BaseModel):
    imageHash: str
    items: list[MealItem]
    totalCarbs: NutrientRange
    totalNetCarbs: NutrientRange
    totalProtein: NutrientRange
    totalFat: NutrientRange
    totalCalories: NutrientRange
    confidence: float = Field(ge=0.0, le=1.0)
    mode: str
