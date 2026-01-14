# BolusBuddy Backend

## Endpoints

### POST `/analyzeMeal`

Multipart form data:
- `image` (JPEG)
- `image_hash` (SHA-256)
- `mode` (`depth_capture`, `quick_photo`, `multi_angle`)
- `width`, `height` (image dims)
- Optional:
  - `depth_png16` (16-bit PNG)
  - `depth_f32` (gzip float32)
  - `depth_encoding` (`f32_gzip`)
  - `confidence_png` (8-bit PNG)
  - `intrinsics_json` (`{"fx":...,"fy":...,"cx":...,"cy":...}`)
  - `extra_images` (JPEG)

Returns `MealEstimate` with per-item and total macro ranges.

### POST `/confirmCorrections`

```json
{
  "image_hash": "...",
  "items": [{"id": "item_1", "grams": 120, "unit": "g"}]
}
```

## DB Schema (SQLite)

```sql
CREATE TABLE foods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fdc_id INTEGER,
  description TEXT NOT NULL,
  data_type TEXT,
  brand_owner TEXT,
  ingredients TEXT
);

CREATE TABLE nutrients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  food_id INTEGER NOT NULL,
  nutrient_name TEXT NOT NULL,
  unit TEXT NOT NULL,
  amount_per_100g REAL NOT NULL,
  FOREIGN KEY(food_id) REFERENCES foods(id)
);

CREATE TABLE serving_units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  food_id INTEGER NOT NULL,
  unit TEXT NOT NULL,
  grams_per_unit REAL NOT NULL,
  FOREIGN KEY(food_id) REFERENCES foods(id)
);
```
