import os

API_VERSION = "v1"
USDA_API_KEY = os.getenv("USDA_API_KEY", "")
USDA_BASE_URL = "https://api.nal.usda.gov/fdc/v1"
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", "3600"))
MEAL_CACHE_TTL_SECONDS = int(os.getenv("MEAL_CACHE_TTL_SECONDS", "86400"))
